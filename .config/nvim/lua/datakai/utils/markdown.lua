local M = {}

function M.setup()
    local group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function()
            local opt = vim.opt_local

            -- Better display
            opt.wrap = true
            opt.linebreak = true
            opt.list = false
            opt.conceallevel = 2
            opt.concealcursor = 'nc'

            -- Add extra syntax highlighting for code blocks
            vim.cmd([[
                syntax match markdownBlockStart "^```.*$"
                syntax match markdownBlockEnd "^```$"
                hi def link markdownBlockStart Comment
                hi def link markdownBlockEnd Comment
            ]])
        end
    })
end

return M
