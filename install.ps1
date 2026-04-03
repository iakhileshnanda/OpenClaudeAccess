# Claude Easy Install - PowerShell version for Windows
# One-command setup for free Claude Code

param(
    [switch]$NoPrompt
)

$ErrorActionPreference = "Stop"

# Colors
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Banner {
    Write-Host $Blue
    Write-Host "╔═══════════════════════════════════════╗"
    Write-Host "║        Claude Easy Install            ║"
    Write-Host "║      Free Claude Code Setup           ║"
    Write-Host "╚═══════════════════════════════════════╝"
    Write-Host $Reset
}

function Test-Dependencies {
    Write-Host "${Yellow}Checking dependencies...${Reset}"
    
    # Check Python
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Host "${Red}Python not found. Please install Python 3.8+ from python.org${Reset}"
        exit 1
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "${Red}PowerShell 5+ required. Please update PowerShell${Reset}"
        exit 1
    }
    
    Write-Host "${Green}Dependencies OK${Reset}"
}

function Install-Claude {
    Write-Host "${Yellow}Installing Claude Code...${Reset}"
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://claude.ai/install.sh'))
        Write-Host "${Green}Claude Code installed${Reset}"
    } catch {
        Write-Host "${Red}Failed to install Claude Code: $_${Reset}"
        exit 1
    }
}

function Install-UV {
    Write-Host "${Yellow}Installing uv...${Reset}"
    try {
        irm https://astral.sh/uv/install.ps1 | iex
        Write-Host "${Green}uv installed${Reset}"
    } catch {
        Write-Host "${Red}Failed to install uv: $_${Reset}"
        exit 1
    }
}

function Setup-Config {
    Write-Host "${Yellow}Setting up configuration...${Reset}"
    
    # Ask user for NVIDIA API key
    Write-Host "${Blue}Do you have an NVIDIA API key? (get from: https://build.nvidia.com/meta/llama-3_1-8b-instruct)${Reset}"
    $nvidia_key = Read-Host "Enter your NVIDIA API key (or press Enter to skip)"
    
    if ([string]::IsNullOrEmpty($nvidia_key)) {
        Write-Host "${Yellow}No API key provided. You'll need to update .env file manually later.${Reset}"
        $nvidia_key = "YOUR_NVIDIA_API_KEY_HERE"
    } else {
        Write-Host "${Green}NVIDIA API key received${Reset}"
    }
    
    # Detect Git Bash path for Windows
    $gitBashPath = ""
    $possiblePaths = @(
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\usr\bin\bash.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Git\usr\bin\bash.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $gitBashPath = $path
            break
        }
    }
    
    if ([string]::IsNullOrEmpty($gitBashPath)) {
        Write-Host "${Yellow}Git Bash not found in standard locations. Please install Git for Windows first.${Reset}"
        $gitBashPath = "C:\Program Files\Git\usr\bin\bash.exe"
    }
    
    $envContent = @"
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
CLAUDE_CODE_GIT_BASH_PATH="$gitBashPath"
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "${Green}Configuration created at .env${Reset}"
    Write-Host "${Green}Git Bash path detected: $gitBashPath${Reset}"
    
    if ($nvidia_key -eq "YOUR_NVIDIA_API_KEY_HERE") {
        Write-Host "${Yellow}⚠️ Please edit .env file and replace YOUR_NVIDIA_API_KEY_HERE with your actual key${Reset}"
    }
}

function Start-Server {
    Write-Host "${Yellow}Starting Claude proxy server...${Reset}"
    
    # Start server in new window
    Start-Process powershell -ArgumentList "-Command", "uv run uvicorn server:app --host 0.0.0.0 --port 8082; Read-Host 'Press Enter to close'"
    Start-Sleep -Seconds 3
    Write-Host "${Green}Server started on port 8082${Reset}"
}

function Create-BatchFile {
    Write-Host "${Yellow}Creating shortcuts...${Reset}"
    
    # Get Git Bash path for batch file
    $gitBashPath = ""
    $possiblePaths = @(
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\usr\bin\bash.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Git\usr\bin\bash.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $gitBashPath = $path
            break
        }
    }
    
    if ([string]::IsNullOrEmpty($gitBashPath)) {
        $gitBashPath = "C:\Program Files\Git\usr\bin\bash.exe"
    }
    
    $batchContent = @"
@echo off
echo Starting Claude Code (Free)...
set CLAUDE_CODE_GIT_BASH_PATH=$gitBashPath
set ANTHROPIC_AUTH_TOKEN=freecc
set ANTHROPIC_BASE_URL=http://localhost:8082
claude %*
pause
"@
    
    $batchContent | Out-File -FilePath "claude-free.bat" -Encoding ASCII
    Write-Host "${Green}Created claude-free.bat${Reset}"
    
    # Create PowerShell script for Git Bash path detection
    $psContent = @"
# Windows Git Bash path detection for Claude Code
Write-Host "Detecting Git Bash path..."

`$possiblePaths = @(
    "C:\Program Files\Git\usr\bin\bash.exe",
    "C:\Program Files (x86)\Git\usr\bin\bash.exe",
    "C:\Users\`$env:USERNAME\AppData\Local\Programs\Git\usr\bin\bash.exe"
)

foreach (`$path in `$possiblePaths) {
    if (Test-Path `$path) {
        Write-Host "Git Bash found at: `$path"
        Write-Host "Run: cygpath -w `$path"
        break
    }
}
"@
    
    $psContent | Out-File -FilePath "detect-git-bash.ps1" -Encoding ASCII
    Write-Host "${Green}Created detect-git-bash.ps1 for path detection${Reset}"
}

function Show-Success {
    Write-Host $Green
    Write-Host "╔═══════════════════════════════════════╗"
    Write-Host "║        Installation Complete!         ║"
    Write-Host "╚═══════════════════════════════════════╝"
    Write-Host $Reset
    Write-Host "Run: .\claude-free.bat"
    Write-Host ""
    Write-Host "That's it! No login required."
    Write-Host "Server running on http://localhost:8082"
}

# Main execution
Write-Banner
Test-Dependencies
Install-Claude
Install-UV
Setup-Config
Start-Server
Create-BatchFile
Show-Success