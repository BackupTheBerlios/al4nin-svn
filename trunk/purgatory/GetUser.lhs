> import Test.QuickCheck
> 
> digits :: Int -> [Char] -> [Char]
> digits 0 acc = '0' : acc
> digits 1 acc = '1' : acc
> digits n acc = digits (n `div` 2) $ digits (n `mod` 2) acc
> 
> dist :: Int -> [Char] -> [Char]
> dist 0 [] = ['S']
> dist 0 acc = acc
> dist 1 acc = let r = dist 0 acc in 's' : digits (length r) r
> dist n acc = dist (n - 1) $ dist 1 acc
> 
> takeLast n ss = reverse $ take n $ reverse ss
> 
> test = takeLast 40 $ dist 20 []
> 
