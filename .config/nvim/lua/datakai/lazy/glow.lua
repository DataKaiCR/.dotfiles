-- glow.lua - Terminal-based markdown previewer
return {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    ft = { "markdown" },
    build = function()
        -- Attempt to auto-install glow if not present
        if vim.fn.executable("glow") == 0 then
            local os_name = vim.loop.os_uname().sysname

            if os_name == "Darwin" then
                -- macOS
                vim.fn.system("brew install glow")
                vim.notify("Installed glow via Homebrew", vim.log.levels.INFO)
            elseif os_name == "Linux" then
                -- Check if we're on Ubuntu/Debian
                if vim.fn.executable("apt") == 1 then
                    vim.fn.system("sudo apt install -y glow")
                    vim.notify("Installed glow via apt", vim.log.levels.INFO)
                    -- Check for Arch-based distros
                elseif vim.fn.executable("pacman") == 1 then
                    vim.fn.system("sudo pacman -S glow")
                    vim.notify("Installed glow via pacman", vim.log.levels.INFO)
                else
                    vim.notify("Please install glow: https://github.com/charmbracelet/glow", vim.log.levels.WARN)
                end
            else
                -- Windows or other OS
                vim.notify("Please install glow: https://github.com/charmbracelet/glow", vim.log.levels.WARN)
            end
        end
    end,
    config = function()
        require("glow").setup({
            -- Style for the markdown preview (dark/light/auto)
            style = "dark",
            -- Width of the Glow window
            width = 120,
            -- Height ratio of the Glow window
            height_ratio = 0.8,
            -- Border style for the Glow window (shadow/rounded/double/single)
            border = "rounded",
            -- Don't open the Glow window as a pager
            pager = false,
            -- Path to the Glow executable
            -- Will try to automatically detect it if not set
            -- executable = "", -- Leave empty to auto-detect

            -- Integration with live-updating markdown plugins
            -- This updates the Glow window on changes (if visible)
            -- for good real-time previewing
            install_path = vim.fn.stdpath("data") .. "/site/pack/glow.nvim",
            -- Use Glow binary shipped with the plugin (Linux, MacOS)
            use_glow_in_snap = false,
            -- Additional Glow arguments passed
            glow_path = "",
        })

        -- Set up keybindings
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "markdown" },
            callback = function()
                -- Toggle Glow preview
                vim.keymap.set("n", "<leader>mgp", ":Glow<CR>",
                    { buffer = true, desc = "Preview markdown with Glow" })

                -- Open in current window
                vim.keymap.set("n", "<leader>mgc", ":Glow!<CR>",
                    { buffer = true, desc = "Preview markdown in current window" })
            end
        })

        -- Create commands to check if Glow is properly installed
        vim.api.nvim_create_user_command("GlowCheck", function()
            if vim.fn.executable("glow") == 1 then
                local version = vim.fn.system("glow --version"):gsub("\n", "")
                vim.notify("✅ Glow is installed: " .. version, vim.log.levels.INFO)
            else
                vim.notify("❌ Glow is not installed. Run :GlowInstall to install it.", vim.log.levels.ERROR)
            end
        end, {})

        -- Command to install Glow
        vim.api.nvim_create_user_command("GlowInstall", function()
            local os_name = vim.loop.os_uname().sysname

            if os_name == "Darwin" then
                -- macOS
                vim.fn.system("brew install glow")
                vim.notify("Installing glow via Homebrew...", vim.log.levels.INFO)
            elseif os_name == "Linux" then
                -- Check if WSL
                local is_wsl = vim.fn.system("uname -r"):match("WSL") ~= nil

                if is_wsl or vim.fn.executable("apt") == 1 then
                    -- Ubuntu/Debian
                    vim.fn.jobstart("sudo apt install -y glow", {
                        on_exit = function(_, code)
                            if code == 0 then
                                vim.notify("Glow installed successfully!", vim.log.levels.INFO)
                            else
                                vim.notify("Failed to install Glow via apt", vim.log.levels.ERROR)
                            end
                        end
                    })
                elseif vim.fn.executable("pacman") == 1 then
                    -- Arch
                    vim.fn.jobstart("sudo pacman -S glow", {
                        on_exit = function(_, code)
                            if code == 0 then
                                vim.notify("Glow installed successfully!", vim.log.levels.INFO)
                            else
                                vim.notify("Failed to install Glow via pacman", vim.log.levels.ERROR)
                            end
                        end
                    })
                else
                    -- Other Linux or manual install
                    vim.notify("Installing Glow via curl...", vim.log.levels.INFO)
                    vim.fn.jobstart(
                        "curl -fsSL https://raw.githubusercontent.com/charmbracelet/glow/main/install.sh | bash", {
                            on_exit = function(_, code)
                                if code == 0 then
                                    vim.notify("Glow installed successfully!", vim.log.levels.INFO)
                                else
                                    vim.notify(
                                        "Failed to install Glow. Please install manually: https://github.com/charmbracelet/glow",
                                        vim.log.levels.ERROR)
                                end
                            end
                        })
                end
            elseif os_name:match("Windows") then
                -- Windows
                vim.notify(
                    "On Windows, please install glow manually:\n1. Install scoop from https://scoop.sh\n2. Run 'scoop install glow'",
                    vim.log.levels.INFO)
            else
                vim.notify("Unknown OS. Please install glow manually: https://github.com/charmbracelet/glow",
                    vim.log.levels.WARN)
            end
        end, {})
    end,
}
