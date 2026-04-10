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
keymap("n", "<leader>nh", function()
	vim.notify("Press <F1> to insert 42 header", vim.log.levels.INFO)
end, { desc = "42 Header" })

keymap("n", "<leader>nn", function()
	vim.notify("Press <F5> to run Norminette (must be installed in system)", vim.log.levels.INFO)
end, { desc = "42 Norminette" })

-- Colorscheme changer
keymap("n", "<leader>cc", function()
	require("config.colors").pick_theme()
end, { desc = "Colors: choose theme" })

keymap("n", "<leader>cs", function()
	require("config.colors").show_current()
end, { desc = "Colors: show current theme" })

-- Bufferline and Bufdelete keymaps
keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

keymap("n", "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>", { desc = "Go to buffer 1" })
keymap("n", "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>", { desc = "Go to buffer 2" })
keymap("n", "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>", { desc = "Go to buffer 3" })
keymap("n", "<leader>4", "<cmd>BufferLineGoToBuffer 4<CR>", { desc = "Go to buffer 4" })

keymap("n", "<leader>bp", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
keymap("n", "<leader>bd", "<cmd>confirm Bdelete<CR>", { desc = "Close buffer" })
keymap("n", "<leader>bqq", "<cmd>Bdelete!<CR>", { desc = "Force close buffer" })
keymap("n", "<leader>bqa", "<cmd>confirm qall<CR>", { desc = "Close all buffers" })
keymap("n", "<leader>bq!", "<cmd>qall!<CR>", { desc = "Force close all buffers" })
keymap("n", "<leader>ba", "<cmd>wall<CR>", { desc = "Save all open buffers" })
keymap("n", "<leader>bee", "<cmd>confirm quit<CR>", { desc = "Close Nvim" })
keymap("n", "<leader>be!", "<cmd>quit!<CR>", { desc = "Force close Nvim" })

-- Neotree keymaps
keymap("n", "<leader>ee", "<cmd>Neotree filesystem toggle left<CR>", { desc = "Toggle file explorer" })
keymap("n", "<leader>eb", "<cmd>Neotree buffers toggle right<CR>", { desc = "Toggle buffers explorer" })
keymap("n", "<leader>er", "<cmd>Neotree filesystem reveal left<CR>", { desc = "Reveal current file" })

-- : keymaps
keymap("n", "<leader>:w", ":w<CR>", { desc = "Save buffer" })
keymap("n", "<leader>:qq", ":q<CR>", { desc = "Close Nvim" })
keymap("n", "<leader>:q!", ":q!<CR>", { desc = "Force close Nvim" })
keymap("n", "<leader>:ee", ":e ", { desc = "Change open file" })
keymap("n", "<leader>:e!", ":e! ", { desc = "Force change file" })
keymap("n", "<leader>:ss", ":sav ", { desc = "Save/rename file" })
keymap("n", "<leader>:s!", ":sav! ", { desc = "Force save/rename file" })

-- s keymaps: simplified commands
-- -- search commands:
keymap("n", "<leader>sss", "/", { desc = "Search text" } )
keymap("n", "<leader>ssw", "*", { desc = "Search word under cursor" })
keymap("n", "<leader>ssr", ":%s//g<Left><Left>", { desc = "Search and replace" })
keymap("n", "<leader>ssb", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
keymap("n", "<leader>ssg", builtin.live_grep, { desc = "Search in project" })
-- -- jump commands:
keymap("n", "<leader>svv", function()
	vim.ui.input({ prompt = "Go to line: " }, function(input)
		local line = tonumber(input)
		if line then
			vim.cmd(tostring(line))
		end
	end)
end, { desc = "Jump to line" })
keymap("n", "<leader>svs", "^", { desc = "Jump to start of line" })
keymap("n", "<leader>sve", "$", { desc = "Jump to end of line" })
keymap("n", "<leader>svd", "<C-d>", { desc = "Jump half-page down" })
keymap("n", "<leader>svt", "<C-u>", { desc = "Jump half-page up" })
keymap("n", "<leader>svq", "<C-o>", { desc = "Jump back to tag" })
keymap("n", "<leader>sva", "<C-i>", { desc = "Jump forward to tag" })
-- -- editor commands:
keymap("n", "<leader>ser", vim.lsp.buf.rename, { desc = "Rename symbol" })
keymap("n", "<leader>sec", "gcc", { desc = "Toggle comments" })
keymap("v", "<leader>sec", "gc", { desc = "Toggle comment selection" })
keymap("n", "<leader>sea", "ggVG", { desc = "Select all" })
keymap("n", "<leader>sed", "yyp", { desc = "Duplicate line" })
keymap("n", "<leader>sex", "dd", { desc = "Delete current line" })
keymap("n", "<leader>set", "u", { desc = "Undo" })
keymap("n", "<leader>seg", "<C-r>", { desc = "Redo" })
-- -- code commands:
keymap("n", "<leader>scd", vim.lsp.buf.definition, { desc = "Go to symbol definition" })
keymap("n", "<leader>scc", vim.lsp.buf.implementation, { desc = "Go to symbol implementation" })
keymap("n", "<leader>scr", vim.lsp.buf.references, { desc = "References" })
keymap("n", "<leader>sce", builtin.lsp_document_symbols, { desc = "Document symbols" })
-- -- toggle commands:
keymap("n", "<leader>swc", "za", { desc = "Toggle fold" })
keymap("n", "<leader>swq", function()
	vim.wo.number = not vim.wo.number
	vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })
keymap("n", "<leader>swr", function()
	vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative line numbers" })
keymap("n", "<leader>sww", function()
	vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrapping" })
keymap("n", "<leader>sws", function()
	vim.o.hlsearch = not vim.o.hlsearch
end, { desc = "Toggle highlight search" })

