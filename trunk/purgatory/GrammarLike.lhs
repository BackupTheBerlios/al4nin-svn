> {-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FlexibleInstances, UndecidableInstances, TypeOperators, TypeSynonymInstances #-}


> import Data.Char
> import Control.Monad
> import Control.Monad.Identity
> import Control.Category

> class Category (->-) => Apply (->-) where
>   (<$>) :: a ->- b -> a -> b

> instance Apply (->) where
>   (<$>) = ($)

We need a pseudo-Parsec for demonstration
which  is the identity monad (for now)

> type Parser = Identity
> runParser = runIdentity

> anyChar = return '%'
> natural = return 42

My new invention is something that behaves like
a grammar, with terminals, productions, etc.
and is parameterized by a monad

> class Monad m => GrammarLike m a where
>   type Final a
>   produce :: a -> m (Final a)


Here come two ground instances for illustration

> instance GrammarLike Parser Int where
>   type Final Int = Int
>   produce _ = natural

> instance GrammarLike Parser Char where
>   type Final Char = Char
>   produce _ = anyChar


The tricky part is how function types can determine monads

> instance (Monad m, GrammarLike m d, d ~ Final d, GrammarLike m r, Apply (->-))
>     => GrammarLike m (d ->- r) where
>   type Final (d ->- r) = Final r
>   produce f = do { d <- pd; produce (f <$> d) }
>     where converse :: (d ->- r) -> (r ->- d)
>           converse = undefined
>           pd = produce $ converse f <$> undefined

> theAnswer :: Parser Int
> theAnswer = produce ord

Time to make something concrete

> data Foo = F Int Char deriving Show

> instance Monad m => GrammarLike m Foo where
>   type Final Foo = Foo
>   produce = return


> t1 :: Parser Foo
> t1 = produce F
