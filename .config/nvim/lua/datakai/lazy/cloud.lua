-- cloud.lua - Cloud platform integrations (AWS, Databricks, Terraform)
-- Provides LSP, syntax, and workflow support for cloud development
-- Note: LSP servers (yamlls, terraformls) should be installed via Mason

return {
    -- Terraform syntax and formatting
    {
        "hashivim/vim-terraform",
        ft = { "terraform", "hcl", "tf", "tfvars" },
        config = function()
            vim.g.terraform_fmt_on_save = 1
            vim.g.terraform_align = 1
        end
    },

    -- Documentation generation for multiple languages
    {
        "kkoomen/vim-doge",
        ft = { "python", "javascript", "typescript", "terraform" },
        build = ":call doge#install()",
        cmd = { "DogeGenerate", "DogeCreateDocStandard" },
        config = function()
            vim.g.doge_doc_standard_python = "google"
            vim.g.doge_comment_interactive = 1
        end
    },
}
