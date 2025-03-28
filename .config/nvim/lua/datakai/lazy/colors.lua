function ColorMyPencils(color)
    color = color or 'rose-pine'
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
    {
        'folke/tokyonight.nvim',
        config = function()
            require('tokyonight').setup({
                style = 'storm',
                transparent = true,
                terminal_colors = true,
                styles = {
                    comments = { italics = false },
                    keyworks = { italics = false },

                    sidebars = 'dark',
                    floats = 'dark',
                },
                on_highlights = function(hl, c)
                    hl.markdownCode = { fg = c.green }
                    hl.markdownCodeBlock = { fg = c.green }
                end
            })
        end
    },

    {
        'rose-pine/neovim',
        name = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
            require('rose-pine').setup({
                disable_background = true
            })

            ColorMyPencils()
        end

    },

}
