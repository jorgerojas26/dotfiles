local Util = require("lazyvim.util")

return {
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night", transparent = true }, enabled = false },
  { "catppuccin/nvim", name = "catppuccin", opts = { transparent_background = true } },
  -- { "rebelot/kanagawa.nvim" },
  -- { "rose-pine/neovim" },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      -- local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      --
      -- cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }
    end,
  },
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "max397574/better-escape.nvim",
    config = function()
      require("better_escape").setup({
        mapping = { "jk", "kj" }, -- a table with mappings to use
        timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
        clear_empty_lines = false, -- clear line after escaping if there is only whitespace
        keys = "<Esc>", -- keys used for escaping, if it is a function will use the result everytime
        -- example
        -- keys = function()
        --   return vim.fn.col '.' - 2 >= 1 and '<esc>l' or '<esc>'
        -- end,
      })
    end,
  },
  { "nvim-telescope/telescope-fzf-native.nvim" },
  { "nvim-telescope/telescope-project.nvim" },
  -- {
  --   "windwp/nvim-autopairs",
  --   config = function()
  --     local npairs = require("nvim-autopairs")
  --     local Rule = require("nvim-autopairs.rule")
  --
  --     npairs.setup({
  --       check_ts = true,
  --       ts_config = {
  --         lua = { "string" }, -- it will not add a pair on that treesitter node
  --         javascript = { "template_string" },
  --         java = false, -- don't check treesitter on java
  --       },
  --     })
  --
  --     local ts_conds = require("nvim-autopairs.ts-conds")
  --
  --     -- press % => %% only while inside a comment or string
  --     npairs.add_rules({
  --       Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({ "string", "comment" })),
  --       Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({ "function" })),
  --     })
  --   end,
  -- },
  { "tpope/vim-fugitive" },
  { "stefandtw/quickfix-reflector.vim" },
  { "ThePrimeagen/harpoon" },
  {
    "AckslD/nvim-neoclip.lua",
    config = function()
      require("neoclip").setup()
    end,
  },
  { "airblade/vim-rooter" },

  {
    "nvim-telescope/telescope.nvim",
    config = function()
      local telescope = require("telescope")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
            },
            n = {
              ["<C-p>"] = require("telescope.actions.layout").toggle_preview,
            },
          },
          -- buffer_previewer_maker = new_maker,
        },
      })

      telescope.load_extension("project")
      telescope.load_extension("neoclip")
      telescope.load_extension("fzf")
      telescope.load_extension("git_worktree")
      telescope.load_extension("harpoon")
    end,
    keys = {
      -- { "<leader>gs", "<cmd> vertical rightbelow G <CR>", desc = "Fugitive status" },
      {
        "<leader>gs",
        function()
          Util.terminal.open({ "lazygit" }, { cwd = Util.root.get() })
        end,
        desc = "Telescope bcommits",
      },
      { "<leader>sg", "<cmd> Telescope live_grep theme=ivy <CR>", desc = "Telescope live_grep" },
      { "<leader>gc", "<cmd> Telescope git_bcommits theme=ivy <CR>", desc = "Telescope bcommits" },
      { "<leader>gC", "<cmd> Telescope git_commits theme=ivy<CR>", desc = "Telescope commits" },
      { "<leader>ss", "<cmd> Telescope treesitter <CR>", desc = "Treesitter symbols" },
    },
  },
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
          lualine_b = { "branch", "diff", { "diagnostics", sources = { "nvim_diagnostic", "coc" } } },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "location" },
          lualine_z = { "hostname" },
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
  },
  { "ThePrimeagen/git-worktree.nvim" },
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   build = ":Copilot auth",
  --   opts = {
  --     suggestion = {
  --       enabled = true,
  --       auto_trigger = true,
  --       debounce = 0,
  --       keymap = {
  --         accept = "<C-e>",
  --       },
  --     },
  --     panel = { enabled = true },
  --   },
  -- },
  {
    "neovim/nvim-lspconfig",
    opts = {
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
      },
    },
  },
  { "lukas-reineke/indent-blankline.nvim", opts = { enabled = false } },
  {
    "brenoprata10/nvim-highlight-colors",
    config = function()
      require("nvim-highlight-colors").setup()
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
      -- stylua: ignore
      keys = {
    { "<leader>du", function() require("dapui").toggle({reset = true }) end, desc = "Dap UI" },
        { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
      },
    opts = {},
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({})
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
  },
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },
  { "lukas-reineke/cmp-under-comparator" },
  { "github/copilot.vim" },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
    lazy = false,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "splits" } },
  -- stylua: ignore
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
    enabled = false,
  },
  { "gaelph/logsitter.nvim" },
  -- { "echasnovski/mini.pairs", enabled = false },
  { "windwp/nvim-ts-autotag" },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
  },
  {
    "stevearc/oil.nvim",
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    enabled = false,
  },
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "prettierd")
      table.insert(opts.ensure_installed, "eslint_d")
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "prettierd" },
        ["javascriptreact"] = { "prettierd" },
        ["typescript"] = { "prettierd" },
        ["typescriptreact"] = { "prettierd" },
        ["vue"] = { "prettierd" },
        ["css"] = { "prettierd" },
        ["scss"] = { "prettierd" },
        ["less"] = { "prettierd" },
        ["html"] = { "prettierd" },
        ["json"] = { "prettierd" },
        ["jsonc"] = { "prettierd" },
        ["yaml"] = { "prettierd" },
        ["markdown"] = { "prettierd" },
        ["markdown.mdx"] = { "prettierd" },
        ["graphql"] = { "prettierd" },
        ["handlebars"] = { "prettierd" },
      },
    },
  },
  {
    "echasnovski/mini.files",
    version = "*",
    opts = {
      keys = {
        {
          "<leader>fm",
          function()
            require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
          end,
          desc = "Open mini.files (directory of current file)",
        },
        {
          "<leader>fM",
          function()
            require("mini.files").open(vim.loop.cwd(), true)
          end,
          desc = "Open mini.files (cwd)",
        },
      },
    },
  },
  {
    "cormacrelf/dark-notify",
    config = function()
      require("dark_notify").run()
    end,
  },
}
