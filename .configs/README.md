# AnoNvim Configuration Files

This directory contains various configuration files used by AnoNvim.

## Directory Structure

```
.configs/
├── code_runner/       # Code execution configurations
│   ├── config.json   # Main runner configuration
│   └── files.json    # File type associations
├── formatters/       # Code formatting configurations
│   ├── editorconfig  # EditorConfig settings
│   ├── luacheck.toml # Lua linting configuration
│   ├── prettier.json # Prettier formatting rules
│   ├── selene.toml   # Selene linting rules
│   └── stylua.toml   # Lua formatting rules
└── templates/        # Template files and configurations
    ├── .editorconfig # Default editor configuration
    └── README.md     # This file
```

## Configuration Types

### Code Runner

The `code_runner` directory contains configurations for running code:

- `config.json`: Defines runners and language-specific settings
- `files.json`: Maps file extensions to language runners

### Formatters

The `formatters` directory contains various formatting configurations:

- `editorconfig`: Project-wide editor settings
- `luacheck.toml`: Lua code linting rules
- `prettier.json`: JavaScript/TypeScript/JSON formatting
- `.prettierrc.json`: JavaScript/TypeScript/JSON formatting
- `selene.toml`: Advanced Lua linting
- `stylua.toml`: Lua code formatting

### Templates

The `templates` directory contains default configuration templates:

- `.editorconfig`: Base editor configuration
- Other template files for project setup

## Usage

These configurations are automatically loaded by AnoNvim based on file type and context.
