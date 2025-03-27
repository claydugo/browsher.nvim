;; Neovim plugin entry point
(local neovim-platform (require "browsher.platforms.neovim"))

;; Setup function exposed to the user
(fn setup [user-options]
  (neovim-platform.setup user-options))

;; Export functions for Neovim
{:setup setup} 