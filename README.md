# Free Claude Code

Use Claude Code CLI with NVIDIA NIM models - no Anthropic API key needed. **Install once, works everywhere.**

## Step 1 — Get Your Free NVIDIA API Key

> You need this before running the installer. The installer will ask for it.

1. Go to [build.nvidia.com/explore](https://build.nvidia.com/explore)
2. Sign up or log in (free account)
3. Click any model → click **"Get API Key"**
4. Copy the key — it starts with `nvapi-...`

Keep it handy, the installer will prompt you to paste it.

## Step 2 — Prerequisites

Make sure these are installed before running the installer:

- **Node.js** (includes npm) - [nodejs.org](https://nodejs.org)
- **Git** - [git-scm.com](https://git-scm.com)

## Step 3 — Install (one time)

### Linux / macOS

```bash
git clone https://github.com/iakhileshnanda/OpenClaudeAccess.git
cd OpenClaudeAccess
chmod +x install.sh
./install.sh
```

### Windows (PowerShell - Recommended)

```powershell
git clone https://github.com/iakhileshnanda/OpenClaudeAccess.git
cd OpenClaudeAccess
Set-ExecutionPolicy RemoteSigned -Scope Process
.\install.ps1
```

### Windows (Git Bash)

```bash
git clone https://github.com/iakhileshnanda/OpenClaudeAccess.git
cd OpenClaudeAccess
chmod +x install-git-bash.sh
./install-git-bash.sh
```

## Usage

After install, **close and reopen your terminal**. Then from any folder, any IDE (VS Code, Cursor, etc.):

```bash
claude
```

That's it. The server starts automatically in the background if it's not already running. No extra commands needed.

## What the Installer Does

1. Installs **Claude Code CLI** globally via npm
2. Installs **uv** + **Python 3.14**
3. Clones the proxy server to a permanent location (`~/.local/share/free-claude-code` on Linux/macOS, `%LOCALAPPDATA%\free-claude-code` on Windows)
4. Prompts for your **NVIDIA API key** and saves config to `~/.config/free-claude-code/.env`
5. Sets **`ANTHROPIC_AUTH_TOKEN`** and **`ANTHROPIC_BASE_URL`** as permanent environment variables
6. Sets up the proxy server to **auto-start on login** (systemd on Linux, launchd on macOS, Startup folder on Windows)
7. Starts the server immediately

After install you can **delete the cloned `OpenClaudeAccess` folder** - everything is installed globally.

## Models

| Claude Model | Model | Use Case |
|---|---|---|
| Opus | qwen/qwen3.5-397b-a17b | Premium reasoning |
| Sonnet | qwen/qwen3.5-397b-a17b | Advanced coding |
| Haiku | qwen/qwen3.5-397b-a17b | Fast & efficient |
| Default (MODEL) | deepseek-ai/deepseek-v3_2 | Fallback |

## How It Works

```
Claude Code CLI  -->  Proxy Server (localhost:8082)  -->  NVIDIA NIM API
```

The proxy server translates Anthropic API requests into NVIDIA NIM format. Claude Code thinks it's talking to Anthropic, but your requests go to NVIDIA NIM models instead.

## Commands

| Command | Description |
|---|---|
| `claude` | Run Claude Code (env vars are set globally) |
| `claude-free` | Auto-starts server if not running, then runs Claude |
| `fcc-server` | Start the proxy server manually |

## Configuration

Your config file lives at:
- **Linux/macOS:** `~/.config/free-claude-code/.env`
- **Windows:** `%USERPROFILE%\.config\free-claude-code\.env`

### View / Edit the config file

**Linux / macOS / Git Bash:**
```bash
# View
cat ~/.config/free-claude-code/.env

# Edit in nano
nano ~/.config/free-claude-code/.env

# Edit in VS Code
code ~/.config/free-claude-code/.env
```

**Windows (PowerShell):**
```powershell
# View
Get-Content "$env:USERPROFILE\.config\free-claude-code\.env"

# Edit in Notepad
notepad "$env:USERPROFILE\.config\free-claude-code\.env"

# Edit in VS Code (if installed)
code "$env:USERPROFILE\.config\free-claude-code\.env"
```

### Change Models

Open the `.env` file using any method above and update these lines:

```env
MODEL_OPUS="qwen/qwen3.5-397b-a17b"
MODEL_SONNET="qwen/qwen3.5-397b-a17b"
MODEL_HAIKU="qwen/qwen3.5-397b-a17b"
MODEL="deepseek-ai/deepseek-v3_2"
```

Replace the model values with any model available on [NVIDIA NIM](https://build.nvidia.com/explore). The format is just `org/model-name` (no prefix needed).

After editing, restart the server for changes to take effect:

```bash
# Linux/macOS
fcc-server

# Windows (PowerShell)
fcc-server
```

## Uninstall

### Linux
```bash
systemctl --user stop free-claude-code.service
systemctl --user disable free-claude-code.service
rm -rf ~/.local/share/free-claude-code ~/.config/free-claude-code
rm ~/.local/bin/fcc-server ~/.local/bin/claude-free
rm ~/.config/systemd/user/free-claude-code.service
npm uninstall -g @anthropic-ai/claude-code
# Remove the "Free Claude Code env vars" block from your ~/.bashrc or ~/.zshrc
```

### macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.freeclaudecode.server.plist
rm ~/Library/LaunchAgents/com.freeclaudecode.server.plist
rm -rf ~/.local/share/free-claude-code ~/.config/free-claude-code
rm ~/.local/bin/fcc-server ~/.local/bin/claude-free
npm uninstall -g @anthropic-ai/claude-code
# Remove the "Free Claude Code env vars" block from your ~/.zshrc or ~/.bashrc
```

### Windows
```powershell
# Remove autostart
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\free-claude-code.vbs" -ErrorAction SilentlyContinue
# Remove install
Remove-Item -Recurse "$env:LOCALAPPDATA\free-claude-code"
Remove-Item -Recurse "$env:USERPROFILE\.config\free-claude-code"
# Remove env vars
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $null, "User")
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
[System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $null, "User")
npm uninstall -g @anthropic-ai/claude-code
# Edit $PROFILE and remove the "Free Claude Code" function block
```

## Troubleshooting

**PowerShell script won't run?**
Run `Set-ExecutionPolicy RemoteSigned -Scope Process` first, or run PowerShell as Administrator.

**npm not found?**
Install Node.js from [nodejs.org](https://nodejs.org). Restart your terminal after installing.

**Server not running?**
Run `fcc-server` manually, or use `claude-free` which auto-starts it.

**Port 8082 in use?**
Check with `lsof -i :8082` (Linux/macOS) or `netstat -ano | findstr 8082` (Windows). Kill the conflicting process.

**Change NVIDIA API key?**
Edit `~/.config/free-claude-code/.env` and restart the server.
