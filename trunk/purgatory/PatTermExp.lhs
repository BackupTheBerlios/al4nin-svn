This program tries to model the idea I have formulated
in my blog post

http://heisenbug.blogspot.com/2010/11/patterns-and-existentials.html

The gist is that patterns are simply (lambda-less) expressions
that appear on the left-hand side for which an oracle fills in
pattern variables in a way that the result becomes identical
to the scrutinee.

Other relevant reading is McBride and McKinna's "The view from the left"
http://strictlypositive.org/view.ps.gz

> {-# LANGUAGE KindSignatures, GADTs, StandaloneDeriving #-}

> module Exp where

> import Data.Thrist
> import Text.ParserCombinators.Parsec

> data Term
> data Pattern

> data Name a = Name String deriving Show
> data Bind p e = Bound (p, e) deriving Show

The Expr data type is modelled closely after
'Term' in http://byorgey.wordpress.com/2011/03/28/binders-unbound/

> data Expr :: * -> * where
>   Var :: Name (Expr Term) -> Expr a
>   App :: Expr a ->  Expr a -> Expr a
>   Lam :: Bind (Name (Expr Pattern)) (Expr Term) -> Expr Term
>   Con :: String -> [Expr a] -> Expr a -- data constructors

Make sure we can show expressions

> deriving instance Show (Expr a)

A haskell-style equality is a left-hand-side pattern
expression and a right-hand-side term expression

> data Equality = Equal (Expr Pattern) (Expr Term) deriving Show

Here are some test expressions:

> test1 = Equal (Var (Name "xx")) (Lam (Bound (Name "gg", Var (Name "gg"))))
> test2 = Equal (Con "S" [Con "Z" []]) (Con "Z" [])

> symbol a = do { spaces
>               ; string a }

> name :: Parser String
> name = do spaces
>           many1 letter

> -- parens  = between (symbol "(") (symbol ")")

> lambda = do symbol "\\"
>             n <- name
>             symbol "."
>             e <- expr
>             return $ Lam (Bound (Name n, e))

> apply = do symbol "("
>            e1 <- expr
>            symbol "@"
>            e2 <- expr
>            symbol ")"
>            return $ App e1 e2

> var = fmap (Var . Name) name


> expr = var <|> lambda <|> apply

> program = do e <- expr
>              many newline
>              eof

> main = do result <- parseFromFile program "pat-term.txt"
>           case result of
>            Left err -> print err
>            Right e  -> print $ show e
