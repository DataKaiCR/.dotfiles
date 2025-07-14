-- git_dotfiles_keymaps.lua - Dedicated keymaps for git and dotfiles management
-- This module should be required from your init.lua

local M = {}

-- Setup function to initialize all keymaps
M.setup = function()
    -- Load necessary modules
    local dotfiles = require("datakai.utils.dotfiles")
    local git_account = require("datakai.utils.git_account")
    local git_helpers = require("datakai.utils.git_helpers")

    -- Dotfiles keymaps with descriptions
    vim.keymap.set("n", "<leader>ds", dotfiles.status, { desc = "Dotfiles status" })
    vim.keymap.set("n", "<leader>da", dotfiles.add_current, { desc = "Dotfiles add current file" })
    vim.keymap.set("n", "<leader>dA", dotfiles.add_all, { desc = "Dotfiles add all changes" })
    vim.keymap.set("n", "<leader>dr", dotfiles.remove_file, { desc = "Dotfiles remove file" })
    vim.keymap.set("n", "<leader>dc", dotfiles.commit, { desc = "Dotfiles commit" })
    vim.keymap.set("n", "<leader>dp", dotfiles.push, { desc = "Dotfiles push" })
    vim.keymap.set("n", "<leader>dl", dotfiles.pull, { desc = "Dotfiles pull" })

    -- Git account management - uses ga prefix
    vim.keymap.set("n", "<leader>gas", git_account.switch_account, { desc = "Switch Git account" })
    vim.keymap.set("n", "<leader>gal", git_account.list_accounts, { desc = "List Git accounts" })
    vim.keymap.set("n", "<leader>gaa", git_account.add_account, { desc = "Add Git account" })
    vim.keymap.set("n", "<leader>gar", git_account.remove_account, { desc = "Remove Git account" })
    vim.keymap.set("n", "<leader>gah", git_account.list_ssh_hosts, { desc = "List SSH hosts" })
    vim.keymap.set("n", "<leader>gae", git_account.edit_ssh_config, { desc = "Edit SSH config" })

    -- Git repository and worktree management
    vim.keymap.set("n", "<leader>gai", git_account.init_repo, { desc = "Init Git repo with account" })
    vim.keymap.set("n", "<leader>gaw", git_account.create_worktree, { desc = "Create Git worktree" })
    vim.keymap.set("n", "<leader>gaW", git_account.list_worktrees, { desc = "List Git worktrees" })

    -- Additional git helpers
    vim.keymap.set("n", "<leader>gI", function()
        local pattern = vim.fn.input("Pattern to ignore: ")
        if pattern ~= "" then
            git_helpers.add_to_gitignore(pattern)
        end
    end, { desc = "Add to .gitignore" })

    -- Create Git hook
    vim.keymap.set("n", "<leader>gh", function()
        -- Select hook type
        local hooks = {
            "pre-commit", "prepare-commit-msg", "commit-msg", "post-commit",
            "pre-push", "post-checkout", "pre-rebase", "post-merge"
        }

        vim.ui.select(hooks, {
            prompt = "Select hook type:"
        }, function(hook_name)
            if not hook_name then return end

            -- Create a new buffer for editing the hook
            vim.cmd("enew")
            vim.bo.filetype = "sh"
            vim.bo.buftype = "acwrite"

            -- Add shebang and comments
            local lines = {
                "#!/bin/sh",
                "#",
                "# Git hook: " .. hook_name,
                "# Created: " .. os.date("%Y-%m-%d %H:%M:%S"),
                "#",
                "",
                "# Example " .. hook_name .. " hook",
                "# Exit non-zero to abort the operation",
                "",
            }

            -- Add default content based on hook type
            if hook_name == "pre-commit" then
                vim.list_extend(lines, {
                    "# Prevent committing to main/master branch",
                    "branch=\"$(git rev-parse --abbrev-ref HEAD)\"",
                    "if [ \"$branch\" = \"main\" ] || [ \"$branch\" = \"master\" ]; then",
                    "  echo \"You can't commit directly to $branch branch\"",
                    "  exit 1",
                    "fi",
                    ""
                })
            elseif hook_name == "commit-msg" then
                vim.list_extend(lines, {
                    "# Check commit message format",
                    "commit_msg_file=$1",
                    "commit_msg=$(cat \"$commit_msg_file\")",
                    "",
                    "# Check first line length",
                    "first_line=$(head -n 1 \"$commit_msg_file\")",
                    "if [ ${#first_line} -gt 72 ]; then",
                    "  echo \"Commit message first line too long (max 72 chars)\"",
                    "  exit 1",
                    "fi",
                    ""
                })
            end

            -- Set the buffer content
            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

            -- Name the buffer
            vim.api.nvim_buf_set_name(0, hook_name .. ".sh")

            -- Add custom command to save the hook
            vim.api.nvim_create_autocmd("BufWriteCmd", {
                buffer = 0,
                callback = function()
                    local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
                    if git_helpers.create_git_hook(hook_name, content) then
                        vim.bo.modified = false
                        vim.notify("Saved and activated " .. hook_name .. " hook", vim.log.levels.INFO)
                    end
                    return true
                end
            })

            vim.notify("Editing " .. hook_name .. " hook - save to activate", vim.log.levels.INFO)
        end)
    end, { desc = "Create Git hook" })
end

-- Call setup immediately
M.setup()

return M
