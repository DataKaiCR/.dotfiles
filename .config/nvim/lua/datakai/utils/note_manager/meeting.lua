local M = {}

-- Get access to core functions
local core = require("datakai.utils.note_manager.core")

-- Helper to position cursor in Notes section after note creation
local position_cursor_at_notes = function()
    vim.defer_fn(function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        for i, line in ipairs(lines) do
            if line:match("^## Notes") then
                -- Move to line after "## Notes" (skip instruction line)
                local next_line = i + 2
                if lines[next_line] and lines[next_line] == "" then
                    next_line = next_line + 1
                end
                vim.api.nvim_win_set_cursor(0, {next_line, 0})
                vim.cmd("startinsert!")
                break
            end
        end
    end, 300)
end

-- Create meeting note in project-specific meetings folder
M.create_meeting_note = function()
    -- Step 1: List all top-level company/client folders
    local command = "find -L ~/scriptorium/10-projects -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/10-projects' | sort"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    local companies = {}
    for folder in string.gmatch(result, "[^\n]+") do
        local company_name = string.match(folder, "10%-projects/(.+)$")
        if company_name then
            table.insert(companies, company_name)
        end
    end

    if #companies == 0 then
        vim.notify("No companies/clients found in 10-projects/", vim.log.levels.ERROR)
        return
    end

    -- Step 1: Select company/client
    vim.ui.select(companies, {
        prompt = "Select company/client:",
        format_item = function(item)
            return item
        end
    }, function(selected_company)
        if not selected_company then return end

        -- Step 2: List subfolders + option for general meetings
        local sub_command = string.format(
            "find -L ~/scriptorium/10-projects/%s -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/meetings' | sort",
            selected_company
        )
        local sub_handle = io.popen(sub_command)
        local sub_result = sub_handle:read("*a")
        sub_handle:close()

        local options = { "General " .. selected_company .. " meetings" }
        for folder in string.gmatch(sub_result, "[^\n]+") do
            local project_name = string.match(folder, selected_company .. "/(.+)$")
            if project_name then
                table.insert(options, project_name)
            end
        end

        vim.ui.select(options, {
            prompt = "Select project or general meetings:",
            format_item = function(item)
                return item
            end
        }, function(selected_option)
            if not selected_option then return end

            local title = vim.fn.input("Meeting title: ")
            if title == "" then return end

            local meetings_path
            local project_context
            if selected_option:match("^General") then
                -- General company meetings
                meetings_path = "10-projects/" .. selected_company .. "/meetings"
                project_context = selected_company
            else
                -- Specific project meetings
                meetings_path = "10-projects/" .. selected_company .. "/" .. selected_option .. "/meetings"
                project_context = selected_company .. "/" .. selected_option
            end

            -- Ensure meetings subfolder exists
            local full_path = vim.fn.expand("~/scriptorium/" .. meetings_path)
            vim.fn.mkdir(full_path, "p")

            -- Set note type
            vim.g.current_note_type = "meeting"

            -- Create meeting note
            local cmd = string.format("ObsidianNew %s/%s", meetings_path, title)
            vim.cmd(cmd)

            core.process_note_after_creation(title, meetings_path, "meeting", project_context)
            position_cursor_at_notes()
        end)
    end)
end

return M
