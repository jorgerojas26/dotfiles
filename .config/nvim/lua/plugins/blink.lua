return {
  "saghen/blink.cmp",
  -- dependencies = "rafamadriz/friendly-snippets",
  -- use a release tag to download pre-built binaries
  version = "*",
  opts = {
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = false,
        },
      },
      trigger = {
        show_on_backspace_in_keyword = true,
        show_on_insert = true,
      },
      menu = {
        border = "single",
        auto_show = true,
        auto_show_delay_ms = 0,
        draw = {
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                return kind_icon
              end,
              -- Optionally, you may also use the highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },
        },
      },
      documentation = { window = { border = "single" } },
    },
    signature = { window = { border = "single" } },
  },
}
