local M = {
  "MeanderingProgrammer/markdown.nvim",
  opts = {
    file_types = { "markdown", "norg", "rmd" },
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      sign = false,
      icons = {},
    },
  },
}

return M
