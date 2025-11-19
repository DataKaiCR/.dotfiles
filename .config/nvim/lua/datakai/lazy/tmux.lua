-- Tmux integration for Neovim
return {
    -- Seamless navigation between tmux panes and vim splits
    {
        'christoomey/vim-tmux-navigator',
        lazy = false,
        keys = {
            { '<C-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Navigate Left (Tmux)' },
            { '<C-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Navigate Down (Tmux)' },
            { '<C-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Navigate Up (Tmux)' },
            { '<C-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Navigate Right (Tmux)' },
        },
    },

    -- Tmux sessionizer integration
    {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local harpoon = require('harpoon')
            harpoon:setup()

            -- Keymaps for harpoon
            vim.keymap.set('n', '<leader>ha', function() harpoon:list():add() end, { desc = 'Harpoon: Add file' })
            vim.keymap.set('n', '<leader>hh', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: Toggle menu' })

            -- Quick access to first 4 files
            vim.keymap.set('n', '<leader>h1', function() harpoon:list():select(1) end, { desc = 'Harpoon: File 1' })
            vim.keymap.set('n', '<leader>h2', function() harpoon:list():select(2) end, { desc = 'Harpoon: File 2' })
            vim.keymap.set('n', '<leader>h3', function() harpoon:list():select(3) end, { desc = 'Harpoon: File 3' })
            vim.keymap.set('n', '<leader>h4', function() harpoon:list():select(4) end, { desc = 'Harpoon: File 4' })

            -- Navigation
            vim.keymap.set('n', '<leader>hp', function() harpoon:list():prev() end, { desc = 'Harpoon: Previous' })
            vim.keymap.set('n', '<leader>hn', function() harpoon:list():next() end, { desc = 'Harpoon: Next' })
        end,
    },
}
