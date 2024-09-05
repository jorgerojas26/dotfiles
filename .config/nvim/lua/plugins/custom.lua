local Util = require("lazyvim.util")

return {
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night", transparent = false }, enabled = false },
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

      table.insert(opts.sources, { name = "neorg", { name = "orgmode" } })
    end,
  },
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
  { "tpope/vim-fugitive", enabled = false },
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
      -- telescope.load_extension("git_worktree")
      telescope.load_extension("harpoon")
    end,
    keys = {

      -- { "<leader>gs", mode = "n", "<cmd>Fugit2<cr>" },
      -- { "<leader>gs", "<cmd> vertical rightbelow G <CR>", desc = "Fugitive status" },
      -- { "<leader>gs", "<cmd> Neogit <CR>", desc = "Neogit status" },
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
      -- {
      --   "<leader>ff",
      --   "<cmd> Telescope find_files find_command=rg,--ignore,--hidden,--files prompt_prefix=🔍 <CR>",
      --   desc = "Treesitter symbols",
      -- },
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
  { "ThePrimeagen/git-worktree.nvim", enabled = false },
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
  { "lukas-reineke/indent-blankline.nvim", opts = { enabled = true } },
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
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   opts = {},
  -- },
  -- { "lukas-reineke/cmp-under-comparator" },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
    lazy = false,
  },
  -- {
  --   "folke/persistence.nvim",
  --   keys = {
  --     {
  --       "<leader>qs",
  --       function()
  --         require("persistence").load()
  --       end,
  --       desc = "Restore Session",
  --     },
  --     {
  --       "<leader>ql",
  --       function()
  --         require("persistence").load({ last = true })
  --       end,
  --       desc = "Restore Last Session",
  --     },
  --     {
  --       "<leader>qd",
  --       function()
  --         require("persistence").stop()
  --       end,
  --       desc = "Don't Save Current Session",
  --     },
  --   },
  --   enabled = true,
  -- },
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
      table.insert(opts.ensure_installed, "biome")
      -- table.insert(opts.ensure_installed, "prettierd")
      -- table.insert(opts.ensure_installed, "eslint_d")
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["javascript"] = { "biome" },
        ["javascriptreact"] = { "biome" },
        ["typescript"] = { "biome" },
        ["typescriptreact"] = { "biome" },
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
  {
    "supermaven-inc/supermaven-nvim",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-e>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
      })
    end,
  },

  -- {
  --   "gnikdroy/projections.nvim",
  --   branch = "dev",
  --   config = function()
  --     require("projections").setup({
  --       -- Workspaces to search for, (table|string)[]
  --       workspaces = {
  --         -- Examples:
  --         -- { path = "~/dev", patterns = { ".git" } },
  --         -- { path = "~/repos", patterns = {} }      , -- An empty pattern list indicates that all subdirectories are projects
  --         -- i.e patterns are not considered
  --         -- { path = "~/dev" },                        -- When patterns is not provided, default patterns is used (specified below)
  --         { path = "~/projects", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "~/projects/TilaApp", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "~/projects/quip", patterns = {} },
  --         { path = "~/projects/TILA/baby-tila/baby-tila-app", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "~/projects/TILA/baby-tila/baby-tila-server", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "~/projects/gochata/gochata-web", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "~/projects/gochata/gochata-server", patterns = { ".git", ".svn", ".hg" } },
  --         { path = "/Users/jorgerojas/.dotfiles/.config", patterns = {} },
  --       },
  --
  --       -- Default set of patterns, string[]
  --       -- NOTE: patterns are not regexps
  --       default_patterns = { ".git", ".svn", ".hg" },
  --
  --       -- The keymapping to use to launch the picker, string?
  --       -- selector_mapping = "<leader>fp",
  --
  --       -- Whether to show preview window via telescope, boolean
  --       show_preview = true,
  --
  --       -- If projections will try to auto restore sessions when you start neovim, boolean
  --       auto_restore = true,
  --       -- The behaviour is as follows:
  --       -- 1) If vim was started with arguments, do nothing
  --       -- 2) If in some project's root, attempt to restore that project's session
  --       -- 3) If not, restore last stored session
  --     })
  --
  --     -- Bind <leader>fp to Telescope projections
  --     require("telescope").load_extension("projections")
  --
  --     -- Autostore session on VimExit
  --     local Session = require("projections.session")
  --
  --     -- vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
  --     --   callback = function()
  --     --     Session.store(vim.loop.cwd())
  --     --   end,
  --     -- })
  --
  --     -- If vim was started with arguments, do nothing
  --     -- If in some project's root, attempt to restore that project's session
  --     -- If not, restore last session
  --     -- If no sessions, do nothing
  --     -- vim.api.nvim_create_autocmd({ "VimEnter" }, {
  --     --   callback = function()
  --     --     if vim.fn.argc() ~= 0 then
  --     --       return
  --     --     end
  --     --     local session_info = Session.info(vim.loop.cwd())
  --     --     if session_info == nil then
  --     --       Session.restore_latest()
  --     --     else
  --     --       Session.restore(vim.loop.cwd())
  --     --     end
  --     --   end,
  --     --   desc = "Restore last session automatically",
  --     -- })
  --
  --     -- local switcher = require("projections.switcher")
  --     -- vim.api.nvim_create_autocmd({ "VimEnter" }, {
  --     --   callback = function()
  --     --     if vim.fn.argc() == 0 then
  --     --       switcher.switch(vim.loop.cwd())
  --     --     end
  --     --   end,
  --     -- })
  --     --
  --     -- vim.api.nvim_create_autocmd("User", {
  --     --   pattern = "ProjectionsPreStoreSession",
  --     --   callback = function()
  --     --     vim.lsp.stop_client(vim.lsp.get_clients())
  --     --   end,
  --     -- })
  --   end,
  -- },
  -- Lua
}
