{-
 * Copyright (c) 2010 Gabor Greif
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

{-# LANGUAGE GADTs, KindSignatures, EmptyDataDecls, TypeOperators #-}

-- See my blog post
--     http://heisenbug.blogspot.com/2010/11/applicative-structures-and-thrists.html

module Appli where

data Thrist :: (* -> * -> *) -> * -> * -> * where
  Nil :: Thrist p a a
  Cons :: p a b -> Thrist p b c -> Thrist p a c


f :: Int -> Bool -> Char -> [Int]
f i b c = if b then [i] else [0]

a :: Int
a = 42
b = True
c = 'A'

{- Variant 0
data Appli :: * -> * -> * where
  Fun :: (a -> b) -> Appli (a -> b) c
  Arg :: a -> Appli b (a -> b)
  Par :: Thrist Appli a c -> Appli b (a -> b)
-}

data Peg
{- Variant 1
data Appli :: * -> * -> * where
  Fun :: (a -> b) -> Appli (a -> b) Peg
  Arg :: a -> Appli b (a -> b)
  Par :: Thrist Appli a Peg -> Appli b (a -> b)
-}

-- Variant 2 ( the winner! )
--
data Appli :: (* -> * -> *) -> * -> * -> * where
  Fun :: (a ~> b) -> Appli (~>) (a ~> b) Peg
  Arg :: a -> Appli (~>) b (a ~> b)
  Par :: Thrist (Appli (~>)) a Peg -> Appli (~>) b (a ~> b)

t0 = Cons (Arg c) $ Cons (Arg b) $ Cons (Arg a) $ Cons (Fun f) Nil
t1 = Par t0
t2 = Cons t1 $ Cons (Fun length) Nil


data Arith :: * -> * -> * where
  Plus :: Arith Int (Arith Int Int)
  Minus :: Arith Int (Arith Int Int)
  Times :: Arith Int (Arith Int Int)
  Div :: Arith Int (Arith Int Int)
  Mod :: Arith Int (Arith Int Int)

t10 = Cons (Arg 42) $ Cons (Fun Plus) Nil
t11 = Cons (Arg 0) t10
t12 = Par t10
t13 = Par t11
