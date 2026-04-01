return {
	"MoulatiMehdi/42norm.nvim",

	config = function()
		local norm = require("42norm")

		norm.setup({
			header_on_save = true,
			format_on_save = false,
			liner_on_change = false,
		})

	vim.keymap.set("n", "<F5>", function()
		norm.check_norms()
		end, { desc = "Update 42norms diagnostics", noremap = true, silent = true })
	vim.keymap.set("n", "<F1>", function()
			norm.stdheader()
		end, { desc = "Insert 42 header", noremap = true, silent = true })
	end,
}
