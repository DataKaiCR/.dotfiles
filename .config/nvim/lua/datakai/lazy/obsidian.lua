return {
    "epwalsh/obsidian.nvim",
    version = "*",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    -- Load the plugin immediately rather than just on markdown files
    -- This ensures commands are available immediately when launching Neovim
    lazy = false,  -- Load immediately instead of lazy-loading
    priority = 50, -- Give it a higher priority for faster loading
    config = function()
        -- Require the note manager module
        local note_manager = require("datakai.utils.note_manager")

        require("obsidian").setup({
            workspaces = {
                {
                    name = "scriptorium",
                    path = "~/scriptorium",
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
                date_format = "%Y-%m-%d",
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
                -- Create note IDs with type prefix for filtering and uniqueness
                -- Daily notes are exception (just date)
                -- Format: [type]-[timestamp]-[slug]
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
                        -- Daily notes: just the date (never linked)
                        return os.date("%Y-%m-%d")
                    elseif vim.g.current_note_type == "zettel" then
                        return "zettel-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "project" then
                        return "project-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "area" then
                        return "area-" .. timestamp .. "-" .. suffix
                    elseif vim.g.current_note_type == "meeting" then
                        return "meeting-" .. timestamp .. "-" .. suffix
                    end
                end

                -- Default case if type isn't set
                return "note-" .. timestamp .. "-" .. suffix
            end,
            -- Disable frontmatter
            disable_frontmatter = true,
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

            -- Instead of mappings here, we'll setup keymaps separately
            mappings = {},

            -- Required for search and completion
            completion = {
                nvim_cmp = true,
                min_chars = 2,
            },
        })

        -- Setup keymaps from our dedicated module
        require("datakai.utils.obsidian_keymaps").setup()
    end,
}
