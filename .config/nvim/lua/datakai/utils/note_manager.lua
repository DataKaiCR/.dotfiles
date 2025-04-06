local M = {}

-- Extract project name from folder path
-- Change 'internal' to 'personal' for better long-term naming
M.extract_project_info = function(folder_path)
    local result = {
        name = "",
        scope = "personal" -- Changed from 'internal' to 'personal'
    }

    if folder_path:match("^10%-projects") then
        -- Remove the base path prefix if present
        local cleaned_path = folder_path:gsub("^10%-projects//home/[^/]+/second%-brain/10%-projects/", "")
        cleaned_path = cleaned_path:gsub("^10%-projects/", "")

        -- Check if it's in the personal folder (formerly internal)
        if cleaned_path:match("^personal") then
            -- For personal projects, use the last segment as the project name
            local segments = {}
            for segment in cleaned_path:gmatch("[^/]+") do
                table.insert(segments, segment)
            end

            if #segments > 1 then
                result.name = segments[#segments] -- Use the last segment
            else
                result.name = "personal"          -- Just use "personal" if there's no subfolder
            end
            result.scope = "personal"
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

-- Function to ensure frontmatter comes first and fix duplicate headers
M.fix_note_format = function(title)
    -- Get all lines in the current buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local final_content = {}
    local frontmatter_start = nil
    local frontmatter_end = nil
    local has_title_header = false
    local title_pattern = "^# " .. vim.fn.escape(title, "%-().+*?[]^$") .. "$"

    -- First, identify key elements in the note
    for i, line in ipairs(lines) do
        if line == "---" then
            if frontmatter_start == nil then
                frontmatter_start = i
            else
                frontmatter_end = i
            end
        elseif line:match(title_pattern) then
            has_title_header = true
        end
    end

    -- If frontmatter exists, make sure it's at the beginning
    if frontmatter_start and frontmatter_end then
        -- Extract frontmatter
        local frontmatter = {}
        for i = frontmatter_start, frontmatter_end do
            table.insert(frontmatter, lines[i])
        end

        -- Start with frontmatter
        for _, line in ipairs(frontmatter) do
            table.insert(final_content, line)
        end

        -- Add title if not already present
        if not has_title_header then
            table.insert(final_content, "")
            table.insert(final_content, "# " .. title)
            table.insert(final_content, "")
        end

        -- Add remaining content, skipping the frontmatter we already added
        for i, line in ipairs(lines) do
            if i < frontmatter_start or i > frontmatter_end then
                -- Skip any duplicate title headers
                if not line:match(title_pattern) or
                    (line:match(title_pattern) and not has_title_header) then
                    has_title_header = has_title_header or line:match(title_pattern)
                    table.insert(final_content, line)
                end
            end
        end

        -- Update the buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, final_content)
    elseif has_title_header then
        -- No frontmatter but has title - find where to place frontmatter
        local added_frontmatter = false

        for i, line in ipairs(lines) do
            if line:match(title_pattern) and not added_frontmatter then
                -- Add frontmatter before the title
                table.insert(final_content, "---")
                table.insert(final_content, "title: " .. title)
                table.insert(final_content, "created: " .. os.date("%Y-%m-%dT%H:%M:%S%z"))
                table.insert(final_content, "---")
                table.insert(final_content, "")
                added_frontmatter = true
            end
            table.insert(final_content, line)
        end

        vim.api.nvim_buf_set_lines(0, 0, -1, false, final_content)
    else
        -- Neither frontmatter nor title header - add both
        table.insert(final_content, "---")
        table.insert(final_content, "title: " .. title)
        table.insert(final_content, "created: " .. os.date("%Y-%m-%dT%H:%M:%S%z"))
        table.insert(final_content, "---")
        table.insert(final_content, "")
        table.insert(final_content, "# " .. title)
        table.insert(final_content, "")

        -- Add existing content
        for _, line in ipairs(lines) do
            table.insert(final_content, line)
        end

        vim.api.nvim_buf_set_lines(0, 0, -1, false, final_content)
    end
end

-- Generalized function for creating notes in different folders
M.create_note = function(options)
    options = options or {}
    local base_folder = options.base_folder or "00-inbox"
    local prompt_title = options.prompt_title or "Select folder:"
    local template_name = options.template_name
    local note_type = options.note_type or "note"

    -- Set the global note type variable used by Obsidian's note creation
    vim.g.current_note_type = note_type

    -- Make sure we have an editable buffer
    if vim.bo.modifiable == false then
        vim.cmd("enew") -- Create a new empty buffer
    end

    -- If direct_folder is provided, skip folder selection
    if direct_folder then
        local title = vim.fn.input("Note title: ")
        if title ~= "" then
            local folder_path = direct_folder
            if not folder_path:match("^" .. base_folder) then
                folder_path = base_folder .. "/" .. folder_path
            end

            local cmd = string.format("ObsidianNew %s/%s", folder_path, title)
            vim.cmd(cmd)

            M.process_note_after_creation(title, folder_path, template_name)
        end
        return
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
        prompt = prompt_title,
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

                M.process_note_after_creation(title, obsidian_path, template_name, selected)
            end
        end
    end)
end

-- Helper function to process note after creation
M.process_note_after_creation = function(title, path, template_name, selected_path)
    -- Generate timestamp and date variables for potential use
    local timestamp = os.date("%Y%m%d%H%M%S")
    local date = os.date("%Y-%m-%d")
    local time = os.date("%H:%M:%S")
    local tz = os.date("%z")
    local formatted_created = date .. "T" .. time .. tz

    -- Apply template if provided
    if template_name and template_name ~= "" then
        vim.defer_fn(function()
            -- Apply template (this overwrites everything)
            vim.cmd("ObsidianTemplate " .. template_name)

            -- Process template and update the title
            vim.defer_fn(function()
                -- Generate ID in the same format as note_id_func
                local timestamp = os.date("%Y%m%d%H%M%S")
                local date = os.date("%Y-%m-%d")
                local time = os.date("%H:%M:%S")
                local tz = os.date("%z")
                local month = os.date("%B") -- Full month name
                local day = os.date("%d")   -- Day of month
                local year = os.date("%Y")  -- Year
                local formatted_created = date .. "T" .. time .. tz

                -- Replace all placeholders
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                for i, line in ipairs(lines) do
                    lines[i] = line:gsub("{{title}}", title)
                        :gsub("{{date}}", date)
                        :gsub("{{time}}", time)
                        :gsub("{{id}}", timestamp)
                        :gsub("{{date}} {{time}}", formatted_created)
                        :gsub("{{created}}", formatted_created)
                        :gsub("{{tz}}", tz)
                        :gsub("{{month}}", month)
                        :gsub("{{day}}", day)
                        :gsub("{{year}}", year)
                end
                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

                -- Fix note format to ensure frontmatter is first
                M.fix_note_format(title)

                -- If it's a project folder, update project info
                local obsidian_path = path
                if obsidian_path:match("^10%-projects") or (selected_path and selected_path:match("^10%-projects")) then
                    -- Use the path for project info extraction
                    local project_path = obsidian_path:match("^10%-projects") and obsidian_path or selected_path
                    M.update_project_info(project_path)
                end
            end, 100) -- Small delay to ensure template is applied
        end, 100)
    else
        -- Even without a template, fix note format after creation
        vim.defer_fn(function()
            -- Add minimal frontmatter if none exists
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local has_frontmatter = false

            for _, line in ipairs(lines) do
                if line == "---" then
                    has_frontmatter = true
                    break
                end
            end

            if not has_frontmatter then
                -- Create minimal frontmatter
                local frontmatter = {
                    "---",
                    "title: " .. title,
                    "created: " .. formatted_created,
                    "id: " .. timestamp,
                    "---",
                    "",
                }

                -- Prepend frontmatter to existing content
                for i = #frontmatter, 1, -1 do
                    vim.api.nvim_buf_set_lines(0, 0, 0, false, { frontmatter[i] })
                end
            end

            M.fix_note_format(title)
        end, 200)
    end
end

-- Function to create a daily note with proper formatting
M.create_daily_note = function()
    vim.g.current_note_type = "daily"
    vim.cmd("ObsidianToday")

    -- Fix formatting after creation
    vim.defer_fn(function()
        local title = os.date("%Y-%m-%d")
        M.fix_note_format(title)
    end, 200)
end

-- Create a quick note directly in the inbox
M.create_quick_note = function(template_name)
    M.create_note({
        base_folder = "00-inbox",
        direct_folder = "00-inbox",
        note_type = "note",
        template_name = template_name -- Only use template if explicitly provided
    })
end

-- Function to create a note in the input or output folders
M.create_io_note = function(io_type)
    local folder = io_type == "input" and "60-input" or "70-output"
    local template = io_type == "input" and "input" or "output"

    M.create_note({
        base_folder = folder,
        prompt_title = "Select " .. io_type .. " folder:",
        note_type = io_type,
        template_name = template
    })
end

-- Maintain backwards compatibility
M.create_note_in_folder = function(base_folder, prompt_title, template_name)
    M.create_note({
        base_folder = base_folder,
        prompt_title = prompt_title,
        template_name = template_name
    })
end

return M
