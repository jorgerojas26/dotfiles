local M = {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = {
      enabled = false,
    },
    setup = {
      gopls = function(_, opts)
        opts.on_attach = function(client)
          client.server_capabilities.document_formatting = false
          client.server_capabilities.document_range_formatting = false
        end
      end,
      tsserver = function(_, opts)
        opts.on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
      denols = function(_, opts)
        opts.root_dir = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
      end,
      tailwindcss = function(_, opts)
        opts.filetypes = { "javascriptreact", "typescriptreact" }
      end,
    },
  },
}

return M
