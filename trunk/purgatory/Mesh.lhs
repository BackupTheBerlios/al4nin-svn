I want a 2-dimensional list like this

              ...

^     ^     ^     ^     ^     ^
|     |     |     |     |     |
A --> B --> C --> D --> E --> F --> ...
^     ^     ^     ^     ^     ^
|     |     |     |     |     |
a --> b --> c --> d --> e --> f --> ...


I'd model the nodes (e.g. 'B') as a normal list/thrist horizontally:

> type Payload = (Int, Char)

> b :: Uplist Payload
> (b:_) = tail southmost

and the uplist again as a list

> data Uplist a = Up a [Uplist Payload] deriving Show



> southmost :: [Uplist Payload]
> southmost = gen southmost 0 'a'
>   where gen node n l = up hrest : hrest
>           where up ~(Up _ ruplist:_) = Up (n, l) (undefined (succ n, l) : ruplist)
>                 hrest = gen hrest n $ succ l
