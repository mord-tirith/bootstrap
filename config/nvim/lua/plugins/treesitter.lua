return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = function()
    require("nvim-treesitter").install({ "lua", "python", "vim", "vimdoc", "c", "cpp" }):wait(300000)
    vim.cmd("TSUpdate")
  end,
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "python", "vim", "vimdoc", "c", "cpp" },
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "lua", "python", "vim", "vimdoc" },
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
