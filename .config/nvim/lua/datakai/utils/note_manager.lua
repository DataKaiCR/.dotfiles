local M = {}

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

    -- Wait for the note to be created and template applied
    vim.defer_fn(function()
        -- Find the "## Journal" header
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local journal_line = nil

        for i, line in ipairs(lines) do
            if line:match("^## Journal") then
                journal_line = i
                break
            end
        end

        if journal_line then
            -- Position cursor after "## Journal" header (skip blank line if present)
            local next_line = journal_line + 1
            if lines[next_line] and lines[next_line] == "" then
                next_line = next_line + 1
            end

            vim.api.nvim_win_set_cursor(0, {next_line, 0})
            vim.cmd("startinsert!")
        else
            -- Fallback: go to end of file
            vim.cmd("normal! G")
            vim.cmd("startinsert!")
        end
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

-- Function removed - input/output folders deleted in Scriptoria system

-- Enhanced workflow functions

-- Process a line from inbox into a proper note
M.process_inbox_line = function()
    local current_line = vim.api.nvim_get_current_line()
    
    -- Skip empty lines or lines that don't look like notes
    if current_line == "" or current_line:match("^#") then
        vim.notify("Please position cursor on a note line to process", vim.log.levels.WARN)
        return
    end
    
    local note_type = vim.fn.input('Note type: (z)ettel, (p)roject, (a)rea, (r)esource: ')
    if note_type == "" then return end
    
    local title = vim.fn.input('Title: ')
    if title == "" then return end
    
    local type_map = {
        z = { type = 'zettel', folder = 'zettelkasten', template = 'zettel' },
        p = { type = 'project', folder = '10-projects', template = 'project' },
        a = { type = 'area', folder = '20-areas', template = 'area' }
    }
    
    local config = type_map[note_type]
    if not config then
        vim.notify("Invalid note type. Use z (zettel), p (project), or a (area)", vim.log.levels.ERROR)
        return
    end
    
    -- Set note type for obsidian
    vim.g.current_note_type = config.type
    
    -- Create the note
    local cmd = string.format("ObsidianNew %s/%s", config.folder, title)
    vim.cmd(cmd)
    
    -- Add the inbox content to the note
    vim.defer_fn(function()
        -- Apply template first if needed
        if config.template then
            vim.cmd("ObsidianTemplate " .. config.template)
            
            vim.defer_fn(function()
                -- Process template variables
                local timestamp = os.date("%Y%m%d%H%M%S")
                local date = os.date("%Y-%m-%d")
                local time = os.date("%H:%M:%S")
                local tz = os.date("%z")
                local formatted_created = date .. "T" .. time .. tz
                
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                for i, line in ipairs(lines) do
                    lines[i] = line:gsub("{{title}}", title)
                        :gsub("{{date}}", date)
                        :gsub("{{time}}", time)
                        :gsub("{{id}}", timestamp)
                        :gsub("{{created}}", formatted_created)
                end
                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
                
                -- Add the inbox content
                vim.api.nvim_buf_set_lines(0, -1, -1, false, {
                    "",
                    "## From Inbox",
                    current_line,
                    ""
                })
                
                M.fix_note_format(title)
            end, 100)
        else
            -- No template, just add content
            vim.api.nvim_buf_set_lines(0, -1, -1, false, {
                "",
                "## From Inbox", 
                current_line,
                ""
            })
            M.fix_note_format(title)
        end
    end, 100)
    
    -- Remove the line from inbox
    vim.api.nvim_del_current_line()
    
    vim.notify("Processed inbox line into " .. config.type .. " note: " .. title, vim.log.levels.INFO)
end

-- Quick capture with context
M.capture_with_context = function()
    local timestamp = os.date('%Y%m%d %H:%M')
    local idea = vim.fn.input('Quick idea: ')
    if idea == "" then return end
    
    local context = vim.fn.input('Context/Source: ')
    
    -- Use the correct daily note format (YYYY-MM-DD)
    local daily_file = string.format('%s/00-journal/daily/%s.md',
        vim.fn.expand('~/second-brain'), os.date('%Y-%m-%d'))
    
    -- Build the entry - append to Ideas section
    local entry = {}
    table.insert(entry, '')  -- Empty line before timestamp
    table.insert(entry, string.format('### %s', timestamp))
    table.insert(entry, string.format('- %s', idea))
    table.insert(entry, string.format('- Context: %s', context))
    
    -- Check if file exists, create it with template if not
    if vim.fn.filereadable(daily_file) == 0 then
        -- Create daily note first
        M.create_daily_note()
        vim.defer_fn(function()
            -- Append to the Ideas section of the daily note
            local lines = vim.fn.readfile(daily_file)
            -- Find the Ideas section
            local ideas_index = nil
            for i, line in ipairs(lines) do
                if line:match("^## Ideas") then
                    ideas_index = i
                    break
                end
            end
            
            if ideas_index then
                -- Insert after Ideas header
                for j = #entry, 1, -1 do
                    table.insert(lines, ideas_index + 1, entry[j])
                end
                vim.fn.writefile(lines, daily_file)
            else
                -- Just append if no Ideas section found
                vim.fn.writefile(vim.list_extend(lines, entry), daily_file)
            end
            
            vim.notify("Captured to daily note: " .. daily_file, vim.log.levels.INFO)
        end, 500)
    else
        -- Append to existing daily note
        local lines = vim.fn.readfile(daily_file)
        -- Find the Ideas section
        local ideas_index = nil
        for i, line in ipairs(lines) do
            if line:match("^## Ideas") then
                ideas_index = i
                break
            end
        end
        
        if ideas_index then
            -- Insert after Ideas header
            for j = #entry, 1, -1 do
                table.insert(lines, ideas_index + 1, entry[j])
            end
            vim.fn.writefile(lines, daily_file)
        else
            -- Just append if no Ideas section found
            vim.fn.writefile(vim.list_extend(lines, entry), daily_file)
        end
        
        vim.notify("Captured to daily note: " .. daily_file, vim.log.levels.INFO)
    end
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
    local command = "find -L ~/second-brain/10-projects -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/10-projects' | sort"
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
            "find -L ~/second-brain/10-projects/%s -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/notes' -not -path '*/meetings' | sort",
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
            local full_path = vim.fn.expand("~/second-brain/" .. notes_path)
            vim.fn.mkdir(full_path, "p")

            vim.g.current_note_type = "project"

            local cmd = string.format("ObsidianNew %s/%s", notes_path, title)
            vim.cmd(cmd)

            M.process_note_after_creation(title, notes_path, "project", selected_company)
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
            local full_path = vim.fn.expand("~/second-brain/" .. notes_path)
            vim.fn.mkdir(full_path, "p")

            vim.g.current_note_type = "project"

            local cmd = string.format("ObsidianNew %s/%s", notes_path, title)
            vim.cmd(cmd)

            M.process_note_after_creation(title, notes_path, "project", selected_company .. "/" .. selected_project)
            position_cursor_at_notes()
        end)
    end)
end

-- Create meeting note in project-specific meetings folder
M.create_meeting_note = function()
    -- Step 1: List all top-level company/client folders
    local command = "find -L ~/second-brain/10-projects -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/10-projects' | sort"
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
            "find -L ~/second-brain/10-projects/%s -maxdepth 1 -type d -not -path '*/\\.*' -not -path '*/meetings' | sort",
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
            local full_path = vim.fn.expand("~/second-brain/" .. meetings_path)
            vim.fn.mkdir(full_path, "p")

            -- Set note type
            vim.g.current_note_type = "meeting"

            -- Create meeting note
            local cmd = string.format("ObsidianNew %s/%s", meetings_path, title)
            vim.cmd(cmd)

            M.process_note_after_creation(title, meetings_path, "meeting", project_context)
            position_cursor_at_notes()
        end)
    end)
end

-- Create a Zettel directly (flat folder, no subfolder selection)
M.create_zettel = function()
    vim.g.current_note_type = "zettel"

    local title = vim.fn.input("Zettel title: ")
    if title == "" then return end

    -- Create directly in zettelkasten folder (flat structure)
    local cmd = string.format("ObsidianNew zettelkasten/%s", title)
    vim.cmd(cmd)

    M.process_note_after_creation(title, "zettelkasten", "zettel", nil)

    -- Position cursor at Summary section after template is applied
    vim.defer_fn(function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        for i, line in ipairs(lines) do
            if line:match("^## Summary") then
                -- Move to the line after "## Summary" (skip the italic instruction)
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

-- Smart inbox capture - creates/finds today's section
M.capture_to_inbox = function()
    local inbox_file = vim.fn.expand("~/second-brain/00-inbox/capture.md")

    -- Open the file
    vim.cmd("edit " .. inbox_file)

    -- Get today's date header
    local today = os.date("%Y-%m-%d")
    local header = "## " .. today

    -- Read all lines
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Find if today's header exists
    local header_line = nil
    local separator_line = nil

    for i, line in ipairs(lines) do
        if line == header then
            header_line = i
            break
        elseif line == "---" then
            separator_line = i
        end
    end

    if header_line then
        -- Header exists, go to it and create new line below
        vim.api.nvim_win_set_cursor(0, {header_line + 1, 0})
        vim.cmd("normal! o- [ ] ")
        vim.cmd("startinsert!")
    else
        -- Header doesn't exist, create it after the separator line
        local insert_line = separator_line or 6  -- Fallback to line 6 if no separator

        -- Insert blank line, header, and checkbox after separator
        vim.api.nvim_buf_set_lines(0, insert_line, insert_line, false, {"", header, "- [ ] "})

        -- Move cursor to the checkbox line (insert_line + 3 because we added 3 lines)
        vim.api.nvim_win_set_cursor(0, {insert_line + 3, 6})
        vim.cmd("startinsert!")
    end
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
