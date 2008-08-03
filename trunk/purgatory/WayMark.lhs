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

> import Monad
> import Test.QuickCheck

First we define the datatype for tagged pointers.
The Fin constructor points back to the Value itself:

> data UsePtr = Zero UsePtr | One UsePtr | Stop UsePtr | Fin Value
> instance Show UsePtr where
>     show (Zero p) = "0" ++ show p
>     show (One p) = "1" ++ show p
>     show (Stop p) = "s" ++ show p
>     show (Fin _) = "S"

Values (here) store the numerical integer for the bit pattern of the
pointer (Value*) and the first Use* in the chain.

> data Value = Val Int UsePtr
>     deriving Show

The verify function walks the Use chain and for each pointer performs
a check whether the computed Value* matches up with the reality.

> verify :: Value -> Bool
> verify (Val i (p@(Zero p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(One p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(Stop p'))) = compute p == i && verify (Val i p')
> verify (Val i (Fin (Val i' _))) = i == i'

Forwarding function supplying step counter and seed:

> compute p = compute' 0 0 p

The following function scans the waymarks along the chain and
returns the numerical pattern for Value*.

Note: for simplicity the required step count is 3 at the moment.

> requiredSteps = 3

> compute' :: Int -> Int -> UsePtr -> Int
> compute' steps seed (Zero p) = compute' (steps + 1) (seed + seed) p
> compute' steps seed (One p) = compute' (steps + 1) (seed + seed + 1) p
> compute' steps seed (Stop p) = if steps == requiredSteps then seed else compute' 0 0 p
> compute' steps seed (Fin (Val i _)) = i

Test section:

> testcase = Val 5 (One $ Zero $ One $ Stop $ Zero $ Fin testcase)

> soundTags :: Int -> Property
> soundTags n = n > 0 && n < 8 ==> verify (Val 5 p) where Val i p = testcase 

     where arr = takeLast n testcase

> t1 = quickCheck soundTags

> data History
>   = Insert History
>   | Remove Int History
>   | Done
>  deriving Show

Some quickCheck helpers:

> instance Arbitrary History where
>   arbitrary = sized history
>     where
>       history 0 = return Done
>       history n | n>0 = oneof
>         [ return Done
>         , liftM Insert subtree
>         , liftM2 Remove arbitrary subtree]
>           where subtree = history (n `div` 2)

Now we can construct a Value given the pointer pattern and a history:

> construct :: Int -> History -> Value
> construct i h = construct' seed h where seed = Val i (Fin seed)

The actual mutating function is construct':

> construct' v Done = v
> construct' (Val i p) (Insert rest) = construct' (Val i $ Stop p) rest
> construct' (Val i (Zero p)) (Remove 0 rest) = construct' (Val i p) rest
> construct' (Val i (One p)) (Remove 0 rest) = construct' (Val i p) rest
> construct' (Val i (Stop p)) (Remove 0 rest) = construct' (Val i p) rest

> construct' (Val i (Stop p)) (Remove (n+1) rest) = Val i (Stop p')
>     where (Val i' p') = construct' (Val i p) (Remove n rest)


      >     where v = remove 