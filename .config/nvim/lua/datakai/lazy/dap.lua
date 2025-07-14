return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "mfussenegger/nvim-dap-python",
        "theHamsta/nvim-dap-virtual-text",
    },
    ft = { "python", "rust", "javascript", "typescript" },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        -- Setup DAP UI
        dapui.setup({
            icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
            mappings = {
                -- Use a table to apply multiple mappings
                expand = { "<CR>", "<2-LeftMouse>" },
                open = "o",
                remove = "d",
                edit = "e",
                repl = "r",
                toggle = "t",
            },
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.25 },
                        "breakpoints",
                        "stacks",
                        "watches",
                    },
                    size = 40,
                    position = "left",
                },
                {
                    elements = {
                        "repl",
                        "console",
                    },
                    size = 0.25,
                    position = "bottom",
                },
            },
        })

        -- Virtual text for debugging
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            enabled_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
            only_first_definition = true,
            all_references = false,
            filter_references_pattern = "<module",
        })

        -- Python specific setup
        local dap_python = require("dap-python")
        -- Uses the venv selector to get the current Python interpreter
        dap_python.setup()
        dap_python.test_runner = "pytest"

        -- Debugger signs
        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
        vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "✗", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })

        -- Automatically open/close DAP UI
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end

        -- Keymaps
        vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        vim.keymap.set("n", "<leader>dB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Set conditional breakpoint" })
        vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue debugging" })
        vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run to cursor" })
        vim.keymap.set("n", "<leader>dg", dap.goto_, { desc = "Go to line (no execute)" })
        vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
        vim.keymap.set("n", "<leader>dj", dap.down, { desc = "Down in stack" })
        vim.keymap.set("n", "<leader>dk", dap.up, { desc = "Up in stack" })
        vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run last debug configuration" })
        vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step out" })
        vim.keymap.set("n", "<leader>dO", dap.step_over, { desc = "Step over" })
        vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Pause" })
        vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Toggle REPL" })
        vim.keymap.set("n", "<leader>ds", dap.session, { desc = "Session" })
        vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
        vim.keymap.set("n", "<leader>dw", require("dap.ui.widgets").hover, { desc = "Widgets" })
        vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
        vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "Eval expression" })
        vim.keymap.set("v", "<leader>de", dapui.eval, { desc = "Eval expression" })

        -- Python-specific keymaps
        vim.keymap.set("n", "<leader>dPt", dap_python.test_method, { desc = "Debug test method" })
        vim.keymap.set("n", "<leader>dPc", dap_python.test_class, { desc = "Debug test class" })
        vim.keymap.set("v", "<leader>dPs", dap_python.debug_selection, { desc = "Debug selection" })
    end,
}