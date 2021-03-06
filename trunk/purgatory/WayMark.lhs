{-
 * Copyright (c) 2008-2012 Gabor Greif
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 -}

This is a literate Haskell file.

High level description:

Def-use chains are managed via linked lists in LLVM.
They allow O(1) removal because of a Pred member in the
Use struct that points to a Use* of the previous Use or
Value. The invariant is that *Pred == this if it is
chained up.

This chain (viz. the lowest significant bist of the
Next pointers in the Use) can be used to carry a serial
line protocol that when decoded does deliver the Value*
that this chain belongs to. Any Use* is sufficient as
input to the algorithm.

The metaphor gives us these correspondences:
 - 0, 1 --> data bits
 - s    --> stop bit
 - S    --> full stop, NO CARRIER

I call this protocol waymarking, and the below algorithm
is an implementation of it. It is self-repairing, in that
any succession of Insert and Delete events won't change
the result. Lookup events even reapply compromized waymarks
in a conservative fashion, no potentially valid clusters are
modified. This is all at the cost of a potentially longer
sequence of bits to be scanned from the chain. The big benefit
however is the reduction of the Use struct by a pointer: since
the Value* can always be reliably recovered, there is no need
to store it in the Use struct any more.

The invariant that leads to this behaviour is that fixed-size
clusters can only decrease in size and never increase.
Clusters of the wrong size are always discarded and potentially
refreshed at a Lookup.

Bugs: This invariant is currently violated by a bug that
removal of a single Stop may join two clusters.

> import Monad
> import Test.QuickCheck

First we define the datatype for tagged pointers.
The Fin constructor points back to the Value itself:

> data UseTag = Zero | One | Stop
>   deriving Show

> data UsePtr = Tagged UseTag UsePtr | Fin Value
> instance Show UsePtr where
>     show (Tagged Zero p) = "0" ++ show p
>     show (Tagged One p) = "1" ++ show p
>     show (Tagged Stop p) = "s" ++ show p
>     show (Fin (Val i _)) = "S(" ++ show i ++ ")"

Values (here) store the numerical integer for the bit pattern of the
pointer (Value*) and the first Use* in the chain.

> data Value = Val Int UsePtr
>     deriving Show

The verify function walks the Use chain and for each pointer performs
a check whether the computed Value* matches up with the reality.

> verify :: Value -> Bool
> verify (Val i (p@(Tagged _ p'))) = compute p == i && verify (Val i p')
> verify (Val i (Fin (Val i' _))) = i == i'

Forwarding function supplying step counter and seed:

> compute p = compute' 0 0 p

The 0 for steps above means that a Value serves
as an implicit Stop.

The following function scans the waymarks along the chain and
returns the numerical pattern for Value*.

Note: for simplicity the required step count is 3 at the moment.
In the end it may well be a value that depends on the bit pattern
itself.

> requiredSteps = 3

> compute' :: Int -> Int -> UsePtr -> Int
> compute' steps seed (Tagged Zero p) = compute' (steps + 1) (seed + seed) p
> compute' steps seed (Tagged One p) = compute' (steps + 1) (seed + seed + 1) p
> compute' steps seed (Tagged Stop p) = if steps == requiredSteps then seed else compute' 0 0 p
> compute' steps seed (Fin (Val i _)) = i

The lookup function calls compute' to get the bit pattern and returns also the
position of a potential start pointer at which the fresh marks could be reapplied.

> lookup :: UsePtr -> (Int, UsePtr)
> lookup p = case repaint False requiredSteps 0 0 p of
>            Nothing -> (i, p)
>            Just pos -> (i, fst $ reapply i pos requiredSteps p)
>   where
>     i = compute' 0 0 p
>     reapply i 1 steps (Tagged Zero p) = (Tagged Stop $ fst $ reapply i 0 steps p, 0)
>     reapply i 1 steps (Tagged One p) = (Tagged Stop $ fst $ reapply i 0 steps p, 0)
>     reapply i 0 0 p = (p, i)
>     reapply i 0 (s + 1) (Tagged _ p) = (Tagged (if odd i' then One else Zero) p', i' `div` 2)
>         where (p', i') = reapply i 0 s p
>     reapply i (offs + 1) steps (Tagged t p) = (Tagged t $ fst $ reapply i offs steps p, 0)

Now we have to provide the function for obtaining the repaint position.
Be sure that a possible digit before this position must be changed to a Stop
to avoid cluster extension.
The function returns the index relative to UsePtr (zero based) where
the requiredSteps digits maust be placed.

> repaint :: Bool -> Int -> Int -> Int -> UsePtr -> Maybe Int

repaint accepts a bool as the first argument, whose semantics are
that a current cluster is properly initiated. Even if this is false,
but the to-go argument arrived at 0 the cluster is valid.

We handle the latter case first, because if we have a complete
cluster then there is nothing to repaint before that:

> repaint _ 0 _ _ _ = Nothing

If we get a Stop and the cluster is not seen as properly initiated
we have to assume that we started in the middle of a potentially
valid cluster and we are not permitted to overpaint anything. But
we have to carry on and shift the pos:

E.g. 10s
       ^

> repaint False _ pos _ (Tagged Stop p) = repaint True requiredSteps (pos + 1) 0 p

Seeing a digit of a potentially valid cluster means decreasing to-go and increasing pos:
E.g. 10s
      ^

> repaint False (moretogo + 1) pos _ (Tagged _ p) = repaint False moretogo (pos + 1) 0 p

We have to catch Fin at last:

> repaint False _ _ _ (Fin _) = Nothing

Ok, now we are left with properly initiated clusters (of possibly zero length). Let's
handle Stop first:

> repaint True _ pos steps (Tagged Stop p) = case (validcluster requiredSteps p, steps == requiredSteps) of
>                                            (True, True) -> Just pos
>                                            (True, False) -> Nothing
>                                            (False, True) -> repaint True requiredSteps (pos + 1) requiredSteps p
>                                            (False, False) -> repaint True requiredSteps pos (steps + 1) p
>     where
>       validcluster 0 _ = True
>       validcluster _ (Tagged Stop _) = False
>       validcluster n (Tagged _ p) = validcluster (n - 1) p
>       validcluster _ _ = False

Digits simply increment the steps or if already enough, advance pos:

> repaint True (moretogo + 1) pos steps (Tagged _ p) = if steps == requiredSteps
>                                                      then repaint True moretogo (pos + 1) requiredSteps p
>                                                      else repaint True moretogo pos (steps + 1) p

Remains to handle Fin:

> repaint True _ pos steps (Fin _) = if steps == requiredSteps
>                                    then Just pos
>                                    else Nothing


Test section:

> testcase = Val 5 (i $ o $ i $ s $ o $ Fin testcase)
> testcase' = let (Val i p) = testcase in let v = Val (i+1) $ copy v p in v
> fishy = Val 5 (i $ o $ i $ s $ i $ o $ i $ Fin fishy)

> data HistoryElem
>   = Insert
>   | Remove Int
>   | Lookup Int
>  deriving Show

> type History = [HistoryElem]

Some quickCheck helpers:

> instance Arbitrary HistoryElem where
>   coarbitrary = undefined
>   arbitrary = frequency [ (2, return Insert)
>                         , (1, liftM Remove (fmap abs arbitrary))
>                         , (1, liftM Lookup (fmap abs arbitrary))]


Now we can construct a Value given the pointer pattern and a history:

> construct :: Int -> History -> Value
> construct i h = construct' seed h where seed = Val i (Fin seed)

The actual mutating function is construct':

> construct' v [] = v
> construct' (Val i p) (Insert : rest) = let v = Val i $ Tagged Stop $ copy v p in construct' v rest

> construct' v@(Val _ (Fin _)) (Remove _ : rest) = construct' v rest

We have to special case removal of a Stop, since that may merge clusters.
Better put a stop downstream to prevent this. TODO

> construct' (Val i p) (Remove n : rest) = let v = Val i $ copy v $ shp p (shorten p n) in construct' v rest
> construct' (Val i p) (Lookup n : rest) = let v = Val i $ copy v $ pep p (peek p n) in construct' v rest

> shp p (Left p') = p'
> shp p (Right n) = shp p (shorten p n)
 
> shorten (Tagged _ p) 0 = Left p
> shorten (Fin _) n = Right n
> shorten (Tagged t p) (n+1) = ext t $ shorten p n

> ext constr (Left p) = Left $ Tagged constr p
> ext _ r@(Right n) = r

> pep :: UsePtr -> Either UsePtr Int -> UsePtr
> pep p (Left p') = p'
> pep p (Right n) = pep p (peek p n)

> peek p@(Tagged _ _) 0 = Left $ snd $ Main.lookup p
> peek (Fin _) n = Right n
> peek (Tagged t p) (n+1) = ext t $ peek p n


The copy function ensures that we maintain the invariant that
Fin actually points to the same Val (sharing)

> copy v (Fin _) = Fin v
> copy v (Tagged t p) = Tagged t $ copy v p

Declare some QuickCheck properties

> prop_hist h = verify (construct' testcase h)
> prop_hist_fishy h = verify (construct' fishy h)

> t1 = quickCheck prop_hist
> t2 = quickCheck prop_hist_fishy

Some niceties for interactive testing:

> o = Tagged Zero
> i = Tagged One
> s = Tagged Stop
> f = Fin $ Val 0 f


> te1 = s $ s $ s $ s $ o $ i $ o $ s $ f
> te2 = s $ s $ s $ o $ i $ f
> te3 = i $ o $ i te1
> te4 = i $ o $ te1
