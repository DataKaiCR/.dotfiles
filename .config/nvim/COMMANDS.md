# Neovim Commands Reference

## Python Development

### Running Python Files
- `<leader>rp` - Save and run current Python file
- `<leader>ri` - Save and run Python file in interactive mode (drops to REPL after execution)

### Python REPL (Iron.nvim)
- `<leader>rs` - Start Python REPL
- `<leader>rr` - Restart REPL
- `<leader>rf` - Send entire file to REPL
- `<leader>rl` - Send current line to REPL
- `<leader>rc` - Send motion/visual selection to REPL
- `<leader>ru` - Send from start to cursor position
- `<leader>rm` - Mark a block for repeated sending
- `<leader>rmc` - Mark motion/visual selection
- `<leader>rmd` - Remove mark
- `<leader>r<cr>` - Send carriage return to REPL
- `<leader>r<space>` - Interrupt REPL execution
- `<leader>rq` - Exit REPL
- `<leader>rx` - Clear REPL
- `<leader>rh` - Hide REPL window
- `<leader>rf` - Focus REPL window

### Virtual Environment Management
- `<leader>vs` - Select virtual environment (requires fd)
- `<leader>vc` - Select cached virtual environment

### Python Debugging (DAP)
- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Set conditional breakpoint
- `<leader>dc` - Continue debugging
- `<leader>dC` - Run to cursor
- `<leader>dg` - Go to line (no execute)
- `<leader>di` - Step into
- `<leader>dj` - Down in stack
- `<leader>dk` - Up in stack
- `<leader>dl` - Run last debug configuration
- `<leader>do` - Step out
- `<leader>dO` - Step over
- `<leader>dp` - Pause execution
- `<leader>dr` - Toggle REPL
- `<leader>ds` - Debug session
- `<leader>dt` - Terminate debugging
- `<leader>dw` - Show hover widget
- `<leader>du` - Toggle DAP UI
- `<leader>de` - Evaluate expression (normal/visual mode)

### Python-specific Debug Commands
- `<leader>dPt` - Debug test method
- `<leader>dPc` - Debug test class
- `<leader>dPs` - Debug selection (visual mode)

### Python Code Generation
- `<leader>nd` - Generate docstring (Google/NumPy/reST style)

## Docker Development

### Docker Management
- `<leader>kd` - List Docker containers
- `<leader>ki` - List Docker images
- `<leader>kc` - Docker compose commands
- `<leader>ks` - Docker swarm commands
- `<leader>kn` - List Docker networks
- `<leader>kv` - List Docker volumes

### Dev Container Commands
- `<leader>cdu` - Start devcontainer (opens terminal split)
- `<leader>cde` - Execute in devcontainer (opens bash in running container)
- `<leader>cdb` - Build devcontainer (rebuild the container image)

## General LSP Commands (All Languages)
- `gd` - Go to definition
- `K` - Show hover documentation
- `<leader>vws` - Workspace symbol search
- `<leader>vd` - Open diagnostics float
- `<leader>vca` - Code actions
- `<leader>vrr` - Find references
- `<leader>vrn` - Rename symbol
- `<C-h>` - Signature help (insert mode)
- `<F3>` - Format file

## Git Commands
- `<leader>gs` - Git status (fugitive)
- `<leader>gd` - Git diff
- `<leader>gb` - Git blame
- `<leader>gl` - Git log
- `<leader>ga` - Switch git account

## Telescope Navigation
- `<leader>pf` - Find files in current directory
- `<C-p>` - Find git files
- `<leader>ps` - Grep search in files
- `<leader>pb` - Browse buffers

## Harpoon File Navigation
- `<leader>a` - Add file to Harpoon
- `<C-e>` - Toggle Harpoon menu
- `<C-h>` - Navigate to Harpoon file 1
- `<C-t>` - Navigate to Harpoon file 2
- `<C-n>` - Navigate to Harpoon file 3
- `<C-s>` - Navigate to Harpoon file 4

## Obsidian/Notes
- `<leader>z*` - Various Obsidian commands (see obsidian_keymaps.lua)

## Dotfiles Management
- `<leader>d*` - Various dotfiles commands (see git_dotfiles_keymaps.lua)

## Terminal Commands

### Python/Poetry/Pyenv Setup
```bash
# Install Python with pyenv
pyenv install 3.12.11
pyenv local 3.12.11  # Set for current project

# Poetry commands
poetry init          # Initialize new project
poetry add [package] # Add dependency
poetry install       # Install all dependencies
poetry shell        # Activate virtual environment
poetry run python   # Run Python in virtual env
poetry env info     # Show environment info
poetry env use $(pyenv which python)  # Use pyenv Python

# Install common AI/ML packages
poetry add langchain langchain-community langchain-openai
poetry add ipython jupyter pandas numpy
poetry add python-dotenv
```

### Required System Tools
```bash
# Install via Homebrew
brew install fd       # Required for venv-selector
brew install pyenv    # Python version management
pip3 install poetry   # Python package management
brew install docker   # Required for dev containers
```

## Dev Container Workflow

### Setup
1. **Build the container**: `<leader>cdb` or `docker build -t genai-dev -f .devcontainer/Dockerfile .`
2. **Start container**: `<leader>cdu` - Opens terminal split with interactive container

### Development Flow
1. **Edit code** in Neovim on your host machine (files auto-sync via volume mounts)
2. **Test/run code** using `<leader>cde` to jump into container
3. **Container benefits**:
   - Consistent Python 3.12.11 environment
   - All dependencies pre-installed (langchain, ipython, etc.)
   - Development tools (black, ruff, mypy, pytest, jupyter)
   - Your Neovim config available inside container

### Manual Docker Commands
```bash
# Run container directly
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.config/nvim:/home/vscode/.config/nvim \
  -p 8888:8888 \
  genai-dev bash

# Start Jupyter Lab in container
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

### Container Features
- **Python 3.12.11** (matches your pyenv setup)
- **All Poetry dependencies** installed
- **Jupyter Lab** for interactive development
- **Your code mounted** at `/workspace`
- **Your Neovim config** mounted for consistent editing experience

## Tips
- After installing new LSP servers, restart Neovim
- Run `:Lazy sync` to update plugins
- Run `:Mason` to manage LSP servers
- Python LSP uses Basedpyright + Ruff for fast, modern development
- Virtual environments are automatically detected when you open Python files
- Use dev containers for consistent environments across different machines/projects