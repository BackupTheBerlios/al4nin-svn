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
data Tg = AnyTg (Tg -> Tg) | It's Int | Arr (Tg, Tg) | Tup [Tg] | Spec (String, [Tg])

-- universal quantification
--
ny :: Tg
ny = AnyTg (\x->x)

int, fa, tr, bo, plus1, iib, ibi :: Tg
int = It's 2
fa = It's (3 * 5)
tr = It's (5 * 3)
bo = tr
plus1 = Arr (int, int)
iib = Tup [int, int, bo]
ibi = Tup [int, bo, int]


-- unification function
--
unify :: Tg -> Tg -> Maybe Tg

unify (It's x) (It's y)
 | x == y = Just (It's x)
 | True = Nothing

unify (Arr (a, b)) (Arr (c, d))
 | (unifiable a c) && (unifiable b d) = Just (Arr (a, b))
 | True = Nothing

unify (Tup xs) (Tup ys)
 | length xs == length ys && foldl unif True (zip xs ys) = Just (Tup xs)
 | True = Nothing
  where unif sofar (a, b) = sofar && unifiable a b

unify s (AnyTg f) = Just (f s)

unify (It's _) _ = Nothing
unify (Arr _) _ = Nothing
unify (Tup _) _ = Nothing
unify (Spec _) _ = Nothing


unify s t = unify t s -- try again reversed!


-- another unification function
--
unifiable :: Tg -> Tg -> Bool
unifiable x y = case unify x y of { Nothing -> False; _ -> True }
 


-- Documentation
{-

we model types with numbers (or things built up from numbers)
i.e. the haskell Int would be our 2 (always primes)
a tagged union type (Bool) would be a product, say 3 * 5 (union of nullaries)
a type of a haskell function would be a pair (11, 2)
a type of a haskell tuple (Int, Int, Bool) would be a list [2, 2, 15]
haskell type constructor is then a function here? no, ("Maybe", [15]) is it



-}