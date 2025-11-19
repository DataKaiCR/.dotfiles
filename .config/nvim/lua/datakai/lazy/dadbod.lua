-- dadbod.lua - Database management and SQL workflow
-- Provides DBUI, query execution, and completion for SQL databases

return {
    -- Core dadbod (database interface)
    {
        "tpope/vim-dadbod",
        cmd = { "DB", "DBUIToggle" },
    },

    -- Database UI
    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = { "tpope/vim-dadbod" },
        cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
        keys = {
            { "<leader>sqt", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
            { "<leader>sqf", "<cmd>DBUIFindBuffer<cr>", desc = "Find DB buffer" },
            { "<leader>sqa", "<cmd>DBUIAddConnection<cr>", desc = "Add DB connection" },
            { "<leader>sqr", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename DB buffer" },
            { "<leader>sqi", "<cmd>DBUILastQueryInfo<cr>", desc = "Last query info" },
        },
        init = function()
            -- UI settings
            vim.g.db_ui_use_nerd_fonts = 1
            vim.g.db_ui_show_database_icon = 1
            vim.g.db_ui_force_echo_notifications = 1
            vim.g.db_ui_win_position = "right"
            vim.g.db_ui_winwidth = 40

            -- Auto-execute queries
            vim.g.db_ui_auto_execute_table_helpers = 1

            -- Save location for queries
            vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"

            -- Default table helpers to show
            vim.g.db_ui_table_helpers = {
                postgresql = {
                    Count = "SELECT COUNT(*) FROM {table}",
                    Describe = "\\d+ {table}",
                    Indexes = "SELECT * FROM pg_indexes WHERE tablename = '{table}'",
                    ["First 100"] = "SELECT * FROM {table} LIMIT 100",
                },
                mysql = {
                    Count = "SELECT COUNT(*) FROM {table}",
                    Describe = "DESCRIBE {table}",
                    ["First 100"] = "SELECT * FROM {table} LIMIT 100",
                },
                sqlite = {
                    Count = "SELECT COUNT(*) FROM {table}",
                    Schema = "SELECT sql FROM sqlite_master WHERE name = '{table}'",
                    ["First 100"] = "SELECT * FROM {table} LIMIT 100",
                },
            }
        end,
        config = function()
            -- Auto-completion setup for SQL files
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sql", "mysql", "plsql" },
                callback = function()
                    require("cmp").setup.buffer({
                        sources = {
                            { name = "vim-dadbod-completion" },
                            { name = "buffer" },
                        },
                    })
                end,
            })

            -- Execute query keymaps for SQL buffers
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sql", "mysql", "plsql" },
                callback = function()
                    vim.keymap.set("n", "<leader>se", "<Plug>(DBUI_ExecuteQuery)",
                        { buffer = true, desc = "Execute SQL query" })
                    vim.keymap.set("v", "<leader>se", "<Plug>(DBUI_ExecuteQuery)",
                        { buffer = true, desc = "Execute SQL selection" })
                    vim.keymap.set("n", "<leader>ss", "<Plug>(DBUI_SaveQuery)",
                        { buffer = true, desc = "Save SQL query" })
                end,
            })
        end,
    },

    -- SQL completion
    {
        "kristijanhusak/vim-dadbod-completion",
        dependencies = { "tpope/vim-dadbod", "hrsh7th/nvim-cmp" },
        ft = { "sql", "mysql", "plsql" },
    },
}
