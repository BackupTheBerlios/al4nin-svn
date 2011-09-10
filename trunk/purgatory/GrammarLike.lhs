> {-# LANGUAGE TypeFamilies #-}


> import Data.Char

> class GL a where
>   type Final a
>   foo :: a -> Final a

> instance GL Int where
>   type Final Int = Int
>   foo _ = 42

> instance GL r => GL (d -> r) where
>   type Final (d -> r) = Final r
>   foo on = foo $ on undefined

> theAnswer = foo ord

