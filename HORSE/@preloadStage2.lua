if HORSE.__INITIALIZED then return end
HORSE.__INITIALIZED = true
HORSE._events = {}
HORSE.Event = {}
HORSE.Loaded = false
setmetatable(HORSE.Event, {
    __newindex = function(self, key, value) 
        if not HORSE._events[key] then HORSE._events[key] = {} end
        HORSE._events[key][#HORSE._events[key]+1] = value
    end,
    __index = function(self, key) 
        if HORSE._events[key] then 
            return function(...)
                for index, value in ipairs(HORSE._events[key]) do
                    value(...)
                end
            end
        else
            return function() end
        end
    end
})


HORSE.Profiler = {}
HORSE.Profiler._pending = {}
HORSE.Profiler._output = {}
function HORSE.Profiler:Push(key)
    if not (HORSE.config.debug > 0) then return end
    self._pending[#self._pending+1] = {key, client:getSystemTime()}
end

function HORSE.Profiler:Pop()
    if not (HORSE.config.debug > 0) then return end
    local value = table.remove(self._pending, #self._pending)
    if value == nil then
        error("[HORSE PROFILER] Mismatched pop/push! (missing a push?)")
    end
    HORSE.Profiler._output[#HORSE.Profiler._output+1] = {value[1], client:getSystemTime() - value[2]}
end

function HORSE.Profiler:PopPush(key)
    if not (HORSE.config.debug > 0) then return end
    self:Pop()
    self:Push(key)
end

function HORSE.Profiler:Flush()
    local output = self._output
    self._output = {}
    if HORSE.config.debug > 0 then
        for index, value in ipairs(output) do
            if tonumber(("%.2f"):format(value[2] / 1000)) > HORSE.config.debug then
                printJson(toJson {
                    {text=""},
                    {color = "gray", text=("[HORSE/Profiler/%s] "):format(value[1])},
                    ("%sms / %.2fs"):format(value[2], value[2] / 1000),
                    "\n"
                })
            end
        end
    end
end


HORSE.pending = {}

if not addScript then
    __HORSE__Bail("Your instance does not support `addScript`! This is required for HORSE to work! Host scripts will NOT be loaded!\n(Psst.... get the polyfill, it works with HORSE!)")
    require(HORSE.config.initScript)
    return
end

function HORSE:getResource(path, cb)
    if not file:exists(HORSE.config.folder .. "/" .. path) then return cb(nil) end
    local stream = file:openReadStream(HORSE.config.folder .. "/" .. path)
    local future = stream:readAsync()
    local buf = data:createBuffer(102400)
    -- buf:readFromStream(stream)
    -- buf:setPosition(0)
    -- cb(buf)
    FutureCallback.FromFuture(future):Then(function (res)
        stream:close()
        buf:writeByteArray(res)
        buf:setPosition(0)
        cb(buf)
    end)
end

function HORSE:isDir(path)
    return file:isDirectory(HORSE.config.folder .. "/" .. path)
end

function HORSE:getResourceSync(path)
    local stream = file:openReadStream(HORSE.config.folder .. "/" .. path)
    local buf = data:createBuffer()
    buf:readFromStream(stream)
    buf:setPosition(0)
    local res = buf:readByteArray()
    stream:close()
    buf:close()
    return res
end

function HORSE:list(path)
    return file:list(HORSE.config.folder .. "/" .. path)
end
---@param ... string
---@return string
function HORSE:joinPath(...)
    local args = table.pack(...)
    args["n"] = nil -- BEGONE!
    local final = ""
    for index, value in ipairs(args) do
        final = final .. value:gsub("/$", "") .. "/"
    end
    return final:sub(1,-2)
end

---@param folder string
---@param exec boolean?
function HORSE:executeFolder(folder, exec)
    exec = exec or false
    local i = 0
    local files = file:list(folder)
    if not files then return end
    for _, filename in ipairs(files) do
        local path = HORSE:joinPath(folder, filename)
        if not path:match("/%.") then 
            -- print(path)
            if file:isDirectory(path) then 
                i = i + HORSE:executeFolder(path, exec)
            elseif path:match(".*@.*%.lua$") then
                local luapath = path
                    :gsub("/", ".")
                    :gsub("%.lua$", "")
                    -- :gsub("%.@", "")
                    :gsub(HORSE.config.folder:gsub("%-", "%%-") .. "%.", "")
                addScript(luapath, nil, "NBT")
                HORSE:load(path, luapath, exec)
                i = i + 1
            end
        end
    end
    return i
end

HORSE._readcache = {}
function HORSE:readFile(path, cb)
    if HORSE._readcache[path] then return cb(HORSE._readcache[path]) end
    local stream = file:openReadStream(path)
    local future = stream:readAsync()
    local key = "HORSE:readFile(" .. path .. ")"
    events.TICK:register(function ()
        if future:isDone() then
            local v = future:getValue()
            HORSE._readcache[path] = v
            cb(v)
            stream:close()
            events.TICK:remove(key)
        end
    end, key)
end

function HORSE:load(path, luapath, exec)
    HORSE:readFile(path, function(dt)
        HORSE.pending[#HORSE.pending+1] = { luapath, dt, exec }
    end)
end

local _ticks = 0
local begunExec = false
events.TICK:register(function ()
    if not begunExec then return end
    host:actionbar(tostring(#HORSE.pending) .. " scripts left to initialize!")
    if #HORSE.pending >= 1 then
        _ticks = 0
        for i = 1, HORSE.config.scripts_per_tick, 1 do
            local p = table.remove(HORSE.pending, 1)
            if p == nil then break end
            local path, cont, exec = p[1], p[2], p[3]
            HORSE.Profiler:Push((exec and "Exec/" or "Read/") .. path)
            if not getScripts()[path:gsub("%.", "/")] then addScript(path, cont, "RUNTIME") end
            if exec then 
                require(path)
            end
            HORSE.Profiler:Pop()
        end
    else
        _ticks = _ticks + 1
        if _ticks == 3 then
            HORSE.Loaded = true
            HORSE.Profiler:Pop()
            HORSE.Profiler:Pop()
            HORSE.Profiler:Flush()
            events.TICK:remove("HORSE.ScriptLoader")
            require(HORSE.config.initScript)
            HORSE.Event.ENTITY_INIT()
        end
    end
end, "HORSE.ScriptLoader")

function HORSE:loadResources(dir)
    for index, path in ipairs(file:list(dir)) do
        if path:match("%.png$") then 
            local texturePath = HORSE:joinPath(dir, path):gsub("/", "."):sub(1,-5):gsub(HORSE.config.folder:gsub("%-", "%%-") .. ".", "")
            if not textures[texturePath] then 
                local dt = file:openReadStream(HORSE:joinPath(dir, path))
                local buf = data:createBuffer(dt:available())
                buf:readFromStream(dt)
                buf:setPosition(0)
                local b64 = buf:readBase64()
                textures:read(texturePath, b64)
                dt:close()
                buf:close()  
            end
        elseif file:isDirectory(HORSE:joinPath(dir, path)) then
            HORSE:loadResources(HORSE:joinPath(dir, path))
        end
    end
end
for key, _ in pairs(getScripts()) do
    if key:match(".*@.+$") then
        local luapath = key
            :gsub("/", ".")
        addScript(luapath, nil, "NBT")
    end
end
HORSE.Profiler:Push("HORSE")
HORSE.Profiler:Push("Resources.INIT")
HORSE:loadResources(HORSE.config.folder)
HORSE.Profiler:PopPush("AddScripts")
HORSE:executeFolder(HORSE.config.folder, false)
HORSE.Profiler:PopPush("WaitingForDeferredExec")
__HORSE__Bail = nil

local dl = 0
events.TICK:register(function ()
    if dl == 5 then 
        HORSE.Profiler:PopPush("ExecScripts")
        HORSE:executeFolder(HORSE.config.folder, true)
        begunExec = true
        events.TICK:remove("HORSE.DeferredExec")
    end
    dl = dl + 1
end, "HORSE.DeferredExec")
