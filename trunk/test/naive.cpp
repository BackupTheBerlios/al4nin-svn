#include <vector>
#include <map>
#include "alloc.hpp"


using namespace std;
using namespace aL4nin;



int main(void)
{
    vector<int, alloc<int> > v;
    map<int, int, less<int>, alloc<int> > m;
}
