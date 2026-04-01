return {
	"mg979/vim-visual-multi",
	branch = "master",
	init = function()
		vim.g.VM_maps = {
			["Add Cursor Down"] = "<C-Down>",
			["Add Cursor Up"] = "<C-Up>",
		}
	end,
}
