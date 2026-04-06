return {
  "saghen/blink.cmp",
  dependencies = "rafamadriz/friendly-snippets",

  version = "1.*",
  opts = {
    keymap = {
      preset = "default",
      ["<A-1>"] = {
        function(cmp)
          cmp.accept({ index = 1 })
        end,
      },
      ["<A-2>"] = {
        function(cmp)
          cmp.accept({ index = 2 })
        end,
      },
      ["<A-3>"] = {
        function(cmp)
          cmp.accept({ index = 3 })
        end,
      },
      ["<A-4>"] = {
        function(cmp)
          cmp.accept({ index = 4 })
        end,
      },
      ["<A-5>"] = {
        function(cmp)
          cmp.accept({ index = 5 })
        end,
      },
      ["<A-6>"] = {
        function(cmp)
          cmp.accept({ index = 6 })
        end,
      },
      ["<A-7>"] = {
        function(cmp)
          cmp.accept({ index = 7 })
        end,
      },
      ["<A-8>"] = {
        function(cmp)
          cmp.accept({ index = 8 })
        end,
      },
      ["<A-9>"] = {
        function(cmp)
          cmp.accept({ index = 9 })
        end,
      },
      ["<A-0>"] = {
        function(cmp)
          cmp.accept({ index = 10 })
        end,
      },

      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "accept", "fallback" },

    },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },

    completion = {
      keyword = { range = "full" },

      accept = { auto_brackets = { enabled = false } },

      list = {
        selection = {
          preselect = false,
          auto_insert = false,
        },
      },

      menu = {
        auto_show = true,
        border = "single",
        draw = {
          components = {
            item_idx = {
              text = function(ctx)
                return ctx.idx == 10 and "0" or ctx.idx >= 10 and " " or tostring(ctx.idx)
              end,
              highlight = "BlinkCmpItemIdx",
            },
          },
          columns = {
            { "item_idx" },
            { "label",    "label_description", gap = 1 },
            { "kind_icon" },
            { "kind" },
          },
        },
      },

      documentation = {
        auto_show = true,
        auto_show_delay_ms = 1000,
        window = {
          border = "single",
        },
      },

      ghost_text = { enabled = true },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" },

    signature = {
      enabled = true,
      window = {
        show_documentation = true,
      },
    },
  },
  opts_extend = { "sources.default" },

}

