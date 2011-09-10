> {-# LANGUAGE TypeFamilies #-}


> import Data.Char

> class GrammarLike a where
>   type Final a
>   produce :: a -> Final a

> instance GrammarLike Int where
>   type Final Int = Int
>   produce _ = 42

> instance GrammarLike r => GrammarLike (d -> r) where
>   type Final (d -> r) = Final r
>   produce on = produce $ on undefined

> theAnswer = produce ord

