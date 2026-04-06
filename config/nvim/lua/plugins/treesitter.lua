return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    ts.setup({
      ensure_installed = { "c", "lua", "python", "vim", "vimdoc" },
      auto_install = true,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "c", "lua", "python", "vim", "vimdoc" },
      callback = function()
        vim.treesitter.start()
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "c", "lua", "python", "vim", "vimdoc" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
