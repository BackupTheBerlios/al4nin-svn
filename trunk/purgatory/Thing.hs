{-
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
 -}
 
 



-- Introduce Things "Tg"
--
data Tg = AnyTg (Tg -> Tg) | It's Int

-- universal quantification
--
ny :: Tg
ny = AnyTg (\x->x)


-- unification function
--
unify :: Tg -> Tg -> Maybe Tg

unify (It's x) (It's y)
 | x == y = Just (It's x)
 | True = Nothing

unify (AnyTg f) s = Just (f s)

unify s t = unify t s



-- Documentation
{-

we model types with numbers
i.e. the haskell Int would be our 2 (always primes)
a tagged union type (Bool) would be a product, say 3 * 5
a type of a haskell function would be a pair (11, 2)
a type of a haskell tuple (Int, Int, Bool) would be a list [2, 2, 15]




-}