module XYZuse (resource) where

import If
import Foreign.Ptr

resource = Interface {
   processTree = return
 , exampleTree = nullPtr
 , version = 2
}
