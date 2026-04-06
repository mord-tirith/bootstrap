return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				always_show_bufferline = true,
				diagnostics = "nvim_lsp",
				separator_style = "slant",
				show_close_icon = false,
				show_buffer_close_icons = true,
				numbers = "ordinal",
			},
		})
	end,
}
