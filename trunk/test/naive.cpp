/*
 * Copyright (c) 2004-2005 Gabor Greif
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
 
/* QUOTE OF THE DAY

 From #gcc channel:

    bje: nickc told me once that compilers are buggers, which is why we need debuggers.

*/

#include <vector>
#include <map>
#include <cstring>
#include <algorithm>
#include <iostream>




#include "alloc.hpp"
#include "raw.hpp"
#include "safemacros.h"

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

namespace aL4nin
{
    template <>
    struct meta<int>
    {
        int* allocate(std::size_t elems)
        {
            return new int[elems];
        }
    };



    template <>
    meta<int>& get_meta<int>(std::size_t)
    {
        static meta<int> m;
        return m;
    }
}

// metadata entry defines the
// marking method:
// a) bitpattern (up to 31 bits representing pointers to follow)
// b) freestyle procedural marker
//     - uncommitted arrays must zero out object data before setting marker
//     - concurrency in data <--> metadata access???


// let's fix some hard conventions
// - T* is non-null collectable pointer that is to be followed
// - nullable<T> is a possibly NULL pointer that should be followed
// - T& is a non-assignable, non-null reference that is to be followed
// - const T is a non-assignable non-null reference that is to be followed
// - const nullable<T> is a non-assignable, possibly NULL pointer that should be followed
// - references to builtin basic types are not followed
// - non<T> is a pointer that will not be followed
// - const non<T> is a non-assignable pointer that will not be followed
// - thresholded<T, N> is like nullable but does not follow <= N

#define WRAP(TYPE, MODIFIER) \
    MODIFIER ## _WRAPPER(TYPE)

#define BARE_WRAPPER(TYPE) TYPE
#define _WRAPPER(TYPE) BARE_WRAPPER(TYPE)
#define NULLABLE_WRAPPER(TYPE) nullable<TYPE>
#define NON_WRAPPER(TYPE) non<TYPE>
#define NULLABLE_WRAPPER(TYPE) nullable<TYPE>

template <typename T>
struct nullable
{
    T* real;
    nullable(T* real)
        : real(real)
        {}
};


template <typename T>
struct non
{
    T real;
    non(const T& real)
        : real(real)
        {}
};


WRAP(int, NON) hh(42);
WRAP(int, /*BARE*/) hh1;
WRAP(int, NULLABLE) hh2(0);

struct foo
{
    foo& f;
    foo() : f(*this)
        {}
    void bar()
        {
///            int i(&foo::f);
        }

};


namespace aL4nin
{

// Helpers (these should go into a header).
//
namespace {

template <unsigned NEED, typename DATA, unsigned FROM>
struct UnsetBitsAt
{
    static inline unsigned find(DATA d)
    {
        enum
        {
            at = sizeof(DATA) * 8 - FROM,
            mask = ((1 << NEED) - 1) << at
        };

        if (d & mask)
            return UnsetBitsAt<NEED, DATA, FROM - 1>::find(d);
        else
            return at;
    }
};

// here go specializations
template <unsigned NEED, typename DATA>
struct UnsetBitsAt<NEED, DATA, 0>
{
    static inline unsigned find(DATA d)
    {
        return sizeof(DATA) * 8;
    }
};
}


template <unsigned NEED, typename DATA>
unsigned FindUnsetBits(DATA d)
{
    return UnsetBitsAt<NEED, DATA, sizeof(DATA) * 8 - NEED + 1>::find(d);
}


}
namespace aL4nin
{

// Anatomy of the WORLD.
//
// The world is the part of the process memory that the GC
// is interested in. It is completely subdivided in clusters.
// The first cluster of the world is special.
// Every other cluster is subdivided into 2^p pages. The size
// of a page must match a (supported) VM page size.
// The number of pages a cluster consists of (2^p) is dependent
// on the cluster, so the world must store the ps in the special
// cluster in order to be able to find the cluster boundaries.
// At the start of each cluster we find the metaobjects.
// The metaobject at displacement 0 (into the cluster) is
// special, describing the metaobjects themselves, i.e. it is
// a meta-metaobject.
// Metaobjects are just additional information that is factored
// out of the objects or can add information about the validity
// and GC-properties of a group of objects.
//
// Clusters comprised of one page are possible (p=0),
// in this case the metaobjects and objects are both
// located in the same VM page.

// Note: later I may introduce a multiworld, which may be
// a linked list of worlds.




// World: define the layout of a world in the memory
// and subdivide in pages. Provide info about the
// location and size.
// NUMPAGES: how many pages should this world hold
// BASE: where should this world be located in the memory
// PAGE: bits needed to address a byte in a page. i.e.
//       pagesize == 2^PAGE bytes
//
template <unsigned NUMPAGES, unsigned BASE, unsigned PAGE>
struct World
{
    enum { PageSize = 1 << PAGE };

    struct Page
    {
        char raw[PageSize];
    };

    Page pages[NUMPAGES];

    static void* start(void)
        {
            Divides<PageSize, BASE> c1;
            return reinterpret_cast<void*>(BASE);
        }

    static size_t size(void)
        {
            return PageSize * NUMPAGES;
        }

    static World& self(void)
        {
            return *static_cast<World*>(start());
        }

    template <typename WORLD>
    static WORLD& selfAs(void)
        {
            return static_cast<WORLD&>(self());
        }

    void protectPageRW(unsigned pagenum)
        {
            protectClusterRW(pagenum, 1);
        }

    void unprotectPage(unsigned pagenum)
        {
            unprotectCluster(pagenum, 1);
        }

    void protectClusterRW(unsigned from_pagenum, unsigned ps)
        {
            if (0 != mprotect(pages + from_pagenum, PageSize * ps, PROT_NONE))
                perror("mprotect");
        }

    void unprotectCluster(unsigned from_pagenum, unsigned ps)
        {
            if (0 != mprotect(pages + from_pagenum, PageSize * ps, PROT_READ | PROT_WRITE))
                perror("mprotect");
        }

    void* operator new(size_t s, int hdl)
        {
            void* here(mmap(start(),
                            s,
                            PROT_READ | PROT_WRITE,
                            MAP_SHARED | MAP_FIXED,
                            hdl,
                            0));
            if (MAP_FAILED == here)
                perror("mmap");

            assert(s == size());
            assert(here == start());
            assert(sysconf(_SC_PAGESIZE) == PageSize);
    
            return here;
        }
};


// MISC ideas
// allocation: tell a cluster to allocate an obj of a certain
// metadata "class". returns a cluster address, which may be the
// same as the current cluster or pointer to a new cluster with
// the object being in there. In this case the pointer must be
// stored away for the next allocation request.

// GC: use a posix message queue to tell which thread stack ranges
// must be mprotected. This way the threads can be starved out
// systematically.



template <unsigned long CLUSTER>
unsigned char* GapFinder(unsigned char*, size_t pages, size_t maxpages);

void GapFiller(unsigned char* gap, size_t ps)
{
    static const unsigned char pattern[] = 
        {
              1, 2, 3, 4, 5, 6, 7, 8 , 9, 10
            , 11, 12, 13, 14, 15, 16, 17, 18 , 19, 20
            , 21, 22, 23, 24, 25, 26, 27, 28 , 29, 30
            , 31, 32
        };

    if (ps < sizeof pattern)
    {
        memcpy(gap, pattern, ps);
    }
    else
    {
        assert(!(reinterpret_cast<unsigned long>(gap) & 0x11));
        unsigned long pat(*reinterpret_cast<const unsigned long*>(pattern));
        Same<sizeof pat, 4> c1;
        Same<sizeof pattern, 32> c2;

        unsigned char* begin(gap);
        for (const unsigned char* end(gap + ps - sizeof pat); begin <= end; begin += sizeof pat, pat += 0x04040404)
        {
            *reinterpret_cast<unsigned long*>(begin) = pat;
        }

        for (size_t remains(ps & (sizeof pat - 1)); remains > 0; --remains, ++begin)
        {
            *begin = begin[-1] + 1;
        }
    }
};
    

template <unsigned NUMPAGES, unsigned BASE, unsigned PAGE>
struct ClusteredWorld : World<NUMPAGES, BASE, PAGE>
{
    template <unsigned long CLUSTER, unsigned long SCALE>
    struct Cluster
    {
        enum { Magnitude = CLUSTER };

        template <unsigned long GRAN>
        static inline const void* Raw2Meta(const void* obj)
        {
            return RawObj2Meta<PAGE + CLUSTER, SCALE, GRAN>(obj);
        }

        template <unsigned long OBJBYTES, unsigned long GRAN>
        static inline unsigned Raw2Index(const void* obj)
        {
            return RawObj2Index<PAGE + CLUSTER, OBJBYTES, SCALE, GRAN>(obj);
        }

        template <unsigned long OBJBYTES>
        static inline void* Meta2Object(void* meta, unsigned index)
        {
            return RawMeta2Obj<PAGE + CLUSTER, OBJBYTES, SCALE>(meta, index);
        }

        template <typename TYPE>
        static inline TYPE* Meta2Cluster(void* meta)
        {
            return static_cast<TYPE*>(static_cast<Cluster*>(RawMeta2Cluster<PAGE + CLUSTER>(meta)));
        }
        
        void printCharacteristics(void)
        {
            std::cerr << "NUMPAGES: " << NUMPAGES << std::endl
                      << "BASE: " << BASE << std::endl
                      << "PAGE: " << PAGE << std::endl
                      << "CLUSTER: " << SCALE << std::endl;
        };
    };

    static unsigned char& clusterPage(unsigned i)
    {
        return *static_cast<unsigned char*>(ClusteredWorld::start());
    }

    ClusteredWorld(void)
        {
            unsigned char& first(clusterPage(0));
            memset(&first, 0, NUMPAGES);
            first = 1; // mark the clusterPage as used
        }

    template <unsigned long CLUSTER>
    static void* allocate(size_t ps = std::min(1 << CLUSTER, 255))
    {
        assert(ps < 256);
        // TODO ### grab semaphore
        unsigned char* first(&clusterPage(0));
        unsigned char* gap(GapFinder<CLUSTER>(first, ps, NUMPAGES));
        assert(gap); // for now ###
        assert(gap - first < NUMPAGES);
        GapFiller(gap, ps);
        return &ClusteredWorld::self().pages[gap - first];
    }
    
};

/// template FastestAccess
template <unsigned long CLUSTER>
struct FastestAccess;


template <>
struct FastestAccess<2>
{
    typedef unsigned long is;
    enum { increment = 1 << 2/*, advance = sizeof(is), bits = advance - 1, mask = ~bits*/ };
    
    static bool isZeroRange(const unsigned char* first, size_t pages)
    {
        static const unsigned char zeroes[] = { 0, 0, 0, 0 };
        return 0 == memcmp(first, zeroes, pages);
    }
    
};

template <>
struct FastestAccess<3>
{
    typedef unsigned long is;
    enum { increment = 1 << 3/*, advance = sizeof(is), bits = advance - 1, mask = ~bits*/ };
    
    static bool isZeroRange(const unsigned char* first, size_t pages)
    {
        static const unsigned char zeroes[] = { 0, 0, 0, 0, 0, 0, 0, 0 };
        return 0 == memcmp(first, zeroes, pages);
    }
    
};

template <unsigned long CLUSTER>
struct FastestAccess
{
    typedef unsigned long is;
    enum { increment = 1 << CLUSTER, advance = sizeof(is), bits = advance - 1, mask = ~bits };
    
    static bool isZeroRange(const unsigned char* first, size_t pages)
    {
        const unsigned char* const end(first + pages - advance);
        for (; first < end; first += advance)
        {
            if (*reinterpret_cast<const is*>(first))
                return false;
        }
        
        switch (pages & bits)
        {
            case 3:
                if (end[advance - 3])
                    return false;
            case 2:
                if (end[advance - 2])
                    return false;
            case 1:
                if (end[advance - 1])
                    return false;
        }

        return true;
    }
    
};


template <unsigned long CLUSTER>
unsigned char* GapFinder(unsigned char* first, size_t pages, size_t maxpages)
{
    assert(pages <= FastestAccess<CLUSTER>::increment);

    register unsigned char* end(first + maxpages);
    register bool shortcluster(pages < 4);

    for (; first < end; first += FastestAccess<CLUSTER>::increment)
    {
        if (shortcluster)
        {
            switch (pages)
            {
                case 1:
                {
                    if (!*first)
                        return first;
                    continue;
                }
                case 2:
                {
                    if (!*reinterpret_cast<unsigned short*>(first))
                        return first;
                    continue;
                }
                case 3:
                {
                    if (*reinterpret_cast<unsigned short*>(first)
                        || first[2])
                        continue;
                    return first;
                }
            }
        }
        else
        {
            if (FastestAccess<CLUSTER>::isZeroRange(first, pages))
                return first;
        }
    }

    return NULL;
};


}

using namespace aL4nin;

#   ifdef __APPLE__
    typedef ClusteredWorld<2000, 0xF0000000UL, 12> world;
#   else
    typedef ClusteredWorld<1000, 0xF0000000UL, 13> world;
#   endif
    

#include "alloc.cpp"

using namespace std;

namespace aL4nin
{
    template <>
    meta<void>* object_meta<void>(void* p)
    {
        if (!p)
            return 0;

        static meta<void> me;
        return &me;
    }

    template <>
    struct meta<std::_Rb_tree_node<std::pair<const int, int> > >
    {
        typedef std::_Rb_tree_node<std::pair<const int, int> > payload;

        payload* allocate(std::size_t elems)
        {
            return new payload[elems];
        }
    };

    template <>
    meta<std::_Rb_tree_node<std::pair<const int, int> > >& get_meta<std::_Rb_tree_node<std::pair<const int, int> > >(std::size_t)
    {
        static meta<std::_Rb_tree_node<std::pair<const int, int> > > m;
        return m;
    }

    struct cons : pair<void*, void*>
    {};

    template <>
    struct meta<cons>
    {
        enum { bits = 32 };

        cons* objects;
        bool bitmap[bits];
        bool marks[bits];

        meta(void)
            {
                memset(this, 0, sizeof *this);
            }

        cons* allocate(std::size_t)
            {
                if (!objects)
                {
                    objects = new cons[bits];
                    *bitmap = true;
                    return objects;
                }

                bool* end(bitmap + meta<cons>::bits);
                bool* freebit(find(bitmap, end, 0));
                if (freebit == end)
                    return 0;

                *freebit = true;

                return objects + (freebit - bitmap);
            }

        void mark(const cons* p PLUS_VERBOSITY_ARG())
            {
                // simple minded!
                int i(bits - 1);
                for (const cons* my(objects + i);
                     i >= 0;
                     --my, --i)
                {
                    if (bitmap[i] && p == my)
                    {
                        VERBOSE("identified as cons");
                        if (marks[i])
                        {
                            VERBOSE("already marked");
                            return /*true*/;
                        }


                        marks[i] = true;
                        if (object_meta(p->first))
                        {
                            object_meta(p->first)->mark(p->first PASS_VERBOSE);
                        }

                        if (object_meta(p->second))
                        {
                            object_meta(p->second)->mark(p->second PASS_VERBOSE);
                        }


                        return /*true*/;
                    }
                }

                VERBOSE_ABORT("not a cons");
            }
    };


    template <>
    meta<cons>& get_meta<cons>(std::size_t)
    {
        static meta<cons> m;

        if (find(m.bitmap, m.bitmap + meta<cons>::bits, 0))
            return m;

        abort();
    }

    void* rooty(0);

    void collect(VERBOSITY_ARG())
    {
        VERBOSE("starting");

        // do we need meta<void>
        // or can we safely assume
        // to know the exact meta type?
        // probably not: if a slot is just declared
        // <object> we never know the metadata
        meta<void>* m(object_meta(rooty));
        if (m)
            m->mark(rooty PASS_VERBOSE);
        /// if (m.trymark(rooty.first)) ...;

        VERBOSE("done");
    }

    void meta<void>::mark(void* p PLUS_VERBOSITY_ARG())
    {
        // look whether it is a cons
        VERBOSE("trying to mark: " << p);
        // hack!
        meta<cons>& m(get_meta<cons>(1));
        m.mark(static_cast<cons*>(p) PASS_VERBOSE);
    }


    template <typename ELEM>
    struct Clustered
    {
        void* operator new(size_t s)
            {
                return seed->allocate(s);
            }
        void operator delete(void*) { }

        static meta<ELEM>* seed;
        static ELEM* (*strategy)(meta<ELEM>*);
        
        static ELEM* searchOtherCluster(meta<ELEM>*);
    };

    template <typename ELEM>
    meta<ELEM>* Clustered<ELEM>::seed = 0;

    template <typename ELEM>
    ELEM* (*Clustered<ELEM>::strategy)(meta<ELEM>*) = &Clustered<ELEM>::searchOtherCluster;

    struct vcons : cons, Clustered<vcons>
    {
        typedef vcons selftype;
        
#       define IMPL_METH(CONSTNESS, NAME, RES, ...) static RES _ ## NAME(CONSTNESS selftype& self, ##__VA_ARGS__)
#       define IMPL_OUTLINE_METH(CONSTNESS, CLASS, NAME, RES, ...) RES CLASS:: _ ## NAME(CONSTNESS selftype& self, ##__VA_ARGS__)

        IMPL_METH(const, sayhello, void)
        {
            printf("Hello from %p\n", &self);
        }

        IMPL_METH(const, car, void*)
        {
            return self.first;
        };

        IMPL_METH(const, cdr, void*)
        {
            return self.second;
        };

        IMPL_METH(,set_car, void, void* new_car)
        {
            self.first = new_car;
        };

        IMPL_METH(,set_cdr, void, void* new_cdr)
        {
            self.second = new_cdr;
        };
        
        IMPL_METH(const, sayindex, void);

        struct vtbl
        {
#           define VTBL_ENTRY(NAME) __typeof__(&selftype::_ ## NAME) const NAME
            VTBL_ENTRY(sayhello);
            VTBL_ENTRY(car);
            VTBL_ENTRY(cdr);
            VTBL_ENTRY(set_car);
            VTBL_ENTRY(set_cdr);
            VTBL_ENTRY(sayindex);
        };

        const vtbl& getvtbl(void) const;
        
        
        void sayhello(void) const
        {
            getvtbl().sayhello(*this);
        }

        void sayindex(void) const
        {
            getvtbl().sayindex(*this);
        }

        static vtbl v;
        
        vcons(void* car = 0, void* cdr = 0);
    };

    vcons::vtbl vcons::v = { _sayhello, _car, _cdr, _set_car, _set_cdr, _sayindex };

    template <>
    struct meta<vcons>
    {
        const vcons::vtbl* vtbl;
        unsigned long used;
        meta(void)
        : vtbl(NULL), used(0)
        {}
        
        void mark(const vcons* o);
        vcons* allocate(std::size_t);
    };

    template <typename T, size_t COUNT>
    struct Scale
    {
        enum
        {
            is = sizeof(T (&)[COUNT]) / sizeof(meta<T>),
            log2 = Log2<is>::is,
            pof2 = Log2<is>::exact,
            rest = sizeof(T (&)[COUNT]) - is * sizeof(meta<T>)
        };
    };
    

    // Cluster_vcons: a cluster for aggregating vcons'
    //
    struct Cluster_vcons : world::Cluster<4/*=16 pages max*/, Scale<vcons, 32>::log2>
    {
        char filler[sizeof(meta<vcons>)];
        meta<vcons> metas[31];
        vcons objs[1024 - 32];
        
        Cluster_vcons(void)
        {
            vcons::seed = metas; // #### if not null
        }
        
        meta<vcons>* meta_begin(void) { return metas; }
        meta<vcons>* meta_end(void) { return metas + sizeof metas / sizeof *metas; }
        
        static Cluster_vcons& allocate(void)
        {
            return *new(world::allocate<Magnitude>(2/*pages*/)) Cluster_vcons;
        }
    };
    
    vcons* Clustered<vcons>::searchOtherCluster(meta<vcons>*)
    {
        abort();
        /// ### world::FindCluster(signature);
    }


    void meta<vcons>::mark(const vcons* o)
    {
        register const unsigned i = Cluster_vcons::Raw2Index<sizeof(vcons), Log2<sizeof(meta<vcons>)>::is>(o);
        register const unsigned long bit(1 << i);
        if (used & bit)
            return;
        
        used |= bit;
    }

    template <>
    inline meta<vcons>* object_meta(vcons* o)
    {
        return const_cast<meta<vcons>*>(static_cast<const meta<vcons>*>(Cluster_vcons::Raw2Meta<Log2<sizeof(meta<vcons>)>::is>(o)));
    }

    vcons* meta<vcons>::allocate(std::size_t s)
    {
        unsigned i(FindUnsetBits<1>(used));
        if (i < sizeof used * 8)
        {
            used |= (1 << i);
            return static_cast<vcons*>(Cluster_vcons::Meta2Object<sizeof(vcons)>(this, i));
        }
        else for (meta* next(this + 1), *e(Cluster_vcons::Meta2Cluster<Cluster_vcons>(this)->meta_end()); next != e; ++next)
        {
            if (~next->used) // there are empty ones // ####### TODO compare vtbl-ptr too
            {
                vcons::seed = next;
                return next->allocate(s);
            }
            
            return (vcons::strategy)(this);
            // return vcons::strategy(this); // linker error without parens on Panther
        }
    }


    inline vcons::vcons(void* car, void* cdr)
    {
        first = car;
        second = cdr;
        /*if every 32th!!##*/
        object_meta(this)->vtbl = &v;
    }


    inline const vcons::vtbl& vcons::getvtbl(void) const
    {
        return *object_meta(const_cast<vcons*>(this))->vtbl;
    }

    IMPL_OUTLINE_METH(const, vcons, sayindex, void)
    {
        printf("Index in group is %d\n", Cluster_vcons::Raw2Index<sizeof(vcons), Log2<sizeof(meta<vcons>)>::is>(&self));
    }

/*
    IsZero<Scale<vcons, 32>::is> t0;
    IsZero<sizeof(Cluster_vcons)> t1;
    IsZero<sizeof(*c1.metas)> t2;
    IsZero<sizeof(*c1.objs)> t3;
    IsZero<sizeof(c1.metas)> t4;
    IsZero<sizeof(c1.objs)> t5;
*/




    IsZero<Scale<vcons, 32>::log2 != 5> t6;
    IsZero<Scale<vcons, 32>::pof2 != true> t7;

    Same<Log2<32>::is, 5> t8;
    IsZero<Scale<vcons, 32>::rest> t9;



    template <typename ELEM>
    struct ClusteredDeletable : Clustered<ELEM>
    {
        void operator delete(void*);
    };


    // FROM GCBench.cpp // TEMPORARY.
    typedef struct Node0 *Node;

    struct Node0 : ClusteredDeletable<Node0> {
        Node left;
        Node right;
        int i, j;
        Node0(Node l = 0, Node r = 0) : left(l), right(r) { }
        ~Node0(void) { delete left; delete right; }
    };
    
    template <>
    struct meta<Node0>
    {
        unsigned long* used;
        meta(void)
        : used(0)
        {}
        
        void mark(const Node0* o);
        void unmark(const Node0* o);
        Node0* allocate(std::size_t);
    };


    // a cluster for 100000 (50000 on MacOS) objects:
    // HomogenousCluster: a cluster for aggregating objects of the same size,
    // all sharing the same metaobject
    //
    template <typename T, unsigned OBJECTS>
    struct HomogenousCluster : world::Cluster<Log2<sizeof(T (&)[OBJECTS]) / world::PageSize>::is, Scale<T, OBJECTS>::log2>
    {
        char filler[sizeof(meta<T>)];
        meta<T> metas[1];
        T objs[OBJECTS];
        
        HomogenousCluster(void)
        {
            IsZero<(sizeof(T (&)[OBJECTS]) / world::PageSize > 255)> c1;
            if (!T::seed) T::seed = metas;
            enum { chunk = sizeof *metas->used
                 , chunk_bits = 8 * chunk
                 , rounder = chunk_bits - 1
                 , chunks = (OBJECTS + rounder) / chunk_bits
                 };

            Same<chunk, 4> c2;
            Same<chunk_bits, 32> c3;
            Same<rounder, 31> c4;
            // Same<chunks, 50000 / 32> c5; // commentable

            metas->used = new unsigned long[chunks]; // round up
            memset(metas->used, 0, chunks * chunk);
            assert(objs == static_cast<void*>(metas + 1));
        }
        
        meta<T>* meta_begin(void) { return metas; }
        meta<T>* meta_end(void) { return metas + sizeof metas / sizeof *metas; }
        
        static inline const void* Raw2Meta(const void* obj)
        {
            enum { mask = ~((1 << HomogenousCluster::Magnitude) - 1) };
            return reinterpret_cast<HomogenousCluster*>(mask & reinterpret_cast<unsigned long>(obj))->meta_begin();
        }
        
        static HomogenousCluster& allocate(void)
        {
            return *new(world::allocate<HomogenousCluster::Magnitude>()) HomogenousCluster;
        }
    };
    
    
    template <typename ELEM>
    inline void ClusteredDeletable<ELEM>::operator delete(void* raw)
    {
        ELEM* o(static_cast<ELEM*>(raw));
        object_meta(o)->unmark(o);
    }

    typedef HomogenousCluster<Node0, 50000> nodeCluster;

    template <>
    inline meta<Node0>* object_meta(Node0* o)
    {
        return const_cast<meta<Node0>*>(static_cast<const meta<Node0>*>(nodeCluster::Raw2Meta(o)));
    }

    inline void meta<Node0>::mark(const Node0* o)
    {
        register size_t i(o - reinterpret_cast<const Node0*>(this + 1)); // trick
        unsigned bit(i & ((1 << 5) - 1));
        unsigned word(i >> 5);
    }

    void meta<Node0>::unmark(const Node0* o)
    {
        // TODO ###
    }

    Node0* meta<Node0>::allocate(std::size_t)
    {
        // simple-minded
        unsigned i(FindUnsetBits<1>(*used));
        if (i < sizeof *used * 8)
        {
            *used |= (1 << i);
            return reinterpret_cast<Node0*>(this + 1) + i;
        }
/*        for ()
        {
            
        }*/
    }
    
    // Pyramid: fast hierarchical bitmap
    //
    template <unsigned DEPTH, unsigned short FACTOR>
    struct Pyramid : IsZero<FACTOR % 32>
    {
        typedef Pyramid<DEPTH - 1, FACTOR> Pado;
        enum { bits = FACTOR * Pado::bits, madobits = 8 * sizeof(unsigned long) };
        unsigned long mado[FACTOR / madobits]; // fantasy name :-)
        Pado pado[FACTOR];                     // fantasy name :-)
        
        Pyramid(void)
        {
            memset(mado, 0, sizeof mado);
            memset(pado, 0, sizeof pado);
        }

        template <unsigned (*scanner)(unsigned long), void (*marker)(unsigned long&, long bit)>
        unsigned find(void)
        {
            for (unsigned long* b(mado), *e(mado + FACTOR); b < e; ++b)
            {
                unsigned i(scanner(*b));
                if (i <= madobits)
                {
                    unsigned p0(b - mado);
                    marker(*b, i);
                    unsigned p1(p0 * madobits + i);
                    return p1 * Pado::bits + pado[p1].find<scanner, marker>();
                }
            }
        }
        
        template <void (*unmarker)(unsigned long&, long bit)>
        unsigned clean(unsigned n)
        {
            unsigned p(n / Pado::bits);
            unsigned r(n % Pado::bits);
            unsigned m(n / Pado::bits);
            pado[p].clean<unmarker>(r);
            unmarker(mado[p / madobits], p % madobits);
        }
        
        void* operator new (size_t bits_needed)
        {
            unsigned pados_needed((bits_needed + Pado::bits - 1) / Pado::bits);
            assert(pados_needed < FACTOR);
            return ::operator new(sizeof(Pyramid) - sizeof(Pado (&)[FACTOR]) + sizeof(Pado) * pados_needed);
        }
    };
    
    template <unsigned short FACTOR>
    struct Pyramid<0, FACTOR>
    {
        unsigned long mado[FACTOR];
        enum { bits = sizeof(unsigned long (&)[FACTOR]) * 8
             , madobits = 8 * sizeof(unsigned long)
             };
        Pyramid(void)
        {
            memset(mado, 0, sizeof mado);
        }

        template <unsigned (*scanner)(unsigned long), void (*marker)(unsigned long&, long bit)>
        unsigned find(void)
        {
            for (unsigned long* b(mado), *e(mado + FACTOR); b < e; ++b)
            {
                unsigned i(scanner(*b));
                if (i <= madobits)
                {
                    unsigned p0(b - mado);
                    marker(*b, i);
                    return i;
                }
            }
        }
    };
    
    Pyramid<1, 32> p1;
    Same<Pyramid<1, 32>::bits, 32*1024> cp1;

    inline unsigned simple_minded_scanner(unsigned long u)
    {
        unsigned i(FindUnsetBits<1>(u));
        return i;
    }
    
    inline void simple_minded_marker(unsigned long& u, long bit)
    {
        u |= (1 << bit);
    }
    
    
    unsigned cp2(p1.find<simple_minded_scanner, simple_minded_marker>());


}




// http://www.opengroup.org/onlinepubs/007908799/xsh/sigaction.html
// http://www.gnu.org/software/libc/manual/html_node/Sigaction-Function-Example.html
// http://www.opengroup.org/onlinepubs/000095399/basedefs/signal.h.html
// http://www.ravenbrook.com/project/mps/master/code/protxcpp.c
#include <sys/ucontext.h>


#   ifdef __APPLE__
void yummy(int, siginfo_t*, void*);
void yummy(int what, siginfo_t* info, void* context)
{
    printf("Mac OS X: handling (%p)\n", info);

    if (!info)
    {  
        printf("info == 0!\n");
        abort();
    }
    
    if (!context)
    {  
        printf("context == 0!\n");
        abort();
    }
    
    switch (what)
    {
        case SIGBUS:
        {
            printf("SIGBUS\n");
            switch  (info->si_code)
            {
                case BUS_ADRALN:
                    printf("ADRALN\n");
                    break;
/*                case BUS_ADRERR:
                    printf("ADRERR\n");
                    break;
                case BUS_OBJERR:
                    printf("OBJERR\n");
                    break;*/
            }
            
            ucontext_t* ucontext(static_cast<ucontext_t*>(context));
            info->si_addr = (void*)ucontext->uc_mcontext->es.dar;
            printf("info->si_addr = %p\n", info->si_addr);


            break;
        }
        
        default:
            printf("bogus signal (%d)\n", what);
            abort();
    }
    
    world::self().unprotectPage(0);
    printf("*info->si_addr = %x\n", *(unsigned long*)info->si_addr);
}
#   endif

void wummy(int, siginfo_t *, void *);
void wummy(int what, siginfo_t* info, void *)
{
    printf("Solaris: handling (%p)\n", info);

    if (!info)
    {  
        printf("info == 0!\n");
        abort();
    }
    
    switch (what)
    {
        case SIGSEGV:
        {
            printf("SIGSEGV\n");
            switch  (info->si_code)
            {
                case SEGV_MAPERR:
                    printf("MAPERR\n");
                    break;
                case SEGV_ACCERR:
                    printf("MAPERR\n");
                    break;
            }
            printf("info->si_addr = %p\n", info->si_addr);
        }
    }
    
    world::self().unprotectPage(0);
    printf("*info->si_addr = %x\n", *(unsigned long*)info->si_addr);
}


void mark(vcons* o) throw ()
{
    printf("marking (%p) in process %d\n", o, getpid());
    object_meta(o)->mark(o);
}


void fork_and_exception(vcons& it)
try
{
    const pid_t father(getpid());
    const pid_t child(fork());
    
    if (0 > child)
    {
        perror("fork");
        abort();
    }
    else if (0 == child)
    {
        printf("new process (%d)\n", getpid());
        throw &it;
    }
    else
    {
        int stat(0);
        waitpid(child, &stat, 0);
        printf("child (%d) exited with status: %d\n", child, stat);
    }
}
catch (vcons*)
{
    mark(&it);
    throw;
}



int main(void)
{
    // STL allocators experiment
    //
    vector<int, alloc<int> > v(3);
    map<int, int, less<int>, alloc<int> > m;
    m.insert(make_pair(1, 42));

    cons* c(alloc<cons>().allocate(1));
    c->first = c;
    c->second = 0;
    rooty = c;


    collect(true);

    // get the world set up
    //
    static const char worldPath[] = "/aL4nin";
    int ul0(shm_unlink(worldPath));
    if (ul0 == -1)
        perror("(preventive) shm_unlink");

    int hdl(shm_open(worldPath,
                     O_RDWR | O_CREAT,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP));
    if (hdl == -1)
        perror("shm_open");

    int tr(ftruncate(hdl, world::size()));
    if (tr == -1)
        perror("ftruncate");

    world* w(new(hdl) world);
    void* area(w);
    

    // Clusters experiment
    //
    Cluster_vcons& clu(Cluster_vcons::allocate());
    vcons& babe(clu.objs[10]);
    

    // vcons experiment
    //
    vcons& vc(babe);
    vc.sayhello();
    for (vcons* s = clu.objs + 640, *e = clu.objs + 690; s != e; ++s)
        s->sayindex();

    // allocation experiment
    //
    vcons* aa(new vcons);
    printf("alloced at: (%p)\n", aa);
    vcons* bb(new vcons);
    printf("blloced at: (%p)\n", bb);
    vcons* yy(
        (new vcons, new vcons, new vcons, new vcons,
        new vcons, new vcons, new vcons, new vcons,
        new vcons, new vcons, new vcons, new vcons,
        new vcons, new vcons, new vcons, new vcons,
            new vcons, new vcons, new vcons, new vcons,
            new vcons, new vcons, new vcons, new vcons,
            new vcons, new vcons, new vcons, new vcons,
            new vcons, new vcons));
    printf("ylloced at: (%p)\n", yy);
    vcons* zz(new vcons);
    printf("zlloced at: (%p)\n", zz);


    // HomogenousCluster experiment
    //
    nodeCluster& nc(nodeCluster::allocate());
    nc.printCharacteristics();
    Node n(new Node0);
    delete n;


    // forked exceptions experiment
    //
    vcons& ev(babe);
    try
    {
        fork_and_exception(ev);
    }
    catch (vcons*)
    {
        printf("exiting... (%d)\n", getpid());
        _exit(0);
    }


    unsigned long* p((unsigned long*)area);
///    *p = 0xbeeffece;

    w->protectPageRW(0);
    
    struct sigaction act, oact;
    memset(&act, 0, sizeof act);
    sigemptyset(&act.sa_mask);
    act.sa_flags = SA_SIGINFO;
    
#   ifdef __APPLE__
    act.sa_sigaction = yummy;
    if (sigaction(SIGBUS, &act, &oact))
#   else
    act.sa_sigaction = wummy;
    if (sigaction(SIGSEGV, &act, &oact))
#   endif
        perror("sigaction");
    
    {
        for (int i(0); i < 100; i += 4)
        {
            char* p((char*)area + i);
            printf("i: %d, o: %p, m: %p\n", i, p, world::Cluster<4, 3>::Raw2Meta<3>(p));
            *p = 0;
            printf("*p = %x\n", *(unsigned long*)p);
        }
        
        for (int i(10000); i < 10100; i += 4)
        {
            char* p((char*)area + i);
            printf("i: %d, o: %p, m: %p\n", i, p, world::Cluster<4, 3>::Raw2Meta<3>(p));
            *p = 0;
        }
        
        int um(munmap(area, world::size()));
        if (um == -1)
            perror("munmap");
    }
    
    int ul(shm_unlink(worldPath));
    if (ul == -1)
        perror("shm_unlink");
}
