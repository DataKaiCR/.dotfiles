local M = {}

-- Get access to core functions
local core = require("datakai.utils.note_manager.core")

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

                core.fix_note_format(title)
            end, 100)
        else
            -- No template, just add content
            vim.api.nvim_buf_set_lines(0, -1, -1, false, {
                "",
                "## From Inbox",
                current_line,
                ""
            })
            core.fix_note_format(title)
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
        -- Create daily note first - need to load daily module
        local daily = require("datakai.utils.note_manager.daily")
        daily.create_daily_note()
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

return M
