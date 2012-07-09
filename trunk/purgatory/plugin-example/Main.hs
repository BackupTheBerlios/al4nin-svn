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
import System.Plugins
import If



main = load "XYZuse.o" ["."] [] "resource" >>= (\(LoadSuccess _ v) -> (processTree v nullPtr))

