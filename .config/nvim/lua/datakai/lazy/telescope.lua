return {
    'nvim-telescope/telescope.nvim',
    name = 'telescope',
    tag = '0.1.5',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-file-browser.nvim'
    }, 
    config = function()
        local telescope = require('telescope')
        local builtin = require('telescope.builtin')
        
        -- Configure telescope
        telescope.setup({
            defaults = {
                file_ignore_patterns = {
                    "node_modules",
                    ".git/",
                    ".DS_Store"
                },
                path_display = { "truncate" },
                sorting_strategy = "ascending",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.55,
                    },
                    vertical = {
                        mirror = false,
                    },
                    width = 0.87,
                    height = 0.80,
                    preview_cutoff = 120,
                }
            },
            pickers = {
                find_files = {
                    -- Always search hidden files but respect gitignore
                    hidden = true
                }
            },
            extensions = {
                file_browser = {
                    theme = "dropdown",
                    hijack_netrw = false,
                    mappings = {
                        ["i"] = {
                            -- Insert mode mappings
                        },
                        ["n"] = {
                            -- Normal mode mappings
                        },
                    },
                },
            },
        })
        
        -- Load extensions
        telescope.load_extension("file_browser")
        
        -- Key mappings - only run when these keys are pressed
        vim.keymap.set('n', '<leader>pf', function()
            builtin.find_files({ 
                cwd = vim.fn.expand('%:p:h'),
                prompt_title = "Files in Current Directory"
            })
        end, { desc = "Find files in current directory" })
        
        vim.keymap.set('n', '<leader>pF', function()
            builtin.find_files({ prompt_title = "Files in Project" })
        end, { desc = "Find files in project" })
        
        vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = "Find git files" })
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end, { desc = "Search for WORD under cursor" })
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end, { desc = "Search for word under cursor" })
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = "Search for pattern" })
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, { desc = "Search help tags" })
        vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = "Find open buffers" })
        
        -- File browser
        vim.keymap.set('n', '<leader>fb', function()
            telescope.extensions.file_browser.file_browser({
                path = vim.fn.expand('%:p:h'),
                cwd = vim.fn.expand('%:p:h'),
                respect_gitignore = false,
                hidden = true,
                grouped = true,
                previewer = false,
                initial_mode = "normal",
                layout_config = { height = 40 }
            })
        end, { desc = "Browse files" })
    end,
    -- Set lazy-loading to ensure Telescope only loads when needed
    lazy = true,
    keys = {
        { "<leader>pf", desc = "Find files in current directory" },
        { "<leader>pF", desc = "Find files in project" },
        { "<C-p>", desc = "Find git files" },
        { "<leader>pWs", desc = "Search for WORD under cursor" },
        { "<leader>pws", desc = "Search for word under cursor" },
        { "<leader>ps", desc = "Search for pattern" },
        { "<leader>vh", desc = "Search help tags" },
        { "<leader>pb", desc = "Find open buffers" },
        { "<leader>fb", desc = "Browse files" },
    }
}
