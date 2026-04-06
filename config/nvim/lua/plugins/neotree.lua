return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = true,
			enable_git_status = true,
			enable_diagnostics = true,

			filesystem = {
				follow_current_file = {
					enabled = true,
				},
				hijack_netrw_behavior = "open_default",
				use_libuv_file_watcher = true,
			},

			window = {
				position = "left",
				width = 32,
				mappings = {
					-- Let <leader> sequences work inside Neo-tree
					["<space>"] = "none",

					-- Keep the native fast key if you want it
					["a"] = "add",

					-- Discoverable leader workflow inside the explorer
					["<leader>ec"] = "add",
					["<leader>ee"] = "close_window",

					-- Optional convenience
					["q"] = "close_window",
				},
			},
		})
	end,
}
