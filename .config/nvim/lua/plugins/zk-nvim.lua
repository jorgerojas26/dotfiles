return {
  "zk-org/zk-nvim",
  keys = {
    { "<leader>zn", "<cmd>ZkNew<cr>", desc = "New note" },
    { "<leader>zo", "<cmd>ZkNotes<cr>", desc = "Open notes" },
    { "<leader>zt", "<cmd>ZkTags<cr>", desc = "Open tags" },
    { "<leader>zs", mode = "v", ":'<,'>ZkMatch<CR>", desc = "Search notes" },
    { "<leader>zs", mode = "n", "<cmd>ZkMatch<cr>", desc = "Search notes" },
  },
  config = function()
    require("zk").setup({})
  end,
}
