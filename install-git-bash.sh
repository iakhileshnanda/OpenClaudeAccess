#!/bin/bash
# Claude Easy Install - Git Bash version for Windows
# One-command setup for free Claude Code

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

write_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║        Claude Easy Install            ║"
    echo "║      Free Claude Code Setup           ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

test_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    # Check Python
    if ! command -v python &> /dev/null; then
        echo -e "${RED}Python not found. Please install Python 3.8+ from python.org${NC}"
        exit 1
    fi
    
    # Check Git Bash
    if [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "win32" ]]; then
        echo -e "${RED}This script is designed for Git Bash on Windows${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Dependencies OK${NC}"
}

install_claude() {
    echo -e "${YELLOW}Installing Claude Code...${NC}"
    
    # Use npm to install Claude Code globally
    if command -v npm &> /dev/null; then
        npm install -g @anthropic-ai/claude-code
        echo -e "${GREEN}Claude Code installed via npm${NC}"
    else
        echo -e "${RED}npm not found. Please install Node.js first${NC}"
        exit 1
    fi
}

install_uv() {
    echo -e "${YELLOW}Installing uv...${NC}"
    
    # Install uv for Python package management
    if command -v curl &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}uv installed${NC}"
    else
        echo -e "${RED}curl not found. Please install curl${NC}"
        exit 1
    fi
}

setup_config() {
    echo -e "${YELLOW}Setting up configuration...${NC}"
    
    # Ask user for NVIDIA API key
    echo -e "${BLUE}Do you have an NVIDIA API key? (get from: https://build.nvidia.com/meta/llama-3_1-8b-instruct)${NC}"
    read -p "Enter your NVIDIA API key (or press Enter to skip): " nvidia_key
    
    if [[ -z "$nvidia_key" ]]; then
        echo -e "${YELLOW}No API key provided. You'll need to update .env file manually later.${NC}"
        nvidia_key="YOUR_NVIDIA_API_KEY_HERE"
    else
        echo -e "${GREEN}NVIDIA API key received${NC}"
    fi
    
    # Get Git Bash path
    git_bash_path="$(which bash)"
    
    cat > .env << EOF
# Free Claude Code Configuration
# Uses NVIDIA NIM models

# NVIDIA API Key (get from: https://build.nvidia.com/meta/llama-3_1-8b-instruct)
NVIDIA_NIM_API_KEY="$nvidia_key"

# Model configurations
MODEL_OPUS="nvidia_nim/moonshotai/kimi-k2-instruct-0905"
MODEL_SONNET="nvidia_nim/qwen/qwen3-coder-480b-a35b-instruct"
MODEL_HAIKU="nvidia_nim/deepseek-ai/deepseek-v3_2"
MODEL="nvidia_nim/deepseek-ai/deepseek-v3_2"

# Claude bypass settings
ANTHROPIC_AUTH_TOKEN="freecc"
ANTHROPIC_BASE_URL="http://localhost:8082"

# Windows Git Bash path for Claude Code
CLAUDE_CODE_GIT_BASH_PATH="$git_bash_path"
EOF
    
    echo -e "${GREEN}Configuration created at .env${NC}"
    echo -e "${GREEN}Git Bash path detected: $git_bash_path${NC}"
    
    if [[ "$nvidia_key" == "YOUR_NVIDIA_API_KEY_HERE" ]]; then
        echo -e "${YELLOW}⚠️ Please edit .env file and replace YOUR_NVIDIA_API_KEY_HERE with your actual key${NC}"
    fi
}

create_scripts() {
    echo -e "${YELLOW}Creating shortcuts...${NC}"
    
    # Create bash script for running Claude
    cat > claude-free.sh << 'EOF'
#!/bin/bash
export CLAUDE_CODE_GIT_BASH_PATH="$(which bash)"
export ANTHROPIC_AUTH_TOKEN="freecc"
export ANTHROPIC_BASE_URL="http://localhost:8082"
claude "$@"
EOF
    
    chmod +x claude-free.sh
    echo -e "${GREEN}Created claude-free.sh${NC}"
    
    # Create Windows batch file for CMD/PowerShell
    cat > claude-free.bat << 'EOF'
@echo off
echo Starting Claude Code (Free)...
set CLAUDE_CODE_GIT_BASH_PATH=C:\Program Files\Git\usrinash.exe
set ANTHROPIC_AUTH_TOKEN=freecc
set ANTHROPIC_BASE_URL=http://localhost:8082
claude %*
pause
EOF
    
    echo -e "${GREEN}Created claude-free.bat${NC}"
}

start_server() {
    echo -e "${YELLOW}Starting Claude proxy server...${NC}"
    
    # Create server script
    cat > start-server.sh << 'EOF'
#!/bin/bash
echo "Starting Claude proxy server on port 8082..."
uv run uvicorn server:app --host 0.0.0.0 --port 8082
EOF
    
    chmod +x start-server.sh
    echo -e "${GREEN}Server script created at start-server.sh${NC}"
    echo -e "${GREEN}Run: ./start-server.sh to start the proxy${NC}"
}

show_success() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║        Installation Complete!         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Run: ./claude-free.sh"
    echo ""
    echo "That's it! No login required."
    echo "Server running on http://localhost:8082"
}

# Main execution
write_banner
test_dependencies
install_claude
install_uv
setup_config
create_scripts
start_server
show_success