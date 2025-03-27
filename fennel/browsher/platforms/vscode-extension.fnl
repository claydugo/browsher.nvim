;; VSCode extension entry point
;; This file will be compiled to JavaScript

(local vscode (require "vscode"))
(local vscode-platform (require "browsher.platforms.vscode"))

;; Activate extension
(fn activate [context]
  (vscode-platform.setup context))

;; Deactivate extension
(fn deactivate [])

;; Export functions for VSCode
{:activate activate
 :deactivate deactivate} 