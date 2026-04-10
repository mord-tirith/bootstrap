return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
		{ "<leader>l", group = "LSP" },
		{ "<leader>d", group = "Diagnostics" },
		{ "<leader>f", group = "Find" },
		{ "<leader>n", group = "42 specific" },
		{ "<leader>c", group = "Colors" },
		{ "<leader>e", group = "File Explorer" },
		{ "<leader>b", group = "Buffer (window)" },
		{ "<leader>bq", group = "Close" },
		{ "<leader>be", group = "Exit" },
		{ "<leader>:", group = "Nvim commands" },
		{ "<leader>:q", group = "Quit" },
		{ "<leader>:e", group = "Change" },
		{ "<leader>:s", group = "Save/rename" },
		{ "<leader>s", group = "Shortcuts" },
		{ "<leader>ss", group = "Search shortcuts" },
		{ "<leader>sv", group = "Jump shortcuts" },
		{ "<leader>se", group = "Editor shortcuts" },
		{ "<leader>sc", group = "Code shortcuts" },
		{ "<leader>sw", group = "Toggle shortcuts" },
		{ "<leader>1", hidden = true },
		{ "<leader>2", hidden = true },
		{ "<leader>3", hidden = true },
		{ "<leader>4", hidden = true },
		{ "<leader>?", hidden = true },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Show buffer-local keymaps",
    },
  },
}
