if host:isHost() and avatar:getPermissionLevel() ~= "MAX" then figuraMetatables.HostAPI.__index.isHost = function()return false end end
if not host:isHost() then
    HORSE = setmetatable({}, {__index = function() error("HORSE accessed outside of host-only context!") end})
    HORSE._events = {}
    HORSE.Event = {}
    HORSE.Loaded = true
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
    function events.ENTITY_INIT() HORSE.Event.ENTITY_INIT() end
    return require "scripts.init"
end

local scripts = listFiles("", true)
local addScriptPoly = false
local SolsticeCallbacks = false
for index, value in ipairs(scripts) do
    if (addScript or addScriptPoly) and SolsticeCallbacks then break end
    if value:find("addScriptPolyfill") then
        require(value)
        addScriptPoly = true
    end
    if value:find("SolsticeCallbacks") then
        require(value)
        SolsticeCallbacks = true
    end
end
HORSE = {}
HORSE.config = {
    folder = "folderName",       -- Name of the folder within the data folder to load from
    initScript = "init",         -- Script to require when HORSE loaded
    stage2 = "@preloadStage2",   -- Name of the second part of the HORSE
    scripts_per_tick = 25,       -- Amount of scripts to require from HORSE per tick
    debug = 0                    -- Minimum amount of time for entry to be logged. 0 to disable.
}

function __HORSE__Bail(text) 
    printJson(toJson {
        {text=""},
        {text = "[", color = "gold"},
        {text = "WARN", color = "yellow"},
        {text = "] ", color = "gold"},
        {text = text},
        {text="\n"}
    })
end

if not SolsticeCallbacks then
    __HORSE__Bail("Dependency SolsticeCallbacks not found! Bailing out.")
    require(HORSE.config.initScript)
    return
end

local rStream = file:openReadStream(HORSE.config.folder .. "/" .. HORSE.config.stage2:gsub("%.", "/") .. ".lua")
ImmediateFutureCallback.FromFuture(rStream:readAsync()):Then(function (res)
    if addScript then
        addScript("__HORSE_preload", res, "RUNTIME")
        require("__HORSE_preload")
    else
        loadstring(res,"__HORSE_preload",_ENV)()
    end
end):Start()
