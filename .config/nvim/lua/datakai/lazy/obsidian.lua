return {
    "epwalsh/obsidian.nvim",
    version = "*",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    event = {
        "BufReadPre *.md",
        "BufNewFile *.md",
    },
    config = function()
        -- Require the note manager module
        local note_manager = require("datakai.utils.note_manager")

        require("obsidian").setup({
            workspaces = {
                {
                    name = "second-brain",
                    path = "~/second-brain",
                },
            },
            -- Configure note locations
            notes_subdir = "00-inbox",
            new_notes_location = "notes_subdir",
            -- Templates configuration
            templates = {
                subdir = "_templates",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M:%S%z",
            },
            -- Daily notes configuration
            daily_notes = {
                enabled = true,
                folder = "00-journal/daily",
                date_format = "daily-%Y%m%d",
                template = "daily",
            },
            -- Additional attachments configuration
            attachments = {
                img_folder = "_assets/images",
                additional_folders = {
                    "_assets/excalidraw",
                    "_assets/input",
                    "_assets/output"
                },
            },
            -- UI settings
            ui = {
                enable = true,
                conceallevel = 2,
                folding = true,
            },
            -- Note ID settings - use the title as the ID by default
            note_id_func = function(title)
                -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
                -- In this case a note with the title 'My new note' will be given an ID that looks
                -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
                local timestamp = os.date("%Y%m%d%H%M%S")
                local suffix = ""
                if title ~= nil then
                    -- If title is given, transform it into valid file name.
                    suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
                else
                    -- If title is nil, just add 4 random uppercase letters to the suffix.
                    for _ = 1, 4 do
                        suffix = suffix .. string.char(math.random(65, 90))
                    end
                end
                -- Use a global variable that gets set in your shortcut functions
                if vim.g.current_note_type then
                    if vim.g.current_note_type == "daily" then
                        return "daily-" .. os.date("%Y%m%d")
                    elseif vim.g.current_note_type == "zettel" then
                        return "zettel-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "project" then
                        return "project-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "area" then
                        return "area-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "resource" then
                        return "resource-" .. timestamp .. "-" .. suffix
                    end
                end

                -- Default case if type isn't set
                return "note-" .. timestamp .. "-" .. suffix
            end,
            -- Disable frontmatter
            disable_frontmatter = true,
            -- Customize the frontmatter data for all note types
            -- Customize the frontmatter data for all note types
            note_frontmatter_func = function(note)
                -- Start with the basic fields
                local out = { id = note.id, title = note.title }

                -- Add created timestamp with ISO 8601 format
                local date = os.date("%Y-%m-%d")
                local time = os.date("%H:%M:%S")
                local tz = os.date("%z")
                out.created = date .. "T" .. time .. tz

                -- Only add aliases for non-daily notes - safely check if path exists
                if note.path and type(note.path) == "string" and note.path:match("^00%-journal/daily/") then
                    -- For daily notes, we might customize differently
                else
                    -- For all other notes, include aliases if they exist
                    if note.aliases then
                        out.aliases = note.aliases
                    end
                end

                -- Add tags if they exist (and default to empty array if not)
                out.tags = note.tags or {}

                -- Preserve any manually added fields in the frontmatter
                if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                    for k, v in pairs(note.metadata) do
                        out[k] = v
                    end
                end

                return out
            end,
            -- Key mappings for different note types
            mappings = {
                -- Basic commands using direct Vim commands
                ["<leader>zn"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "note"
                        local title = vim.fn.input("Note title: ")
                        if title ~= "" then
                            local cmd = string.format("ObsidianNew %s", title)
                            vim.cmd(cmd)
                        else
                            vim.cmd("ObsidianNew")
                        end
                    end,
                    desc = "Create new note in inbox"
                },
                ["<leader>zo"] = {
                    action = function() vim.cmd("ObsidianFollowLink") end,
                    desc = "Open/follow link"
                },
                ["<leader>zt"] = {
                    action = function() vim.cmd("ObsidianTemplate") end,
                    desc = "Insert template"
                },
                ["<leader>zd"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "daily"
                        vim.cmd("ObsidianToday")
                    end,
                    desc = "Create/open daily note"
                },
                ["<leader>zs"] = {
                    action = function() vim.cmd("ObsidianSearch") end,
                    desc = "Search in vault"
                },
                -- Custom commands using the note manager module
                ["<leader>zp"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "project"
                        note_manager.create_note_in_folder("10-projects", "Select project folder:", "project")
                    end,
                    desc = "Create note in Projects folder"
                },
                ["<leader>za"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "area"
                        note_manager.create_note_in_folder("20-areas", "Select area folder:", "area")
                    end,
                    desc = "Create note in Areas folder"
                },
                ["<leader>zr"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "resource"
                        note_manager.create_note_in_folder("30-resources", "Select resource folder:", "resource")
                    end,
                    desc = "Create note in Resources folder"
                },
                ["<leader>zv"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "archive"
                        note_manager.create_note_in_folder("40-archive", "Select archive folder:", "archive")
                    end,
                    desc = "Create note in Archive folder"
                },
                -- For Zettelkasten notes, use timestamp ID + title for uniqueness and readability
                ["<leader>zz"] = {
                    action = function()
                        -- Set the note type
                        vim.g.current_note_type = "zettel"
                        local title = vim.fn.input("Zettelkasten note title: ")
                        if title ~= "" then
                            local timestamp = os.date("%Y%m%d%H%M%S")
                            local zettel_title = timestamp .. " - " .. title
                            local cmd = string.format("ObsidianNew 50-zettelkasten/%s", title)
                            vim.cmd(cmd)
                            -- Apply Zettelkasten template
                            vim.defer_fn(function()
                                vim.cmd("ObsidianTemplate zettelkasten")
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
                            end, 100)
                        end
                    end,
                    desc = "Create Zettelkasten note"
                },
            },
            -- Required for search and completion
            completion = {
                nvim_cmp = true,
                min_chars = 2,
            },
        })
    end,
}
