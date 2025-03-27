;; VSCode platform implementation for browsher

(local {: merge-configs} (require "browsher.core.config"))
(local git (require "browsher.core.git"))
(local url (require "browsher.core.url"))
(local core (require "browsher.core.init"))

(local M {})

;; Store VSCode extension context and configuration
(local state {:vscode nil
              :context nil
              :config {}})

;; Initialize the module
(fn M.init []
  ;; Override platform-specific functions in the core modules
  
  ;; Git module overrides
  (set git.execute-git-command M.execute-git-command)
  (set git.get-current-file-path M.get-current-file-path)
  (set git.get-config (fn [key] (. state.config key)))
  (set git.platform-escape-path M.escape-path)
  (set git.notify M.notify)
  
  ;; URL module overrides
  (set url.get-providers (fn [] state.config.providers))
  (set url.notify M.notify)
  
  ;; Core module overrides
  (set core.get-current-file-path M.get-current-file-path)
  (set core.get-config (fn [key] (. state.config key)))
  (set core.notify M.notify))

;; Execute a git command - VSCode implementation using child_process
(fn M.execute-git-command [cmd callback]
  (let [child-process (js.require "child_process")]
    (if callback
        ;; Async mode
        (child-process:exec cmd 
                           (fn [err stdout stderr]
                             (if err
                                 (do
                                   (M.notify stderr "error")
                                   (callback nil err))
                                 (callback (M.split-lines stdout)))))
        
        ;; Sync mode - using execSync
        (let [result (child-process:execSync cmd)]
          (M.split-lines (result:toString))))))

;; Split a string into lines
(fn M.split-lines [str]
  (local lines [])
  (var start 1)
  (var newline nil)
  (while true
    (set newline (string.find str "\n" start))
    (if newline
        (do
          (table.insert lines (string.sub str start (- newline 1)))
          (set start (+ newline 1)))
        (do
          (when (< start (length str))
            (table.insert lines (string.sub str start)))
          (lua "break"))))
  lines)

;; Get the current file path - VSCode implementation
(fn M.get-current-file-path []
  (let [editor (state.vscode.window:getActiveTextEditor)]
    (when editor
      (let [document (editor:getDocument)]
        (when document
          (document:fsPath))))))

;; Escape paths for shell commands
(fn M.escape-path [path]
  (-> path
      (string.gsub "\\" "\\\\") ; Escape backslashes
      (string.gsub "\"" "\\\"") ; Escape quotes
      (string.gsub " " "\\ "))) ; Escape spaces

;; Open a URL - VSCode implementation
(fn M.open-url [url]
  (state.vscode.env:openExternal (state.vscode.Uri:parse url)))

;; Notify the user - VSCode implementation
(fn M.notify [message level]
  (cond
    (= level "error") (state.vscode.window:showErrorMessage message)
    (= level "warn") (state.vscode.window:showWarningMessage message)
    :else (state.vscode.window:showInformationMessage message)))

;; Set up context menu command - VSCode implementation
(fn M.register-commands []
  (local context state.context)
  (local vscode state.vscode)
  
  ;; Register the share code command
  (let [disposable (vscode.commands:registerCommand
                    "browsher.shareCode"
                    (fn []
                      (let [editor (vscode.window:getActiveTextEditor)]
                        (when editor
                          (let [selection (editor:getSelection)
                                start-line (+ (. selection :start :line) 1) ; VSCode is 0-based
                                end-line (+ (. selection :end :line) 1)
                                ;; Get config value for pin type
                                pin-type (or state.config.default-pin "commit")
                                url (core.generate-url {:pin-type pin-type
                                                      :start-line start-line
                                                      :end-line end-line})]
                            (when url
                              (M.open-url url)))))))]
    
    (context.subscriptions:push disposable)))

;; Setup function 
(fn M.setup [context]
  (set state.vscode (js.global.require "vscode"))
  (set state.context context)
  
  ;; Load configuration from VSCode settings
  (local vscode-config (state.vscode.workspace:getConfiguration "browsher"))
  (local user-config {:default-remote (vscode-config:get "defaultRemote")
                     :default-branch (vscode-config:get "defaultBranch")
                     :default-pin (vscode-config:get "defaultPin" "commit")
                     :commit-length (vscode-config:get "commitLength")
                     :allow-line-numbers-with-uncommitted-changes 
                       (vscode-config:get "allowLineNumbersWithUncommittedChanges" false)
                     :cache-ttl (vscode-config:get "cacheTtl" 10)
                     :async (vscode-config:get "async" false)
                     :providers (vscode-config:get "providers" {})})
  
  (set state.config (merge-configs user-config))
  (M.init)
  (M.register-commands))

;; Create context menu contributions
(fn M.get-package-json []
  {:name "browsher"
   :displayName "Browsher"
   :description "Open the current file in your remote git repository browser"
   :version "0.1.0"
   :engines {:vscode "^1.60.0"}
   :categories ["Other"]
   :activationEvents ["onCommand:browsher.shareCode"]
   :main "./extension.js"
   :contributes
   {:commands
    [{:command "browsher.shareCode"
      :title "Share Code Link"}]
    
    :menus
    {:editor/context
     [{:command "browsher.shareCode"
       :group "browsher"
       :when "editorTextFocus"}]
     
     :explorer/context
     [{:command "browsher.shareCode"
       :group "browsher"
       :when "resourceLangId"}]}}
   
   :configuration
   {:title "Browsher"
    :properties
    {:browsher.defaultRemote
     {:type ["string" "null"]
      :default nil
      :description "Default remote name (e.g., 'origin')"}
     
     :browsher.defaultBranch
     {:type ["string" "null"]
      :default nil
      :description "Default branch name"}
     
     :browsher.defaultPin
     {:type "string"
      :default "commit"
      :enum ["commit" "branch" "tag"]
      :description "Default pin type ('commit', 'branch', or 'tag')"}
     
     :browsher.commitLength
     {:type ["integer" "null"]
      :default nil
      :description "Length of the commit hash to use in URLs"}
     
     :browsher.allowLineNumbersWithUncommittedChanges
     {:type "boolean"
      :default false
      :description "Allow line numbers with uncommitted changes"}
     
     :browsher.cacheTtl
     {:type "integer"
      :default 10
      :description "Cache time-to-live in seconds for git operations"}
     
     :browsher.async
     {:type "boolean"
      :default false
      :description "Enable asynchronous operations"}
     
     :browsher.providers
     {:type "object"
      :default {}
      :description "Custom providers for building URLs"}}}})

M 