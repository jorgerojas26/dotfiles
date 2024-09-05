-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- This file is automatically loaded by lazyvim.plugins.config

local Util = require("lazyvim.util")

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

map("n", "<leader>fs", "<cmd> update <CR>", { desc = "Save file" })
map("n", "<leader>fq", "<cmd> q <CR>", { desc = "Quit buffer" })
map("n", "<leader>l", "<cmd> b# <CR>", { desc = "Go to last buffer" })

map("n", "<leader>fl", "<cmd> Telescope resume <CR>", { desc = "Telescope resume" })
map("n", "<leader>gb", "<cmd> Telescope git_branches <CR>", { desc = "Telescope branches" })

map("n", "<leader>pl", "<cmd> Telescope project theme=dropdown <CR>", { desc = "Telescope project" })

map("n", "<c-p>", "<cmd> Telescope neoclip theme=dropdown <CR>", { desc = "Neoclip" })
map("i", "<c-p>", "<cmd> Telescope neoclip theme=dropdown <CR>", { desc = "Neoclip" })

map("n", "<leader>gs", function()
  Util.terminal.open({ "lazygit" }, { cwd = Util.root.get() })
end, { desc = "Lazygit (root dir)" })
--
map("n", "<C-t>", function()
  Util.terminal.open({ "lazysql" }, {
    cwd = Util.root.get(),
    ctrl_hjkl = false,
    border = "rounded",
    persistent = true,
    title = "Lazysql",
    title_pos = "center",
  })
end, { desc = "Lazysql" })

-- map("n", "<leader>gs", "<cmd> Neogit kind=vsplit <CR>", { desc = "Git status" })
-- map("n", "<leader>gs", "<cmd> vertical rightbelow G <CR>", { desc = "Git status" })
map("n", "<leader>gf", "<cmd> diffget //2 <CR>", { desc = "Keep left" })
map("n", "<leader>gl", "<cmd> diffget //3 <CR>", { desc = "Keep right" })
map("n", "<leader>g-", "<cmd> G switch - <CR>", { desc = "Switch to last git branch" })

-- HARPOON
map("n", "<leader>h", "<cmd>lua require'harpoon.ui'.toggle_quick_menu()<CR>", { desc = "Harpoon quick menu" })
map("n", "<leader>ah", "<cmd>lua require'harpoon.mark'.add_file()<CR>", { desc = "Harpoon add file" })
map("n", "<leader>[", "<cmd>lua require'harpoon.ui'.nav_file(1)<CR>", { desc = "Harpoon nav file 1" })
map("n", "<leader>]", "<cmd>lua require'harpoon.ui'.nav_file(2)<CR>", { desc = "Harpoon nav file 2" })
map("n", "<leader>\\", "<cmd>lua require'harpoon.ui'.nav_file(3)<CR>", { desc = "Harpoon nav file 3" })

map("n", "<leader>xc", ":g/console.lo/d<cr>", { desc = "Remove console.log of current file" })

-- NVIM DAP
map("n", "<leader>dt", '<cmd>lua require("dapui").toggle() <CR>', { desc = "Toggle nvim-dap-ui" })
map("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint() <CR>", { desc = "DAP breakpoint" })

map("n", "<leader>gt", "<cmd> Telescope git_worktree git_worktrees <CR>", { desc = "List worktrees" })
map("n", "<leader>gaw", "<cmd> Telescope git_worktree create_git_worktree <CR>", { desc = "Create worktree" })

-- map("n", "<C-h>", "<cmd> TmuxNavigateLeft <CR>", { desc = "Tmux navigate left" })
-- map("n", "<C-l>", "<cmd> TmuxNavigateRight <CR>", { desc = "Tmux navigate right" })
-- map("n", "<C-k>", "<cmd> TmuxNavigateUp <CR>", { desc = "Tmux navigate up" })
-- map("n", "<C-j>", "<cmd> TmuxNavigateDown <CR>", { desc = "Tmux navigate down" })

-- recommended mappings
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
map("n", "<C>", require("smart-splits").resize_left)
map("n", "<A-j>", require("smart-splits").resize_down)
map("n", "<A-k>", require("smart-splits").resize_up)
map("n", "<A-l>", require("smart-splits").resize_right)
--move between splits
map("n", "<C-h>", require("smart-splits").move_cursor_left)
map("n", "<C-j>", require("smart-splits").move_cursor_down)
map("n", "<C-k>", require("smart-splits").move_cursor_up)
map("n", "<C-l>", require("smart-splits").move_cursor_right)
-- swapping buffers between windows
map("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
map("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
map("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
map("n", "<leader><leader>l", require("smart-splits").swap_buf_right)
map("n", "<leader>cL", "<cmd>lua require('logsitter').log() <CR>", { desc = "Console log" })

-- map("n", "<leader>gh", "<cmd>! gh browse <CR>", { desc = "Browse github repo" })

-- map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

function _G.toggle_current_term()
  local opts = { buffer = 0 }
  local term_buf = vim.fn.bufname(vim.api.nvim_get_current_buf())

  if term_buf:match("lazysql") then
    vim.keymap.set("t", "<C-t>", [[<cmd>hide <CR>]], opts)
  end
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd("autocmd! TermOpen term://* lua toggle_current_term()")

-- map("n", "<C-s>", require("auto-session.session-lens").search_session, { noremap = true })

map("n", "<C-s>", "<cmd> Telescope projections <CR>")

map("n", "<c-->", "<cmd> Terminal <CR>", { desc = "Terminal (Root Dir)" })
map("t", "<c-->", "<cmd>bw! <CR>", { desc = "Remove terminal" })
