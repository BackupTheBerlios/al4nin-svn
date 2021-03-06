{-
 * Copyright (c) 2008 - 2012 Gabor Greif
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

> import Data.List
> import Test.QuickCheck
> 
> digits :: Bool -> Int -> [Char] -> [Char]
> digits _ 0 acc = '0' : acc
> digits True 1 acc = acc
> digits False 1 acc = '1' : acc
> digits dr n acc = digits dr (n `quot` 2) $ digits False (n `rem` 2) acc
> 
> dist :: Int -> [Char] -> [Char]
> dist 0 [] = "S"
> dist 0 acc = acc
> dist 1 acc = let r = dist 0 acc in 's' : digits True (length r) r
> dist n acc = dist (n - 1) $ dist 1 acc
> 
> takeLast n ss = drop excess ss
>                   where excess = length ss - n
> 
> test = takeLast 40 $ dist 20 []
> 

Now we need a decoder.

It takes a prefix of an encoded string and returns the
string length together with the number of accesses needed.

> pref' :: [Char] -> (Int, Int)
> pref' "S" = (1, 1)
> pref' ('s':rest) = decode 1 1 1 rest
>   where

Decode regular digits after 's'.

>     decode walk acc n ('0':rest) = decode (walk + 1) (acc * 2) (n + 1) rest
>     decode walk acc n ('1':rest) = decode (walk + 1) (acc * 2 + 1) (n + 1) rest
>     decode walk acc n _ = (walk + acc, n + 1)
> 
> pref' (_:rest) = (1 + res, 1 + n)
>   where (res, n) = pref' rest
> 

> pref :: [Char] -> Int
> pref = fst . pref'


Here come the accompanying tests.

> testcase = dist 10000 []
> testcase20 = dist 20 []
> accessPatterns20 = [(suff, pref' suff) | suff <- tails testcase20, (not . null) suff]
> accesses20 = reverse $ map (snd . snd) accessPatterns20
> 

And a QuickCheck property.

> identityProp n' = n == pref arr
>     where n = abs n' `rem` testcaseLength + 1
>           arr = takeLast n testcase
>           testcaseLength = length testcase
> 

And some more exhaustive ones.

> 
> deepCheck p = quickCheckWith (stdArgs {maxSuccess = 5000}) p
> 

Can we have a speculative random access read first and when that fails
continue with the linear one?

Here is the mapping for the first (speculative) offset

> --offs 'S' = 1
> offs '0' = 1
> offs '1' = 6
> offs 's' = 0

> specul "S" = (1, 1)
> specul (d:rest) | 'S' <- rest !! offs d = (offs d + 2, 2)
> specul all@('s':rest) = pref' all
> specul (d:rest) = (val + offs d + 2, 2 + n)
>   where (val, n) = pref' $ drop (offs d + 1) rest

Handcrafted for now:

> specTest = dist 3 "s0sS"

> accessPatternsSpec = [(suff, specul suff) | suff <- tails specTest, (not . null) suff]
> accessesSpec = reverse $ map (snd . snd) accessPatternsSpec
> accessesSpecSeq = reverse $ map (fst . snd) accessPatternsSpec


Now a decoder for a 3-bit alphabet:
- 'S'        --> full-stop
- 's'        --> stop, start (both unvalued)
- '0' .. '3' --> two-bits
- 'x'        --> two-bits encoding 01 but also being start and stop (both valued)
- 'y'        --> two-bits as start (valued 10) and unvalued stop

Special rules:
- 's' followed by '0' is three bits 100,
- 's', 'x', 'y' followed by any stop has fixed value (special full-stop)

> pref3 "S" = 1
> pref3 ('s':'0':rest) = d3code 2 4 rest
> pref3 ('s':'x':rest) = d3code 2 1 rest
> pref3 ('s':'y':_) = 4
> pref3 ('s':rest) = d3code 1 0 rest
> pref3 ('x':'S':_) = 2
> pref3 ('y':'x':_) = 3
> pref3 ('x':rest) = d3code 1 1 rest
> pref3 ('y':rest) = d3code 1 2 rest
> pref3 (_:rest) = 1 + pref3 rest

Decode regular digits after 's'.

> d3code walk acc ('0':rest) = d3code (walk + 1) (acc * 4) rest
> d3code walk acc ('1':rest) = d3code (walk + 1) (acc * 4 + 1) rest
> d3code walk acc ('2':rest) = d3code (walk + 1) (acc * 4 + 2) rest
> d3code walk acc ('3':rest) = d3code (walk + 1) (acc * 4 + 3) rest
> d3code walk acc ('x':_) = walk + 1 + acc * 4 + 1
> d3code walk acc _ = walk + acc

Hand-made testcase:

> t3 = di3t 1221 "s1x0syxS"
> t3length = length t3

> di3its :: Int -> [Char] -> [Char]
> di3its 0 acc = '0' : acc
> di3its 1 acc = '1' : acc
> di3its 2 acc = '2' : acc
> di3its 3 ('s':eff@('x':_)) = eff
> di3its 3 acc = '3' : acc
> di3its 4 acc = 's' : '0' : acc
> di3its n acc = di3its (n `quot` 4) $ di3its (n `rem` 4) acc
> 
> di3t :: Int -> [Char] -> [Char]
> di3t 0 [] = "S"
> di3t 0 acc = acc
> di3t 1 acc = close follow
>                where close ('1':rest) = 's' : 'x' : rest
>                      close ('2':rest) = 'y' : rest
>                      close (all@('s':_)) = all
>                      close all = 's' : all
>                      follow = di3its (length r) r
>                      r = di3t 0 acc
> di3t n acc = di3t (n - 1) $ di3t 1 acc


A similar property

> i3Prop n' = n > 0 && n <= t3length ==> n == pref3 arr
>     where n = n' `rem` t3length + 1
>           arr = takeLast n t3
