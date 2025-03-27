;; Neovim platform implementation for browsher
(local {: merge-configs} (require "browsher.core.config"))
(local git (require "browsher.core.git"))
(local url (require "browsher.core.url"))
(local core (require "browsher.core.init"))

(local M {})

;; Store the user configuration
(local config {:options {}})

;; Initialize the module
(fn M.init []
  ;; Override platform-specific functions in the core modules
  
  ;; Git module overrides
  (set git.execute-git-command M.execute-git-command)
  (set git.get-current-file-path M.get-current-file-path)
  (set git.get-config (fn [key] (. config.options key)))
  (set git.platform-escape-path vim.fn.fnameescape)
  (set git.notify M.notify)
  
  ;; URL module overrides
  (set url.get-providers (fn [] config.options.providers))
  (set url.notify M.notify)
  
  ;; Core module overrides
  (set core.get-current-file-path M.get-current-file-path)
  (set core.get-config (fn [key] (. config.options key)))
  (set core.notify M.notify))

;; Execute a git command - Neovim implementation
(fn M.execute-git-command [cmd callback]
  (if callback
      ;; Async mode
      (vim.fn.jobstart cmd {:on_stdout (fn [_ data _]
                                        (callback data))
                           :on_stderr (fn [_ data _] 
                                       (when (and data (> (length data) 0) (not= (. data 1) ""))
                                         (M.notify (table.concat data "\n") "error")
                                         (callback nil "Error executing command")))
                           :detach true})
      
      ;; Sync mode
      (let [output (vim.fn.systemlist cmd)]
        (if (not= vim.v.shell_error 0)
            (do 
              (M.notify (table.concat output "\n") "error")
              nil)
            output))))

;; Get the current file path - Neovim implementation
(fn M.get-current-file-path []
  (vim.api.nvim_buf_get_name 0))

;; Get the command to open URLs
(fn M.get-open-command []
  (let [open-cmd config.options.open-cmd]
    (if open-cmd
        (if (= (type open-cmd) "string")
            [open-cmd]
            open-cmd)
        
        ;; Check OS type
        (if (= (vim.fn.has "unix") 1)
            ["xdg-open"]
            (if (= (vim.fn.has "macunix") 1)
                ["open"]
                (if (= (vim.fn.has "win32") 1)
                    ["explorer.exe"]
                    nil))))))

;; Open a URL - Neovim implementation
(fn M.open-url [url]
  (let [open-cmd (M.get-open-command)]
    (if (not open-cmd)
        (M.notify "Unsupported OS" "error")
        
        ;; Check if it's a register
        (if (and (= (type (. open-cmd 1)) "string") (= (length (. open-cmd 1)) 1))
            (do
              (vim.fn.setreg (. open-cmd 1) url)
              (M.notify (.. "URL copied to '" (. open-cmd 1) "' register") "info"))
            
            ;; It's a command
            (do
              (table.insert open-cmd url)
              (vim.fn.jobstart open-cmd {:detach true}))))))

;; Notify the user - Neovim implementation
(fn M.notify [message level]
  (local levels {:error vim.log.levels.ERROR
                 :warn vim.log.levels.WARN
                 :info vim.log.levels.INFO})
  (vim.notify message (or (and level (. levels level)) vim.log.levels.INFO)))

;; Set up plugin command - Neovim implementation
(fn M.setup-command []
  (vim.api.nvim_create_user_command 
    "Browsher"
    (fn [opts]
      (let [pin-type (if (and opts.args (not= opts.args ""))
                         (let [args (vim.split opts.args " ")]
                           (. args 1))
                         nil)
            specific-commit (if (and opts.args (not= opts.args ""))
                               (let [args (vim.split opts.args " ")]
                                 (. args 2))
                               nil)
            ;; Get line selection
            [start-line end-line] (if (> opts.range 0)
                                     [opts.line1 opts.line2]
                                     (let [mode (vim.fn.mode)]
                                       (if (or (= mode "v") (= mode "V") (= mode "\22"))
                                           [(vim.fn.line "v") (vim.fn.line ".")]
                                           [(. (vim.api.nvim_win_get_cursor 0) 1) 
                                            (. (vim.api.nvim_win_get_cursor 0) 1)])))
            url (core.generate-url {:pin-type pin-type
                                   :specific-commit specific-commit
                                   :start-line start-line
                                   :end-line end-line})]
        (when url
          (M.open-url url))))
    {:range true 
     :nargs "*"
     :desc "Open the current file in browser"})
  nil)

;; Setup function
(fn M.setup [user-options]
  (set config.options (merge-configs user-options))
  (M.init)
  (M.setup-command))

M 