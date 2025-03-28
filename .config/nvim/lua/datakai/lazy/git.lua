return {
    -- Core Git commands
    {
        "tpope/vim-fugitive",
        config = function()
            vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
            vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })
            vim.keymap.set("n", "<leader>ga", ":Git add %<CR>", { desc = "Git add current file" })
            vim.keymap.set("n", "<leader>gA", ":Git add .<CR>", { desc = "Git add all files" })
            vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
            vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
            vim.keymap.set("n", "<leader>gl", ":Git pull<CR>", { desc = "Git pull" })
        end
    },

    -- Git signs in the gutter
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = '│' },
                    change       = { text = '│' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns

                    -- Navigation
                    vim.keymap.set('n', ']c', function()
                        if vim.wo.diff then return ']c' end
                        vim.schedule(function() gs.next_hunk() end)
                        return '<Ignore>'
                    end, { expr = true, buffer = bufnr })

                    vim.keymap.set('n', '[c', function()
                        if vim.wo.diff then return '[c' end
                        vim.schedule(function() gs.prev_hunk() end)
                        return '<Ignore>'
                    end, { expr = true, buffer = bufnr })

                    -- Actions
                    vim.keymap.set('n', '<leader>hs', gs.stage_hunk, { desc = "Stage hunk", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hr', gs.reset_hunk, { desc = "Reset hunk", buffer = bufnr })
                    vim.keymap.set('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
                        { desc = "Stage selected hunks", buffer = bufnr })
                    vim.keymap.set('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
                        { desc = "Reset selected hunks", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hS', gs.stage_buffer, { desc = "Stage buffer", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, { desc = "Undo stage hunk", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hR', gs.reset_buffer, { desc = "Reset buffer", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { desc = "Preview hunk", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hb', function() gs.blame_line { full = true } end,
                        { desc = "Blame line", buffer = bufnr })
                    vim.keymap.set('n', '<leader>tb', gs.toggle_current_line_blame,
                        { desc = "Toggle blame", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hd', gs.diffthis, { desc = "Diff this", buffer = bufnr })
                    vim.keymap.set('n', '<leader>hD', function() gs.diffthis('~') end,
                        { desc = "Diff with HEAD", buffer = bufnr })
                    vim.keymap.set('n', '<leader>td', gs.toggle_deleted, { desc = "Toggle deleted", buffer = bufnr })
                end
            })
        end
    },

    -- Git worktree for multiple clients/projects
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

            require("telescope").load_extension("git_worktree")

            -- Keymaps
            vim.keymap.set("n", "<leader>wt", function()
                require("telescope").extensions.git_worktree.git_worktrees()
            end, { desc = "Manage worktrees" })

            vim.keymap.set("n", "<leader>wc", function()
                require("telescope").extensions.git_worktree.create_git_worktree()
            end, { desc = "Create worktree" })
        end
    },

    -- Diff view for merge conflicts and complex diffs
    {
        "sindrets/diffview.nvim",
        dependencies = "nvim-lua/plenary.nvim",
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

            -- Keymaps
            vim.keymap.set("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "Open diffview" })
            vim.keymap.set("n", "<leader>dh", ":DiffviewFileHistory %<CR>", { desc = "File history" })
            vim.keymap.set("n", "<leader>df", ":DiffviewClose<CR>", { desc = "Close diffview" })
        end
    },
}
