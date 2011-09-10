> {-# LANGUAGE TypeFamilies #-}


> import Data.Char
> import Control.Monad
> import Control.Monad.Identity

We need a pseudo-Parsec for demonstration

> -- data Parser what = P what

It is the identity monad (for now)

> type Parser = Identity

> --instance Monad Parser where
> --  return v = P v
> --  v >>= t = t v

> anyChar :: Parser Char
> anyChar = undefined


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

> 
