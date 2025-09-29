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
  -- { "nvim-telescope/telescope-project.nvim" },
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
  { "airblade/vim-rooter" },
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   config = function()
  --     local telescope = require("telescope")
  --
  --     telescope.setup({
  --       defaults = {
  --         mappings = {
  --           i = {
  --             ["<esc>"] = require("telescope.actions").close,
  --           },
  --           n = {
  --             ["<C-p>"] = require("telescope.actions.layout").toggle_preview,
  --           },
  --         },
  --         -- buffer_previewer_maker = new_maker,
  --       },
  --     })
  --
  --     telescope.load_extension("project")
  --     telescope.load_extension("neoclip")
  --     telescope.load_extension("fzf")
  --     -- telescope.load_extension("git_worktree")
  --     telescope.load_extension("harpoon")
  --   end,
  --   keys = {
  --
  --     -- { "<leader>gs", mode = "n", "<cmd>Fugit2<cr>" },
  --     -- { "<leader>gs", "<cmd> vertical rightbelow G <CR>", desc = "Fugitive status" },
  --     -- { "<leader>gs", "<cmd> Neogit <CR>", desc = "Neogit status" },
  --     {
  --       "<leader>gs",
  --       function()
  --         Util.terminal.open({ "lazygit" }, { cwd = Util.root.get() })
  --       end,
  --       desc = "Telescope bcommits",
  --     },
  --     { "<leader>sg", "<cmd> Telescope live_grep theme=ivy <CR>", desc = "Telescope live_grep" },
  --     { "<leader>gc", "<cmd> Telescope git_bcommits theme=ivy <CR>", desc = "Telescope bcommits" },
  --     { "<leader>gC", "<cmd> Telescope git_commits theme=ivy<CR>", desc = "Telescope commits" },
  --     { "<leader>ss", "<cmd> Telescope treesitter <CR>", desc = "Treesitter symbols" },
  --     -- {
  --     --   "<leader>ff",
  --     --   "<cmd> Telescope find_files find_command=rg,--ignore,--hidden,--files prompt_prefix=🔍 <CR>",
  --     --   desc = "Treesitter symbols",
  --     -- },
  --   },
  -- },
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
  -- {
  --   "rcarriga/nvim-dap-ui",
  --     -- stylua: ignore
  --     keys = {
  --   { "<leader>du", function() require("dapui").toggle({reset = true }) end, desc = "Dap UI" },
  --       { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
  --     },
  --   opts = {},
  --   config = function(_, opts)
  --     local dap = require("dap")
  --     local dapui = require("dapui")
  --     dapui.setup(opts)
  --     dap.listeners.after.event_initialized["dapui_config"] = function()
  --       dapui.open({})
  --     end
  --     dap.listeners.before.event_terminated["dapui_config"] = function()
  --       dapui.close({})
  --     end
  --     dap.listeners.before.event_exited["dapui_config"] = function()
  --       dapui.close({})
  --     end
  --   end,
  -- },
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
  -- {
  --   "cormacrelf/dark-notify",
  --   config = function()
  --     require("dark_notify").run()
  --   end,
  -- },
  -- {
  --   "supermaven-inc/supermaven-nvim",
  --   config = function()
  --     require("supermaven-nvim").setup({})
  --   end,
  -- },
  {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
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
        menu = {
          border = "single",
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
  },
  { "sindrets/diffview.nvim" },
}
