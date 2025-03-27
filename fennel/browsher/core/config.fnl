;; Configuration module for browsher
;; Core functionality shared between Neovim and VSCode

(local M {})

;; Default configuration
(local default-config
  {:default-remote nil
   :default-branch nil
   :default-pin "commit"
   :commit-length nil
   :open-cmd nil
   :allow-line-numbers-with-uncommitted-changes false
   :cache-ttl 10
   :async false
   :providers
   {"github.com" 
    {:url-template "%s/blob/%s/%s"
     :single-line-format "#L%d"
     :multi-line-format "#L%d-L%d"}
    
    "gitlab.com"
    {:url-template "%s/-/blob/%s/%s"
     :single-line-format "#L%d"
     :multi-line-format "#L%d-%d"}
    
    "bitbucket.org"
    {:url-template "%s/src/%s/%s"
     :single-line-format "#lines-%d"
     :multi-line-format "#lines-%d:%d"}
    
    "dev.azure.com"
    {:url-template "%s?path=/%s&version=GB%s"
     :single-line-format "&line=%d&lineEnd=%d"
     :multi-line-format "&line=%d&lineEnd=%d"}
    
    "gitea.io"
    {:url-template "%s/src/%s/%s"
     :single-line-format "#L%d"
     :multi-line-format "#L%d-L%d"}
    
    "forgejo.org"
    {:url-template "%s/src/%s/%s"
     :single-line-format "#L%d"
     :multi-line-format "#L%d-L%d"}}})

;; Get a copy of the default config
(fn M.get-default-config []
  (M.deep-copy default-config))

;; Deep copy a table
(fn M.deep-copy [tbl]
  (if (= (type tbl) "table")
      (let [result {}]
        (each [k v (pairs tbl)]
          (tset result k (M.deep-copy v)))
        result)
      tbl))

;; Merge user config with defaults
(fn M.merge-configs [user-config]
  (local result (M.deep-copy default-config))
  
  ;; Handle providers separately to deep merge them
  (when (and user-config user-config.providers)
    (each [provider-key provider-data (pairs user-config.providers)]
      (tset result.providers provider-key provider-data))
    (tset user-config :providers nil))
  
  ;; Merge the rest of the config
  (when user-config
    (each [k v (pairs user-config)]
      (tset result k v)))
  
  result)

M 