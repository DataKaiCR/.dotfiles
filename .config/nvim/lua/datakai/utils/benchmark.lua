-- benchmark.lua - Neovim startup and performance profiling utilities
-- Provides tools to measure and optimize startup time

local M = {}

-- Measure startup time
M.measure_startup = function()
    -- Use nvim --startuptime to measure startup
    local temp_file = vim.fn.tempname()
    local cmd = string.format("nvim --headless --startuptime %s +qall", temp_file)

    vim.notify("Measuring startup time...", vim.log.levels.INFO)

    vim.fn.system(cmd)

    -- Read the results
    if vim.fn.filereadable(temp_file) == 1 then
        local lines = vim.fn.readfile(temp_file)
        local total_time = "Unknown"

        -- Last line usually has total time
        if #lines > 0 then
            local last_line = lines[#lines]
            total_time = last_line:match("(%d+%.%d+)") or total_time
        end

        -- Create a new buffer to show results
        vim.cmd("new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.bo.filetype = "startuptime"
        vim.bo.buftype = "nofile"
        vim.api.nvim_buf_set_name(0, "Startup Time: " .. total_time .. "ms")

        -- Make it read-only
        vim.bo.modifiable = false

        vim.notify("Startup time: " .. total_time .. "ms", vim.log.levels.INFO)
    else
        vim.notify("Failed to measure startup time", vim.log.levels.ERROR)
    end

    -- Cleanup
    vim.fn.delete(temp_file)
end

-- Profile Neovim using built-in profiler
M.profile_start = function()
    vim.cmd("profile start /tmp/nvim-profile.log")
    vim.cmd("profile func *")
    vim.cmd("profile file *")
    vim.notify("Profiling started. Results will be saved to /tmp/nvim-profile.log", vim.log.levels.INFO)
    vim.notify("Run :ProfileStop when done", vim.log.levels.INFO)
end

M.profile_stop = function()
    vim.cmd("profile stop")
    vim.notify("Profiling stopped. View results: less /tmp/nvim-profile.log", vim.log.levels.INFO)

    -- Optionally open the profile log
    vim.ui.select({ "Yes", "No" }, {
        prompt = "Open profile log?",
    }, function(choice)
        if choice == "Yes" then
            vim.cmd("tabnew /tmp/nvim-profile.log")
        end
    end)
end

-- Show plugin load times (requires lazy.nvim)
M.plugin_times = function()
    local ok, lazy = pcall(require, "lazy")
    if not ok then
        vim.notify("Lazy.nvim not found", vim.log.levels.ERROR)
        return
    end

    -- Get lazy stats
    local stats = lazy.stats()

    -- Create a new buffer
    vim.cmd("new")

    local lines = {
        "=== Lazy.nvim Plugin Statistics ===",
        "",
        string.format("Total plugins: %d", stats.count),
        string.format("Loaded: %d", stats.loaded),
        string.format("Startup time: %.2fms", stats.startuptime),
        "",
        "=== Slowest Plugins ===",
        "",
    }

    -- Get individual plugin times (this is a simplified view)
    -- For detailed info, use :Lazy profile
    table.insert(lines, "For detailed plugin profiling, run :Lazy profile")
    table.insert(lines, "")

    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.filetype = "markdown"
    vim.bo.buftype = "nofile"
    vim.api.nvim_buf_set_name(0, "Plugin Load Times")
    vim.bo.modifiable = false
end

-- Benchmark specific operations
M.benchmark_operation = function(name, fn, iterations)
    iterations = iterations or 100

    local start_time = vim.loop.hrtime()

    for _ = 1, iterations do
        fn()
    end

    local end_time = vim.loop.hrtime()
    local total_ms = (end_time - start_time) / 1000000
    local avg_ms = total_ms / iterations

    vim.notify(string.format(
        "%s: %.2fms total, %.4fms avg (%d iterations)",
        name, total_ms, avg_ms, iterations
    ), vim.log.levels.INFO)

    return { total = total_ms, average = avg_ms, iterations = iterations }
end

-- Health check for configuration
M.health_check = function()
    local issues = {}
    local config = require("datakai.config")

    -- Check critical paths exist
    if vim.fn.isdirectory(config.workspace.projects_dir) ~= 1 then
        table.insert(issues, "❌ Projects directory not found: " .. config.workspace.projects_dir)
    else
        table.insert(issues, "✅ Projects directory OK")
    end

    if vim.fn.isdirectory(config.knowledge.vault_path) ~= 1 then
        table.insert(issues, "❌ Vault directory not found: " .. config.knowledge.vault_path)
    else
        table.insert(issues, "✅ Vault directory OK")
    end

    if vim.fn.filereadable(config.ssh.config_path) ~= 1 then
        table.insert(issues, "⚠️  SSH config not found: " .. config.ssh.config_path)
    else
        table.insert(issues, "✅ SSH config OK")
    end

    -- Check LSP servers
    local lsp_servers = { "lua_ls", "basedpyright", "ts_ls", "rust_analyzer" }
    for _, server in ipairs(lsp_servers) do
        local clients = vim.lsp.get_active_clients({ name = server })
        if #clients > 0 then
            table.insert(issues, "✅ LSP server running: " .. server)
        else
            table.insert(issues, "⚠️  LSP server not active: " .. server)
        end
    end

    -- Display results
    vim.cmd("new")
    local header = {
        "=== Neovim Configuration Health Check ===",
        "",
        "Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
        "",
    }

    local all_lines = vim.list_extend(header, issues)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, all_lines)
    vim.bo.filetype = "markdown"
    vim.bo.buftype = "nofile"
    vim.api.nvim_buf_set_name(0, "Health Check")
    vim.bo.modifiable = false
end

-- Create user commands
vim.api.nvim_create_user_command("StartupTime", M.measure_startup, {})
vim.api.nvim_create_user_command("ProfileStart", M.profile_start, {})
vim.api.nvim_create_user_command("ProfileStop", M.profile_stop, {})
vim.api.nvim_create_user_command("PluginTimes", M.plugin_times, {})
vim.api.nvim_create_user_command("HealthCheck", M.health_check, {})

return M
