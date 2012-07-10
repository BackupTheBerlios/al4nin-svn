module If (Interface(..),Tree(..)) where

import Foreign.Ptr

data Tree = Tree (Ptr Tree) deriving Show

data Interface = Interface
 { processTree :: Ptr Tree -> IO (Ptr Tree)
 , exampleTree :: Ptr Tree
 , version :: Int }
