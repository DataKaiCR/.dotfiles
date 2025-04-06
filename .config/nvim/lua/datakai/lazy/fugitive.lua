-- Enhanced Fugitive configuration
return {
    'tpope/vim-fugitive',
    event = "VeryLazy", -- Load when needed
    config = function()
        -- Use <leader>fg prefix for fugitive commands to avoid conflicts
        -- with gitsigns' <leader>gs and other mappings

        -- Main fugitive status window
        vim.keymap.set("n", "<leader>fg", vim.cmd.Git, { desc = "Fugitive: Git status" })

        -- Git operations
        vim.keymap.set("n", "<leader>fgb", ":Git blame<CR>", { desc = "Fugitive: Git blame" })
        vim.keymap.set("n", "<leader>fga", ":Git add %<CR>", { desc = "Fugitive: Git add current file" })
        vim.keymap.set("n", "<leader>fgA", ":Git add .<CR>", { desc = "Fugitive: Git add all" })
        vim.keymap.set("n", "<leader>fgc", ":Git commit<CR>", { desc = "Fugitive: Git commit" })
        vim.keymap.set("n", "<leader>fgp", ":Git push<CR>", { desc = "Fugitive: Git push" })
        vim.keymap.set("n", "<leader>fgl", ":Git pull<CR>", { desc = "Fugitive: Git pull" })

        -- Diff operations
        vim.keymap.set("n", "<leader>fgd", ":Gdiff<CR>", { desc = "Fugitive: Git diff" })
        vim.keymap.set("n", "<leader>fgD", ":Gdiffsplit!<CR>", { desc = "Fugitive: Git diff split" })
        vim.keymap.set("n", "<leader>fgm", ":GMove<CR>", { desc = "Fugitive: Git move" })

        -- Log/history
        vim.keymap.set("n", "<leader>fgh", ":0Gclog<CR>", { desc = "Fugitive: Git file history" })
        vim.keymap.set("n", "<leader>fgH", ":GcLog<CR>", { desc = "Fugitive: Git commit history" })

        -- Add some useful autocmds for fugitive buffers
        local fugitive_group = vim.api.nvim_create_augroup("FugitiveConfig", { clear = true })

        -- Set up Fugitive buffer-specific mappings
        vim.api.nvim_create_autocmd("FileType", {
            group = fugitive_group,
            pattern = { "fugitive", "git" },
            callback = function()
                -- Local mappings in fugitive buffers
                vim.keymap.set("n", "cc", ":Git commit<CR>", { buffer = true, desc = "Create commit" })
                vim.keymap.set("n", "ca", ":Git commit --amend<CR>", { buffer = true, desc = "Amend commit" })
                vim.keymap.set("n", "p", ":Git push<CR>", { buffer = true, desc = "Push" })
                vim.keymap.set("n", "q", ":close<CR>", { buffer = true, desc = "Close" })

                -- Set a more readable width for the commit message buffer
                if vim.bo.filetype == "gitcommit" then
                    vim.opt_local.textwidth = 72
                    vim.opt_local.colorcolumn = "72"
                    vim.opt_local.spell = true
                end
            end
        })

        -- Help for common fugitive commands in the status buffer
        vim.api.nvim_create_autocmd("BufEnter", {
            group = fugitive_group,
            pattern = "fugitive://*",
            callback = function()
                -- Add a reminder of common commands at the top of the buffer
                local help_text = {
                    "Fugitive Commands:",
                    "s: Stage file/hunk    u: Unstage file/hunk    =: Toggle inline diff",
                    "cc: Commit            ca: Amend commit        p: Push",
                    "dv: Vertical diff     dh: Horizontal diff     q: Close"
                }

                -- Don't add if buffer is empty or already has help
                local line1 = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
                if not line1 or not line1:match("^Fugitive Commands") then
                    if vim.api.nvim_buf_line_count(0) > 0 then
                        vim.api.nvim_buf_set_lines(0, 0, 0, false, help_text)
                    end
                end
            end,
            once = false
        })
    end
}
