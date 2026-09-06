-- AI-agent change review: diffview.nvim + grep over changed files.
-- Replaces herdr-reviewer (read-only) with a full editor workflow.
-- herdr keymap prefix+ctrl+r opens `nvim -c DiffviewOpen` via herdr-toggle.py.
return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewRefresh",
    "DiffviewFileHistory",
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff: working tree vs HEAD" },
    {
      "<leader>gw",
      function()
        -- Live grep restricted to changed/untracked files (agent output review).
        if vim.fn.system("git rev-parse --is-inside-work-tree"):find("true") == nil then
          vim.notify("Not in a git work tree", vim.log.levels.WARN)
          return
        end
        local files = vim.fn.systemlist("git ls-files -mo --exclude-standard")
        if vim.v.shell_error ~= 0 then
          vim.notify("git ls-files failed", vim.log.levels.ERROR)
          return
        end
        if #files == 0 then
          vim.notify("No changes to grep", vim.log.levels.INFO)
          return
        end
        local root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
        local paths = {}
        for _, f in ipairs(files) do
          paths[root .. "/" .. f] = true
        end
        Snacks.picker.grep({ filter = { paths = paths } })
      end,
      desc = "Grep changed files",
    },
  },
  opts = {
    view = {
      file_panel = { win_config = { position = "right" } },
      merge_tool = { layout = "diff3_mixed" },
    },
  },
}
