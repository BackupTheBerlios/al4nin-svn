{-
 * Copyright (c) 2007 Gabor Greif
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


module Embeddings where

import Prelude
import Control.Arrow
import Char


data Thrist :: (* -> * -> *) -> * -> * -> * where
  Nil :: Thrist p a a
  Cons :: p a b -> Thrist p b c -> Thrist p a c


-- embedding

data Arrow' :: (* -> * -> *) -> * -> * -> * where
  Arr :: Arrow a => a b c -> Arrow' a b c
  First :: Arrow a => Arrow' a b c -> Arrow' a (b, d) (c, d)

t1 :: Thrist (->) Char Char
t1 = Cons ord (Cons chr Nil)

t2 :: Arrow' (->) Char Int
t2 = Arr ord

t3 :: Thrist (Arrow' (->)) Char Int
t3 = Cons t2 Nil

t4 :: Arrow' (->) a (a, Int)
t4 = Arr (\a -> (a, 42))

t5 :: Thrist (Arrow' (->)) Int (Int, Int)
t5 = Cons (Arr chr) (Cons t4 (Cons (First t2) Nil))


-- semantics

recover :: Arrow a => Thrist (Arrow' a) b c -> a b c
recover Nil = arr id
recover (Cons (Arr f) r) = f >>> recover r
recover (Cons (First a) r) = first (recover $ Cons a Nil) >>> recover r

