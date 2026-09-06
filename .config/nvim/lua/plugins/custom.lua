return {
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night", transparent = false } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { transparent_background = true, integrations = { blink_cmp = true } },
    enabled = false,
  },
  -- { "rose-pine/neovim" },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   opts = function(_, opts)
  --     local cmp = require("cmp")
  --     -- local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  --     --
  --     -- cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  --
  --     opts.window = {
  --       completion = cmp.config.window.bordered(),
  --       documentation = cmp.config.window.bordered(),
  --     }
  --
  --     table.insert(opts.sources, { name = "neorg", { name = "orgmode" } })
  --   end,
  -- },
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "max397574/better-escape.nvim",
    config = function()
      -- lua, default settings
      require("better_escape").setup({
        timeout = vim.o.timeoutlen,
        default_mappings = false,
        mappings = {
          i = {
            j = {
              k = "<Esc>",
            },
            k = {
              j = "<Esc>",
            },
          },
        },
      })
    end,
  },
  { "stefandtw/quickfix-reflector.vim" },
  { "airblade/vim-rooter" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      autotag = {
        enable = true,
        enable_close_on_slash = false,
      },
      indent = {
        enable = false,
        disable = { "go" },
      },
      highlight = {
        enable = true,
        disable = function(_, buf)
          local max_filesize = 10000 * 1024 -- 10 MB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            vim.notify("Tree sitter disabled")
            return true
          end
        end,
      },
      ignore_install = { "org" },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      -- local navic = require("nvim-navic")

      local function cwd()
        -- GET directory name
        local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        return string.upper(dir)
      end

      require("lualine").setup({
        tabline = {
          lualine_a = { cwd },
          lualine_b = { { "filename", path = 1 } },
          -- lualine_c = { { navic.get_location, cond = navic.is_available } },
          lualine_c = { "aerial" },
          lualine_y = { "diagnostics" },
          lualine_z = { "tabs" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = { "filename" },
          lualine_x = { "filetype" },
          lualine_y = { "location" },
          -- lualine_z = { "hostname" },
        },
      })
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
      messages = {
        enabled = false,
      },
      -- notify = {
      --   enabled = false,
      -- },
    },
    enabled = false,
  },
  { "gaelph/logsitter.nvim" },
  { "windwp/nvim-ts-autotag" },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "biome", "biome-organize-imports" },
        ["astro"] = { "biome" },
        ["javascriptreact"] = { "biome", "biome-organize-imports" },
        ["typescript"] = { "biome", "biome-organize-imports" },
        ["typescriptreact"] = { "biome", "biome-organize-imports" },
        ["vue"] = { "biome" },
        ["css"] = { "biome" },
        ["scss"] = { "biome" },
        ["less"] = { "biome" },
        ["html"] = { "biome" },
        ["json"] = { "biome" },
        ["jsonc"] = { "biome" },
        ["yaml"] = { "biome" },
        ["markdown"] = { "biome" },
        ["markdown.mdx"] = { "biome" },
        ["graphql"] = { "biome" },
        ["handlebars"] = { "biome" },
        -- ["sql"] = { "sqlfluff" },
      },
      formatters = {
        sqlfluff = {
          cwd = require("conform.util").root_file({ "deno.json" }),
          append_args = { "--dialect", "postgres" },
        },
      },
    },
  },
  { "sindrets/diffview.nvim" },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
  {
    "dmmulroy/ts-error-translator.nvim",
    config = function()
      require("ts-error-translator").setup()
    end,
  },
}
