-- This file defines all Git-related plugins but delegates detailed configuration to separate files
return {
    -- Core Git commands with Fugitive
    -- Detailed configuration in fugitive.lua
    {
        "tpope/vim-fugitive",
        lazy = true,
        cmd = {
            "Git", "G", "Gdiff", "Gdiffsplit", "Gvdiffsplit",
            "Gedit", "Gsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete"
        },
        -- Configuration is in fugitive.lua
    },

    -- Visual Git indicators with Gitsigns
    {
        "lewis6991/gitsigns.nvim",
        event = "BufReadPre", -- Load when buffer is read
        config = function()
            require("gitsigns").setup({
                -- Sign configuration
                signs                        = {
                    add          = { text = '│' },
                    change       = { text = '│' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                -- Appearance options
                signcolumn                   = true,  -- Show signs in the signcolumn
                numhl                        = false, -- Highlight line numbers
                linehl                       = false, -- Highlight the whole line
                word_diff                    = false, -- Show a diff per word
                -- Watch for git changes
                watch_gitdir                 = {
                    follow_files = true, -- Follow files that get moved
                    interval = 1000,     -- Check for changes every 1000ms
                },
                -- Blame settings
                current_line_blame           = false, -- Toggle with keybinding
                current_line_blame_opts      = {
                    virt_text = true,                 -- Show blame info as virtual text
                    virt_text_pos = 'eol',            -- Position at end of line
                    delay = 500,                      -- Delay before showing blame
                    ignore_whitespace = false,
                },
                current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',

                -- Performance settings
                update_debounce              = 100,   -- Update signs every 100ms
                max_file_length              = 40000, -- Don't process large files

                -- Configure keymaps that don't conflict with harpoon
                on_attach                    = function(bufnr)
                    local gs = package.loaded.gitsigns

                    -- Navigation between hunks
                    vim.keymap.set('n', ']g', function()
                        if vim.wo.diff then return ']g' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                    end, { expr = true, buffer = bufnr, desc = "Next git hunk" })

                    vim.keymap.set('n', '[g', function()
                        if vim.wo.diff then return '[g' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                    end, { expr = true, buffer = bufnr, desc = "Previous git hunk" })

                    -- Actions - using <leader>g prefix for Gitsigns operations
                    vim.keymap.set('n', '<leader>gs', gs.stage_hunk,
                        { buffer = bufnr, desc = "Stage hunk" })
                    vim.keymap.set('n', '<leader>gr', gs.reset_hunk,
                        { buffer = bufnr, desc = "Reset hunk" })
                    vim.keymap.set('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
                        { buffer = bufnr, desc = "Stage selected hunks" })
                    vim.keymap.set('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
                        { buffer = bufnr, desc = "Reset selected hunks" })

                    -- Buffer operations
                    vim.keymap.set('n', '<leader>gS', gs.stage_buffer,
                        { buffer = bufnr, desc = "Stage buffer" })
                    vim.keymap.set('n', '<leader>gu', gs.undo_stage_hunk,
                        { buffer = bufnr, desc = "Undo stage hunk" })
                    vim.keymap.set('n', '<leader>gR', gs.reset_buffer,
                        { buffer = bufnr, desc = "Reset buffer" })

                    -- Preview and info
                    vim.keymap.set('n', '<leader>gp', gs.preview_hunk,
                        { buffer = bufnr, desc = "Preview hunk" })
                    vim.keymap.set('n', '<leader>gb', function() gs.blame_line { full = true } end,
                        { buffer = bufnr, desc = "Blame line" })

                    -- Toggle options
                    vim.keymap.set('n', '<leader>gB', gs.toggle_current_line_blame,
                        { buffer = bufnr, desc = "Toggle blame" })
                    vim.keymap.set('n', '<leader>gd', gs.diffthis,
                        { buffer = bufnr, desc = "Diff this" })
                    vim.keymap.set('n', '<leader>gD', function() gs.diffthis('~') end,
                        { buffer = bufnr, desc = "Diff with HEAD" })
                    vim.keymap.set('n', '<leader>gx', gs.toggle_deleted,
                        { buffer = bufnr, desc = "Toggle deleted" })

                    -- Extra toggles for line highlighting
                    vim.keymap.set('n', '<leader>gn', gs.toggle_numhl,
                        { buffer = bufnr, desc = "Toggle number hl" })
                    vim.keymap.set('n', '<leader>gl', gs.toggle_linehl,
                        { buffer = bufnr, desc = "Toggle line hl" })
                    vim.keymap.set('n', '<leader>gw', gs.toggle_word_diff,
                        { buffer = bufnr, desc = "Toggle word diff" })
                end
            })

            -- Set up highlights to make signs more visible
            vim.cmd([[
                highlight GitSignsAdd    guifg=#00ff00 ctermfg=2
                highlight GitSignsChange guifg=#ffff00 ctermfg=3
                highlight GitSignsDelete guifg=#ff0000 ctermfg=1
            ]])
        end
    },

    -- Git worktree for multiple branches/projects
    {
        "ThePrimeagen/git-worktree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        config = function()
            require("git-worktree").setup({
                -- Configuration options
                change_directory_command = "cd",
                update_on_change = true,
                update_on_change_command = "e .",
                clearjumps_on_change = true,
                autopush = false,
            })

            -- Integration with telescope
            require("telescope").load_extension("git_worktree")

            -- Keymaps - telescope integration
            vim.keymap.set("n", "<leader>gwo", function()
                require("telescope").extensions.git_worktree.git_worktrees()
            end, { desc = "List git worktrees" })

            vim.keymap.set("n", "<leader>gwc", function()
                require("telescope").extensions.git_worktree.create_git_worktree()
            end, { desc = "Create git worktree" })
        end
    },

    -- Enhanced diff view for complex changes
    {
        "sindrets/diffview.nvim",
        dependencies = "nvim-lua/plenary.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory" },
        config = function()
            require("diffview").setup({
                -- Enhanced merge tool configuration
                enhanced_diff_hl = true,
                use_icons = true,
                icons = {
                    folder_closed = "",
                    folder_open = "",
                },
                signs = {
                    fold_closed = "",
                    fold_open = "",
                },
            })

            -- Keymaps - using <leader>dv prefix for diff operations
            vim.keymap.set("n", "<leader>dvo", ":DiffviewOpen<CR>",
                { desc = "Open diffview" })
            vim.keymap.set("n", "<leader>dvh", ":DiffviewFileHistory %<CR>",
                { desc = "File history" })
            vim.keymap.set("n", "<leader>dvc", ":DiffviewClose<CR>",
                { desc = "Close diffview" })
        end
    },
}
