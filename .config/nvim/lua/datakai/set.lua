vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.opt.clipboard = "unnamedplus"
-- WSL clipboard integration
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
elseif vim.fn.has("mac") == 1 then
  -- macOS uses pbcopy and pbpaste by default, handled by unnamedplus
  -- No additional configuration needed
elseif vim.fn.has("unix") == 1 then
  -- For Linux, ensure xclip or xsel is installed
  if vim.fn.executable("xclip") == 1 then
    -- Configuration is handled by unnamedplus
  elseif vim.fn.executable("xsel") == 1 then
    -- Configuration is handled by unnamedplus
  else
    vim.notify("Please install xclip or xsel for clipboard support", vim.log.levels.WARN)
  end
end

-- Optimize performance for WSL
vim.opt.shadafile = "NONE"
vim.opt.swapfile = false
vim.opt.updatetime = 50

-- Set conceallevel for Obsidian markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
  end
})

-- Enable digraph support for international characters
vim.opt.digraph = true


-- Auto-format markdown files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.md",
  callback = function()
    -- Fix common markdown issues
    
    -- Convert spaces at beginning of list items
    vim.cmd([[silent! %s/^\( *\)- /\1- /ge]])
    
    -- Fix trailing spaces
    vim.cmd([[silent! %s/\s\+$//ge]])
    
    -- Ensure single blank line between sections
    vim.cmd([[silent! %s/\(\n\n\)\n\+/\1/ge]])
    
    -- Format tables if available
    if vim.fn.exists(':TableFormat') > 0 then
      vim.cmd('TableFormat')
    end
  end,
})

-- Auto-format on save for specific file types
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.lua", "*.py", "*.js", "*.jsx", "*.ts", "*.tsx" },  -- Add your file types
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
