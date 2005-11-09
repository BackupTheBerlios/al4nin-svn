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

#ifndef _ALLOC_A4L_
#define _ALLOC_A4L_

#include <memory>
#include "safemacros.h"

namespace aL4nin
{
    void collect(VERBOSITY_ARG(= false));

    template <typename T>
    struct meta;

    template <>
    struct meta<void>
    {
        void mark(void*, bool verbose);
        bool trymark(void*, bool verbose);
    };

    template <typename T>
    meta<T>& get_meta(std::size_t);

    template <typename T>
    meta<T>* object_meta(T*);

    template <typename T>
    struct alloc : std::allocator<T>
    {
        typedef typename std::allocator<T>::pointer pointer;

        template <typename U>
        struct rebind
        {
            typedef alloc<U> other;
        };

        pointer allocate(std::size_t);
        void deallocate(pointer, size_t);

        alloc(void) throw() { }

        alloc(const alloc& a) throw()
            : std::allocator<T>(a) { }

        template<typename U>
        alloc(const alloc<U>&) throw() { }

        ~alloc(void) throw() { }
    };


    // Log2: is: compute the binary logarithm of U
    //       bits: how many bits are needed to represent
    //             all integers form 0 .. U.
    //       exact: iff U is a power of 2
    //
    template <unsigned long U>
    struct Log2
    {
        static const int bits = 1 + Log2<(U >> 1)>::bits;
        static const int is = Log2<(U - 1)>::bits;
        static const bool exact = (1U << is) == U;
    };

    template <> struct Log2<0> { static const int bits = 1;  };
    template <> struct Log2<1>
    {
        static const int bits = 1;
        static const int is = 0;
        static const bool exact = true;
    };

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

    template <unsigned long LHS, unsigned long RHS>
    struct Same : IsZero<LHS != RHS>
    {};


}

#include "safemacros.h" // undo them

#endif // _ALLOC_A4L_
