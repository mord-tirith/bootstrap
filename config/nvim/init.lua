-- == Welcome msg ==
print("Mord's Nvim")

-- == lazy.nvim bootstrap ==
require("config.lazy")

-- == Config files ==
require("config.options")
require("config.mapping")

-- == Colorscheme boot ==
require("config.colors").load_current()
