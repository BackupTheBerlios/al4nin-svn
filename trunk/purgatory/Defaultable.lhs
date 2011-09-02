> {-# LANGUAGE FlexibleInstances, UndecidableInstances, MultiParamTypeClasses #-}

> module Foo where

> import Prelude

-- TODO: check whether it is sufficient to annotate the penultimate combinator?
-------  


This is the theory:
if we have a function typed as
foo :: bla -> bar -> (Maybe a -> Foo) -> Foo

then doing

foo bla bar _defaulted_

automatically supply the Nothing.

Then we can go on and do the same for all signatures like this:

foo :: bla -> bar -> (Maybe a -> (quuz -> (... -> Foo)) -> (quuz -> (... -> Foo))

i.e. the value <defaulted> at third argument should also work.


> class c `TrailedBy` b where
>   squelch :: b -> c -> c

> instance b `TrailedBy` b where
>   squelch b _ = b

> instance (c `TrailedBy` b) => (d -> c) `TrailedBy` b where
>   squelch b dc = \ _ -> squelch b (dc undefined)

> class Defaultable a where
>   defaulted :: a

> instance Defaultable ((Maybe a -> b) -> b) where
>   defaulted f = f Nothing


> instance ((d -> c) `TrailedBy` b) => Defaultable ((Maybe a -> b) -> d -> c) where
>  defaulted f = squelch (f Nothing) (defaulted f)



;> instance Defaultable ((Maybe a -> b) -> b) =>
;>          Defaultable ((Maybe a -> b) -> c -> b) where 
;>  defaulted f _ = f Nothing 


> bar :: Int -> ((Maybe Bar -> Foo) -> Int -> Foo) -> Int -> Foo
> bar i cont = cont $ Foo [i] [i]

> m sofar = let j = 42 in sofar . Just $ Bar [j] [j]

> m2 sofar j = sofar . Just $ Bar [j] [j]


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