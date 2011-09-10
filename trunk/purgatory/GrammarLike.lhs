> {-# LANGUAGE TypeFamilies #-}


> import Data.Char
> import Control.Monad
> import Control.Monad.Identity
> import Control.Arrow

We need a pseudo-Parsec for demonstration

> -- data Parser what = P what

It is the identity monad (for now)

> type Parser = Identity

> --instance Monad Parser where
> --  return v = P v
> --  v >>= t = t v

> anyChar :: Parser Char
> anyChar = undefined

> natural :: Parser Int
> natural = undefined


> class GrammarLike a where
>   type Final a
>   produce :: a -> Final a

> instance GrammarLike Int where
>   type Final Int = Parser Int
>   produce _ = return 42

> instance GrammarLike r => GrammarLike (d -> r) where
>   type Final (d -> r) = Final r
>   produce on = produce $ on undefined

> theAnswer = produce ord

> class Materializable arrow where
>   materialize :: Arrow arrow => arrow (Parser a) (Parser b)
>   materialize = undefined

> instance Materializable (->) where
>   materialize = undefined

Time to make something concrete

> data Foo = F Int

> instance GrammarLike Foo where
>   type Final Foo = Parser Foo
>   produce f = return f
