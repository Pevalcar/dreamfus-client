---
name: godot-cli-install
description: "Install godot-cli and the Godot-MCP addon: Node.js requirements, npm installation, npx and troubleshooting. How to use the CLI: the godot-cli skill."
metadata:
  generated-by: godot-mcp
  ai-game-dev: exclude
---
# Godot CLI

Install and use `godot-cli` to call the engine's MCP tools from a terminal.

## Prerequisites

Node.js 22.14 or later and npm are required.
Check existing installations first:

```powershell
node --version
npm.cmd --version
```

If needed, install a supported Node.js LTS release from https://nodejs.org/ and reopen the terminal.
Use the Windows installer and reopen PowerShell. The examples use .cmd launchers to avoid npm PowerShell execution-policy restrictions.

## Install and verify

```powershell
npm.cmd install -g godot-cli
godot-cli.cmd --version
godot-cli.cmd --help
```

Alternatively, use npm's temporary runner without a global installation:

```powershell
npx.cmd godot-cli --help
```

Replace the leading `godot-cli.cmd` with `npx.cmd godot-cli` in subsequent examples when using this option.

## Use it

Run commands in the game project's folder; the first editor command starts a headless editor itself.
The `godot-cli` skill has the workflow (RQL recipes, exit codes). To write it into an agent's skills folder:

```powershell
godot-cli.cmd setup-skills claude-code
```

`godot-cli.cmd setup-skills --list` shows the other agents. A project without an `addons/godot_mcp` folder needs `godot-cli.cmd install-plugin` once.

## Troubleshooting

- `node` or `npm.cmd` not found: finish installing Node.js, check PATH, and reopen the terminal.
- `godot-cli.cmd` not found: reopen the terminal, check the npm global executable directory in PATH, or use `npx.cmd godot-cli`.
- Global npm installation denied: use a user-owned Node.js installation or the npx alternative.
- Exit 7 (editor unreachable): check that the project has the `addons/godot_mcp` folder, then read the message for the cause.

For optional asset-generation and Blender workflows, consult the `ai-game-dev-app` skill.
