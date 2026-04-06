#!/bin/bash

# Claude Easy Install - One-command global setup for free Claude Code
# After running this, just type "claude" from anywhere and it works.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/share/free-claude-code"
CONFIG_DIR="$HOME/.config/free-claude-code"

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║      Free Claude Code - Installer     ║"
    echo "║   One-time setup, works everywhere    ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    echo -e "${GREEN}Detected OS: $OS${NC}"
}

check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"

    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm not found. Please install Node.js first (https://nodejs.org)${NC}"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl not found. Please install curl first${NC}"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        echo -e "${RED}git not found. Please install git first${NC}"
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

clone_and_install_project() {
    echo -e "${YELLOW}Installing Free Claude Code globally...${NC}"

    # Clone or update the project
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
    echo -e "${YELLOW}Setting up environment variables permanently...${NC}"

    # Determine shell profile
    SHELL_PROFILE=""
    if [[ -f "$HOME/.zshrc" ]] && [[ "$SHELL" == */zsh ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        SHELL_PROFILE="$HOME/.bash_profile"
    elif [[ -f "$HOME/.profile" ]]; then
        SHELL_PROFILE="$HOME/.profile"
    else
        SHELL_PROFILE="$HOME/.bashrc"
    fi

    # Add env vars + claude wrapper function if not already present
    local marker="# Free Claude Code env vars"
    if ! grep -q "$marker" "$SHELL_PROFILE" 2>/dev/null; then
        cat >> "$SHELL_PROFILE" << 'PROFILE'

# Free Claude Code env vars
export ANTHROPIC_AUTH_TOKEN="freecc"
export ANTHROPIC_BASE_URL="http://localhost:8082"
export PATH="$HOME/.local/bin:$PATH"

# Wrapper: auto-start server when you run "claude"
claude() {
    if ! curl -s http://localhost:8082/health > /dev/null 2>&1; then
        echo "Starting Free Claude Code server..."
        fcc-server > /dev/null 2>&1 &
        for i in {1..15}; do
            curl -s http://localhost:8082/health > /dev/null 2>&1 && break
            sleep 1
        done
    fi
    command claude "$@"
}
PROFILE
        echo -e "${GREEN}Environment variables + claude wrapper added to $SHELL_PROFILE${NC}"
    else
        echo -e "${GREEN}Environment variables already in $SHELL_PROFILE${NC}"
    fi

    # Apply for current session
    export ANTHROPIC_AUTH_TOKEN="freecc"
    export ANTHROPIC_BASE_URL="http://localhost:8082"
    export PATH="$HOME/.local/bin:$PATH"
}

create_server_script() {
    echo -e "${YELLOW}Creating server launcher...${NC}"

    mkdir -p "$HOME/.local/bin"

    # Create a global "fcc-server" command
    cat > "$HOME/.local/bin/fcc-server" << EOF
#!/bin/bash
# Free Claude Code - Start proxy server
cd "$INSTALL_DIR"
exec uv run uvicorn server:app --host 0.0.0.0 --port 8082
EOF
    chmod +x "$HOME/.local/bin/fcc-server"

    # Create a "claude-free" wrapper that starts server if needed + runs claude
    cat > "$HOME/.local/bin/claude-free" << 'SCRIPT'
#!/bin/bash
export ANTHROPIC_AUTH_TOKEN="freecc"
export ANTHROPIC_BASE_URL="http://localhost:8082"

# Start server if not already running
if ! curl -s http://localhost:8082/health > /dev/null 2>&1; then
    echo "Starting Free Claude Code server..."
    fcc-server > /dev/null 2>&1 &
    # Wait for server to be ready
    for i in {1..15}; do
        if curl -s http://localhost:8082/health > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
fi

claude "$@"
SCRIPT
    chmod +x "$HOME/.local/bin/claude-free"

    echo -e "${GREEN}Commands created: fcc-server, claude-free${NC}"
}

setup_autostart() {
    echo -e "${YELLOW}Setting up server autostart...${NC}"

    if [[ "$OS" == "linux" ]] && command -v systemctl &> /dev/null; then
        # Create systemd user service
        mkdir -p "$HOME/.config/systemd/user"
        cat > "$HOME/.config/systemd/user/free-claude-code.service" << EOF
[Unit]
Description=Free Claude Code Proxy Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$HOME/.local/bin/fcc-server
Restart=on-failure
RestartSec=5
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF

        systemctl --user daemon-reload
        systemctl --user enable free-claude-code.service
        systemctl --user start free-claude-code.service
        echo -e "${GREEN}Server set up as systemd service (auto-starts on login)${NC}"

    elif [[ "$OS" == "macos" ]]; then
        # Create launchd plist
        mkdir -p "$HOME/Library/LaunchAgents"
        cat > "$HOME/Library/LaunchAgents/com.freeclaudecode.server.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.freeclaudecode.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.local/bin/fcc-server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.local/share/free-claude-code/server.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.local/share/free-claude-code/server.log</string>
</dict>
</plist>
EOF

        launchctl load "$HOME/Library/LaunchAgents/com.freeclaudecode.server.plist" 2>/dev/null || true
        echo -e "${GREEN}Server set up as launchd service (auto-starts on login)${NC}"
    else
        echo -e "${YELLOW}Auto-start not available on this OS. Run 'fcc-server' manually.${NC}"
    fi
}

start_server_now() {
    echo -e "${YELLOW}Starting server...${NC}"

    # If systemd/launchd is handling it, it's already running
    if [[ "$OS" == "linux" ]] && systemctl --user is-active free-claude-code.service &> /dev/null; then
        echo -e "${GREEN}Server already running via systemd${NC}"
        return
    fi

    # Fallback: start manually
    if ! curl -s http://localhost:8082/health > /dev/null 2>&1; then
        cd "$INSTALL_DIR"
        nohup uv run uvicorn server:app --host 0.0.0.0 --port 8082 > "$INSTALL_DIR/server.log" 2>&1 &
        echo $! > "$INSTALL_DIR/server.pid"
        sleep 3
    fi

    echo -e "${GREEN}Server running on http://localhost:8082${NC}"
}

print_success() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      Installation Complete!           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Now open ${BLUE}any terminal, any folder, any IDE${NC} and run:"
    echo ""
    echo -e "  ${GREEN}claude${NC}         (works directly - env vars are set globally)"
    echo -e "  ${GREEN}claude-free${NC}    (auto-starts server if needed + runs claude)"
    echo ""
    echo -e "${YELLOW}NOTE: Restart your terminal (or run 'source $SHELL_PROFILE') for env vars to take effect.${NC}"
    echo ""
    echo -e "Server auto-starts on login. To manage manually:"
    echo -e "  Start:  ${BLUE}fcc-server${NC}"
    echo -e "  Config: ${BLUE}$CONFIG_DIR/.env${NC}"
}

# Main execution
print_banner
detect_os
check_dependencies
install_claude_code
install_uv
clone_and_install_project
setup_config
setup_env_variables
create_server_script
setup_autostart
start_server_now
print_success
