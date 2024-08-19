-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- vim.cmd(
--   [[ autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} }) ]]
-- )

local Util = require("lazyvim.util")

vim.cmd([[
autocmd BufNewFile,BufRead Podfile,*.podspec set filetype=ruby
]])

-- Helper function to escape tmux session names
local function escape_tmux_session_name(session_name)
  -- Replace non-alphanumeric characters with underscores
  return session_name:gsub("[^%w_]", "-")
end

-- Helper function to get the escaped session name based on the current working directory
local function get_tmux_session_name()
  local cwd = vim.fn.getcwd()
  -- local session_name = vim.fn.fnamemodify(cwd, ":t")
  return escape_tmux_session_name(cwd)
end

-- Function to create or attach to a tmux session
local function tmux_attach_or_create()
  -- Check if tmux is running, if not, start it

  if not vim.fn.executable("tmux") then
    vim.fn.system("tmux start-server")
  end
  local session_name = get_tmux_session_name()

  -- Check if the session exists
  local session_check_command = string.format("tmux has-session -t %s 2>/dev/null", session_name)
  local session_exists = os.execute(session_check_command)

  if session_exists ~= 0 then
    -- Create a new session if it doesn't exist
    local create_command =
      string.format("tmux new-session -d -s %s -c %s", session_name, vim.fn.shellescape(vim.fn.getcwd()))
    os.execute(create_command)
  end

  -- Return the command to attach to the session
  return string.format("tmux a -t %s", session_name)
end

-- Function to open a terminal in Neovim attached to tmux
local function open_tmux_terminal()
  local tmux_command = tmux_attach_or_create()
  local tmux_command_splitted = {}

  for word in tmux_command:gmatch("%S+") do
    table.insert(tmux_command_splitted, word)
  end

  Util.terminal.open(tmux_command_splitted, {
    cwd = Util.root.get(),
    ctrl_hjkl = false,
    border = "rounded",
    persistent = false,
    title = "Tmux terminal",
    title_pos = "center",
  })
end

-- Autocmd to override :terminal command
vim.api.nvim_create_user_command("Terminal", open_tmux_terminal, {})
