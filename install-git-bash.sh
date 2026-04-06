#!/bin/bash
# Claude Easy Install - Git Bash version for Windows
# One-time global setup. After this, just type "claude" from anywhere.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Windows paths via Git Bash
INSTALL_DIR="$LOCALAPPDATA/free-claude-code"
CONFIG_DIR="$USERPROFILE/.config/free-claude-code"
SCRIPTS_DIR="$LOCALAPPDATA/free-claude-code/bin"

write_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║      Free Claude Code - Installer     ║"
    echo "║   One-time setup, works everywhere    ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

test_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"

    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm not found. Please install Node.js first (https://nodejs.org)${NC}"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        echo -e "${RED}git not found. Please install Git for Windows first${NC}"
        exit 1
    fi

    if [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "win32" ]]; then
        echo -e "${RED}This script is for Git Bash on Windows. Use install.sh for Linux/macOS.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Dependencies OK${NC}"
}

install_claude_code() {
    echo -e "${YELLOW}Installing Claude Code CLI...${NC}"
    npm install -g @anthropic-ai/claude-code
    echo -e "${GREEN}Claude Code CLI installed${NC}"
}

install_uv() {
    echo -e "${YELLOW}Installing uv...${NC}"

    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo -e "${GREEN}uv already installed, updating...${NC}"
        uv self update 2>/dev/null || true
    fi

    echo -e "${YELLOW}Installing Python 3.14 via uv...${NC}"
    uv python install 3.14
    echo -e "${GREEN}uv + Python 3.14 ready${NC}"
}

install_project() {
    echo -e "${YELLOW}Installing Free Claude Code globally...${NC}"

    if [[ -d "$INSTALL_DIR/.git" ]]; then
        echo -e "${YELLOW}Updating existing installation...${NC}"
        git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null || true
    else
        rm -rf "$INSTALL_DIR"
        git clone https://github.com/iakhileshnanda/freecode.git "$INSTALL_DIR"
    fi

    echo -e "${GREEN}Project installed at $INSTALL_DIR${NC}"
}

setup_config() {
    echo -e "${YELLOW}Setting up configuration...${NC}"

    mkdir -p "$CONFIG_DIR"

    if [[ -f "$CONFIG_DIR/.env" ]]; then
        echo -e "${YELLOW}Config already exists at $CONFIG_DIR/.env - keeping it${NC}"
        return
    fi

    echo -e "${BLUE}Get a free NVIDIA API key from: https://build.nvidia.com/explore${NC}"
    read -p "Enter your NVIDIA API key (or press Enter to skip): " nvidia_key

    if [[ -z "$nvidia_key" ]]; then
        nvidia_key="YOUR_NVIDIA_API_KEY_HERE"
    fi

    cat > "$CONFIG_DIR/.env" << EOF
# Free Claude Code Configuration

# NVIDIA API Key (get from: https://build.nvidia.com/explore)
NVIDIA_NIM_API_KEY="$nvidia_key"

# Model configurations
MODEL_OPUS="nvidia_nim/moonshotai/kimi-k2-instruct-0905"
MODEL_SONNET="nvidia_nim/qwen/qwen3-coder-480b-a35b-instruct"
MODEL_HAIKU="nvidia_nim/deepseek-ai/deepseek-v3_2"
MODEL="nvidia_nim/deepseek-ai/deepseek-v3_2"
EOF

    echo -e "${GREEN}Config created at $CONFIG_DIR/.env${NC}"

    if [[ "$nvidia_key" == "YOUR_NVIDIA_API_KEY_HERE" ]]; then
        echo -e "${YELLOW}WARNING: Edit $CONFIG_DIR/.env and add your NVIDIA API key later${NC}"
    fi
}

setup_env_variables() {
    echo -e "${YELLOW}Setting environment variables permanently...${NC}"

    # Set Windows user environment variables via PowerShell
    powershell -Command '[System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "freecc", "User")'
    powershell -Command '[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "http://localhost:8082", "User")'

    # Detect and set Git Bash path
    local bash_path
    bash_path=$(cygpath -w "$(which bash)" 2>/dev/null || echo "")
    if [[ -n "$bash_path" ]]; then
        powershell -Command "[System.Environment]::SetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', '$bash_path', 'User')"
        echo -e "${GREEN}Git Bash path set: $bash_path${NC}"
    fi

    # Apply to current session
    export ANTHROPIC_AUTH_TOKEN="freecc"
    export ANTHROPIC_BASE_URL="http://localhost:8082"

    echo -e "${GREEN}Environment variables set permanently (User level)${NC}"
}

create_server_scripts() {
    echo -e "${YELLOW}Creating server launcher...${NC}"

    mkdir -p "$SCRIPTS_DIR"

    # Get Windows-style install path for batch files
    local win_install_dir
    win_install_dir=$(cygpath -w "$INSTALL_DIR" 2>/dev/null || echo "$INSTALL_DIR")

    # Create fcc-server.bat
    cat > "$SCRIPTS_DIR/fcc-server.bat" << EOF
@echo off
cd /d "$win_install_dir"
uv run uvicorn server:app --host 0.0.0.0 --port 8082
EOF

    # Create claude-free.bat (auto-starts server + runs claude)
    cat > "$SCRIPTS_DIR/claude-free.bat" << EOF
@echo off
set ANTHROPIC_AUTH_TOKEN=freecc
set ANTHROPIC_BASE_URL=http://localhost:8082

REM Check if server is running
curl -s http://localhost:8082/health >nul 2>&1
if errorlevel 1 (
    echo Starting Free Claude Code server...
    start /b cmd /c "cd /d $win_install_dir && uv run uvicorn server:app --host 0.0.0.0 --port 8082 > nul 2>&1"
    timeout /t 5 /nobreak >nul
)

claude %*
EOF

    # Add to Windows PATH
    local win_scripts_dir
    win_scripts_dir=$(cygpath -w "$SCRIPTS_DIR" 2>/dev/null || echo "$SCRIPTS_DIR")
    powershell -Command "
        \$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
        if (\$currentPath -notlike '*$win_scripts_dir*') {
            [System.Environment]::SetEnvironmentVariable('PATH', \"\$currentPath;$win_scripts_dir\", 'User')
        }
    "

    echo -e "${GREEN}Commands created: fcc-server, claude-free${NC}"
}

setup_autostart() {
    echo -e "${YELLOW}Setting up server autostart on login...${NC}"

    local startup_dir="$APPDATA/Microsoft/Windows/Start Menu/Programs/Startup"
    local win_install_dir
    win_install_dir=$(cygpath -w "$INSTALL_DIR" 2>/dev/null || echo "$INSTALL_DIR")

    # Use VBScript to run the server completely hidden (no window flash)
    cat > "$startup_dir/free-claude-code.vbs" << EOF
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c cd /d ""$win_install_dir"" && uv run uvicorn server:app --host 0.0.0.0 --port 8082", 0, False
EOF

    # Remove old .bat autostart if it exists
    rm -f "$startup_dir/free-claude-code.bat" 2>/dev/null

    echo -e "${GREEN}Server will auto-start on Windows login${NC}"
}

start_server_now() {
    echo -e "${YELLOW}Starting server...${NC}"

    if curl -s http://localhost:8082/health > /dev/null 2>&1; then
        echo -e "${GREEN}Server already running${NC}"
        return
    fi

    local win_install_dir
    win_install_dir=$(cygpath -w "$INSTALL_DIR" 2>/dev/null || echo "$INSTALL_DIR")
    cmd //c "start /min cmd /c \"cd /d $win_install_dir && uv run uvicorn server:app --host 0.0.0.0 --port 8082\"" 2>/dev/null &

    sleep 5
    echo -e "${GREEN}Server running on http://localhost:8082${NC}"
}

show_success() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║      Installation Complete!           ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "Now open ${BLUE}ANY terminal, ANY folder, ANY IDE${NC} (VS Code, Cursor, etc.) and run:"
    echo ""
    echo -e "  ${GREEN}claude${NC}         (works directly - env vars are set globally)"
    echo -e "  ${GREEN}claude-free${NC}    (auto-starts server if needed + runs claude)"
    echo ""
    echo -e "${YELLOW}NOTE: Close and reopen your terminal for env vars to take effect.${NC}"
    echo ""
    echo -e "Server auto-starts on login. To manage manually:"
    echo -e "  Start:  ${BLUE}fcc-server${NC}"
    echo -e "  Config: ${BLUE}$CONFIG_DIR/.env${NC}"
}

# Main execution
write_banner
test_dependencies
install_claude_code
install_uv
install_project
setup_config
setup_env_variables
create_server_scripts
setup_autostart
start_server_now
show_success
