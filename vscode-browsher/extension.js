local vscode = js.global.require("vscode")
local fengari = js.global.require("fengari")
local interop = js.global.require("fengari-interop")
local util = js.global.require("util")
local lua_lib = fengari.lua
local lauxlib = fengari.lauxlib
local lualib = fengari.lualib
local L = lauxlib.luaL_newstate()
lualib.luaL_openlibs(L)
interop.push(L, js.global)
lua_lib.lua_setglobal(L, "_G")
local function load_fennel(code, filename)
  lauxlib.luaL_loadstring(L, code)
  lua_lib.lua_pcall(L, 0, 1, 0)
  lua_lib.lua_setglobal(L, "fennel")
  lauxlib.luaL_loadstring(L, ("return require('fennel').eval([[" .. code .. "]], {filename='" .. filename .. "', allowedGlobals = false})"))
  return lua_lib.lua_pcall(L, 0, 1, 0)
end
local function load_browsher()
  local fs = js.global.require("fs")
  local path = js.global.require("path")
  local base_path = "./lua/browsher"
  load_fennel(fs:readFileSync(path:join(base_path, "core/config.fnl"), "utf8"), "config.fnl")
  load_fennel(fs:readFileSync(path:join(base_path, "core/git.fnl"), "utf8"), "git.fnl")
  load_fennel(fs:readFileSync(path:join(base_path, "core/url.fnl"), "utf8"), "url.fnl")
  load_fennel(fs:readFileSync(path:join(base_path, "core/init.fnl"), "utf8"), "init.fnl")
  return load_fennel(fs:readFileSync(path:join(base_path, "platforms/vscode.fnl"), "utf8"), "vscode.fnl")
end
local function register_bridge_functions()
  local function _1_(fn_name, ...)
    interop.push(L, fn_name)
    lua_lib.lua_getglobal(L, "browsher_vscode")
    lua_lib.lua_getfield(L, -1, fn_name)
    local args = {...}
    for _, arg in ipairs(args) do
      interop.push(L, arg)
    end
    lua_lib.lua_call(L, #args, 1)
    local result = interop.tojs(L, -1)
    lua_lib.lua_pop(L, 1)
    return result
  end
  js.global.callFennel = _1_
  return nil
end
local function activate(context)
  load_browsher()
  register_bridge_functions()
  return js.global.callFennel("setup", context)
end
local function deactivate()
  return js.global.callFennel("cleanup")
end
return {activate = activate, deactivate = deactivate}
