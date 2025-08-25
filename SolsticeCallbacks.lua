--- @class FutureCallback
--- @field future Future
--- @field _ticker Event.Generic|Event.Generic.func
FutureCallback = {}
FutureCallback.future = nil
FutureCallback._ticker = nil
FutureCallback._then = function() end

--- @param future Future
function FutureCallback.FromFuture(future)
    local cb = setmetatable({}, { __index = FutureCallback })
    cb.future = future
    local _id = tostring(math.random()) .. client:getFPSString()
    cb._ticker = events.TICK:register(function ()
        if cb.future:isDone() then 
            events.TICK:remove(_id)
            cb._then(cb.future:getValue())
        end
    end, _id)
    return cb
end

--- @param func fun(res: any)
function FutureCallback:Then(func)
    self._then = func
end

--- @class ImmediateFutureCallback
--- @field future Future
ImmediateFutureCallback = {}
ImmediateFutureCallback.future = nil
ImmediateFutureCallback._then = function() end

--- @param future Future
function ImmediateFutureCallback.FromFuture(future)
    local cb = setmetatable({}, { __index = ImmediateFutureCallback })
    cb.future = future
    return cb
end

--- @param func fun(res: any)
function ImmediateFutureCallback:Then(func)
    self._then = func
    return self
end

function ImmediateFutureCallback:Start()
    repeat until self.future:isDone()
    self._then(self.future:getValue())
end

return {
    FutureCallback = FutureCallback,
    ImmediateFutureCallback = ImmediateFutureCallback
}