This program tries to model the idea I have formulated
in my blog post

http://heisenbug.blogspot.com/2010/11/patterns-and-existentials.html

The gist is that patterns are simply (lambda-less) expressions
that appear on the left-hand side for which an oracle fills in
pattern variables in a way that the result becomes identical
to the scrutinee.

Other relevant reading is McBride and McKinna's "The view from the left"
http://strictlypositive.org/view.ps.gz

> {-# LANGUAGE KindSignatures, GADTs #-}

> module Exp where

> data Term
> data Pattern

> data Name a = Name String
> data Bind p e = Bound (p, e)

The Expr data type is modelled closely after
'Term' in http://byorgey.wordpress.com/2011/03/28/binders-unbound/

> data Expr :: * -> * where
>   Var :: Name (Expr a) -> Expr a
>   App :: Expr a ->  Expr a -> Expr a
>   Lam :: Bind (Name (Expr Pattern)) (Expr Term) -> Expr Term
>   Con :: String -> [Expr a] -> Expr a -- data constructors
> -- deriving Show

> data Equality = Equal (Expr Pattern) (Expr Term)

Here is a test expression:

> test1 = Equal (Var (Name "xx")) (Lam (Bound (Name "gg", Var (Name "gg"))))
> test2 = Equal (Con "S" [Con "Z" []]) (Con "Z" [])

