
> data UsePtr = Zero UsePtr | One UsePtr | Stop UsePtr | Fin Value

> data Value = Val Int UsePtr

> verify :: Value -> Bool
> verify (Val i (p@(Zero p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(One p'))) = compute p == i && verify (Val i p')
> verify (Val i (p@(Stop p'))) = compute p == i && verify (Val i p')
> verify (Val i (Fin (Val i' _))) = i == i'

> compute p = compute' 0 0 p

> compute' :: Int -> Int -> UsePtr -> Int
> compute' steps seed (Zero p) = compute' (steps + 1) (seed + seed) p
> compute' steps seed (One p) = compute' (steps + 1) (seed + seed + 1) p
> compute' steps seed (Stop p) = if steps == 3 then seed else compute' 0 0 p
> compute' steps seed (Fin (Val i _)) = i

> test = Val 5 $ One $ Zero $ One $ Stop $ Zero $ Fin test
