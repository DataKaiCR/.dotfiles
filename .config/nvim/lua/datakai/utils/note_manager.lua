-- note_manager.lua - Utilities for managing Obsidian notes

local M = {}

-- Extract project name from folder path
M.extract_project_info = function(folder_path)
    local result = {
        name = "",
        scope = "internal"
    }

    if folder_path:match("^10%-projects") then
        -- Remove the base path prefix if present
        local cleaned_path = folder_path:gsub("^10%-projects//home/[^/]+/second%-brain/10%-projects/", "")
        cleaned_path = cleaned_path:gsub("^10%-projects/", "")

        -- Check if it's in the internal folder
        if cleaned_path:match("^internal/") then
            -- For internal projects, use the last segment as the project name
            local segments = {}
            for segment in cleaned_path:gmatch("[^/]+") do
                table.insert(segments, segment)
            end

            if #segments > 1 then
                result.name = segments[#segments] -- Use the last segment
            else
                result.name = cleaned_path:gsub("^internal/", "")
            end
            result.scope = "internal"
        else
            -- For client projects, use client/project format
            local segments = {}
            for segment in cleaned_path:gmatch("[^/]+") do
                table.insert(segments, segment)
            end

            if #segments == 1 then
                -- Just the client name (e.g., "trulieve")
                result.name = segments[1]
            else
                -- Client and project (e.g., "trulieve/msk")
                result.name = segments[1] .. "/" .. segments[#segments]
            end
            result.scope = "client"
        end
    end

    return result
end

-- Update project-specific information
M.update_project_info = function(folder_path)
    local project_info = M.extract_project_info(folder_path)
    if project_info.name ~= "" then
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local updated_lines = {}
        local in_frontmatter = false
        local project_found = false
        local scope_found = false
        local tags_line_index = nil

        for i, line in ipairs(lines) do
            -- Track if we're in frontmatter
            if line == "---" then
                in_frontmatter = not in_frontmatter
            end

            -- Update project field
            if in_frontmatter and line:match("^project:") then
                updated_lines[i] = "project: " .. project_info.name
                project_found = true
                -- Update scope field
            elseif in_frontmatter and line:match("^scope:") then
                updated_lines[i] = "scope: " .. project_info.scope
                scope_found = true
                -- Track tags line for later update
            elseif in_frontmatter and line:match("^tags:") then
                tags_line_index = i
            else
                updated_lines[i] = line
            end
        end

        -- Update the actual buffer
        for i, line in pairs(updated_lines) do
            if lines[i] ~= line then
                vim.api.nvim_buf_set_lines(0, i - 1, i, false, { line })
            end
        end

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

-- Main function for creating notes in folders
M.create_note_in_folder = function(base_folder, prompt_title, template_name)
    -- Make sure we have an editable buffer
    if vim.bo.modifiable == false then
        vim.cmd("enew") -- Create a new empty buffer
    end

    -- List all subdirectories - but use realpath to resolve symlinks
    local command = string.format("find -L ~/second-brain/%s -type d -not -path '*/\\.*' | sort", base_folder)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Parse results into a table - use the original paths for consistency with Obsidian
    local folders = { base_folder } -- Add the root folder as first option
    for folder in string.gmatch(result, "[^\n]+") do
        -- Extract relative path in the standard format
        local folder_name = string.match(folder, "second%-brain/(.+)$")
        if folder_name and folder_name ~= base_folder then
            table.insert(folders, folder_name)
        end
    end

    -- Present folders as selection menu
    vim.ui.select(folders, {
        prompt = prompt_title or "Select folder:",
        format_item = function(item)
            -- Clean up the display of folders
            if type(item) == "string" then
                return item:gsub("//home/[^/]+/second%-brain/", "/"):gsub("^/mnt/c/Users/[^/]+/second%-brain/", "/")
            else
                return tostring(item)
            end
        end
    }, function(selected)
        if selected then
            local title = vim.fn.input("Note title: ")
            if title ~= "" then
                -- Create new note with obsidian - use path relative to vault
                local obsidian_path = selected
                if obsidian_path:match("^/") then
                    -- Extract the part after second-brain/
                    obsidian_path = obsidian_path:match("second%-brain/(.+)$") or obsidian_path
                end

                local cmd = string.format("ObsidianNew %s/%s", obsidian_path, title)
                vim.cmd(cmd)

                -- Apply template if provided
                if template_name then
                    vim.defer_fn(function()
                        -- Apply template (this overwrites everything)
                        vim.cmd("ObsidianTemplate " .. template_name)

                        -- Update the title in both frontmatter and heading
                        vim.defer_fn(function()
                            -- Generate ID in the same format as note_id_func
                            local timestamp = os.date("%Y%m%d%H%M%S")
                            local date = os.date("%Y-%m-%d")
                            local time = os.date("%H:%M:%S")
                            local tz = os.date("%z")
                            local month = os.date("%B") -- Full month name (e.g., "March")
                            local day = os.date("%d")   -- Day of month (e.g., "26")
                            local year = os.date("%Y")  -- Four-digit year (e.g., "2025")
                            local formatted_created = date .. ":" .. time .. " " .. tz

                            -- Replace all placeholders
                            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            for i, line in ipairs(lines) do
                                lines[i] = line:gsub("{{title}}", title)
                                    :gsub("{{date}}", date)
                                    :gsub("{{time}}", time)
                                    :gsub("{{id}}", timestamp)
                                    :gsub("{{date}} {{time}}", formatted_created)
                                    :gsub("{{tz}}", tz)
                                    :gsub("{{month}}", month)
                                    :gsub("{{day}}", day)
                                    :gsub("{{year}}", year)
                            end
                            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

                            -- Remove any duplicate title headers or headers before frontmatter
                            local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                            local final_content = {}
                            local in_frontmatter = false
                            local frontmatter_started = false
                            local frontmatter_ended = false
                            local title_found = false

                            for i, line in ipairs(content) do
                                -- Track frontmatter bounds
                                if line == "---" then
                                    if not frontmatter_started then
                                        frontmatter_started = true
                                        in_frontmatter = true
                                    else
                                        frontmatter_ended = true
                                        in_frontmatter = false
                                    end
                                    table.insert(final_content, line)
                                elseif line:match("^# " .. title .. "$") then
                                    -- Skip title headers before frontmatter
                                    if frontmatter_ended and not title_found then
                                        title_found = true
                                        table.insert(final_content, line)
                                    end
                                    -- Skip duplicate title headers
                                else
                                    table.insert(final_content, line)
                                end
                            end

                            -- Only update if we found and removed duplicates
                            if #final_content ~= #content then
                                vim.api.nvim_buf_set_lines(0, 0, -1, false, final_content)
                            end

                            -- If it's a project folder, update project info
                            if obsidian_path:match("^10%-projects") or selected:match("^10%-projects") then
                                -- Use the path for project info extraction
                                local project_path = obsidian_path:match("^10%-projects") and obsidian_path or selected
                                M.update_project_info(project_path)
                            end
                        end, 100)
                    end, 100)
                end
            end
        end
    end)
end

return M
