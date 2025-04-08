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
                'ruff_lsp',
                'zls',
                'powershell_es',
                -- 'pyright',
                'marksman',
                'sqlls',
                -- 'gopls',
                'bashls',
                'yamlls',
                'taplo',
                'dockerls',
                'metalls',
                'jedi_language_server'
            },
            handlers = {
                function(server_name)
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

        -- require('mason-tool-installer').setup({
        --     ensure_installed = {
        --         'black',
        --         'ruff',
        --         'pyright',
        --         'debugpy',
        --         'lua-language-server',
        --         'rust_analyzer',
        --         'json-lsp',
        --         'codelldb'
        --     }
        -- })
        require('lspconfig').yamlls.setup {
            settings = {
                yaml = {
                    schemas = {
                        ["https://raw.githubusercontent.com/databricks/databricks-cli/main/databricks_cli/workspace/databricks.yaml"] = "/*databricks*.{yml,yaml}",
                        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                        ["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = "*docker-compose*.{yml,yaml}",
                        -- Add other schemas as needed
                    },
                    format = { enabled = true },
                    validate = true,
                    completion = true,
                },
            },
        }
    end
}
