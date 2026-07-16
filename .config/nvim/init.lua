-- disable native nvim file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- enable 24-bit RGB color in the TUI
vim.opt.termguicolors = true

require('config.lazy')
