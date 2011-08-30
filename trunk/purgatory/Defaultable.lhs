> {-# LANGUAGE FlexibleInstances, UndecidableInstances #-}

> module Foo where

import Prelude

Let's define the data structure we want to fill in

> data Foo = Foo [Int] (Maybe Bar)
>   deriving Show

> data Bar = Bar [Int]
>   deriving Show

Here is a test input

> oP :: [Int] -> ((Maybe Bar -> Foo) -> a -> Foo) -> (a -> Foo)
> t1 = oP [897] iT [111]

We match the first three items with the initial
command 'oP'

> oP n cont = cont $ Foo n

The continuation above will be 'iT' for the test input 't1'
so we have to define it

> iT sofar val = sofar $ Just $ Bar val

As we can see, it simply applies it.

When we only partially saturate it, it is harder to
show

> t2 = oP [1347]

> instance Show b => Show (Maybe a -> b) where
>   show a = show $ a Nothing

> instance (Show b, Show (Maybe a->b)) => Show (((Maybe a->b) -> (c->b)) -> (c->b)) where
>   show a = show $ (a applyNothing undefined)
>     where applyNothing f _ = f Nothing


This is enough to show both t1 (saturated) and t2 (unsaturated)

> t3 = show (t1, t2)

