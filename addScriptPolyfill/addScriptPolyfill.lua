if addScript then return end
local _addedScripts = {}
local _returned = {}


local orig_require = require

local function getCallingChunk(d)
    local traceback = select(2, pcall(function (...)
        error("",d or 0)
    end))
    traceback = traceback:gsub(":%d+.*", ""):gsub("/", ".")
    return traceback
end

local function getLuaParent(luaPath)
    local ret, _ = luaPath:gsub("%.[^.]+$", "")
    -- print(luaPath, ret)
    return ret
end

local function traversePath(path, caller, depth)
    depth = depth or 1
    if depth > 40 then error("couldn't traverse " .. path .. " (recursion limit reached)") end
    local parent = getLuaParent(caller)
    if ("^" .. path):find("[^.]%./") then
        local resolved = ("^" .. path):gsub("([^.]*)%./", "%1", 1):sub(2,-1)
        resolved = parent .. "." .. resolved
        return traversePath(resolved, caller, depth + 1)
    end
    if path:find("%.%./") then
        local s, e = path:find("%.%./")
        local a = path:sub(1,s)
        local b = path:sub(e+1,-1)
        local resolved = getLuaParent(parent) .. "." .. b
        return traversePath(resolved, caller, depth + 1)
    end
    -- print(path, caller, depth)
    return path
end

local function wrap(name, cont)
    local a = getLuaParent(name)
    local b = name:sub(#a + 2, -1)
    local prefix = "return (function(...) "
    local suffix = (" end)('%s','%s')"):format(a,b)
    return prefix .. cont .. suffix
end

local function stringify(tbl)
    local final = ""
    for index, value in ipairs(tbl) do
        value = value % 256
        final = final .. string.char(value)
    end
    return final
end

local _cached = {}

function getScripts() 
    local scripts = {}
    local scriptsNBT = avatar:getNBT().scripts

    for key, value in pairs(scriptsNBT) do
        scripts[key] = _cached[key] or stringify(value)
        _cached[key] = scripts[key]
    end

    for key, value in pairs(_addedScripts) do
        scripts[key] = value
    end

    return scripts
end
function addScript(scriptName, contents, side)
    -- if side and side ~= "RUNTIME" then
    --     print("Cannot add to NBT from addScript polyfill.")
    -- end
    _addedScripts[scriptName] = wrap(scriptName, contents or "")
    _returned[scriptName] = nil
end

function require(orig_mod)
    local caller = getCallingChunk(5)
    local mod = orig_mod
    mod = traversePath(mod, caller)
    mod = mod:gsub("/", ".")
    -- print(caller, "@", orig_mod, "→", mod)
    if caller == mod then error("smth fucked up") end
    if _addedScripts[mod] then
        if _returned[mod] then 
            local r = _returned[mod]
            return table.unpack(r)
        end
        local ret = loadstring(_addedScripts[mod], mod, _G)
        if ret then 
            ret = table.pack(ret()) 
        else
            ret = table.pack()
        end
        _returned[mod] = ret
        -- print(mod, ret)
        return table.unpack(ret)
    end
    return orig_require(mod)
end

local orig_listFiles = listFiles
function listFiles(dir, recursive)
    local res = orig_listFiles(dir, recursive)
    if recursive then
        for key, value in pairs(_addedScripts) do
            if key:find("^" .. dir:gsub("%.", "%%.")) then
                res[#res+1] = key
            end
        end
    else
        for key, value in pairs(_addedScripts) do
            if getLuaParent(key) == dir then
                res[#res+1] = key
            end
        end 
    end
    
    -- print(dir, recursive, "→", res)
    return res
end
