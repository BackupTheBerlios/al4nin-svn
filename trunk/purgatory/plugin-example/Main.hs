module Main (main) where

-- simple plugin experiment
--
-- see mail thread http://www.haskell.org/pipermail/glasgow-haskell-users/2008-February/014368.html

-- build like this:
-- $ ghc --make Main.hs
-- $ ghc -c -o XYZuse.o XYZuse.hs

-- invoke in ghci:
-- $ ghci Main.hs
-- Prelude Main> main
-- ...

import Foreign.Ptr
import System.Plugins.Load
import If

main = do LoadSuccess _ v <- load "XYZuse.o" ["."] [] "resource"
          t <- processTree v (exampleTree v)
          putStrLn (show t)
          return (version v)

