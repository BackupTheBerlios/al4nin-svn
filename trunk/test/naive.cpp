#include <vector>
#include <map>
#include <cstring>
#include <algorithm>
#include <iostream>




#include "alloc.hpp"
#include "safemacros.h"

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

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

// Note: later I may introduce a multiworld, which may be
// a linked list of worlds.


// Checker templates
//
template <unsigned>
struct IsZero;

template <>
struct IsZero<0>
{};


template <unsigned long DIVISOR, unsigned long DIVIDEND>
struct Divides : IsZero<DIVIDEND % DIVISOR>
{};




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

    void* start(void)
        {
            Divides<PageSize, BASE> c1;
            return reinterpret_cast<void*>(BASE);
        }

    size_t size(void)
        {
            return PageSize * NUMPAGES;
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



// RawObj2Meta is intended to return a pointer for an object
// living in the world, that describes its allocation and collection
// behaviour.
// PAGE: number of bits needed to address a byte in a VM-page
// CLUSTER: how many bits are needed to address a page in a VM cluster of pages
// SCALE: how many bytes together have the same metadata info (2^SCALE bytes)
//   ##!! not true: SCALE simply tells us how much "denser" metaobjects are
//        compared to objects. I.e. 32*8byte (cons cells) together share the same
//        metaobject, and the metaobject is 8bytes then SCALE is 5 because
//        2^5==32.
//
// Theory of operation:
//   Find the lowest address in the cluster and scale down the displacement
//   of the object to the appropriate metaobject.

template <unsigned long PAGE, unsigned long CLUSTER, unsigned long SCALE>
inline void* RawObj2Meta(void* obj)
{
    typedef unsigned long sptr_t;
    register sptr_t o(reinterpret_cast<sptr_t>(obj));
    enum 
        {
            pat = (1 << PAGE + CLUSTER) - 1
        };
    
    register sptr_t b(o & ~static_cast<sptr_t>(pat));
    register sptr_t d(o & static_cast<sptr_t>(pat));
    return reinterpret_cast<void*>(b + (d >> SCALE));
}



#include "alloc.cpp"


using namespace std;
using namespace aL4nin;

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
}


int main(void)
{
    vector<int, alloc<int> > v(3);
    map<int, int, less<int>, alloc<int> > m;
    m.insert(make_pair(1, 42));

    cons* c(alloc<cons>().allocate(1));
    c->first = c;
    c->second = 0;
    rooty = c;


    collect(true);

    int hdl(shm_open("/blubber",
                     O_RDWR | O_CREAT,
                     S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP));

    perror("shm_open");
    
///    World<100, 0xF0000000UL, 12> world;
    World<100, 0xFF090000UL, 12> world;
///    const int lenn(100000000);
    
    int tr(ftruncate(hdl, world.size()));
    if (tr == -1)
        perror("ftruncate");


///    void* area(mmap(reinterpret_cast<void*>(/*0xF0000000UL*/world.start()),
    void* area(mmap(world.start(),
///                    lenn,
                    world.size(),
                    PROT_READ | PROT_WRITE,
                    MAP_SHARED,
                    hdl,
                    0));
    if (MAP_FAILED == area)
        perror("mmap");
    else
    {

        for (int i(0); i < 100; i += 4)
        {
            char* p((char*)area + i);
            printf("i: %d, o: %p, m: %p\n", i, p, RawObj2Meta<12, 4, 3>(p));
        }
        
        for (int i(10000); i < 10100; i += 4)
        {
            char* p((char*)area + i);
            printf("i: %d, o: %p, m: %p\n", i, p, RawObj2Meta<12, 4, 3>(p));
        }
        
        sleep(3);
        int um(munmap(area, world.size()));
        if (um == -1)
            perror("munmap");
    }
    
    int ul(shm_unlink("/blubber"));
    if (ul == -1)
        perror("shm_unlink");

    
}
