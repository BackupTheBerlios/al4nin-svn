#include <vector>
#include <map>




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
    meta<int> get_meta<int>(std::size_t)
    {
        return meta<int>();
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
    meta<std::_Rb_tree_node<std::pair<const int, int> > > get_meta<std::_Rb_tree_node<std::pair<const int, int> > >(std::size_t)
    {
        return meta<std::_Rb_tree_node<std::pair<const int, int> > >();
    }

}


int main(void)
{
    vector<int, alloc<int> > v(3);
    map<int, int, less<int>, alloc<int> > m;
    m.insert(make_pair(1, 42));
}
