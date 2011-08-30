> {-# LANGUAGE FlexibleInstances, UndecidableInstances, FlexibleContexts #-}

> module Foo (Defaultable(..)) where

import Prelude

Let's define the data structure we want to fill in

> data Foo = Foo [Int] (Maybe Bar)
>   deriving Show

> data Bar = Bar [Int]
>   deriving Show

Here is a test input

> t1 = oP [897] iT [111]

We match the first three items with the initial
command 'oP'

;> oP :: [Int] -> (([Int] -> Foo) -> ([Int] -> Foo))  -> (Maybe Bar -> Foo)

> oP :: [Int] -> ((Maybe Bar -> Foo) -> a -> Foo) -> (a -> Foo)
> oP n cont = cont $ Foo n

The continuation above will be 'iT' for the test input 't1'
so we have to define it

> iT sofar val = sofar $ Just $ Bar val

As we can see, it simply applies it.

When we only partially saturate it, it is harder to
show

> type C a b = ((Maybe a -> b) -> (Maybe a -> b)) -> (Maybe a -> b)

> -- t2 :: C Bar Foo
> t2 = oP [1347]

> 

> instance Show b => Show (Maybe a -> b) where
>   show a = show $ a Nothing

> instance (Show b, Show (Maybe a->b)) => Show (((Maybe a->b) -> (c->b)) -> (c->b)) where
>   show a = show $ (a apply undefined) --  (($)::(Maybe m->Foo)->(Maybe m->Foo)))

;>   show a = show $ (a :: Show (Maybe m->Foo) => ((Maybe m -> Foo) -> t) -> t) ($) -- (a ($))

;> instance Defaultable a => Show a where
;>   show = show . saturate

> class Defaultable a where
>   saturate :: a -> Foo

;> instance Defaultable Foo where 
;>   saturate = id

> instance Defaultable (Maybe b -> Foo) where
>   saturate a = a Nothing


> apply f a = f Nothing

;> instance Defaultable b =>Defaultable ((Maybe a -> b) -> (Maybe a -> b)) -> (Maybe a -> b)
;>   saturate a = a (