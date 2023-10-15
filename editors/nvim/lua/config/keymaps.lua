-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- This file is automatically loaded by lazyvim.plugins.config

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
map("n", "<leader>gc", "<cmd> Telescope git_bcommits <CR>", { desc = "Telescope bcommits" })
map("n", "<leader>gC", "<cmd> Telescope git_commits <CR>", { desc = "Telescope commits" })
map("n", "<leader>gb", "<cmd> Telescope git_branches <CR>", { desc = "Telescope branches" })

map("n", "<leader>pl", "<cmd> Telescope project theme=dropdown <CR>", { desc = "Telescope branches" })

map("n", "<c-p>", "<cmd> Telescope neoclip theme=dropdown <CR>", { desc = "Neoclip" })
map("i", "<c-p>", "<cmd> Telescope neoclip theme=dropdown <CR>", { desc = "Neoclip" })

map("n", "<leader>gs", "<cmd> vertical rightbelow G <CR>", { desc = "Git status" })
map("n", "<leader>gf", "<cmd> diffget //2 <CR>", { desc = "Keep left" })
map("n", "<leader>gl", "<cmd> diffget //3 <CR>", { desc = "Keep right" })
map("n", "<leader>g-", "<cmd> G switch - <CR>", { desc = "Switch to last git branch" })

map("n", "<leader>h", "<cmd>lua require'harpoon.ui'.toggle_quick_menu()<CR>")
map("n", "<leader>ah", "<cmd>lua require'harpoon.mark'.add_file()<CR>")
map("n", "<leader>u", "<cmd>lua require'harpoon.ui'.nav_file(1)<CR>")
map("n", "<leader>i", "<cmd>lua require'harpoon.ui'.nav_file(2)<CR>")
map("n", "<leader>o", "<cmd>lua require'harpoon.ui'.nav_file(3)<CR>")
map("n", "<leader>xc", ":g/console.lo/d<cr>", { desc = "Remove console.log of current file" })

-- NVIM DAP
map("n", "<leader>dt", '<cmd>lua require("dapui").toggle() <CR>', { desc = "Toggle nvim-dap-ui" })
map("n", "<leader>db", "<cmd>lua require'dap'.toggle_breakpoint() <CR>", { desc = "DAP breakpoint" })

map("n", "<leader>gt", "<cmd> Telescope git_worktree git_worktrees <CR>", { desc = "List worktrees" })
map("n", "<leader>gaw", "<cmd> Telescope git_worktree create_git_worktree <CR>", { desc = "Create worktree" })

map("n", "<C-h>", "<cmd> TmuxNavigateLeft <CR>", { desc = "Tmux navigate left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight <CR>", { desc = "Tmux navigate right" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp <CR>", { desc = "Tmux navigate up" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown <CR>", { desc = "Tmux navigate down" })
