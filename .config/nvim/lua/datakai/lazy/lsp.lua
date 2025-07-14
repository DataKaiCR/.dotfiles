return {
    --'mason-tool-installer',
    'neovim/nvim-lspconfig',
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
    },


    config = function()
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

        require('mason').setup()
        require('mason-lspconfig').setup({
            ensure_installed = {
                'lua_ls',
                'rust_analyzer',
                'jsonls',
                'ruff',  -- Modern Python linter/formatter
                'basedpyright',  -- Better Pyright fork for Python
                'zls',
                'powershell_es',
                'marksman',
                'sqlls',
                -- 'gopls',
                'bashls',
                'yamlls',
                'taplo',
                'dockerls',
                'docker_compose_language_service',  -- Docker compose support
                -- 'metalls',
                -- 'jedi_language_server'  -- Replaced by basedpyright
            },
            handlers = {
                function(server_name)
                    require('lspconfig')[server_name].setup {}
                end,

                ['basedpyright'] = function()
                    local lspconfig = require('lspconfig')
                    lspconfig.basedpyright.setup {
                        capabilities = capabilities,
                        settings = {
                            basedpyright = {
                                analysis = {
                                    typeCheckingMode = "standard",
                                    autoImportCompletions = true,
                                    diagnosticSeverityOverrides = {
                                        strictListInference = true,
                                        strictDictionaryInference = true,
                                        strictSetInference = true,
                                        reportUnusedImport = "warning",
                                        reportUnusedClass = "warning",
                                        reportUnusedFunction = "warning",
                                        reportUnusedVariable = "warning",
                                        reportUnusedCoroutine = "warning",
                                        reportDuplicateImport = "warning",
                                        reportPrivateUsage = "warning",
                                        reportUnusedExpression = "warning",
                                        reportConstantRedefinition = "error",
                                        reportIncompatibleMethodOverride = "error",
                                        reportMissingImports = "error",
                                        reportUndefinedVariable = "error",
                                        reportAssertAlwaysTrue = "error",
                                    }
                                }
                            }
                        }
                    }
                end,

                ['ruff'] = function()
                    local lspconfig = require('lspconfig')
                    lspconfig.ruff.setup {
                        capabilities = capabilities,
                        init_options = {
                            settings = {
                                -- Ruff settings
                                args = {
                                    "--line-length=88",
                                },
                            }
                        }
                    }
                end,
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
