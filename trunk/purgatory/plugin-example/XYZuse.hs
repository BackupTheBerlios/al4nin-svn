module XYZuse (resource, egg) where

import If
import Foreign.Ptr
import Data.Dynamic

resource = Interface
 { processTree = return
 , exampleTree = nullPtr
 , version = 2 }

spellCheck [] = []
-- http://www.dumbtionary.com/word/sucessfull.shtml
spellCheck ('s':'u':'c':'e':'s':'s':rest) = 's':'u':'c':'c':'e':'s':'s':spellCheck rest
spellCheck (' ':f:'u':'l':'l':' ':rest) | f == 'f' || f == 'F' = ' ':f:'u':'l':'l':' ':spellCheck rest
spellCheck ('f':'u':'l':'l':' ':rest) = 'f':'u':'l':' ':spellCheck rest
spellCheck (letter:rest) = letter:spellCheck rest

egg = toDyn spellCheck
