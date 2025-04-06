return {
    -- Browser-based markdown preview
    {
        "iamcco/markdown-preview.nvim",
        ft = "markdown",
        cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
        build = function() vim.fn["mkdp#util#install"]() end,
        init = function()
            -- Set browser based on platform
            if vim.fn.has("wsl") == 1 then
                vim.g.mkdp_browser = 'wslview'
            elseif vim.fn.has("mac") == 1 then
                vim.g.mkdp_browser = 'open'
            elseif vim.fn.has("unix") == 1 then
                vim.g.mkdp_browser = 'xdg-open'
            end

            -- Preview settings
            vim.g.mkdp_auto_start = 0
            vim.g.mkdp_auto_close = 0
            vim.g.mkdp_refresh_slow = 0
            vim.g.mkdp_echo_preview_url = 0

            -- Preview page title
            vim.g.mkdp_page_title = '「${name}」'
        end
    },

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
