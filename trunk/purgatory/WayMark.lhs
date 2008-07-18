{-
 * Copyright (c) 2008 Gabor Greif
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
 -}


> data UsePtr = Zero UsePtr | One UsePtr | Stop UsePtr | Fin Value

> data Value = Val Int UsePtr

> verify :: Value -> Bool
> verify (Val i (p@(Zero p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(One p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(Stop p'))) = compute p == i && verify (Val i p')
> verify (Val i (Fin (Val i' _))) = i == i'

> compute p = compute' 0 0 p

> compute' :: Int -> Int -> UsePtr -> Int
> compute' steps seed (Zero p) = compute' (steps + 1) (seed + seed) p
> compute' steps seed (One p) = compute' (steps + 1) (seed + seed + 1) p
> compute' steps seed (Stop p) = if steps == 3 then seed else compute' 0 0 p
> compute' steps seed (Fin (Val i _)) = i

> test = Val 5 $ One $ Zero $ One $ Stop $ Zero $ Fin test
