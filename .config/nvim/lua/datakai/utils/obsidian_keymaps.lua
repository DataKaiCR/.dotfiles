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
    vim.keymap.set("n", "<leader>zp", function()
        note_manager.create_project_note()
    end, { desc = "Create project work note" })

    vim.keymap.set("n", "<leader>za", function()
        note_manager.create_note({
            base_folder = "20-areas",
            prompt_title = "Select area folder:",
            note_type = "area",
            template_name = "area"
        })
    end, { desc = "Create note in Areas folder" })

    vim.keymap.set("n", "<leader>zz", function()
        note_manager.create_zettel()
    end, { desc = "Create Zettel" })

    vim.keymap.set("n", "<leader>zd", function()
        note_manager.create_daily_note()
    end, { desc = "Create/open daily note" })

    vim.keymap.set("n", "<leader>zm", function()
        note_manager.create_meeting_note()
    end, { desc = "Create meeting note" })

    -- Quick capture to inbox
    vim.keymap.set("n", "<leader>zc", function()
        note_manager.capture_to_inbox()
    end, { desc = "Quick capture to inbox" })

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
            cwd = "~/scriptorium",
            file_ignore_patterns = { "%.jpg", "%.png" },
            find_command = { "fd", "--type", "f", "--extension", "md" },
        })
    end, { desc = "Find notes in vault" })

    vim.keymap.set("n", "<leader>zg", function()
        require("telescope.builtin").live_grep({
            prompt_title = "Search Notes Content",
            cwd = "~/scriptorium",
            file_ignore_patterns = { "%.jpg", "%.png" },
        })
    end, { desc = "Search notes content" })
    -- Enhanced workflow keymaps
    vim.keymap.set("n", "<leader>zl", function()
        require('telescope.builtin').find_files({
            cwd = vim.fn.expand('~/scriptorium/zettelkasten'),
            prompt_title = 'Link to Zettel',
            attach_mappings = function(_, map)
                map('i', '<CR>', function(prompt_bufnr)
                    local selection = require('telescope.actions.state').get_selected_entry()
                    if selection then
                        local filename = selection.value:match('([^/]+)%.md$')
                        local link = '[[' .. filename .. ']]'
                        vim.api.nvim_put({link}, 'c', true, true)
                        require('telescope.actions').close(prompt_bufnr)
                    end
                end)
                return true
            end
        })
    end, { desc = 'Insert Zettel Link' })

    vim.keymap.set("n", "<leader>zP", function()
        note_manager.process_inbox_line()
    end, { desc = 'Process Inbox Line' })

    -- Removed: <leader>zc (capture_with_context) - conflicts with inbox capture
    -- Old function wrote to daily journal directly
    -- New <leader>zc defined above: opens inbox capture.md

    vim.keymap.set("n", "<leader>zw", function()
        note_manager.weekly_review()
    end, { desc = 'Weekly Review' })

    vim.keymap.set("n", "<leader>zC", function()
        require('telescope.builtin').live_grep({
            cwd = vim.fn.expand('~/scriptorium'),
            prompt_title = 'Search with Context',
            additional_args = { '--context=2' }
        })
    end, { desc = 'Search Notes with Context' })

    -- AI workflow keymaps
    vim.keymap.set("n", "<leader>zE", function()
        vim.cmd('!cd ~/scriptorium && ./scripts/ai_workflow.sh export-rag')
    end, { desc = 'Export notes for RAG' })

    vim.keymap.set("n", "<leader>zT", function()
        vim.cmd('!cd ~/scriptorium && ./scripts/ai_workflow.sh list-tags')
    end, { desc = 'List most common tags' })

    vim.keymap.set("n", "<leader>zS", function()
        vim.cmd('!cd ~/scriptorium && ./scripts/ai_workflow.sh stats')
    end, { desc = 'Show scriptorium statistics' })

    vim.keymap.set("n", "<leader>zB", function()
        vim.cmd('!cd ~/scriptorium && ./scripts/ai_workflow.sh backup')
    end, { desc = 'Backup scriptorium' })

    -- Reload command
    vim.keymap.set("n", "<leader>zR", function()
        M.init_obsidian()
        vim.notify("Obsidian functionality reloaded", vim.log.levels.INFO)
    end, { desc = "Reload Obsidian functionality" })
end

return M
