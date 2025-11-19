-- which-key.lua - Keybinding discovery and documentation
-- Shows available keybindings as you type

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300  -- Show which-key after 300ms
    end,
    config = function()
        local wk = require("which-key")

        wk.setup({
            preset = "modern",  -- v3 preset (modern, classic, helix)
            delay = 300,  -- delay before showing which-key (replaces timeout)
            plugins = {
                marks = true,
                registers = true,
                spelling = {
                    enabled = true,
                    suggestions = 20,
                },
                presets = {
                    operators = true,
                    motions = true,
                    text_objects = true,
                    windows = true,
                    nav = true,
                    z = true,
                    g = true,
                },
            },
        })

        -- Register key groups and bindings using v3 add() API
        wk.add({
            -- Key groups
            { "<leader>d", group = "debug/dap" },
            { "<leader>df", group = "dotfiles" },
            { "<leader>g", group = "git" },
            { "<leader>ga", group = "git-account" },
            { "<leader>p", group = "telescope" },
            { "<leader>v", group = "lsp/venv" },
            { "<leader>r", group = "repl/run" },
            { "<leader>z", group = "zettel/notes" },
            { "<leader>k", group = "docker" },
            { "<leader>cd", group = "devcontainer" },
            { "<leader>sq", group = "sql" },
            { "<leader>s", group = "sql/search" },
            { "<leader>h", group = "harpoon" },
            { "<leader>t", group = "tmux" },
            { "<leader>m", group = "markdown" },
            { "<leader>n", group = "notes/docstring" },

            -- Debug/DAP
            { "<leader>db", desc = "Toggle breakpoint" },
            { "<leader>dB", desc = "Conditional breakpoint" },
            { "<leader>dc", desc = "Continue debugging" },
            { "<leader>dC", desc = "Run to cursor" },
            { "<leader>di", desc = "Step into" },
            { "<leader>do", desc = "Step out" },
            { "<leader>dO", desc = "Step over" },
            { "<leader>dr", desc = "Toggle REPL" },
            { "<leader>ds", desc = "Debug session" },
            { "<leader>dt", desc = "Terminate" },
            { "<leader>du", desc = "Toggle DAP UI" },

            -- Dotfiles
            { "<leader>dfs", desc = "Dotfiles status" },
            { "<leader>dfa", desc = "Dotfiles add current" },
            { "<leader>dfA", desc = "Dotfiles add all" },
            { "<leader>dfc", desc = "Dotfiles commit" },
            { "<leader>dfp", desc = "Dotfiles push" },
            { "<leader>dfl", desc = "Dotfiles pull" },

            -- Git Account
            { "<leader>gas", desc = "Switch git account" },
            { "<leader>gal", desc = "List git accounts" },
            { "<leader>gaa", desc = "Add git account" },
            { "<leader>gar", desc = "Remove git account" },
            { "<leader>gai", desc = "Init repo with account" },

            -- Telescope
            { "<leader>pf", desc = "Find files" },
            { "<C-p>", desc = "Git files" },
            { "<leader>ps", desc = "Grep search" },
            { "<leader>pb", desc = "Browse buffers" },

            -- LSP
            { "<leader>vws", desc = "Workspace symbols" },
            { "<leader>vd", desc = "Diagnostics float" },
            { "<leader>vca", desc = "Code actions" },
            { "<leader>vrr", desc = "Find references" },
            { "<leader>vrn", desc = "Rename symbol" },

            -- Python venv
            { "<leader>vs", desc = "Select venv" },
            { "<leader>vc", desc = "Select cached venv" },

            -- REPL
            { "<leader>rs", desc = "Start REPL" },
            { "<leader>rr", desc = "Restart REPL" },
            { "<leader>rf", desc = "Send file to REPL" },
            { "<leader>rl", desc = "Send line to REPL" },
            { "<leader>rc", desc = "Send selection to REPL" },

            -- Harpoon
            { "<leader>ha", desc = "Harpoon add" },
            { "<leader>hh", desc = "Harpoon menu" },
            { "<leader>h1", desc = "Harpoon file 1" },
            { "<leader>h2", desc = "Harpoon file 2" },
            { "<leader>h3", desc = "Harpoon file 3" },
            { "<leader>h4", desc = "Harpoon file 4" },

            -- SQL
            { "<leader>sqt", desc = "Toggle DB UI" },
            { "<leader>sqf", desc = "Find DB buffer" },
            { "<leader>sqa", desc = "Add DB connection" },
            { "<leader>se", desc = "Execute SQL query" },
            { "<leader>ss", desc = "Save SQL query" },

            -- Docker
            { "<leader>kc", desc = "Docker compose" },
            { "<leader>ks", desc = "Docker swarm" },

            -- Devcontainer
            { "<leader>cdu", desc = "Start devcontainer" },
            { "<leader>cde", desc = "Execute in devcontainer" },
            { "<leader>cdb", desc = "Build devcontainer" },

            -- Tmux
            { "<C-f>", desc = "Tmux sessionizer" },
            { "<leader>tw", desc = "Tmux workspace" },

            -- Format
            { "<F3>", desc = "Format file" },

            -- Reload/Source
            { "<leader><leader>", desc = "Source current file" },
        })
    end,
}
