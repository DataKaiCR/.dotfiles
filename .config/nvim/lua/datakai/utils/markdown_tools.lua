-- Enhanced markdown module with Glow integration
local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })

    -- Apply consistent settings to markdown files
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            local opt = vim.opt_local

            -- Better display
            opt.wrap = true
            opt.linebreak = true     -- Don't break words when wrapping
            opt.list = false         -- Don't show listchars in markdown
            opt.conceallevel = 2     -- Hide markup
            opt.concealcursor = 'nc' -- Don't reveal markup in normal and command mode
            opt.spell = true         -- Enable spell checking

            -- Set textwidth for better formatting
            opt.textwidth = 80

            -- Better syntax highlighting for code blocks
            vim.cmd([[
                syntax match markdownBlockStart "^```.*$" containedin=ALL
                syntax match markdownBlockEnd "^```$" containedin=ALL
                hi def link markdownBlockStart Special
                hi def link markdownBlockEnd Special

                " Better header highlighting
                syntax match markdownH1 "^# .*$" containedin=ALL
                syntax match markdownH2 "^## .*$" containedin=ALL
                syntax match markdownH3 "^### .*$" containedin=ALL
                syntax match markdownH4 "^#### .*$" containedin=ALL
                hi def link markdownH1 Title
                hi def link markdownH2 Title
                hi def link markdownH3 Title
                hi def link markdownH4 Title
            ]])

            -- Set formatting options
            opt.formatoptions:append('ron')
            opt.formatoptions:remove('t') -- Don't auto-wrap text
            opt.formatoptions:append('q') -- Allow formatting of comments with gq

            -- Check if glow is installed
            local has_glow = vim.fn.executable("glow") == 1

            -- Add markdown-specific keymaps
            if has_glow then
                -- Use Glow for preview if available
                vim.keymap.set("n", "<leader>mp", ":Glow<CR>",
                    { buffer = true, desc = "Preview markdown with Glow" })
                vim.keymap.set("n", "<leader>mc", ":Glow!<CR>",
                    { buffer = true, desc = "Preview markdown in current window" })
            elseif vim.fn.exists(":MarkdownPreview") > 0 then
                -- Fall back to browser-based preview if available
                vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<CR>",
                    { buffer = true, desc = "Start Markdown preview" })
                vim.keymap.set("n", "<leader>ms", "<cmd>MarkdownPreviewStop<CR>",
                    { buffer = true, desc = "Stop Markdown preview" })
                vim.keymap.set("n", "<leader>mt", "<cmd>MarkdownPreviewToggle<CR>",
                    { buffer = true, desc = "Toggle Markdown preview" })
            end

            -- Additional markdown editing keymaps
            vim.keymap.set("n", "<leader>mh", function()
                -- Convert current line to header
                local line = vim.api.nvim_get_current_line()
                local level = vim.fn.input("Header level (1-6): ")
                local prefix = string.rep("#", tonumber(level) or 1) .. " "

                -- Remove existing header markers if any
                line = line:gsub("^#+%s*", "")

                vim.api.nvim_set_current_line(prefix .. line)
            end, { buffer = true, desc = "Convert to header" })

            vim.keymap.set("n", "<leader>ml", function()
                -- Convert current line to list item
                local line = vim.api.nvim_get_current_line()
                -- Remove existing list markers if any
                line = line:gsub("^%s*[-*+]%s*", "")
                line = line:gsub("^%s*%d+%.%s*", "")

                -- Add list marker
                vim.api.nvim_set_current_line("- " .. line)
            end, { buffer = true, desc = "Convert to list item" })

            -- Toggle checkbox
            vim.keymap.set("n", "<leader>mx", function()
                local line = vim.api.nvim_get_current_line()
                local new_line = line

                -- If it's a task item, toggle its state
                if line:match("^%s*[-*+]%s*%[[ xX]%]") then
                    if line:match("^%s*[-*+]%s*%[[ ]%]") then
                        new_line = line:gsub("%[ %]", "[x]", 1)
                    else
                        new_line = line:gsub("%[[xX]%]", "[ ]", 1)
                    end
                    -- If it's a regular list item, convert to task
                elseif line:match("^%s*[-*+]%s+") then
                    new_line = line:gsub("^(%s*[-*+]%s+)", "%1[ ] ", 1)
                    -- Otherwise, create a new task
                else
                    new_line = "- [ ] " .. line
                end

                vim.api.nvim_set_current_line(new_line)
            end, { buffer = true, desc = "Toggle checkbox" })

            -- Make table formatting available if possible
            if vim.fn.exists(":TableFormat") > 0 then
                vim.keymap.set("n", "<leader>mf", "<cmd>TableFormat<CR>",
                    { buffer = true, desc = "Format table" })
            end

            -- Add a link
            vim.keymap.set("n", "<leader>mk", function()
                local text = vim.fn.expand("<cword>")
                local url = vim.fn.input("URL: ")

                if url ~= "" then
                    local link = "[" .. text .. "](" .. url .. ")"
                    vim.cmd("normal! ciw" .. link)
                end
            end, { buffer = true, desc = "Add link" })

            -- Toggle Zen Mode if available
            if vim.fn.exists(":ZenMode") > 0 then
                vim.keymap.set("n", "<leader>mz", "<cmd>ZenMode<CR>",
                    { buffer = true, desc = "Toggle Zen Mode" })
            end
        end
    })

    -- Auto-format markdown files on save
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        pattern = "*.md",
        callback = function()
            -- Save cursor position
            local cursor_pos = vim.api.nvim_win_get_cursor(0)

            -- Fix common markdown issues

            -- Convert spaces at beginning of list items
            vim.cmd([[silent! %s/^\( *\)- /\1- /ge]])

            -- Fix trailing spaces (careful with line breaks)
            vim.cmd([[silent! %s/\([^  ]\)\s\+$/\1/ge]])

            -- Ensure single blank line between sections
            vim.cmd([[silent! %s/\(\n\n\)\n\+/\1/ge]])

            -- Format tables if available
            if vim.fn.exists(':TableFormat') > 0 then
                vim.cmd('TableFormat')
            end

            -- Restore cursor position
            vim.api.nvim_win_set_cursor(0, cursor_pos)
        end,
    })

    -- Create commands for markdown editing
    vim.api.nvim_create_user_command("MarkdownTOC", function()
        M.generate_toc()
    end, {
        desc = "Generate table of contents"
    })

    -- YAML frontmatter command
    vim.api.nvim_create_user_command("MarkdownFrontmatter", function()
        M.add_frontmatter()
    end, {
        desc = "Add or update YAML frontmatter"
    })

    -- Check if markdown preview plugins are available
    vim.api.nvim_create_user_command("MarkdownSetup", function()
        M.check_markdown_setup()
    end, {
        desc = "Check markdown setup and preview plugins"
    })
end

-- Check markdown setup and preview plugins
M.check_markdown_setup = function()
    -- Create a setup report buffer
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(bufnr, "Markdown-Setup-Report")
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

    local append = function(text)
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, { text })
    end

    append("# Markdown Preview Setup")
    append("")

    -- Check for glow
    local has_glow = vim.fn.executable("glow") == 1
    if has_glow then
        local version = vim.fn.system("glow --version"):gsub("\n", "")
        append("## ✅ Glow (Terminal Preview)")
        append("")
        append("Glow is installed: " .. version)
        append("")
        append("Preview commands:")
        append("- `:Glow` - Open preview in floating window")
        append("- `:Glow!` - Open preview in current window")
        append("- `<leader>mp` - Toggle preview")
        append("")
    else
        append("## ❌ Glow (Terminal Preview)")
        append("")
        append("Glow is not installed. To install:")
        append("")

        local os_name = vim.loop.os_uname().sysname
        if os_name == "Darwin" then
            append("```bash")
            append("brew install glow")
            append("```")
        elseif os_name == "Linux" then
            append("```bash")
            append("# On Ubuntu/Debian:")
            append("sudo apt install glow")
            append("")
            append("# On Arch:")
            append("sudo pacman -S glow")
            append("")
            append("# On other distributions:")
            append("curl -fsSL https://raw.githubusercontent.com/charmbracelet/glow/main/install.sh | bash")
            append("```")
        elseif os_name:match("Windows") then
            append("```powershell")
            append("# Install scoop first if you don't have it")
            append("iwr -useb get.scoop.sh | iex")
            append("")
            append("# Then install glow")
            append("scoop install glow")
            append("```")
        end

        append("")
        append("Or run `:GlowInstall` to try automatic installation.")
        append("")
    end

    -- Check for markdown-preview.nvim
    local has_mdp = vim.fn.exists(":MarkdownPreview") > 0
    if has_mdp then
        append("## ✅ markdown-preview.nvim (Browser Preview)")
        append("")
        append("markdown-preview.nvim is installed and commands are available.")
        append("")
        append("Preview commands:")
        append("- `:MarkdownPreview` - Start preview")
        append("- `:MarkdownPreviewStop` - Stop preview")
        append("- `:MarkdownPreviewToggle` - Toggle preview")
        append("")
    else
        append("## ❌ markdown-preview.nvim (Browser Preview)")
        append("")
        append("markdown-preview.nvim is not installed or not properly configured.")
        append("")
        append("This plugin provides browser-based preview but requires setup.")
        append("")
        append("We recommend using Glow instead for a simpler setup.")
        append("")
    end

    -- Add keybindings section
    append("## Markdown Keybindings")
    append("")
    append("The following keybindings are available in markdown files:")
    append("")
    append("| Keybinding | Description |")
    append("|------------|-------------|")
    append("| `<leader>mp` | Preview markdown (Glow or browser) |")
    if has_glow then
        append("| `<leader>mc` | Preview in current window (Glow) |")
    end
    if has_mdp then
        append("| `<leader>ms` | Stop markdown preview (browser) |")
        append("| `<leader>mt` | Toggle markdown preview (browser) |")
    end
    append("| `<leader>mz` | Toggle Zen Mode |")
    append("| `<leader>mh` | Convert to header |")
    append("| `<leader>ml` | Convert to list item |")
    append("| `<leader>mx` | Toggle checkbox |")
    append("| `<leader>mk` | Add link |")
    append("| `<leader>mf` | Format table |")
    append("")

    -- Add closing instructions
    append("## Next Steps")
    append("")
    if not has_glow then
        append("1. Install Glow for the best terminal-based markdown experience")
        append("   Run `:GlowInstall` to attempt automatic installation")
        append("")
    end
    append("Enjoy writing markdown in Neovim!")

    -- Add keymaps for quick actions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "i", ":GlowInstall<CR>",
        { noremap = true, silent = true, desc = "Install Glow" })

    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bd<CR>",
        { noremap = true, silent = true, desc = "Close window" })

    -- Add a footer
    append("")
    append("---")
    append("Press `i` to install Glow or `q` to close this buffer.")
end

-- Generate table of contents
M.generate_toc = function()
    -- Get all lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Find all headings and their levels
    local headings = {}
    local min_level = 6 -- Track minimum heading level for proper indentation

    for i, line in ipairs(lines) do
        local level, text = line:match("^(#+)%s+(.+)$")
        if level then
            level = #level
            min_level = math.min(min_level, level)

            -- Strip out any links or formatting
            text = text:gsub("%[(.-)%]%(.-%))", "%1") -- Remove links but keep text
            text = text:gsub("`(.+)`", "%1")          -- Remove inline code
            text = text:gsub("%*%*(.+)%*%*", "%1")    -- Remove bold
            text = text:gsub("%*(.+)%*", "%1")        -- Remove italic
            text = text:gsub("%~%~(.+)%~%~", "%1")    -- Remove strikethrough
            text = text:gsub("^%s*(.-)%s*$", "%1")    -- Trim whitespace

            -- Create anchor from text
            local anchor = text:lower()
            anchor = anchor:gsub("%s+", "-")    -- Replace spaces with hyphens
            anchor = anchor:gsub("[^%w%-]", "") -- Remove non-alphanumeric chars

            table.insert(headings, {
                level = level,
                text = text,
                anchor = anchor,
                line = i
            })
        end
    end

    -- If no headings found, notify and return
    if #headings == 0 then
        vim.notify("No headings found in document", vim.log.levels.WARN)
        return
    end

    -- Generate TOC lines
    local toc_lines = { "# Table of Contents", "" }

    for _, heading in ipairs(headings) do
        local indent = string.rep("  ", heading.level - min_level)
        local entry = indent .. "- [" .. heading.text .. "](#" .. heading.anchor .. ")"
        table.insert(toc_lines, entry)
    end

    -- Add separator
    table.insert(toc_lines, "")
    table.insert(toc_lines, "---")
    table.insert(toc_lines, "")

    -- Find TOC insertion point - after frontmatter, before first heading
    local insert_point = 0

    -- Skip frontmatter if present
    if lines[1] == "---" then
        for i = 2, #lines do
            if lines[i] == "---" then
                insert_point = i
                break
            end
        end
    end

    -- Insert the TOC
    vim.api.nvim_buf_set_lines(0, insert_point, insert_point, false, toc_lines)
    vim.notify("Table of contents generated", vim.log.levels.INFO)
end

-- Add or update YAML frontmatter
M.add_frontmatter = function()
    -- Get all lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Check if frontmatter already exists
    local has_frontmatter = false
    local frontmatter_end = 0

    if lines[1] == "---" then
        has_frontmatter = true
        for i = 2, #lines do
            if lines[i] == "---" then
                frontmatter_end = i
                break
            end
        end
    end

    -- Prompt for frontmatter fields
    local fields = {}

    -- If frontmatter exists, parse existing fields
    if has_frontmatter then
        for i = 2, frontmatter_end - 1 do
            local key, value = lines[i]:match("^(.-):%s*(.*)$")
            if key and key ~= "" then
                fields[key] = value
            end
        end
    end

    -- Always ensure these fields exist
    if not fields.title then
        -- Try to get title from first heading
        for _, line in ipairs(lines) do
            local title = line:match("^#%s+(.+)$")
            if title then
                fields.title = title
                break
            end
        end

        if not fields.title then
            -- Use filename as title
            local filename = vim.fn.expand("%:t:r")
            fields.title = filename:gsub("[-_]", " "):gsub("^%l", string.upper)
        end
    end

    if not fields.date then
        fields.date = os.date("%Y-%m-%d")
    end

    -- Ask for additional fields
    local add_field = true
    while add_field do
        -- Get field name
        local field_name = vim.fn.input({
            prompt = "Field name (leave empty to finish): "
        })

        if field_name == "" then
            add_field = false
        else
            local default_value = fields[field_name] or ""
            local field_value = vim.fn.input({
                prompt = field_name .. ": ",
                default = default_value
            })

            fields[field_name] = field_value
        end
    end

    -- Generate frontmatter lines
    local frontmatter_lines = { "---" }

    -- Add fields in a specific order
    local ordered_fields = { "title", "date", "description", "tags", "categories" }

    -- Add ordered fields first
    for _, field in ipairs(ordered_fields) do
        if fields[field] then
            if field == "tags" or field == "categories" then
                -- Format as YAML array if it contains commas
                if fields[field]:match(",") then
                    table.insert(frontmatter_lines, field .. ":")
                    for item in fields[field]:gmatch("([^,]+)") do
                        item = item:match("^%s*(.-)%s*$") -- Trim whitespace
                        table.insert(frontmatter_lines, "  - " .. item)
                    end
                else
                    table.insert(frontmatter_lines, field .. ": " .. fields[field])
                end
            else
                table.insert(frontmatter_lines, field .. ": " .. fields[field])
            end
            fields[field] = nil
        end
    end

    -- Add remaining fields
    local remaining_fields = {}
    for field, value in pairs(fields) do
        table.insert(remaining_fields, field)
    end
    table.sort(remaining_fields)

    for _, field in ipairs(remaining_fields) do
        table.insert(frontmatter_lines, field .. ": " .. fields[field])
    end

    table.insert(frontmatter_lines, "---")
    table.insert(frontmatter_lines, "")

    -- Update frontmatter in buffer
    if has_frontmatter then
        vim.api.nvim_buf_set_lines(0, 0, frontmatter_end + 1, false, frontmatter_lines)
    else
        vim.api.nvim_buf_set_lines(0, 0, 0, false, frontmatter_lines)
    end

    vim.notify("Frontmatter updated", vim.log.levels.INFO)
end

return M
