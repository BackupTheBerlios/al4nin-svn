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
import System.Plugins.LoadTypes (ObjType(..))
import If

instance Show ObjType where
  show Vanilla = ".o"
  show Shared = ".so"

main = do LoadSuccess m v <- load "XYZuse.o" ["."] [] "resource"
          putStrLn ("success loading from module '" ++ show (mname m) ++ "', object kind: " ++ show (kind m))
          putStrLn ("module version: " ++ show (version v))
          t <- processTree v (exampleTree v)
          putStrLn (show t)
          loaded <- dynload "XYZuse.o" ["."] [] "egg"
          case loaded of
            LoadSuccess _ spell -> do
                 putStrLn (spell "This sentence is full of awfull typos, that a sucessfull checker can correct.")
                 return ()
            LoadFailure errors -> putStrLn ("error loading 'egg': " ++ concat errors)
