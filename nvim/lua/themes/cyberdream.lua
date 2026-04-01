return function()
	require("cyberdream").setup({
		transparent = false,
		terminal_colors = true,
	})
	vim.cmd("colorscheme cyberdream")
end
