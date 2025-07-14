return {
    -- Docker integration
    {
        "dgrbrady/nvim-docker",
        ft = { "dockerfile", "yaml", "json" },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            -- Docker keymaps
            vim.keymap.set("n", "<leader>kd", "<cmd>DockerContainers<cr>", { desc = "List Docker containers" })
            vim.keymap.set("n", "<leader>ki", "<cmd>DockerImages<cr>", { desc = "List Docker images" })
            vim.keymap.set("n", "<leader>kc", "<cmd>DockerCompose<cr>", { desc = "Docker compose commands" })
            vim.keymap.set("n", "<leader>ks", "<cmd>DockerSwarm<cr>", { desc = "Docker swarm commands" })
            vim.keymap.set("n", "<leader>kn", "<cmd>DockerNetworks<cr>", { desc = "List Docker networks" })
            vim.keymap.set("n", "<leader>kv", "<cmd>DockerVolumes<cr>", { desc = "List Docker volumes" })
        end,
    },

    -- Dockerfile syntax highlighting improvements
    {
        "ekalinin/Dockerfile.vim",
        ft = "dockerfile",
    },

    -- Docker compose file support (already handled by yamlls in lsp.lua)
    -- but this adds specific docker-compose commands
    {
        "https://codeberg.org/esensar/nvim-dev-container",
        dependencies = "nvim-treesitter/nvim-treesitter",
        ft = { "dockerfile", "yaml", "json" },
        config = function()
            require("devcontainer").setup({
                -- By default, all mounts are added (config, data and state)
                -- This can be changed to only include mounts you need
                nvim_data_dir_mount = "always",
                nvim_config_dir_mount = "always",
                nvim_state_dir_mount = "always",
                -- By default, if no .devcontainer directory is found
                -- in project root, it will check for a Dockerfile
                search_strategy = "auto",
                -- Additional mounts for the container
                mounts = {},
                -- Container runtime to use (docker or podman)
                container_runtime = "docker",
                -- Docker/Podman binary path
                docker_path = "docker",
                -- Additional arguments to pass to docker run
                run_args = {},
            })
        end,
        keys = {
            { "<leader>cdu", function() require('datakai.utils.devcontainer').start() end, desc = "Start devcontainer" },
            { "<leader>cde", function() require('datakai.utils.devcontainer').exec() end, desc = "Execute in devcontainer" },
            { "<leader>cdb", function() require('datakai.utils.devcontainer').build() end, desc = "Build devcontainer" },
        },
    },
}