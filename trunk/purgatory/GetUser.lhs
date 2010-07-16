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
> decode walk acc ('0':rest) = decode (walk + 1) (acc * 2) rest
> decode walk acc ('1':rest) = decode (walk + 1) (acc * 2 + 1) rest
> decode walk acc _ = walk + acc
> 

Here come the accompanying tests.

> testcase = dist 10000 []
> testcaseLength = length testcase
> 
> identityProp n = n > 0 && n <= testcaseLength ==> length arr == pref arr
>     where arr = takeLast n testcase
> 

And some more exhaustive ones.

> 
> -- deepCheck p = check (defaultConfig { configMaxTest = 500 }) p
> 

