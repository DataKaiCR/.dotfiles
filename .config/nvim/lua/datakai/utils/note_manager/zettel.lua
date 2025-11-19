local M = {}

-- Get access to core functions
local core = require("datakai.utils.note_manager.core")

-- Create a Zettel directly (flat folder, no subfolder selection)
M.create_zettel = function()
    vim.g.current_note_type = "zettel"

    local title = vim.fn.input("Zettel title: ")
    if title == "" then return end

    -- Create directly in zettelkasten folder (flat structure)
    local cmd = string.format("ObsidianNew zettelkasten/%s", title)
    vim.cmd(cmd)

    core.process_note_after_creation(title, "zettelkasten", "zettel", nil)

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

return M
