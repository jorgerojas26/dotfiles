return {
  { "danilshvalov/org-modern.nvim", event = "VeryLazy", ft = { "org" } },
  {

    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      local Menu = require("org-modern.menu")

      vim.api.nvim_create_user_command("OrgAgenda", function()
        require("orgmode").agenda:agenda({ height = 100 })
      end, {})

      require("orgmode").setup({
        org_agenda_files = "~/org/**/*",
        org_default_notes_file = "~/org/notes.org",
        org_agenda_min_height = 100,

        ui = {
          menu = {
            handler = function(data)
              Menu:new({
                window = {
                  margin = { 1, 0, 1, 0 },
                  padding = { 0, 1, 0, 1 },
                  title_pos = "center",
                  border = "single",
                  zindex = 1000,
                },
                icons = {
                  separator = "➜",
                },
              }):open(data)
            end,
          },
        },
      })
    end,
  },
  {
    "akinsho/org-bullets.nvim",
    event = "VeryLazy",
    config = function()
      require("org-bullets").setup()
    end,
  },
  {
    "chipsenkbeil/org-roam.nvim",
    event = "VeryLazy",
    tag = "0.1.0",
    dependencies = {
      {
        "nvim-orgmode/orgmode",
        tag = "0.3.4",
      },
    },
    config = function()
      require("org-roam").setup({
        directory = "~/org/roam",
      })
    end,
  },
  {
    "ranjithshegde/orgWiki.nvim",
    event = "VeryLazy",
    config = function()
      require("orgWiki").setup({
        wiki_path = { "~/org/wiki" },
        diary_path = "~/org/wiki/diary/",
      })
    end,
  },
}
