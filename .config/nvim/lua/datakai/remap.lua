-- Set Leader key to space

vim.g.mapleader = " "

-- Disable space key default behavior
vim.keymap.set({"n"}, "<Space>", "<Nop>", { silent = true })
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

-- Quick note creation
-- vim.keymap.set('n', '<leader>zn', ":ObsidianNew<CR>", { desc = "New Zettel" })
-- Search notes
-- vim.keymap.set('n', '<leader>zf', ":ObsidianSearch<CR>", { desc = "Find Zettels" })
-- Open daily note
-- vim.keymap.set('n', '<leader>zt', ":ObsidianToday<CR>", { desc = "Today's Note" })
-- Follow link under cursor-- 

-- Clipboard shortcuts
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set({"n", "v"}, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
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

-- Add to your remap.lua file or create a new file for custom functions
-- Function to find and open any note in the vault
vim.keymap.set("n", "<leader>zf", function()
    require("telescope.builtin").find_files({
        prompt_title = "Find Notes",
        cwd = "~/second-brain",
        file_ignore_patterns = {"%.jpg", "%.png"},
        find_command = { "fd", "--type", "f", "--extension", "md" },
    })
end, { desc = "Find notes in vault" })

-- Function to grep content across all notes
vim.keymap.set("n", "<leader>zg", function()
    require("telescope.builtin").live_grep({
        prompt_title = "Search Notes Content",
        cwd = "~/second-brain",
        file_ignore_patterns = {"%.jpg", "%.png"},
    })
end, { desc = "Search notes content" })

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
