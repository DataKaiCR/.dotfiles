-- Set Leader key to space

vim.g.mapleader = " "

-- Disable space key default behavior
vim.keymap.set({"n"}, "<Space>", "<Nop>", { silent = true })
-- mapping to exit using leader key
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<leader>u", ":UndotreeShow<CR>")

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")




vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd('so')
end)
