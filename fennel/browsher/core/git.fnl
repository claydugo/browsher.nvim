;; Git operations for browsher
;; Core functionality shared between Neovim and VSCode

(local M {})

;; Cache for git commands
(local cache {:commands {}
              :timestamps {}})

;; Clear cache for a specific command or all commands
(fn M.clear-cache [cmd]
  (if cmd
      (do
        (tset cache.commands cmd nil)
        (tset cache.timestamps cmd nil))
      (do
        (set cache.commands {})
        (set cache.timestamps {}))))

;; Platform adapter for executing git commands
;; This will be implemented by each platform
(fn M.execute-git-command [cmd git-root use-cache callback]
  (error "Platform must implement execute-git-command"))

;; Run a Git command and get the result
(fn M.run-git-command [cmd git-root use-cache callback]
  ;; Default to using cache unless explicitly set to false
  (local use-cache? (not= use-cache false))
  
  (local cache-key (.. cmd (or git-root "")))
  (local current-time (os.time))
  
  ;; Check for cached result
  (when (and use-cache?
             (. cache.commands cache-key)
             (<= (- current-time (. cache.timestamps cache-key)) 
                 (or (M.get-config :cache-ttl) 10)))
    (if callback
        (do
          ;; Async mode
          (callback (vim.deepcopy (. cache.commands cache-key)))
          nil)
        ;; Sync mode
        (vim.deepcopy (. cache.commands cache-key))))
  
  ;; Build full command
  (local full-cmd (if git-root
                      (string.format "git -C %s %s" (M.escape-path git-root) cmd)
                      (.. "git " cmd)))
  
  ;; Execute the command
  (if callback
      ;; Async mode - return nil immediately
      (do
        (M.execute-git-command full-cmd (fn [output err]
                                        (when (and output (not err))
                                          ;; Cache the result
                                          (when use-cache?
                                            (tset cache.commands cache-key (vim.deepcopy output))
                                            (tset cache.timestamps cache-key (os.time)))
                                          
                                          (callback output))))
        nil)
      ;; Sync mode - return the result immediately
      (let [output (M.execute-git-command full-cmd)]
        (when (and output (or (= (type output) "table")))
          ;; Cache the result
          (when use-cache?
            (tset cache.commands cache-key (vim.deepcopy output))
            (tset cache.timestamps cache-key (os.time)))
          
          output))))

;; Get the git root directory
(fn M.get-git-root []
  (local output (M.run-git-command "rev-parse --show-toplevel"))
  (when (and output 
             (= (type output) "table") 
             (> (length output) 0) 
             (not= (. output 1) ""))
    (. output 1)))

;; Normalize file paths to use forward slashes
(fn M.normalize-path [path]
  (string.gsub path "\\" "/"))

;; Escape file paths for shell commands
(fn M.escape-path [path]
  (M.platform-escape-path path))

;; Get the remote URL for a repository
(fn M.get-remote-url [remote-name]
  (local remote (or remote-name (M.get-default-remote)))
  (local git-root (M.get-git-root))
  (when git-root
    (let [cmd (string.format "config --get remote.%s.url" remote)
          output (M.run-git-command cmd git-root)]
      (when (and output 
                 (= (type output) "table")
                 (> (length output) 0) 
                 (not= (. output 1) ""))
        (. output 1)))))

;; Get the default remote
(fn M.get-default-remote []
  (local git-root (M.get-git-root))
  (when git-root
    (let [output (M.run-git-command "remote" git-root)]
      (when (and output 
                 (= (type output) "table")
                 (> (length output) 0))
        (. output 1)))))

;; Get current branch or commit
(fn M.get-current-branch-or-commit []
  (local git-root (M.get-git-root))
  (when git-root
    (let [output (M.run-git-command "symbolic-ref --short HEAD" git-root)]
      (if (and output 
               (= (type output) "table")
               (> (length output) 0) 
               (not= (. output 1) ""))
          (values (. output 1) "branch")
          (let [output (M.run-git-command "rev-parse --short HEAD" git-root)]
            (when (and output 
                       (= (type output) "table")
                       (> (length output) 0) 
                       (not= (. output 1) ""))
              (values (. output 1) "commit")))))))

;; Get the latest tag
(fn M.get-latest-tag []
  (local git-root (M.get-git-root))
  (when git-root
    (let [output (M.run-git-command "describe --tags --abbrev=0" git-root)]
      (when (and output 
                 (= (type output) "table")
                 (> (length output) 0) 
                 (not= (. output 1) ""))
        (. output 1)))))

;; Get the current commit hash
(fn M.get-current-commit-hash []
  (local git-root (M.get-git-root))
  (when git-root
    (let [commit-length (M.get-config :commit-length)
          abbrev-arg (if commit-length
                         (string.format "--short=%d" commit-length)
                         "")
          cmd (string.format "rev-parse %s HEAD" abbrev-arg)
          output (M.run-git-command cmd git-root)]
      (when (and output 
                 (= (type output) "table")
                 (> (length output) 0) 
                 (not= (. output 1) ""))
        (. output 1)))))

;; Check if a file has uncommitted changes
(fn M.has-uncommitted-changes [relative-path]
  (local git-root (M.get-git-root))
  (when git-root
    (let [cmd (string.format "diff --name-only -- %s" (M.escape-path relative-path))
          output (M.run-git-command cmd git-root)]
      (and output 
           (= (type output) "table")
           (> (length output) 0)))))

;; Check if specific lines have uncommitted changes
(fn M.has-line-changes [relative-path start-line end-line]
  (local git-root (M.get-git-root))
  (when (not git-root)
    (values false nil))
  
  ;; Use git diff with unified format to get context and changed line numbers
  (local cmd (string.format "diff --unified=0 -- %s" (M.escape-path relative-path)))
  (local output (M.run-git-command cmd git-root))
  
  (when (or (not output) 
            (not= (type output) "table")
            (= (length output) 0))
    (values false 0)) ;; No changes, no offset needed
  
  ;; Track the affected line ranges and calculate offsets
  (local affected-ranges [])
  (var line-offset 0) ;; Accumulated offset (negative for deletions, positive for additions)
  
  ;; Parse the git diff output to find changed lines
  (each [_ line (ipairs output)]
    ;; Look for hunk headers: @@ -old_start,old_size +new_start,new_size @@
    (let [hunk-match (string.match line "^@@ %-(%d+),(%d+) %+(%d+),(%d+) @@")]
      (when hunk-match
        (let [old-start (tonumber (string.match line "^@@ %-(%d+),"))
              old-size (tonumber (string.match line "^@@ %-[%d]+,(%d+)"))
              new-start (tonumber (string.match line "^@@ %-[%d]+,[%d]+ %+(%d+),"))
              new-size (tonumber (string.match line "^@@ %-[%d]+,[%d]+ %+[%d]+,(%d+)"))]
          (when (and old-start old-size new-start new-size)
            ;; Calculate the offset before this hunk
            (local hunk-offset (- new-size old-size))
            
            ;; If the lines we're checking are after this hunk, apply the offset
            (when (> start-line (+ new-start new-size -1))
              (set line-offset (+ line-offset hunk-offset)))
            
            ;; Record this range as affected in working copy line numbers
            (if (> new-size 0)
                (table.insert affected-ranges 
                             {:start new-start
                              :end (+ new-start new-size -1)
                              :offset hunk-offset})
                ;; Handle pure deletions
                (table.insert affected-ranges
                             {:start new-start
                              :end new-start
                              :offset hunk-offset})))))))
  
  ;; Check if the requested lines overlap with any affected ranges
  (var has-changes false)
  (each [_ range (ipairs affected-ranges)]
    (when (not (or (< end-line range.start) (> start-line range.end)))
      (set has-changes true)
      (lua "break")))
  
  (values has-changes line-offset))

;; Get adjusted line numbers for uncommitted changes
(fn M.get-adjusted-line-numbers [relative-path start-line end-line]
  (let [(has-changes offset) (M.has-line-changes relative-path start-line end-line)]
    (if (= offset nil)
        ;; Couldn't determine offset, return originals
        (values start-line end-line has-changes)
        ;; Adjust line numbers by the offset
        (let [adjusted-start (- start-line offset)
              adjusted-end (- end-line offset)
              ;; Ensure lines can't be negative
              adjusted-start (math.max 1 adjusted-start)
              adjusted-end (math.max 1 adjusted-end)]
          (values adjusted-start adjusted-end has-changes)))))

;; Check if a file is tracked by git
(fn M.is-file-tracked [relative-path]
  (local git-root (M.get-git-root))
  (when git-root
    (let [cmd (string.format "ls-files --error-unmatch -- %s" (M.escape-path relative-path))
          output (M.run-git-command cmd git-root)]
      (and output 
           (= (type output) "table")
           (> (length output) 0)))))

;; Get the file path relative to git root
(fn M.get-file-relative-path [file-path]
  (local git-root (M.get-git-root))
  (when git-root
    (let [full-path (or file-path (M.get-current-file-path))
          normalized-filepath (string.gsub full-path "\\" "/")
          normalized-git-root (string.gsub git-root "\\" "/")
          ;; Escape special pattern chars
          pattern (string.gsub normalized-git-root "([^%w])" "%%%1")]
      (when (string.match normalized-filepath pattern)
        (string.sub normalized-filepath (+ (length normalized-git-root) 2))))))

;; Platform-specific function to get current file path
(fn M.get-current-file-path []
  (error "Platform must implement get-current-file-path"))

;; Platform-specific function to get config
(fn M.get-config [key]
  (error "Platform must implement get-config"))

;; Platform-specific function to escape paths
(fn M.platform-escape-path [path]
  (error "Platform must implement platform-escape-path"))

;; Platform-specific function to notify user
(fn M.notify [message level]
  (error "Platform must implement notify"))

M 