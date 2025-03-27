;; URL builder for browsher
;; Core functionality shared between Neovim and VSCode

(local M {})

;; Sanitize the remote URL to a standard HTTPS URL
(fn M.sanitize-remote-url [remote-url]
  (-> remote-url
      (string.gsub "%.git$" "")
      (string.gsub "^git@(.-):(.*)$" "https://%1/%2")
      (string.gsub "^ssh://git@(.-)/(.*)$" "https://%1/%2")
      (string.gsub "^gitea@(.-):(.*)$" "https://%1/%2")
      (string.gsub "^ssh://gitea@(.-)/(.*)$" "https://%1/%2")
      (string.gsub "^forgejo@(.-):(.*)$" "https://%1/%2")
      (string.gsub "^ssh://forgejo@(.-)/(.*)$" "https://%1/%2")
      (string.gsub "git://(.-)/(.*)$" "https://%1/%2")
      (string.gsub "https?://[^@]+@" "https://")))

;; URL-encode a string
(fn M.url-encode [str]
  (when str
    (string.gsub str "([^%w_%-%./~])" 
                 (fn [c] 
                   (string.format "%%%02X" (string.byte c))))))

;; Build the URL to open in the browser
(fn M.build-url [remote-url branch-or-tag relative-path line-info]
  (let [remote-url (M.sanitize-remote-url remote-url)
        branch-or-tag (M.url-encode branch-or-tag)
        relative-path (M.url-encode relative-path)
        providers (M.get-providers)]
    
    ;; Find the matching provider
    (var found-url nil)
    (each [provider data (pairs providers)]
      (when (string.match remote-url provider)
        (let [url (string.format data.url-template remote-url branch-or-tag relative-path)
              line-part (when line-info
                          (if (and line-info.start-line line-info.end-line)
                              (let [format-str (if (= line-info.start-line line-info.end-line)
                                                  data.single-line-format
                                                  data.multi-line-format)]
                                (string.format format-str line-info.start-line line-info.end-line))
                              (when line-info.line-number
                                (string.format data.single-line-format line-info.line-number))))]
          (set found-url (.. url (or line-part "")))
          (lua "break"))))
    
    (when (not found-url)
      (M.notify (.. "Unsupported remote provider: " remote-url) "error"))
    
    found-url))

;; Platform-specific function to get providers
(fn M.get-providers []
  (error "Platform must implement get-providers"))

;; Platform-specific function to notify
(fn M.notify [message level]
  (error "Platform must implement notify"))

M 