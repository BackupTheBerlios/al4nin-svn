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




#include "alloc.cpp"


using namespace std;
using namespace aL4nin;


int main(void)
{
    vector<int, alloc<int> > v(3);
    map<int, int, less<int>, alloc<int> > m;
}
