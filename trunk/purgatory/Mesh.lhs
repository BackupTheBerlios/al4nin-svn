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

> type Uplist a = [a]



> southmost :: [Uplist Payload]
> southmost = gen southmost 'a'
>   where gen node l = up hrest : hrest
>           where up hrest = [(0, l)]
>                 hrest = gen hrest $ succ l
