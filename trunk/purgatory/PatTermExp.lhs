This program tries to model the idea I have formulated
in my blog post

XXX

The gist is that patterns are simply (lambda-less) expressions
that appear on the left-hand side for which an oracle fills in
pattern variables in a way that the result becomes identical
to the scrutinee.

> {-# LANGUAGE KindSignatures, GADTs #-}

> module Exp where

> data Term
> data Pattern

> data Name a = Name String
> data Bind p e = Bound (p, e)

> data Expr :: * -> * where
>   Var :: Name (Expr a) -> Expr a
>   App :: Expr a ->  Expr a -> Expr a
>   Lam :: Bind (Name (Expr Pattern)) (Expr Term) -> Expr Term
> -- deriving Show

> data Equality = Equal (Expr Pattern) (Expr Term)

