local M = {
  "nvim-neorg/neorg",
  lazy = false,
  version = "*",
  enabled = false,
  config = function()
    require("neorg").setup({
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.export"] = {},
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
          },
        },
        ["core.keybinds"] = {
          config = {
            default_keybinds = true,
            preset = "neorg",
          },
        },
        ["core.integrations.nvim-cmp"] = {},
        ["core.integrations.treesitter"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              notes = "~/.config/notes/notes/",
            },
            default_workspace = "notes",
          },
        },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "norg",
      callback = function()
        vim.keymap.set(
          "n",
          "<leader>nq",
          "<cmd>Neorg return<cr>",
          { desc = "Neorg return", noremap = true, silent = true }
        )
      end,
    })

    vim.wo.foldlevel = 99
    vim.wo.conceallevel = 2
  end,
  keys = {
    { "<leader>nj", "<cmd>Neorg journal today<cr>", desc = "Neorg journal today" },
  },
}

return M
