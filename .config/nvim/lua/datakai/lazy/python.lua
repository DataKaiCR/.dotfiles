return {
    -- Environment selector for virtual environments
    {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-telescope/telescope.nvim",
            "mfussenegger/nvim-dap-python"
        },
        branch = "main",
        ft = "python",
        config = function()
            require("venv-selector").setup({
                -- Automatically set virtual environment when opening Python files
                auto_refresh = true,
                -- DAP support
                dap_enabled = true,
                -- Poetry/Pyenv detection
                poetry_path = "poetry",
                pyenv_path = "pyenv",
                -- Search settings
                search_venv_managers = true,
                search_workspace = true,
                search = true,
                -- Virtual environment names to search for
                name = {
                    "venv",
                    ".venv",
                    "env",
                    ".env",
                },
                -- Notification settings
                notify_user_on_activate = true,
            })
        end,
        keys = {
            { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select virtualenv" },
            { "<leader>vc", "<cmd>VenvSelectCached<cr>", desc = "Select cached virtualenv" },
        },
    },

    -- REPL support for interactive Python development
    {
        "Vigemus/iron.nvim",
        ft = { "python" },
        config = function()
            local iron = require("iron.core")
            iron.setup({
                config = {
                    -- Should the repl be opened in a vertical split
                    repl_open_cmd = require("iron.view").split.vertical.botright(0.4),
                    -- Your repl definitions
                    repl_definition = {
                        python = {
                            command = function()
                                -- Check if ipython is available, otherwise use python3
                                if vim.fn.executable("ipython") == 1 then
                                    return { "ipython", "--no-autoindent" }
                                else
                                    return { "python3" }
                                end
                            end,
                            format = require("iron.fts.common").bracketed_paste_python
                        },
                    },
                },
                keymaps = {
                    send_motion = "<leader>rc",
                    visual_send = "<leader>rc",
                    send_file = "<leader>rf",
                    send_line = "<leader>rl",
                    send_until_cursor = "<leader>ru",
                    send_mark = "<leader>rm",
                    mark_motion = "<leader>rmc",
                    mark_visual = "<leader>rmc",
                    remove_mark = "<leader>rmd",
                    cr = "<leader>r<cr>",
                    interrupt = "<leader>r<space>",
                    exit = "<leader>rq",
                    clear = "<leader>rx",
                },
                -- Highlight the last sent block
                highlight = {
                    italic = true
                },
                ignore_blank_lines = true,
            })
        end,
        keys = {
            { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Start Python REPL" },
            { "<leader>rr", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
            { "<leader>rf", "<cmd>IronFocus<cr>", desc = "Focus REPL" },
            { "<leader>rh", "<cmd>IronHide<cr>", desc = "Hide REPL" },
        },
    },

    -- Better Python indentation
    {
        "Vimjas/vim-python-pep8-indent",
        ft = "python",
    },

    -- Python docstring generation
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        ft = "python",
        config = function()
            require("neogen").setup({
                enabled = true,
                languages = {
                    python = {
                        template = {
                            annotation_convention = "google_docstrings"  -- or "numpydoc", "reST"
                        }
                    },
                }
            })
        end,
        keys = {
            { "<leader>nd", "<cmd>Neogen<cr>", desc = "Generate docstring" },
        },
    },

    -- Python text objects (function, class, etc.)
    {
        "jeetsukumaran/vim-pythonsense",
        ft = "python",
    },


    -- Jupyter notebook support (optional - comment out if not needed)
    {
        "GCBallesteros/jupytext.nvim",
        ft = { "python", "markdown" },
        config = function()
            require("jupytext").setup({
                style = "markdown",
                output_extension = "md",
                force_ft = "markdown",
            })
        end,
    },
}