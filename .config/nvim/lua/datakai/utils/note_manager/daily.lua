local M = {}

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

return M
