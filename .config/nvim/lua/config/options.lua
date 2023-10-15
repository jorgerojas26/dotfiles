-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

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
vim.cmd('imap <silent><script><expr> <C-e> copilot#Accept("")')
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

if vim.g.neovide then
  vim.g.neovide_refresh_rate = 144
  vim.g.neovide_refresh_rate_idle = 5
end

vim.opt.list = false
vim.opt.cmdheight = 0
