local M = {}

-- Get access to core functions
local core = require("datakai.utils.note_manager.core")

-- Extract project metadata from folder path
-- Handles company → project hierarchy
M.extract_project_info = function(folder_path)
    local result = {
        employer = "",
        project = "",
        scope = "personal"
    }

    if folder_path:match("^10%-projects") then
        -- Remove the base path prefix if present
        local cleaned_path = folder_path:gsub("^10%-projects//home/[^/]+/second%-brain/10%-projects/", "")
        cleaned_path = cleaned_path:gsub("^10%-projects/", "")

        -- Remove notes/ or meetings/ suffix if present
        cleaned_path = cleaned_path:gsub("/notes$", "")
        cleaned_path = cleaned_path:gsub("/meetings$", "")

        -- Split path into segments
        local segments = {}
        for segment in cleaned_path:gmatch("[^/]+") do
            table.insert(segments, segment)
        end

        if #segments == 0 then
            return result
        end

        -- First segment is always company/employer
        local company = segments[1]

        -- Check if it's personal
        if company == "personal" then
            result.scope = "personal"
            if #segments > 1 then
                result.project = segments[#segments]
            else
                result.project = "personal"
            end
        else
            -- Client/company work
            result.employer = company
            result.scope = "client"

            if #segments == 1 then
                -- Just company, no specific project
                result.project = company
            else
                -- Has subproject: company/project
                result.project = company .. "/" .. segments[#segments]
            end
        end
    end

    return result
end

-- Update project-specific information
M.update_project_info = function(folder_path)
    local project_info = M.extract_project_info(folder_path)
    if project_info.project ~= "" then
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local in_frontmatter = false
        local tags_line_index = nil

        for i, line in ipairs(lines) do
            -- Track if we're in frontmatter
            if line == "---" then
                in_frontmatter = not in_frontmatter
            end

            if in_frontmatter then
                -- Update project field
                if line:match("^project:") then
                    lines[i] = "project: " .. project_info.project
                -- Update employer field
                elseif line:match("^employer:") then
                    lines[i] = "employer: " .. project_info.employer
                -- Track tags line for scope update
                elseif line:match("^tags:") then
                    tags_line_index = i
                end
            end
        end

        -- Update the buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

        -- Update tags to include scope if we found a tags line
        if tags_line_index then
            local tags_line = vim.api.nvim_buf_get_lines(0, tags_line_index - 1, tags_line_index, false)[1]
            if not tags_line:match("scope/" .. project_info.scope) then
                local new_tags_line

                if tags_line:match("%[%]") then
                    -- Empty tags array
                    new_tags_line = tags_line:gsub("%[%]", "[scope/" .. project_info.scope .. "]")
                elseif tags_line:match("%]$") then
                    -- Tags array with existing tags
                    new_tags_line = tags_line:gsub("%]$", ", scope/" .. project_info.scope .. "]")
                else
                    -- No brackets, just append
                    new_tags_line = tags_line .. " [scope/" .. project_info.scope .. "]"
                end

                vim.api.nvim_buf_set_lines(0, tags_line_index - 1, tags_line_index, false, { new_tags_line })
            end
        end
    end
end

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

-- Create project work note in company → project → notes/ hierarchy
M.create_project_note = function()
    -- Step 1: List all top-level company folders
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
        vim.notify("No companies found in 10-projects/", vim.log.levels.ERROR)
        return
    end

    -- Step 1: Select company
    vim.ui.select(companies, {
        prompt = "Select company:",
        format_item = function(item)
            return item
        end
    }, function(selected_company)
        if not selected_company then return end

        -- Step 2: List projects in that company (exclude notes/ and meetings/ folders)
        local sub_command = string.format(
            "find -L ~/scriptorium/10-projects/%s -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/notes' -not -path '*/meetings' | sort",
            selected_company
        )
        local sub_handle = io.popen(sub_command)
        local sub_result = sub_handle:read("*a")
        sub_handle:close()

        local projects = {}
        for folder in string.gmatch(sub_result, "[^\n]+") do
            local project_name = string.match(folder, selected_company .. "/(.+)$")
            if project_name then
                table.insert(projects, project_name)
            end
        end

        -- If no subprojects, this IS the project
        if #projects == 0 then
            local title = vim.fn.input("Work note title: ")
            if title == "" then return end

            local notes_path = "10-projects/" .. selected_company .. "/notes"
            local full_path = vim.fn.expand("~/scriptorium/" .. notes_path)
            vim.fn.mkdir(full_path, "p")

            vim.g.current_note_type = "project"

            local cmd = string.format("ObsidianNew %s/%s", notes_path, title)
            vim.cmd(cmd)

            core.process_note_after_creation(title, notes_path, "project", selected_company)
            position_cursor_at_notes()
            return
        end

        -- Show project selection
        vim.ui.select(projects, {
            prompt = "Select project:",
            format_item = function(item)
                return item
            end
        }, function(selected_project)
            if not selected_project then return end

            local title = vim.fn.input("Work note title: ")
            if title == "" then return end

            local notes_path = "10-projects/" .. selected_company .. "/" .. selected_project .. "/notes"
            local full_path = vim.fn.expand("~/scriptorium/" .. notes_path)
            vim.fn.mkdir(full_path, "p")

            vim.g.current_note_type = "project"

            local cmd = string.format("ObsidianNew %s/%s", notes_path, title)
            vim.cmd(cmd)

            core.process_note_after_creation(title, notes_path, "project", selected_company .. "/" .. selected_project)
            position_cursor_at_notes()
        end)
    end)
end

return M
