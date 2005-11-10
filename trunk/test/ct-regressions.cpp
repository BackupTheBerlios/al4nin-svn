/*
 * Copyright (c) 2005 Gabor Greif
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

#include "alloc.hpp"

using namespace aL4nin;

namespace 
{
    // Same<Log2<0>::is, 0> l0;
    Same<Log2<1>::is, 0> l1;
    Same<Log2<2>::is, 1> l2;
    Same<Log2<3>::is, 2> l3;
    Same<Log2<4>::is, 2> l4;
    Same<Log2<5>::is, 3> l5;
    Same<Log2<6>::is, 3> l6;
    Same<Log2<7>::is, 3> l7;
    Same<Log2<8>::is, 3> l8;
    Same<Log2<9>::is, 4> l9;
    Same<Log2<15>::is, 4> l15;
    Same<Log2<16>::is, 4> l16;
    Same<Log2<17>::is, 5> l17;


    // Same<Log2<0>::exact> e0;
    Same<Log2<1>::exact, true> e1;
    Same<Log2<2>::exact, true> e2;
    Same<Log2<3>::exact, false> e3;
    Same<Log2<4>::exact, true> e4;
    Same<Log2<5>::exact, false> e5;
    Same<Log2<6>::exact, false> e6;
    Same<Log2<7>::exact, false> e7;
    Same<Log2<8>::exact, true> e8;
    Same<Log2<9>::exact, false> e9;
    Same<Log2<15>::exact, false> e15;
    Same<Log2<16>::exact, true> e16;
    Same<Log2<17>::exact, false> e17;


    Same<Log2<0>::bits, 1> b0;
    Same<Log2<1>::bits, 1> b1;
    Same<Log2<2>::bits, 2> b2;
    Same<Log2<3>::bits, 2> b3;
    Same<Log2<4>::bits, 3> b4;
    Same<Log2<5>::bits, 3> b5;
    Same<Log2<6>::bits, 3> b6;
    Same<Log2<7>::bits, 3> b7;
    Same<Log2<8>::bits, 4> b8;
    Same<Log2<9>::bits, 4> b9;
    Same<Log2<15>::bits, 4> b15;
    Same<Log2<16>::bits, 5> b16;
}
