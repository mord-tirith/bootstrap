local opt = vim.opt

-- Line number
opt.number = true
opt.relativenumber = true

-- Tab control
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = false

-- QoL
opt.smartindent = true
opt.wrap = false
opt.cursorline = true
opt.scrolloff = 8

vim.diagnostic.config({
	virtual_text = true,
})
