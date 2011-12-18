{-
 * Copyright (c) 2010-2011 Gabor Greif
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

{-# LANGUAGE GADTs, KindSignatures, EmptyDataDecls, TypeOperators, StandaloneDeriving, FlexibleInstances #-}

-- See my blog post
--     http://heisenbug.blogspot.com/2010/11/applicative-structures-and-thrists.html

module Appli where

import Data.Thrist

f :: Int -> Bool -> Char -> [Int]
f i b c = if b then [i] else [0]

a :: Int
a = 42
b = True
c = 'A'

data Peg

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

deriving instance Show (Arith a b)
instance Show (Appli Arith a b) where
  show (Fun f) = show f
  show (Arg a) = "<arg>" -- show f
  show (Par p) = show p

instance Show (Thrist (Appli Arith) a b) where
  show Nil = "{}a"
  show (Cons h Nil) = "{" ++ show h ++ "}a"
  show (Cons h t) = "{" ++ show h ++ ", " ++ drop 1 (show t)

t10 = Cons (Arg 42) $ Cons (Fun Plus) Nil
t11 = Cons (Arg 0) t10
t12 = Par t10
t13 = Par t11
-- Times 25 (Plus 42 0)
t14 = Cons (Par $ Cons (Arg 0) t10) $ Cons (Arg 25) $ Cons (Fun Times) Nil
