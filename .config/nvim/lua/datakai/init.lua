require('datakai.lazy_init')
require('datakai.remap')
require('datakai.set')
require('datakai.utils.markdown_tools').setup()
require('datakai.utils.git_dotfiles_keymaps')


local augroup = vim.api.nvim_create_augroup
local DataKaiGroup = augroup('DataKai', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

function R(name)
    require('plenary.reload').reload_module(name)
end

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

--autocmd({'BufWritePre'}, {
--    group = DataKaiGroup,
--    pattern = '*',
--    command = [[%s/\s/+$//e]],
--})

autocmd('LspAttach', {
    group = DataKaiGroup,
    callback = function(e)
        local opts = { buffer = e.buf }

        vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
        vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end, opts)
    end

})

-- Python specific keymaps
autocmd('FileType', {
    group = DataKaiGroup,
    pattern = 'python',
    callback = function()
        local opts = { buffer = true }
        vim.keymap.set('n', '<leader>rp', ':w<CR>:!python3 %<CR>', vim.tbl_extend('force', opts, { desc = 'Run Python file' }))
        vim.keymap.set('n', '<leader>ri', ':w<CR>:!python3 -i %<CR>', vim.tbl_extend('force', opts, { desc = 'Run Python file (interactive)' }))
    end
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25


vim.opt.conceallevel = 2
vim.g.markdown_fenced_languages = {
    'bash', 'javascript', 'js=javascript', 'python', 'html', 'css', 'rust', 'go'
}
