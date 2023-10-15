return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- they way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }
      opts.completion = {
        completeopt = "menu,menuone,noinsert",
      }
      opts.snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      }
      opts.formatting = {
        format = function(_, item)
          local icons = require("lazyvim.config").icons.kinds
          if icons[item.kind] then
            item.kind = icons[item.kind] .. item.kind
          end
          return item
        end,
      }
      opts.experimental = {
        ghost_text = {
          hl_group = "LspCodeLens",
        },
      }
    end,
  },
  { "akinsho/bufferline.nvim", enabled = false },
  { "lewis6991/impatient.nvim" },
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
  {
    "mvllow/modes.nvim",
    config = function()
      vim.opt.cursorline = true
      require("modes").setup()
    end,
  },
  { "nvim-telescope/telescope-fzf-native.nvim" },
  { "nvim-telescope/telescope-project.nvim" },
  { "windwp/nvim-ts-autotag" },
  { "tpope/vim-fugitive" },
  { "stefandtw/quickfix-reflector.vim" },
  { "ThePrimeagen/harpoon" },
  { "norcalli/nvim-colorizer.lua" },
  { "AckslD/nvim-neoclip.lua" },
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
          },
        },
      })

      telescope.load_extension("project")
      telescope.load_extension("neoclip")
      telescope.load_extension("fzf")
      telescope.load_extension("dap")
      telescope.load_extension("git_worktree")
    end,
    keys = {
      { "<leader>gs", "<cmd> vertical rightbelow G <CR>", desc = "Fugitive status" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      autotag = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local navic = require("nvim-navic")

      local function cwd()
        -- GET directory name
        local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        return string.upper(dir)
      end

      require("lualine").setup({
        tabline = {
          lualine_a = { cwd },
          lualine_b = { { "filename", path = 1 } },
          lualine_c = { { navic.get_location, cond = navic.is_available } },
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
    "jose-elias-alvarez/null-ls.nvim",
    opts = function()
      local nls = require("null-ls")
      return {
        sources = {
          -- nls.builtins.formatting.prettierd,
          nls.builtins.formatting.stylua,
          nls.builtins.formatting.rome,
          -- nls.builtins.diagnostics.eslint_d,
        },
      }
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
    },
  },
  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    config = function()
      require("dapui").setup()
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    config = function()
      local mason_nvim_dap = require("mason-nvim-dap")
      mason_nvim_dap.setup({ automatic_setup = true })
      mason_nvim_dap.setup_handlers()
    end,
  },
  { "nvim-telescope/telescope-dap.nvim" },
  { "ThePrimeagen/git-worktree.nvim" },
}
