return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    lazy = false,
    config = function()
        local bufferline = require('bufferline')

        bufferline.setup({
            options = {
                mode = "buffers",
                always_show_bufferline = true,
                custom_filter = function(buf_number, buf_numbers)
                    if vim.bo[buf_number].filetype == "" and vim.fn.bufname(buf_number) == "" then
                        return false
                    end
                    return true
                end,
            },
        })
    end,
    keys = {
        -- Normal Mode
        { "<leader><Tab>",   "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer",          mode = "n" },
        { "<leader><S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer",      mode = "n" },
        { "<leader>c",       "<cmd>bdelete<cr>",             desc = "Close Buffer",         mode = "n" },
        { "<leader>v",       "<cmd>vsplit<cr>",              desc = "Vertical Split",       mode = "n" },
        { "<leader>s",       "<cmd>split<cr>",               desc = "Horizontal Split",     mode = "n" },
        { "<leader>h",       "<C-w>h",                       desc = "Move to left window",  mode = "n" },
        { "<leader>j",       "<C-w>j",                       desc = "Move to lower window", mode = "n" },
        { "<leader>k",       "<C-w>k",                       desc = "Move to upper window", mode = "n" },
        { "<leader>l",       "<C-w>l",                       desc = "Move to right window", mode = "n" },

        -- Terminal Mode
        { "<Esc>",           [[<C-\><C-n>]],                 desc = "Exit terminal mode",   mode = "t" },
        { "<leader>h",       [[<C-\><C-n><C-w>h]],           desc = "Move to left window",  mode = "t" },
        { "<leader>j",       [[<C-\><C-n><C-w>j]],           desc = "Move to lower window", mode = "t" },
        { "<leader>k",       [[<C-\><C-n><C-w>k]],           desc = "Move to upper window", mode = "t" },
        { "<leader>l",       [[<C-\><C-n><C-w>l]],           desc = "Move to right window", mode = "t" },
    }
}
