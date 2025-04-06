-- Module to organize all Obsidian-related keymaps in one place

local M = {}

-- Function to initialize Obsidian if it hasn't been loaded yet
M.init_obsidian = function()
    local ok, obsidian = pcall(require, "obsidian")
    if not ok then
        vim.notify("Obsidian plugin not available - trying to load it", vim.log.levels.WARN)

        -- Try to load lazy.nvim and load obsidian
        local lazy_ok, lazy = pcall(require, "lazy")
        if lazy_ok then
            -- Force load obsidian plugin
            lazy.load({ plugins = { "obsidian.nvim" } })

            -- Check if it's now available
            ok, obsidian = pcall(require, "obsidian")
            if not ok then
                vim.notify("Failed to load Obsidian plugin", vim.log.levels.ERROR)
                return false
            end
        else
            vim.notify("Lazy plugin manager not available", vim.log.levels.ERROR)
            return false
        end
    end

    return true
end

-- Function to setup all Obsidian-related keymaps
M.setup = function()
    -- Make sure obsidian is loaded
    if not M.init_obsidian() then
        vim.notify("Couldn't set up Obsidian keymaps - plugin not available", vim.log.levels.ERROR)
        return
    end

    local note_manager = require("datakai.utils.note_manager")

    -- Note creation keymaps
    vim.keymap.set("n", "<leader>zn", function()
        note_manager.create_note({
            base_folder = "00-inbox",
            prompt_title = "Select folder:",
            note_type = "note"
        })
    end, { desc = "Create new note in inbox" })

    vim.keymap.set("n", "<leader>zq", function()
        note_manager.create_quick_note()
    end, { desc = "Create quick note directly in inbox" })

    vim.keymap.set("n", "<leader>zp", function()
        note_manager.create_note({
            base_folder = "10-projects",
            prompt_title = "Select project folder:",
            note_type = "project",
            template_name = "project"
        })
    end, { desc = "Create note in Projects folder" })

    vim.keymap.set("n", "<leader>za", function()
        note_manager.create_note({
            base_folder = "20-areas",
            prompt_title = "Select area folder:",
            note_type = "area",
            template_name = "area"
        })
    end, { desc = "Create note in Areas folder" })

    vim.keymap.set("n", "<leader>zr", function()
        note_manager.create_note({
            base_folder = "30-resources",
            prompt_title = "Select resource folder:",
            note_type = "resource",
            template_name = "resource"
        })
    end, { desc = "Create note in Resources folder" })

    vim.keymap.set("n", "<leader>zv", function()
        note_manager.create_note({
            base_folder = "40-archive",
            prompt_title = "Select archive folder:",
            note_type = "archive",
            template_name = "archive"
        })
    end, { desc = "Create note in Archive folder" })

    vim.keymap.set("n", "<leader>zz", function()
        note_manager.create_note({
            base_folder = "50-zettelkasten",
            prompt_title = "Select zettelkasten folder:",
            note_type = "zettel",
            template_name = "zettelkasten"
        })
    end, { desc = "Create Zettelkasten note" })

    vim.keymap.set("n", "<leader>zd", function()
        note_manager.create_daily_note()
    end, { desc = "Create/open daily note" })

    vim.keymap.set("n", "<leader>zi", function()
        note_manager.create_io_note("input")
    end, { desc = "Create input note" })

    vim.keymap.set("n", "<leader>zO", function()
        note_manager.create_io_note("output")
    end, { desc = "Create output note" })

    -- Navigation and utility keymaps
    vim.keymap.set("n", "<leader>zo", function()
        vim.cmd("ObsidianFollowLink")
    end, { desc = "Open/follow link" })

    vim.keymap.set("n", "<leader>zt", function()
        vim.cmd("ObsidianTemplate")
    end, { desc = "Insert template" })

    vim.keymap.set("n", "<leader>zs", function()
        vim.cmd("ObsidianSearch")
    end, { desc = "Search in vault" })

    -- Search keymaps (moved from remap.lua)
    vim.keymap.set("n", "<leader>zf", function()
        require("telescope.builtin").find_files({
            prompt_title = "Find Notes",
            cwd = "~/second-brain",
            file_ignore_patterns = { "%.jpg", "%.png" },
            find_command = { "fd", "--type", "f", "--extension", "md" },
        })
    end, { desc = "Find notes in vault" })

    vim.keymap.set("n", "<leader>zg", function()
        require("telescope.builtin").live_grep({
            prompt_title = "Search Notes Content",
            cwd = "~/second-brain",
            file_ignore_patterns = { "%.jpg", "%.png" },
        })
    end, { desc = "Search notes content" })
    -- Reload command
    vim.keymap.set("n", "<leader>zR", function()
        M.init_obsidian()
        vim.notify("Obsidian functionality reloaded", vim.log.levels.INFO)
    end, { desc = "Reload Obsidian functionality" })
end

return M
