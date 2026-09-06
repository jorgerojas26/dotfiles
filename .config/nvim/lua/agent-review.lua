-- Review comments for AI agents: annotate lines while reviewing, then send
-- the whole list as one prompt to the herdr agent working on this project.
-- Replaces herdr-reviewer's comment + send workflow.
--
-- <leader>ra  add comment on current line (n) / selection start (v)
-- <leader>rl  list comments in the quickfix
-- <leader>rs  send all comments to this project's herdr agent

local M = {}
local comments = {}

local function git_root()
  local out = vim.fn.system("git rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.fn.trim(out)
end

local function rel_path()
  local p = vim.fn.expand("%:.")
  if p == "" then
    p = vim.api.nvim_buf_get_name(0)
  end
  return p
end

function M.add()
  vim.ui.input({ prompt = "Review comment: " }, function(text)
    if not text or text == "" then
      return
    end
    table.insert(comments, {
      file = rel_path(),
      lnum = math.min(vim.fn.line("."), vim.fn.line("v")),
      text = text,
    })
    vim.notify(("Review comment %d saved"):format(#comments))
  end)
end

function M.list()
  local items = {}
  for _, c in ipairs(comments) do
    items[#items + 1] = { filename = c.file, lnum = c.lnum, col = 1, text = c.text }
  end
  vim.fn.setqflist(items, "r", { title = "Review comments" })
  if #items > 0 then
    vim.cmd.copen()
  else
    vim.notify("No review comments yet")
  end
end

local function prompt_text()
  local lines = {
    "Code review feedback — please apply these changes:",
    "",
  }
  for _, c in ipairs(comments) do
    lines[#lines + 1] = ("- `%s:%d` — %s"):format(c.file, c.lnum, c.text)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Address each point, then summarize what you changed."
  return table.concat(lines, "\n")
end

local function do_send(agent)
  local out = vim.fn.system({ "herdr", "agent", "prompt", agent.pane_id, prompt_text() })
  if vim.v.shell_error ~= 0 then
    vim.notify("herdr agent prompt failed: " .. vim.trim(out), vim.log.levels.ERROR)
    return
  end
  vim.notify(("Sent %d review comments to %s (%s)"):format(#comments, agent.agent, agent.pane_id))
  comments = {}
end

local function pick_agent(agents, cb)
  if #agents == 1 then
    return cb(agents[1])
  end
  vim.ui.select(agents, {
    prompt = "Send review to which agent?",
    format_item = function(a)
      return ("%s · pane %s · %s"):format(a.agent, a.pane_id, a.agent_status)
    end,
  }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

function M.send()
  if #comments == 0 then
    vim.notify("No review comments to send", vim.log.levels.WARN)
    return
  end
  local root = git_root()
  if not root then
    vim.notify("Not inside a git repository", vim.log.levels.ERROR)
    return
  end
  local ok, agents = pcall(function()
    return vim.json.decode(vim.fn.system("herdr agent list")).result.agents
  end)
  if not ok or type(agents) ~= "table" then
    vim.notify("herdr agent list failed", vim.log.levels.ERROR)
    return
  end
  -- Agents hosting this project (cwd match; also matches worktrees under it).
  local mine = vim.tbl_filter(function(a)
    return a.cwd == root or (a.cwd and root:find(a.cwd .. "/", 1, true))
  end, agents)
  if #mine == 0 then
    vim.notify(("No herdr agent found for %s"):format(root), vim.log.levels.WARN)
    return
  end
  pick_agent(mine, do_send)
end

return M
