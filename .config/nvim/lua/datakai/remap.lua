-- Set Leader key to space

vim.g.mapleader = " "

-- Disable space key default behavior
vim.keymap.set({ "n" }, "<Space>", "<Nop>", { silent = true })
-- mapping to exit using leader key
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<leader>u", ":UndotreeShow<CR>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd('so')
end)

-- Clipboard shortcuts
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Copy line to system clipboard" })
--vim.keymap.set('n', '<leader>zo', ":ObsidianFollowLink<CR>", { desc = "Open Link" })

-- Create a new file in the current directory
vim.keymap.set("n", "<leader>nf", function()
    local dir = vim.fn.expand("%:p:h")
    local filename = vim.fn.input("New file: ", dir .. "/", "file")
    if filename ~= "" then
        vim.cmd("edit " .. filename)
    end
end, { desc = "Create new file in current directory" })

-- Function to move files
vim.keymap.set("n", "<leader>mv", function()
    local current_file = vim.fn.expand("%:p")
    local current_dir = vim.fn.expand("%:p:h")
    local current_name = vim.fn.expand("%:t")
    local new_name = vim.fn.input("Move to: ", current_dir .. "/", "file")

    if new_name ~= "" and new_name ~= current_file then
        -- Check if the new path is a directory
        if vim.fn.isdirectory(new_name) == 1 then
            -- If it's a directory, append the current filename
            if not new_name:match("/$") then
                new_name = new_name .. "/"
            end
            new_name = new_name .. current_name
        end

        -- Save the buffer if it's modified
        if vim.bo.modified then
            vim.cmd("write")
        end

        -- Move the file using vim.loop (libuv) for better error handling
        local ok, err = os.rename(current_file, new_name)

        if ok then
            -- Edit the new file
            vim.cmd("edit " .. vim.fn.fnameescape(new_name))
            vim.notify("File moved to " .. new_name, vim.log.levels.INFO)
        else
            vim.notify("Failed to move file: " .. (err or "Unknown error"), vim.log.levels.ERROR)
        end
    end
end, { desc = "Move current file" })

-- Git account management
local git_account = require("datakai.utils.git_account")
vim.keymap.set("n", "<leader>gi", git_account.init_repo, { desc = "Init Git repo with account" })
vim.keymap.set("n", "<leader>gC", git_account.switch_account, { desc = "Switch Git account" })
vim.keymap.set("n", "<leader>gw", git_account.create_worktree, { desc = "Create Git worktree" })


-- Dotfiles management
local dotfiles = require("datakai.utils.dotfiles")
vim.keymap.set("n", "<leader>ds", dotfiles.status, { desc = "Dotfiles status" })
vim.keymap.set("n", "<leader>da", dotfiles.add_current, { desc = "Dotfiles add current file" })
vim.keymap.set("n", "<leader>dA", dotfiles.add_all, { desc = "Dotfiles add all changes" })
vim.keymap.set("n", "<leader>dc", dotfiles.commit, { desc = "Dotfiles commit" })
vim.keymap.set("n", "<leader>dp", dotfiles.push, { desc = "Dotfiles push" })
vim.keymap.set("n", "<leader>dl", dotfiles.list_files, { desc = "Dotfiles list tracked files" })
