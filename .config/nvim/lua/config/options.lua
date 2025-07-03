-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local alpha = function()
  return string.format("%x", math.floor(255 * (vim.g.transparency or 0.8)))
end

vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.showtabline = 2
vim.opt.swapfile = false
vim.cmd([[let g:tmux_navigator_preserve_zoom = 1 ]])
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""
-- vim.cmd('imap <silent><script><expr> <C-e> copilot#Accept("")')
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions,globals"
vim.opt.list = false
-- vim.opt.cmdheight = 1

if vim.g.neovide then
  vim.g.neovide_refresh_rate = 144
  vim.g.neovide_refresh_rate_idle = 5
  vim.o.guifont = "Fira Code:h16"

  -- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
  vim.g.neovide_transparency = 0.3
  vim.g.transparency = 0.7
  vim.g.neovide_background_color = "#1E1E2D" .. alpha()
  vim.g.neovide_window_blurred = true
  vim.g.cmdheight = 0

  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode
  vim.keymap.set("t", "<D-v>", '<C-\\><C-n>"+Pi', { noremap = true })
  vim.keymap.set("t", "<D-c>", '"+y<CR>') -- Copy
end

vim.g.snacks_animate = false

vim.g.codecompanion_auto_tool_mode = true
vim.g.lazyvim_prettier_needs_config = true
