> {-# LANGUAGE FlexibleInstances, UndecidableInstances #-}

> module Foo where

import Prelude

Let's define the data structure we want to fill in

> data Foo = Foo [Int] [Int] (Maybe Bar)
>   deriving Show

> data Bar = Bar [Int] [Int]
>   deriving Show

Here is a test input

> t1 = oP [897] iT [111]  iP [1377]

We match the first five items with the initial
command 'oP'

> oP :: [Int] -> c -> [Int] -> ((Maybe Bar -> Foo) -> a -> t0 -> [Int] -> Foo) -> (a -> t0 -> [Int] -> Foo)
> oP n _ m cont = cont $ Foo n m

The continuation above will be 'iT' for the test input 't1'
so we have to define it

> iT = ($)

> iP sofar val _ wal = sofar $ Just $ Bar val wal

As we can see, it simply applies it.

When we only partially saturate it, it is harder to
show

> t2 = oP [1347] iT [108]

> instance Show b => Show (Maybe a -> b) where
>   show a = show $ a Nothing

> instance (Show b, Show (Maybe a->b)) => Show (((Maybe a->b) -> (c->b)) -> (c->b)) where
>   show a = show $ (a applyNothing undefined)
>     where applyNothing f _ = f Nothing

> instance (Show b, Show (Maybe a->b)) => Show (((Maybe a->b) -> (e->d->c->b)) -> (e->d->c->b)) where
>   show a = show $ (a applyNothing undefined undefined undefined)
>     where applyNothing f _ _ _ = f Nothing

This is enough to show both t1 (saturated) and t2 (unsaturated)

> t3 = show (t4, t2)

> wzffi = ($)

> t4 = t1 wzffi [668]