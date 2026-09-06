return {
  {
    "haydenmeade/neotest-jest",
    -- Optional dependencies if you need advanced features like debugging
    dependencies = { "nvim-neotest/nvim-nio", "hrsh7th/nvim-cmp" },
  },
  { "marilari88/neotest-vitest" },
  {
    "nvim-neotest/neotest",
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-jest"),
          require("neotest-vitest"),
        },
      })
    end,
  },
}
