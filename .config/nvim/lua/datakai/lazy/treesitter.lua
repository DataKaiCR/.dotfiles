return {
    'nvim-treesitter/nvim-treesitter',

    build = ':TSUpdate',

    name = 'treesitter',

    config = function()
        -- A list of parser names, or "all" (the listed parsers MUST always be installed)
        require('nvim-treesitter.configs').setup({
            ensure_installed = { "sql", "css", "html", "javascript", "typescript", "python", "rust", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "bash", "yaml", "json", "toml" },

            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,

            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
            auto_install = true,

            indent = {
                enable = true
            },

            highlight = {
                enable = true,
                -- Disable treesitter for dockerfile to avoid parser issues
                disable = { "dockerfile" },
                -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
                -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
                -- Using this option may slow down your editor, and you may see some duplicate highlights.
                -- Instead of true it can also be a list of languages
                -- additional_vim_regex_highlighting = { 'markdown' },
                additional_vim_regex_highlighting = false,
            },
        })
    end
}
