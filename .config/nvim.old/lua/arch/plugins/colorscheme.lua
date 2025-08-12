return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    local theme = require("catppuccin")

    theme.setup({
      flavour = "macchiato",
      transparent_background = true,  
      default_integrations = true,
      integrations = {
        nvimtree = true,
        treesitter = true,
        telescope = {
          enabled = true,
        },
        which_key = true,
        alpha = true,
      },
    })
    
    vim.cmd.colorscheme "catppuccin"
  end
}
