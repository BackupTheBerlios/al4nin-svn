#include <vector>
#include <map>
#include <cstring>
#include <algorithm>
#include <iostream>




#include "alloc.hpp"

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



#include "alloc.cpp"


using namespace std;
using namespace aL4nin;

namespace aL4nin
{
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

    struct cons : pair<cons*, cons*>
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

        void mark(const cons* p)
            {
                // simple minded!
                int i(bits - 1);
                for (const cons* my(objects + i);
                     i >= 0;
                     --my, --i)
                {
                    if (bitmap[i] && p == my)
                    {
                        marks[i] = true;
                        return;
                    }
                }

                abort();
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

    template <>
    meta<void>& object_meta<void>(void*)
    {
        static meta<void> me;
        return me;
    }

    void* rooty(0);

    void collect(bool verbose)
    {
        if (verbose)
            cerr << "starting" << endl;


        // do we need meta<void>
        // or can we safely assume
        // to know the exact meta type?
        // probably not: if a slot is just declared
        // <object> we never know the metadata
        meta<void>& m(object_meta(rooty));
        m.mark(rooty);
        /// if (m.trymark(rooty.first)) ...;
        

        if (verbose)
            cerr << "done" << endl;
    }

    void meta<void>::mark(void* p)
    {
        // look whether it is a cons
        // hack!
        meta<cons>& m(get_meta<cons>(1));
        m.mark(static_cast<cons*>(p));
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
}
