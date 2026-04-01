local keymap = vim.keymap.set

-- Move line up or down with Alt + Arrow
keymap("n", "<A-Up>", ":m . -2<CR>==")
keymap("n", "<A-Down>", ":m .+1<CR>==")

keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv")
keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv")

-- LSP keybinds
keymap("n", "<leader>lk", vim.lsp.buf.hover, { desc = "LSP Hover" })
keymap("n", "<leader>ld", vim.lsp.buf.definition, { desc = "LSP Jump to Definition" })
keymap("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename Symbol" } )
keymap("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP Code Action" })

-- Diagnostic Madness
local diag_state = {
	inline_all_enabled = true,
	inline_warnings_enabled = true,
}

local function apply_diagnostic_virtual_text()
	if not diag_state.inline_all_enabled then
		vim.diagnostic.config({
			virtual_text = false,
		})
		return
	end
	if diag_state.inline_warnings_enabled then
		vim.diagnostic.config({
			virtual_text = true,
		})
	else
		vim.diagnostic.config({
			virtual_text = {
				severity = { min = vim.diagnostic.severity.ERROR },
			},
		})
	end
end

keymap("n", "<leader>dw", function()
	diag_state.inline_warnings_enabled = not diag_state.inline_warnings_enabled
	apply_diagnostic_virtual_text()
end, { desc = "Toggle inline warnings" })

keymap("n", "<leader>da", function()
	diag_state.inline_all_enabled = not diag_state.inline_all_enabled
	apply_diagnostic_virtual_text()
end, { desc = "Toggle all inline diagnostics" })

-- Telescope configs
local builtin = require("telescope.builtin")
keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })

-- Oil configs
keymap("n", "-", "<CMD>Oil --float<CR>", { desc = "Open parent directory" })

-- 42 relevant stuff
keymap("n", "<leader>nh", "<cmd>Stdheader<CR>", { desc = "Insert 42 header" })
keymap("n", "<leader>nn", "<cmd>Norminette<CR>", { desc = "Run Norminette (requires norminette installed)" })

-- Colorscheme changer
keymap("n", "<leader>cc", function()
	require("config.colors").pick_theme()
end, { desc = "Colors: choose theme" })

keymap("n", "<leader>cs", function()
	require("config.colors").show_current()
end, { desc = "Colors: show current theme" })
