-- lualine.lua - Enhanced statusline with context (venv, git account, project)
-- Shows: mode, git branch, file, diagnostics, venv, git account, project, location

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
        local config = require("datakai.config")

        -- Custom component: Python virtual environment
        local function venv()
            local venv_name = os.getenv("VIRTUAL_ENV")
            if venv_name then
                -- Extract just the venv folder name
                local venv_parts = vim.split(venv_name, "/")
                return "🐍 " .. venv_parts[#venv_parts]
            end
            return ""
        end

        -- Custom component: Git account/identity
        local function git_account()
            -- Try to get current git user name
            local handle = io.popen("git config user.name 2>/dev/null")
            if handle then
                local result = handle:read("*a")
                handle:close()
                if result and result ~= "" then
                    result = result:gsub("%s+", "") -- trim whitespace
                    -- Show only first name or identifier
                    local first_part = vim.split(result, " ")[1]
                    return " " .. first_part
                end
            end
            return ""
        end

        -- Custom component: Project context (from .project.toml)
        local function project_info()
            -- Check if we're in a project directory with .project.toml
            local cwd = vim.fn.getcwd()
            local project_file = cwd .. "/.project.toml"

            if vim.fn.filereadable(project_file) == 1 then
                -- Try to extract project name from .project.toml
                local handle = io.open(project_file, "r")
                if handle then
                    for line in handle:lines() do
                        local name = line:match('^name%s*=%s*"(.-)"')
                        if name then
                            handle:close()
                            return "📁 " .. name
                        end
                    end
                    handle:close()
                end
            end
            return ""
        end

        -- LSP clients active
        local function lsp_clients()
            local clients = vim.lsp.get_active_clients({ bufnr = 0 })
            if #clients == 0 then
                return ""
            end

            local client_names = {}
            for _, client in ipairs(clients) do
                table.insert(client_names, client.name)
            end

            return "  " .. table.concat(client_names, ", ")
        end

        require("lualine").setup({
            options = {
                icons_enabled = config.ui.use_icons,
                theme = "auto",  -- auto-detect from colorscheme
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "", right = "" },
                disabled_filetypes = {
                    statusline = { "NvimTree", "neo-tree", "alpha", "dashboard" },
                    winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = true,  -- single statusline for all windows
                refresh = {
                    statusline = 1000,
                    tabline = 1000,
                    winbar = 1000,
                },
            },

            sections = {
                -- Left side
                lualine_a = { "mode" },
                lualine_b = {
                    "branch",
                    {
                        "diff",
                        colored = true,
                        symbols = { added = "+", modified = "~", removed = "-" },
                    },
                },
                lualine_c = {
                    {
                        "filename",
                        file_status = true,  -- displays file status (readonly, modified)
                        path = 1,            -- 0 = just filename, 1 = relative path, 2 = absolute path
                        shorting_target = 40,
                        symbols = {
                            modified = "[+]",
                            readonly = "[-]",
                            unnamed = "[No Name]",
                            newfile = "[New]",
                        },
                    },
                },

                -- Right side
                lualine_x = {
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic", "nvim_lsp" },
                        sections = { "error", "warn", "info", "hint" },
                        symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
                        colored = true,
                        update_in_insert = false,
                        always_visible = false,
                    },
                    { lsp_clients, color = { fg = "#7aa2f7" } },
                    { venv, color = { fg = "#9ece6a" } },
                    { git_account, color = { fg = "#bb9af7" } },
                    { project_info, color = { fg = "#7dcfff" } },
                },
                lualine_y = { "filetype", "encoding", "fileformat" },
                lualine_z = { "progress", "location" },
            },

            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },

            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = { "fugitive", "nvim-tree", "quickfix" },
        })
    end,
}
