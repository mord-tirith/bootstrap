local keymap = vim.keymap.set
local builtin = require("telescope.builtin")
local state = require("config.config_state")

state.load()

local function explain(opts)
	if state.values.tutorial_enabled then
		if opts.tutorial then
			vim.notify(opts.tutorial, vim.log.levels.INFO)
		end
	else
		if opts.action then
			vim.notify(opts.action, vim.log.levels.INFO)
		end
	end
end

local function feed_and_explain(keys, tutorial_msg, action_msg, mode)
	return function()
		local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(term, mode or "n", false)
		explain({
			tutorial = tutorial_msg,
			action = action_msg,
		})
	end
end

-- Move line up or down with Alt + Arrow
keymap("n", "<A-Up>", ":m . -2<CR>==")
keymap("n", "<A-Down>", ":m .+1<CR>==")

keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv")
keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv")

-- LSP keybinds
keymap("n", "<leader>lk", vim.lsp.buf.hover, { desc = "LSP Hover" })
keymap("n", "<leader>ld", vim.lsp.buf.definition, { desc = "LSP Jump to Definition" })
keymap("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP Rename Symbol" })
keymap("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP Code Action" })

-- Diagnostic Madness
local diag_state = {
	inline_all_enabled = true,
	inline_warnings_enabled = true,
}

keymap("n", "<leader>dw", function()
	local enabled = state.toggle("diag_inline_warnings")
	vim.notify("Inline warnings " .. (enabled and "enabled" or "errors only"), vim.log.levels.INFO)
end, { desc = "Toggle inline warnings" })

keymap("n", "<leader>da", function()
	local enabled = state.toggle("diag_inline_all")
	vim.notify("Inline diagnostics " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle all inline diagnostics" })

-- Telescope configs
keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })

-- Oil configs
keymap("n", "-", "<CMD>Oil --float<CR>", { desc = "Open parent directory" })

-- 42 relevant stuff
keymap("n", "<leader>nh", function()
	vim.cmd("Stdheader")
	explain({
		tutorial = "You could have pressed <F1> or run :Stdheader",
		action = "Inserted 42 header",
	})
end, { desc = "42 Header" })

keymap("n", "<leader>ns", function()
	state.prompt_header()
end, { desc = "Set header information" })

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
keymap("n", "<leader>:t", function()
	local enabled = state.toggle("tutorial_enabled")
	vim.notify("Tutorial mode " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle tutorials" })

keymap("n", "<leader>:w", function()
	vim.cmd("w")
	explain({
		tutorial = "You could have done: :w",
		action = "Saved current buffer",
	})
end, { desc = "Save buffer" })

keymap("n", "<leader>:qq", function()
	vim.cmd("q")
	explain({
		tutorial = "You could have done: :q",
		action = "Closed current window",
	})
end, { desc = "Close Nvim" })

keymap("n", "<leader>:q!", function()
	vim.cmd("q!")
	explain({
		tutorial = "You could have done: :q!",
		action = "Force-closed current window",
	})
end, { desc = "Force close Nvim" })

keymap("n", "<leader>:ee", function()
	vim.ui.input({ prompt = "Open file: " }, function(file)
		if not file or file == "" then
			return
		end

		vim.cmd("e " .. vim.fn.fnameescape(file))
		explain({
			tutorial = string.format("You could have done: :e %s", file),
			action = string.format("Opened file: %s", file),
		})
	end)
end, { desc = "Change open file" })

keymap("n", "<leader>:e!", function()
	vim.ui.input({ prompt = "Force open file: " }, function(file)
		if not file or file == "" then
			return
		end

		vim.cmd("e! " .. vim.fn.fnameescape(file))
		explain({
			tutorial = string.format("You could have done: :e! %s", file),
			action = string.format("Force-opened file: %s", file),
		})
	end)
end, { desc = "Force change file" })

keymap("n", "<leader>:ss", function()
	vim.ui.input({ prompt = "Save current buffer as: " }, function(file)
		if not file or file == "" then
			return
		end

		vim.cmd("sav " .. vim.fn.fnameescape(file))
		explain({
			tutorial = string.format("You could have done: :sav %s", file),
			action = string.format("Saved buffer as: %s", file),
		})
	end)
end, { desc = "Save/rename file" })

keymap("n", "<leader>:s!", function()
	vim.ui.input({ prompt = "Force save current buffer as: " }, function(file)
		if not file or file == "" then
			return
		end

		vim.cmd("sav! " .. vim.fn.fnameescape(file))
		explain({
			tutorial = string.format("You could have done: :sav! %s", file),
			action = string.format("Force-saved buffer as: %s", file),
		})
	end)
end, { desc = "Force save/rename file" })

-- s keymaps: simplified commands

-- -- search commands:
keymap("n", "<leader>st", function()
	local enabled = state.toggle("tutorial_enabled")
	vim.notify("Tutorial mode " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle tutorials" })


keymap("n", "<leader>sss",
	feed_and_explain("/", "You could have pressed: /", "Opened text search"),
	{ desc = "Search text" }
)

keymap("n", "<leader>ssw",
	feed_and_explain("*", "You could have pressed: *", "Searched for word under cursor"),
	{ desc = "Search word under cursor" }
)

keymap("n", "<leader>ssr", function()
	vim.ui.input({ prompt = "Replace target: " }, function(old)
		if not old or old == "" then
			return
		end

		vim.ui.input({ prompt = "Replace with: " }, function(new)
			if new == nil then
				return
			end

			local old_esc = vim.fn.escape(old, [[\/]])
			local new_esc = vim.fn.escape(new, [[\/&]])
			vim.cmd(string.format("%%s/%s/%s/g", old_esc, new_esc))

			explain({
				tutorial = string.format("You could have done: :%%s/%s/%s/g", old, new),
				action = string.format("Replaced '%s' with '%s'", old, new),
			})
		end)
	end)
end, { desc = "Search and replace" })

keymap("n", "<leader>ssb", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
keymap("n", "<leader>ssg", builtin.live_grep, { desc = "Search in project" })

-- -- jump commands:
keymap("n", "<leader>svv", function()
	vim.ui.input({ prompt = "Go to line: " }, function(input)
		local line = tonumber(input)
		if line then
			vim.cmd(tostring(line))
			explain({
				tutorial = string.format("You could have done: :%d", line),
				action = string.format("Jumped to line %d", line),
			})
		end
	end)
end, { desc = "Jump to line" })

keymap("n", "<leader>svs",
	feed_and_explain("^", "You could have pressed: ^", "Moved to start of line"),
	{ desc = "Jump to start of line" }
)

keymap("n", "<leader>sve",
	feed_and_explain("$", "You could have pressed: $", "Moved to end of line"),
	{ desc = "Jump to end of line" }
)

keymap("n", "<leader>svd",
	feed_and_explain("<C-d>", "You could have pressed: Ctrl + d", "Moved half-page down"),
	{ desc = "Jump half-page down" }
)

keymap("n", "<leader>svt",
	feed_and_explain("<C-u>", "You could have pressed: Ctrl + u", "Moved half-page up"),
	{ desc = "Jump half-page up" }
)

keymap("n", "<leader>svq",
	feed_and_explain("<C-o>", "You could have pressed: Ctrl + o", "Jumped back"),
	{ desc = "Jump back to tag" }
)

keymap("n", "<leader>sva",
	feed_and_explain("<C-i>", "You could have pressed: Ctrl + i", "Jumped forward"),
	{ desc = "Jump forward to tag" }
)

-- -- editor commands:
keymap("n", "<leader>ser", function()
	vim.lsp.buf.rename()
	explain({
		tutorial = "Native LSP action: vim.lsp.buf.rename()",
		action = "Started symbol rename",
	})
end, { desc = "Rename symbol" })

keymap("n", "<leader>sec", "gcc", { desc = "Toggle comments", remap = true })
keymap("v", "<leader>sec", "gc", { desc = "Toggle comment selection", remap = true })

keymap("n", "<leader>sea",
	feed_and_explain("ggVG", "You could have pressed: ggVG", "Selected entire buffer"),
	{ desc = "Select all" }
)

keymap("n", "<leader>sed",
	feed_and_explain("yyp", "You could have pressed: yyp", "Duplicated current line"),
	{ desc = "Duplicate line" }
)

keymap("n", "<leader>sex",
	feed_and_explain("dd", "You could have pressed: dd", "Deleted current line"),
	{ desc = "Delete current line" }
)

keymap("n", "<leader>set",
	feed_and_explain("u", "You could have pressed: u", "Undid last change"),
	{ desc = "Undo" }
)

keymap("n", "<leader>seg",
	feed_and_explain("<C-r>", "You could have pressed: Ctrl + r", "Redid last undone change"),
	{ desc = "Redo" }
)

-- -- code commands:
keymap("n", "<leader>scd", vim.lsp.buf.definition, { desc = "Go to symbol definition" })
keymap("n", "<leader>scc", vim.lsp.buf.implementation, { desc = "Go to symbol implementation" })
keymap("n", "<leader>scr", vim.lsp.buf.references, { desc = "References" })
keymap("n", "<leader>sce", builtin.lsp_document_symbols, { desc = "Document symbols" })

-- -- toggle commands:
keymap("n", "<leader>swc",
	feed_and_explain("za", "You could have pressed: za", "Toggled fold under cursor"),
	{ desc = "Toggle fold" }
)

keymap("n", "<leader>swq", function()
	local enabled = state.toggle("number")
	if enabled then
		state.set("relativenumber", true)
	end
	explain({
		tutorial = "You could have done: :set number!",
		action = "Toggled line numbers",
	})
end, { desc = "Toggle line numbers" })

keymap("n", "<leader>swr", function()
	state.toggle("relativenumber")
	explain({
		tutorial = "You could have done: :set relativenumber!",
		action = "Toggled relative line numbers",
	})
end, { desc = "Toggle relative line numbers" })

keymap("n", "<leader>sww", function()
	state.toggle("wrap")
	explain({
		tutorial = "You could have done: :set wrap!",
		action = "Toggled wrapping",
	})
end, { desc = "Toggle wrapping" })

keymap("n", "<leader>sws", function()
	state.toggle("hlsearch")
	explain({
		tutorial = "You could have done: :set hlsearch!",
		action = "Toggled search highlighting",
	})
end, { desc = "Toggle highlight search" })

keymap("n", "<leader>swt", function()
	local enabled = tutorial.toggle()
	vim.notify("Tutorial mode " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle tutorial mode" })
