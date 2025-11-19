local M = {}

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
                    -- Load project module to call update_project_info
                    local project = require("datakai.utils.note_manager.project")
                    project.update_project_info(project_path)
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

-- Generalized function for creating notes in different folders
M.create_note = function(options)
    options = options or {}
    local base_folder = options.base_folder or "00-inbox"
    local prompt_title = options.prompt_title or "Select folder:"
    local template_name = options.template_name
    local note_type = options.note_type or "note"
    local direct_folder = options.direct_folder

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

-- Create a quick note directly in the inbox
M.create_quick_note = function(template_name)
    M.create_note({
        base_folder = "00-inbox",
        direct_folder = "00-inbox",
        note_type = "note",
        template_name = template_name -- Only use template if explicitly provided
    })
end

-- Create note with specific content (helper for weekly review)
M.create_note_with_content = function(title, content)
    vim.g.current_note_type = 'note'
    local cmd = string.format("ObsidianNew 00-inbox/%s", title)
    vim.cmd(cmd)

    vim.defer_fn(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
        M.fix_note_format(title)
    end, 100)
end

-- Weekly review helper
M.weekly_review = function()
    local review_notes = {}

    -- Find recent notes (last 7 days)
    local recent_cmd = string.format(
        'find %s -name "*.md" -mtime -7 -type f | head -20',
        vim.fn.expand('~/second-brain')
    )

    local recent_files = vim.fn.systemlist(recent_cmd)

    -- Create review note
    local review_title = 'Weekly Review ' .. os.date('%Y-W%U')
    local review_content = {
        '# ' .. review_title,
        '',
        '## Recent Notes',
        ''
    }

    for _, file in ipairs(recent_files) do
        local basename = vim.fn.fnamemodify(file, ':t:r')
        local folder = file:match('second%-brain/([^/]+)/')
        table.insert(review_content, string.format('- [[%s]] (%s)', basename, folder or 'root'))
    end

    table.insert(review_content, '')
    table.insert(review_content, '## Inbox Items to Process')
    table.insert(review_content, '')

    -- Add section for unprocessed daily notes ideas
    table.insert(review_content, '')
    table.insert(review_content, '## Ideas from Daily Notes')
    table.insert(review_content, '')

    -- Check recent daily notes for ideas sections
    local daily_files = vim.fn.systemlist(string.format(
        'find %s/00-journal/daily -name "*.md" -mtime -7 -type f | sort -r | head -7',
        vim.fn.expand('~/second-brain')
    ))

    for _, daily_file in ipairs(daily_files) do
        local date = daily_file:match('(%d%d%d%d%-%d%d%-%d%d)%.md')
        if date then
            table.insert(review_content, string.format('- [[%s]] - Review ideas section', date))
        end
    end

    -- Check inbox for items
    local inbox_file = vim.fn.expand('~/second-brain/00-inbox/inbox.md')
    if vim.fn.filereadable(inbox_file) == 1 then
        local inbox_lines = vim.fn.readfile(inbox_file)
        for _, line in ipairs(inbox_lines) do
            if line:match('^%s*%-') then  -- Lines starting with -
                table.insert(review_content, line)
            end
        end
    end

    table.insert(review_content, '')
    table.insert(review_content, '## Actions')
    table.insert(review_content, '- [ ] Process inbox items')
    table.insert(review_content, '- [ ] Review and link notes')
    table.insert(review_content, '- [ ] Update project statuses')
    table.insert(review_content, '- [ ] Archive completed notes')

    -- Create the review note
    vim.g.current_note_type = 'note'
    local cmd = string.format("ObsidianNew 00-inbox/%s", review_title)
    vim.cmd(cmd)

    vim.defer_fn(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, review_content)
        M.fix_note_format(review_title)
    end, 100)

    vim.notify("Created weekly review note", vim.log.levels.INFO)
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
