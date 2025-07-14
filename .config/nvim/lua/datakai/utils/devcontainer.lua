-- Simple devcontainer utilities
local M = {}

-- Get the current project root (look for pyproject.toml or .git)
local function get_project_root()
    local cwd = vim.fn.getcwd()
    local root = vim.fn.finddir('.git', cwd .. ';')
    if root ~= '' then
        return vim.fn.fnamemodify(root, ':h')
    end
    
    -- Look for pyproject.toml
    local pyproject = vim.fn.findfile('pyproject.toml', cwd .. ';')
    if pyproject ~= '' then
        return vim.fn.fnamemodify(pyproject, ':h')
    end
    
    return cwd
end

-- Start devcontainer
function M.start()
    local root = get_project_root()
    local cmd = string.format('cd %s && docker run -it --rm -v $(pwd):/workspace -v ~/.config/nvim:/home/vscode/.config/nvim -p 8888:8888 genai-dev bash', root)
    
    -- Open terminal with the command
    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
end

-- Run command in existing container
function M.exec(command)
    local root = get_project_root()
    local cmd = string.format('cd %s && docker exec -it $(docker ps -q --filter ancestor=genai-dev) %s', root, command or 'bash')
    
    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
end

-- Build devcontainer
function M.build()
    local root = get_project_root()
    local cmd = string.format('cd %s && docker build --no-cache -t genai-dev -f .devcontainer/Dockerfile .', root)
    
    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
end

return M