local neovim_platform = require("browsher.platforms.neovim")
local function setup(user_options)
    return neovim_platform.setup(user_options)
end
return { setup = setup }
