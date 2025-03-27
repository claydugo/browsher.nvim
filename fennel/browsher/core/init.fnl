;; Main module for browsher
;; Core functionality shared between Neovim and VSCode

(local git (require "browsher.core.git"))
(local url-builder (require "browsher.core.url"))

(local M {})

;; Main function to generate the browsing URL
(fn M.generate-url [opts]
  (let [file-path (M.get-current-file-path)
        pin-type (or (and opts.pin-type opts.pin-type) 
                     (M.get-config :default-pin) 
                     "commit")
        specific-commit (and opts.specific-commit opts.specific-commit)]
    
    ;; Validate the pin type
    (when (not (or (= pin-type "commit") 
                   (= pin-type "branch") 
                   (= pin-type "tag")
                   (= pin-type "root")))
      (M.notify "Invalid pin type. Use 'branch', 'tag', 'commit', or 'root'." "error")
      (lua "return nil"))
    
    ;; Get the remote name and URL
    (local remote-name (or (M.get-config :default-remote) 
                           (git.get-default-remote)))
    (when (not remote-name)
      (M.notify "No remote found." "error")
      (lua "return nil"))
    
    (local remote-url (git.get-remote-url remote-name))
    (when (not remote-url)
      (M.notify "No remote URL found." "error")
      (lua "return nil"))
    
    ;; For root URL, just return the sanitized repository URL
    (when (= pin-type "root")
      (lua "return url_builder.sanitize_remote_url(remote_url)"))
    
    ;; Get git root and validate the file
    (local git-root (git.get-git-root))
    (when (not git-root)
      (M.notify "Not in a Git repository." "error")
      (lua "return nil"))
    
    (local relative-path (git.get-file-relative-path file-path))
    (when (not relative-path)
      (M.notify "Not in a Git repository." "error")
      (lua "return nil"))
    
    (when (not (git.is-file-tracked relative-path))
      (M.notify "File is untracked by Git." "error")
      (lua "return nil"))
    
    ;; Determine branch, tag, or commit
    (var branch-or-tag nil)
    (if (= pin-type "tag")
        (set branch-or-tag (git.get-latest-tag))
        
        (= pin-type "branch")
        (let [(ref-name ref-type) (git.get-current-branch-or-commit)]
          (if (and ref-name (= ref-type "branch"))
              (set branch-or-tag ref-name)
              (do 
                (M.notify "Cannot use 'branch' pin type in detached HEAD state." "error")
                (lua "return nil"))))
        
        ;; pin-type is "commit"
        (if specific-commit
            (if (string.match specific-commit "^[0-9a-fA-F]+$")
                (set branch-or-tag specific-commit)
                (do
                  (M.notify "Invalid commit hash format." "error")
                  (lua "return nil")))
            (set branch-or-tag (git.get-current-commit-hash))))
    
    (when (not branch-or-tag)
      (lua "return nil"))
    
    ;; Check for uncommitted changes
    (local has-changes (git.has-uncommitted-changes relative-path))
    (var line-info nil)
    
    ;; Get the line selection from options
    (local start-line (or opts.start-line 1))
    (local end-line (or opts.end-line start-line))
    
    (if has-changes
        ;; Get adjusted line numbers and check for changes in selected lines
        (let [(adjusted-start adjusted-end lines-have-changes) 
              (git.get-adjusted-line-numbers relative-path start-line end-line)]
          
          (if (and lines-have-changes 
                   (not (M.get-config :allow-line-numbers-with-uncommitted-changes)))
              (M.notify "Warning: Uncommitted changes detected in the selected lines. Line numbers removed from URL." "warn")
              
              (do
                (when lines-have-changes
                  (M.notify "Warning: Uncommitted changes detected in the selected lines. Line numbers may not be accurate." "warn"))
                
                (when (and has-changes (not lines-have-changes))
                  (M.notify "Note: File has uncommitted changes, but selected lines are unchanged. Line numbers included." "info"))
                
                ;; Show adjustment info if lines were adjusted
                (when (or (not= adjusted-start start-line) (not= adjusted-end end-line))
                  (M.notify (string.format "Lines adjusted from %d-%d to %d-%d to match committed version." 
                                          start-line end-line adjusted-start adjusted-end) 
                           "info"))
                
                ;; Set line info using adjusted lines
                (if (= adjusted-start adjusted-end)
                    (set line-info {:line-number adjusted-start})
                    (set line-info {:start-line adjusted-start :end-line adjusted-end})))))
        
        ;; No changes, use the original line numbers
        (if (= start-line end-line)
            (set line-info {:line-number start-line})
            (set line-info {:start-line start-line :end-line end-line})))
    
    ;; Build and return the URL
    (url-builder.build-url remote-url branch-or-tag relative-path line-info)))

;; Platform-specific function to get the current file path
(fn M.get-current-file-path []
  (error "Platform must implement get-current-file-path"))

;; Platform-specific function to get config values
(fn M.get-config [key]
  (error "Platform must implement get-config"))

;; Platform-specific function to notify user
(fn M.notify [message level]
  (error "Platform must implement notify"))

M 