# SolsticeCallbacks
Simple JS-like `:Then(cb)` handling for `Future`s in Figura.

## Usage
### FutureCallback
```lua
local stream = file:openReadStream("filename")
local future = stream:readAsync()
-- FutureCallback checks if the future is done every tick, 
-- calling the callback function passed to :Then() when done.
FutureCallback.FromFuture(future):Then(function (res)
    stream:close()
    print("File contained: " .. res)
end)
```

### ImmediateFutureCallback
```lua
local rStream = file:openReadStream("filename")
-- This is equivelent to just doing `repeat until self.future:isDone()`
-- You probably don't need this. I don't remember why I made it, and so
-- it will probably be removed in the future.
ImmediateFutureCallback.FromFuture(rStream:readAsync()):Then(function (res)
    rStream:close()
    print("File contained: " .. res)
end):Start()
```

## Files
| Required | Filename | Purpose |
| -------- | -------- | ------- |
| Yes      | `SolsticeCallbacks.lua` | Contains the entire script.