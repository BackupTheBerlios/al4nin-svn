{-
 * Copyright (c) 2008, 2010 Gabor Greif
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

> import Test.QuickCheck
> 
> digits :: Bool -> Int -> [Char] -> [Char]
> digits _ 0 acc = '0' : acc
> digits True 1 acc = acc
> digits False 1 acc = '1' : acc
> digits dr n acc = digits dr (n `div` 2) $ digits False (n `mod` 2) acc
> 
> dist :: Int -> [Char] -> [Char]
> dist 0 [] = ['S']
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

> pref :: [Char] -> Int
> pref "S" = 1
> pref ('s':rest) = decode 1 1 rest
> pref (_:rest) = 1 + pref rest
> 

Decode regular digits after 's'.

> decode walk acc ('0':rest) = decode (walk + 1) (acc * 2) rest
> decode walk acc ('1':rest) = decode (walk + 1) (acc * 2 + 1) rest
> decode walk acc _ = walk + acc
> 

Here come the accompanying tests.

> testcase = dist 10000 []
> testcaseLength = length testcase
> 
> identityProp n' = n > 0 && n <= testcaseLength ==> n == pref arr
>     where n = mod n' testcaseLength + 1
>           arr = takeLast n testcase
> 

And some more exhaustive ones.

> 
> deepCheck p = quickCheckWith (Args {maxSuccess = 5000, replay = Nothing, maxDiscard = 100, maxSize = 100}) p
> 

Now a decoder for a 3-bit alphabet:
- 'S'        --> full-stop
- 's'        --> stop
- '0' .. '3' --> two-bits
- 'x' .. 'y' --> two-bits encoding 01 and 10 but also being stop

Special rules:
's' followed by '0' is three bits 100,
's' followed by 'x' is three bits 101,
's' followed by 'y' is three bits 110.

> stop 'S' = True
> stop 's' = True
> stop 'x' = True
> stop 'y' = True
> stop _ = False


> pref3 "S" = 1
> pref3 ('s':'0':rest) = d3code 3 4 rest -- non regular walk!
> pref3 ('s':'x':rest) = 1 + pref3 ('x':rest)
> pref3 ('s':'y':rest) = 1 + pref3 ('y':rest)
> pref3 ('s':rest) = d3code 1 0 rest
> pref3 ('x':n:_) | stop n = 2
> pref3 ('y':n:_) | stop n = 3
> pref3 ('x':rest) = d3code 1 1 rest
> pref3 ('y':rest) = d3code 1 2 rest
> pref3 (_:rest) = 1 + pref3 rest

Decode regular digits after 's'.

> d3code walk acc ('0':rest) = d3code (walk + 1) (acc * 4) rest
> d3code walk acc ('1':rest) = d3code (walk + 1) (acc * 4 + 1) rest
> d3code walk acc ('2':rest) = d3code (walk + 1) (acc * 4 + 2) rest
> d3code walk acc ('3':rest) = d3code (walk + 1) (acc * 4 + 3) rest
> d3code walk acc ('x':_) = walk + 1 + acc * 4 + 1
> d3code walk acc ('y':_) = walk + 1 + acc * 4 + 2
> d3code walk acc _ = walk + acc

Hand-made testcase:

> t3 = "s00s32sy3sy0s1x0syxS"
> t3Length = length t3

A similar property

> i3Prop n' = n > 0 && n <= t3Length ==> n == pref3 arr
>     where n = mod n' t3Length + 1
>           arr = takeLast n t3
