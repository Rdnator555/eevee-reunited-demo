--funny require() hack so it can be used with luamod. Go to the init file for start stuff.

local json = require("json")

local function isLuaDebugEnabled()
	return package ~= nil
end

local function initGlobalVariable()
	if EEVEEMOD == nil then
		EEVEEMOD = {}
	end
	if EEVEEMOD.Src == nil then
		EEVEEMOD.Src = {}
	end
end

local function unloadEverything()
	for k, v in pairs(EEVEEMOD.Src) do
		package.loaded[k] = nil
	end
end

local vanillaRequire = require
local function patchedRequire(file)
	EEVEEMOD.Src[file] = true
	return vanillaRequire(file)
end

if isLuaDebugEnabled() then
	initGlobalVariable()
	unloadEverything()
	require = patchedRequire
end

local modInit = require("EeveeReunitedInit")
modInit:init(json)

if isLuaDebugEnabled() then
	require = vanillaRequire
end
