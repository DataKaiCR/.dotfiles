-- peek.lua - Embedded markdown preview with Deno backend
return {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = "markdown",
    cmd = { "PeekOpen", "PeekClose" },
    config = function()
        require("peek").setup({
            auto_load = false,       -- Don't auto-open preview when entering markdown files
            close_on_bdelete = true, -- Close preview when buffer is deleted
            syntax = true,           -- Enable syntax highlighting
            theme = "dark",          -- Theme: 'dark' or 'light'
            update_on_change = true, -- Update preview on change
            app = "webview",         -- Use embedded webview
            throttle_at = 200000,    -- Throttle when file exceeds this size (in bytes)
            throttle_time = 500,     -- Throttle time in milliseconds

            -- File types that can be opened in peek
            file_types = { "markdown" },

            -- Default keymaps
            keymaps = {
                -- Close preview window
                close = "<Esc>",
                -- Press to scroll down in preview window
                page_down = "<PageDown>",
                -- Press to scroll up in preview window
                page_up = "<PageUp>",
            },
        })

        -- Create user commands for easier access
        if vim.fn.exists(":PeekOpen") <= 0 then
            vim.api.nvim_create_user_command("PeekOpen", function()
                local peek = require("peek")
                if not peek.is_open() then
                    peek.open()
                end
            end, {})

            vim.api.nvim_create_user_command("PeekClose", function()
                local peek = require("peek")
                if peek.is_open() then
                    peek.close()
                end
            end, {})

            vim.api.nvim_create_user_command("PeekToggle", function()
                local peek = require("peek")
                if peek.is_open() then
                    peek.close()
                else
                    peek.open()
                end
            end, {})
        end

        -- Set up keymaps for markdown files
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "markdown",
            callback = function()
                vim.keymap.set("n", "<leader>mp", ":PeekToggle<CR>",
                    { buffer = true, desc = "Toggle Peek markdown preview" })
                vim.keymap.set("n", "<leader>mo", ":PeekOpen<CR>",
                    { buffer = true, desc = "Open Peek markdown preview" })
                vim.keymap.set("n", "<leader>mc", ":PeekClose<CR>",
                    { buffer = true, desc = "Close Peek markdown preview" })
            end
        })

        -- Check if Deno is installed and provide installation instructions if not
        if vim.fn.executable("deno") == 0 then
            vim.defer_fn(function()
                vim.notify([[
Peek requires Deno to be installed.
To install Deno:

macOS/Linux:
curl -fsSL https://deno.land/install.sh | sh

Windows:
iwr https://deno.land/install.ps1 -useb | iex

Run :PeekInstall after installing Deno.
]], vim.log.levels.WARN)
            end, 1000)

            -- Create installation command
            vim.api.nvim_create_user_command("PeekInstall", function()
                vim.notify("Building Peek (this may take a moment)...", vim.log.levels.INFO)
                vim.fn.jobstart("cd " .. vim.fn.stdpath("data") .. "/lazy/peek.nvim && deno task --quiet build:fast", {
                    on_exit = function(_, code)
                        if code == 0 then
                            vim.notify("Peek successfully built!", vim.log.levels.INFO)
                        else
                            vim.notify("Failed to build Peek. Make sure Deno is installed correctly.",
                                vim.log.levels.ERROR)
                        end
                    end
                })
            end, {})
        end
    end,
}
