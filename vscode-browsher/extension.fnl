;; VSCode extension entry point using Fengari
;; This will be compiled to JavaScript

(local vscode (js.global.require "vscode"))
(local fengari (js.global.require "fengari"))
(local interop (js.global.require "fengari-interop"))
(local util (js.global.require "util"))

(local lua_lib fengari.lua)
(local lauxlib fengari.lauxlib)
(local lualib fengari.lualib)

;; Create Lua state
(local L (lauxlib.luaL_newstate))
(lualib.luaL_openlibs L)

;; Set up interop
(interop.push L js.global)
(lua_lib.lua_setglobal L "_G")

;; Create Fennel runtime
(fn load-fennel [code filename]
  (lauxlib.luaL_loadstring L code)
  (lua_lib.lua_pcall L 0 1 0)
  (lua_lib.lua_setglobal L "fennel")
  
  ;; Now use Fennel to load the code
  (lauxlib.luaL_loadstring L (.. "return require('fennel').eval([["
                                code
                                "]], {filename='" filename "', allowedGlobals = false})"))
  (lua_lib.lua_pcall L 0 1 0))

;; Load the browsher entry point
(fn load-browsher []
  ;; Load file from disk
  (local fs (js.global.require "fs"))
  (local path (js.global.require "path"))
  
  ;; Load each module
  (let [base-path "./lua/browsher"]
    (load-fennel (fs:readFileSync (path:join base-path "core/config.fnl") "utf8") "config.fnl")
    (load-fennel (fs:readFileSync (path:join base-path "core/git.fnl") "utf8") "git.fnl")
    (load-fennel (fs:readFileSync (path:join base-path "core/url.fnl") "utf8") "url.fnl")
    (load-fennel (fs:readFileSync (path:join base-path "core/init.fnl") "utf8") "init.fnl")
    (load-fennel (fs:readFileSync (path:join base-path "platforms/vscode.fnl") "utf8") "vscode.fnl")))

;; Bridge functions for VSCode integration
(fn register-bridge-functions []
  ;; Function to call into Lua/Fennel from JS
  (set js.global.callFennel 
       (fn [fn-name ...]
         (interop.push L fn-name)
         (lua_lib.lua_getglobal L "browsher_vscode")
         (lua_lib.lua_getfield L -1 fn-name)
         
         ;; Push args
         (let [args [...]]
           (each [_ arg (ipairs args)]
             (interop.push L arg))
           
           (lua_lib.lua_call L (length args) 1)
           (let [result (interop.tojs L -1)]
             (lua_lib.lua_pop L 1)
             result)))))

;; Activate extension
(fn activate [context]
  (load-browsher)
  (register-bridge-functions)
  (js.global.callFennel "setup" context))

;; Deactivate extension
(fn deactivate []
  (js.global.callFennel "cleanup"))

{:activate activate
 :deactivate deactivate} 