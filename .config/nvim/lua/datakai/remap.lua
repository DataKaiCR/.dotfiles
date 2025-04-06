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

-- Function to move files with dotfiles integration
vim.keymap.set("n", "<leader>mv", function()
    local current_file = vim.fn.expand("%:p")
    local current_dir = vim.fn.expand("%:p:h")
    local current_name = vim.fn.expand("%:t")
    local home_dir = vim.fn.expand("$HOME")
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

        -- Check if this is a dotfile (under home directory)
        local is_dotfile = current_file:find("^" .. home_dir) ~= nil
        local old_relative = is_dotfile and current_file:sub(#home_dir + 2) or nil
        local new_relative = is_dotfile and new_name:sub(#home_dir + 2) or nil

        -- Move the file using os.rename
        local ok, err = os.rename(current_file, new_name)

        if ok then
            -- Update dotfiles tracking if applicable
            if is_dotfile then
                -- Using system commands for git operations
                if old_relative then
                    vim.fn.system("git --git-dir=" ..
                    home_dir .. "/.dotfiles/ --work-tree=" .. home_dir .. " rm " .. vim.fn.shellescape(old_relative))
                end
                if new_relative then
                    vim.fn.system("git --git-dir=" ..
                    home_dir .. "/.dotfiles/ --work-tree=" .. home_dir .. " add " .. vim.fn.shellescape(new_relative))
                    vim.notify("Dotfile moved and tracking updated", vim.log.levels.INFO)
                end
            end

            -- Edit the new file
            vim.cmd("edit " .. vim.fn.fnameescape(new_name))
            vim.notify("File moved to " .. new_name, vim.log.levels.INFO)
        else
            vim.notify("Failed to move file: " .. (err or "Unknown error"), vim.log.levels.ERROR)
        end
    end
end, { desc = "Move current file" })
