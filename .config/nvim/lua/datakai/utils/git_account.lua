local M = {}

-- Define your Git accounts here
M.accounts = {
    ["DataKaiCR"] = {
        name = "datakaicr",
        email = "hstecher@datakai.net",
    },
    ["West Monroe"] = {
        name = "wmhstecher",
        email = "hstecher@westmonroe.com",
    },
    ["Trulieve"] = {
        name = "hstecher-trulieve",
        email = "heinz.stecher@trulieve.com",
    },
    -- Add more accounts as needed
}

-- Function to switch Git account
M.switch_account = function()
    -- Get account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end

    -- Sort account names
    table.sort(account_names)

    -- Show selection menu
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
    }, function(selected)
        if selected then
            local account = M.accounts[selected]

            -- Set Git config
            vim.fn.system("git config user.name '" .. account.name .. "'")
            vim.fn.system("git config user.email '" .. account.email .. "'")

            -- Get current config for confirmation
            local name = vim.fn.system("git config user.name"):gsub("\n", "")
            local email = vim.fn.system("git config user.email"):gsub("\n", "")

            vim.notify("Git account switched to: " .. name .. " <" .. email .. ">", vim.log.levels.INFO)
        end
    end)
end

-- Function to create a new worktree with specific config
M.create_worktree = function()
    -- Get branch name
    local branch = vim.fn.input("New branch name: ")
    if branch == "" then return end

    -- Get worktree path
    local default_path = vim.fn.getcwd() .. "/../" .. branch
    local path = vim.fn.input({
        prompt = "Worktree path: ",
        default = default_path,
        completion = "dir"
    })
    if path == "" then return end

    -- Get account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Show selection menu for accounts
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
    }, function(selected)
        if selected then
            local account = M.accounts[selected]

            -- Create the worktree
            vim.fn.system(string.format("git worktree add -b %s %s", branch, path))

            -- Configure client-specific Git settings
            vim.fn.system(string.format(
                "cd %s && git config user.name '%s' && git config user.email '%s'",
                path, account.name, account.email
            ))

            vim.notify(string.format(
                "Created worktree at %s with account %s <%s>",
                path, account.name, account.email
            ), vim.log.levels.INFO)
        end
    end)
end

return M
