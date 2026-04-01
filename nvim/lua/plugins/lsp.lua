return {
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.config("clangd", {})
		vim.lsp.config("lua_ls", {})
		vim.lsp.config("pyright", {})

		vim.lsp.enable("clangd")
		vim.lsp.enable("lua_ls")
		vim.lsp.enable("pyright")
	end,
}
