return {
    -- Better code block rendering
    {
        "lukas-reineke/indent-blankline.nvim",
        event = "BufReadPre",
        config = function()
            require("ibl").setup()
        end
    },

    -- Focus mode for writing
    {
        "folke/twilight.nvim",
        cmd = "Twilight",
        config = function()
            require("twilight").setup({
                dimming = {
                    alpha = 0.25,
                },
                context = 10,
                treesitter = true,
            })
        end
    },

    -- Distraction-free writing
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        config = function()
            require("zen-mode").setup({
                window = {
                    width = 0.85,
                },
            })
        end
    },

    -- Mini.nvim components that help with code blocks
    {
        "echasnovski/mini.indentscope",
        event = "BufReadPre",
        config = function()
            require("mini.indentscope").setup()
        end
    },

    {
        "echasnovski/mini.pairs",
        event = "InsertEnter",
        config = function()
            require("mini.pairs").setup()
        end
    },
}
