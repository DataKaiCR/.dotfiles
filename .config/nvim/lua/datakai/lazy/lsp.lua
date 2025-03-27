return {
    --'mason-tool-installer',
    'neovim/nvim-lspconfig',
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
    },


    config = function()
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        --capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

        require('mason').setup()
        require('mason-lspconfig').setup({
            ensure_installed = { 
                'lua_ls', 
                'rust_analyzer',
                'jsonls',
                --'ts_ls',
                'zls',
                'powershell_es',
                'pyright',
                'marksman'
            },
            handlers = {
                function (server_name) 
                    require('lspconfig')[server_name].setup {}
                end,

                --                ['pyright'] = function()
                --                    local on_attach = {}
                --                    local capabilities = {} 
                --                    local lspconfig = require('lspconfig')
                --                    lspconfig.pyright.setup {
                --                        -- on_attach = on_attach,
                --                        capabilities = capabilities,
                --                        filetypes = {'python'},
                --                    }
                --                end,
            }
        })

        --   require('mason-tool-installer').setup({
        --       ensure_installed = {
        --           'black',
        --           'pylint',
        --           'mypy',
        --       }
        --   })
    end
}
