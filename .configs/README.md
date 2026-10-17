# AnoNvim Configuration Files

This directory contains various configuration files used by AnoNvim.

## Directory Structure

```
.configs/
├── code_runner/       # Code execution configurations
│   ├── config.json   # Main runner configuration
│   └── files.json    # File type associations
├── formatters/        # Code formatting configurations
│   ├── editorconfig  # EditorConfig settings
│   ├── prettier.json # Prettier formatting rules
│   ├── .prettierrc.json # Prettier config used by prettierd (see formatting.lua)
│   ├── selene.toml   # Selene linting rules
│   ├── stylua.toml   # Lua formatting rules
│   ├── vim.toml      # vim-language-server settings
│   └── vim.yml       # vim-language-server settings (YAML variant)
└── templates/         # Template files for project setup
    └── .editorconfig # Default editor configuration
```

## Configuration Types

### Code Runner

The `code_runner` directory contains configurations for running code:

- `config.json`: Defines runners and language-specific settings
- `files.json`: Maps file extensions to language runners

### Formatters

The `formatters` directory contains formatting and linting configurations:

- `editorconfig`: Project-wide editor settings
- `prettier.json` / `.prettierrc.json`: JavaScript/TypeScript/JSON formatting
- `selene.toml`: Advanced Lua linting
- `stylua.toml`: Lua code formatting
- `vim.toml` / `vim.yml`: vim-language-server settings

### Templates

The `templates` directory contains default configuration templates:

- `.editorconfig`: Base editor configuration

## Usage

These configurations are automatically loaded by AnoNvim based on file type and context.
