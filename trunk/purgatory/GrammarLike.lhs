> {-# LANGUAGE TypeFamilies, ScopedTypeVariables #-}


> import Data.Char
> import Control.Monad
> import Control.Monad.Identity
> import Control.Arrow

We need a pseudo-Parsec for demonstration

> -- data Parser what = P what

It is the identity monad (for now)

> type Parser = Identity
> runParser = runIdentity

> --instance Monad Parser where
> --  return v = P v
> --  v >>= t = t v

> anyChar :: Parser Char
> anyChar = undefined

> natural :: Parser Int
> natural = undefined


> -- class GrammarLike m a where
> class GrammarLike a where
>   type Final a
>   produce :: a -> Parser (Final a)
>   -- produce :: Monad m => a -> m (Final a)

> instance GrammarLike Int where
>   type Final Int = Int
>   produce _ = return 42

> instance GrammarLike Char where
>   type Final Char = Char
>   produce _ = anyChar

> instance (GrammarLike d, GrammarLike r) => GrammarLike (d -> r) where
>   type Final (d -> r) = Final r
>   produce f = do { d <- pd; produce (f undefined) }
>     where converse :: (d -> r) -> (r -> d)
>           converse = undefined
>           pd = produce $ converse f undefined

> theAnswer :: Parser Int
> theAnswer = produce ord

> class Materializable arrow where
>   materialize :: Arrow arrow => arrow (Parser a) (Parser b)
>   materialize = undefined

> instance Materializable (->) where
>   materialize = undefined

Time to make something concrete

> data Foo = F Int deriving Show

> instance GrammarLike Foo where
>   type Final Foo = Foo
>   produce f = return f


> t1 = produce F
