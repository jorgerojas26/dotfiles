return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- "hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
    "nvim-telescope/telescope.nvim", -- Optional: For using slash commands
    { "MeanderingProgrammer/render-markdown.nvim", ft = { "markdown", "codecompanion" } }, -- Optional: For prettier markdown rendering
    { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
  },
  config = function()
    require("codecompanion").setup({
      strategies = {
        chat = {
          adapter = "ollama",
        },
        inline = {
          adapter = "ollama",
        },
      },
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            env = {
              url = "http://127.0.0.1:11434",
              -- api_key = "OLLAMA_API_KEY",
            },
            headers = {
              ["Content-Type"] = "application/json",
              ["Accept"] = "application/json",
              ["Authorization"] = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjIyMmY5YmU0LWQ3NjMtNDUxOS05ZmFhLWY5NzE2YmNmNTNkYSJ9.wtjTurX7xXoRrxQ5YrtTCalOQ3KAagWeQfougq2QVC4",
            },
            parameters = {
              sync = true,
            },
            schema = {
              model = {
                default = "deepseek-coder:6.7b",
              },
            },
          })
        end,
      },
    })
  end,
}
