> {-# LANGUAGE TypeFamilies, FlexibleInstances #-}


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
>   type Initial a
>   type Final a
>   produce :: a -> Initial a -> Final a

> instance GrammarLike Int where
>   --type Initial Int = a
>   type Final Int = Parser Int
>   produce _ _ = return 42

> instance GrammarLike r => GrammarLike (d -> r) where
>   type Initial (d -> r) = Parser d
>   type Final (d -> r) = Final r
>   produce f pd = pd >>= (\d -> produce (f undefined)

> theAnswer = produce ord

> class Materializable arrow where
>   materialize :: Arrow arrow => arrow (Parser a) (Parser b)
>   materialize = undefined

> instance Materializable (->) where
>   materialize = undefined

Time to make something concrete

> data Foo = F Int

> data Prod a f = Produce (a -> f)

> instance GrammarLike a => GrammarLike (Prod a Foo) where
>   type Initial (Prod a Foo) = Parser a
>   type Final (Prod a Foo) = Parser Foo
>   produce (Produce f) ma = undefined --fmap f
