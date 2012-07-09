module If (Interface(..),Tree(..)) where

import Foreign.Ptr

data Tree = Tree (Ptr Tree)

data Interface = Interface {
        processTree :: Ptr Tree -> IO (Ptr Tree)
}
