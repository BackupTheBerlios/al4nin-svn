> {-# LANGUAGE GADTs, TypeFamilies, TypeSynonymInstances #-}

> module Poor where

We first define the phantom types in the usual manner

> data Z where
> data S n where

To simulate a kind, we declare a type class with no methods

> class Nat n where

and include the phantom types Z and (S n) with the obvious
inference rules

> instance Nat Z
> instance Nat n => Nat (S n)

Now we can define our indexed data types that
adhere to the kind's regime as long as the constructors
are annotated with the corresponding class constraint

> data Nat' :: * -> * where
>   Z :: Nat' Z
>   S :: Nat n => Nat' n -> Nat' (S n)
>   -- rouge constructors
>   Z' :: Nat' Int
>   S' :: Nat' n -> Nat' (S n)

I have included two (primed) data constructors
that intentionally violate the kinding rules
so that I can provoke certain errors in GHCi.

| *Poor> :t S Z
| S Z :: Nat' (S Z)

So far, so good. Now, can GHC detect the violations?

| *Poor> :t S Z'
| 
| <interactive>:1:1:
|     No instance for (Nat Int)
|       arising from a use of `S'
|     Possible fix: add an instance declaration for (Nat Int)
|     In the expression: S Z'
| *Poor> :t S (S' Z')
| 
| <interactive>:1:1:
|     No instance for (Nat Int)
|       arising from a use of `S'
|     Possible fix: add an instance declaration for (Nat Int)
|     In the expression: S (S' Z')

Apparently, it can!

When we write type level functions on the Nat
kind we resort to type families. Here is a
function that computes the sum of two naturals
on the type level

> type family Plus m n :: *
> type instance Plus Z n = n
> type instance Plus (S m) n = S (Plus m n)

[the above three lines are shamelessly frobbed from
http://byorgey.wordpress.com/2010/07/06/typed-type-level-programming-in-haskell-part-ii-type-families/]

But we cannot index Nat' with (Plus m n) unless...

> dummy :: Nat' (Plus m Z)
> dummy = undefined

| *Poor> S dummy
| 
| <interactive>:1:1:
|     No instance for (Nat (Plus m0 Z))
|       arising from a use of `S'
|     Possible fix: add an instance declaration for (Nat (Plus m0 Z))
|     In the expression: S dummy
|     In an equation for `it': it = S dummy

... we add the inference rules to include (Plus m n) into the kind Nat

| > instance (Nat m,Nat n) => Nat (Plus m n)

Alas, GHC (v7.0.3) does not yet support this :-(

| PoorKinds.lhs:85:29:
|     Illegal type synonym family application in instance: Plus m n
|     In the instance declaration for `Nat (Plus m n)'

