/*
 * Copyright (c) 2004 Gabor Greif
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

/*
  ##### HOW TO EXTEND #####
  just put your macro definition
  immediately before the #else
  below and an #undef in the
  line immediately following
  the else. This way including
  safemacros.h twice will clean
  up behind itself.
*/


#ifndef _SAFEMACROS_A4L_
#define _SAFEMACROS_A4L_

#define VERBOSE(WHAT) if (verbose) (::std::cerr << WHAT << ::std::endl)
#define VERBOSE_ABORT(WHAT) VERBOSE(WHAT); abort()
#define PASS_VERBOSE , verbose
#else
#undef PASS_VERBOSE
#undef VERBOSE_ABORT
#undef VERBOSE

#endif
