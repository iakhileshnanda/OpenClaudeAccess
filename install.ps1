# Claude Easy Install - PowerShell version for Windows
# One-time global setup. After this, just type "claude" from anywhere.

param(
    [switch]$NoPrompt
)

$ErrorActionPreference = "Stop"

$InstallDir = "$env:LOCALAPPDATA\free-claude-code"
$ConfigDir = "$env:USERPROFILE\.config\free-claude-code"

function Write-Banner {
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Blue
    Write-Host "      Free Claude Code - Installer     " -ForegroundColor Blue
    Write-Host "   One-time setup, works everywhere    " -ForegroundColor Blue
    Write-Host "=======================================" -ForegroundColor Blue
    Write-Host ""
}

function Test-Dependencies {
    Write-Host "Checking dependencies..." -ForegroundColor Yellow

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Host "npm not found. Please install Node.js first (https://nodejs.org)" -ForegroundColor Red
        exit 1
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "git not found. Please install Git for Windows first (https://git-scm.com)" -ForegroundColor Red
        exit 1
    }

    Write-Host "Dependencies OK" -ForegroundColor Green
}

function Install-ClaudeCLI {
    Write-Host "Installing Claude Code CLI..." -ForegroundColor Yellow
    $ErrorActionPreference = "Continue"
    npm install -g @anthropic-ai/claude-code 2>&1 | ForEach-Object { Write-Host $_ }
    $ErrorActionPreference = "Stop"
    Write-Host "Claude Code CLI installed" -ForegroundColor Green
}

function Install-UV {
    Write-Host "Installing uv..." -ForegroundColor Yellow
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        irm https://astral.sh/uv/install.ps1 | iex
    } else {
        Write-Host "uv already installed, updating..." -ForegroundColor Green
        $ErrorActionPreference = "Continue"
        uv self update 2>&1 | Out-Null
        $ErrorActionPreference = "Stop"
    }

    Write-Host "Installing Python 3.14 via uv..." -ForegroundColor Yellow
    $ErrorActionPreference = "Continue"
    uv python install 3.14 2>&1 | ForEach-Object { Write-Host $_ }
    $ErrorActionPreference = "Stop"
    Write-Host "uv + Python 3.14 ready" -ForegroundColor Green
}

function Install-Project {
    Write-Host "Installing Free Claude Code globally..." -ForegroundColor Yellow

    $ErrorActionPreference = "Continue"
    if (Test-Path "$InstallDir\.git") {
        Write-Host "Updating existing installation..." -ForegroundColor Yellow
        git -C $InstallDir pull --ff-only 2>&1 | ForEach-Object { Write-Host $_ }
    } else {
        if (Test-Path $InstallDir) {
            Remove-Item -Recurse -Force $InstallDir
        }
        git clone https://github.com/iakhileshnanda/freecode.git $InstallDir 2>&1 | ForEach-Object { Write-Host $_ }
    }
    $ErrorActionPreference = "Stop"

    Write-Host "Project installed at $InstallDir" -ForegroundColor Green
}

function Setup-Config {
    Write-Host "Setting up configuration..." -ForegroundColor Yellow

    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }

    if (Test-Path "$ConfigDir\.env") {
        Write-Host "Config already exists at $ConfigDir\.env - keeping it" -ForegroundColor Yellow
        return
    }

    Write-Host "Get a free NVIDIA API key from: https://build.nvidia.com/explore" -ForegroundColor Blue
    $nvidia_key = Read-Host "Enter your NVIDIA API key (or press Enter to skip)"

    if ([string]::IsNullOrEmpty($nvidia_key)) {
        $nvidia_key = "YOUR_NVIDIA_API_KEY_HERE"
    }

    $envContent = @"
# Free Claude Code Configuration

# NVIDIA API Key (get from: https://build.nvidia.com/explore)
NVIDIA_NIM_API_KEY="$nvidia_key"

# Model configurations
MODEL_OPUS="nvidia_nim/moonshotai/kimi-k2-instruct-0905"
MODEL_SONNET="nvidia_nim/qwen/qwen3-coder-480b-a35b-instruct"
MODEL_HAIKU="nvidia_nim/deepseek-ai/deepseek-v3_2"
MODEL="nvidia_nim/deepseek-ai/deepseek-v3_2"
"@

    $envContent | Out-File -FilePath "$ConfigDir\.env" -Encoding UTF8
    Write-Host "Config created at $ConfigDir\.env" -ForegroundColor Green

    if ($nvidia_key -eq "YOUR_NVIDIA_API_KEY_HERE") {
        Write-Host "WARNING: Edit $ConfigDir\.env and add your NVIDIA API key later" -ForegroundColor Yellow
    }
}

function Setup-EnvVariables {
    Write-Host "Setting environment variables permanently..." -ForegroundColor Yellow

    # Set system-wide user environment variables (persist across reboots)
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "freecc", "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "http://localhost:8082", "User")

    # Detect Git Bash path
    $gitBashPath = ""
    $possiblePaths = @(
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\usr\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe"
    )
    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            $gitBashPath = $p
            break
        }
    }
    if (-not [string]::IsNullOrEmpty($gitBashPath)) {
        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $gitBashPath, "User")
        Write-Host "Git Bash path set: $gitBashPath" -ForegroundColor Green
    }

    # Apply to current session too
    $env:ANTHROPIC_AUTH_TOKEN = "freecc"
    $env:ANTHROPIC_BASE_URL = "http://localhost:8082"

    Write-Host "Environment variables set permanently (User level)" -ForegroundColor Green

    # Add a PowerShell profile function so "claude" auto-starts the server
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $marker = "# Free Claude Code - auto-start server"
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent -or $profileContent -notlike "*$marker*") {
        $functionBlock = @'

# Free Claude Code - auto-start server
function claude {
    try { $null = Invoke-WebRequest -Uri "http://localhost:8082/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop }
    catch {
        Write-Host "Starting Free Claude Code server..." -ForegroundColor Yellow
        Start-Process cmd -ArgumentList "/c", "cd /d $env:LOCALAPPDATA\free-claude-code && uv run uvicorn server:app --host 0.0.0.0 --port 8082" -WindowStyle Hidden
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Seconds 1
            try { $null = Invoke-WebRequest -Uri "http://localhost:8082/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop; break } catch {}
        }
    }
    $claudePath = (Get-Command claude.exe -ErrorAction SilentlyContinue).Source
    if ($claudePath) { & $claudePath @args } else { Write-Host "Claude Code CLI not found. Run: npm install -g @anthropic-ai/claude-code" -ForegroundColor Red }
}
'@
        Add-Content -Path $PROFILE -Value $functionBlock
        Write-Host "PowerShell profile updated: claude auto-starts server" -ForegroundColor Green
    }
}

function Create-ServerScript {
    Write-Host "Creating server launcher..." -ForegroundColor Yellow

    # Create start-fcc-server.bat in a PATH-accessible location
    $scriptsDir = "$env:LOCALAPPDATA\free-claude-code\bin"
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    }

    # Add to user PATH if not already there
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$scriptsDir*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptsDir", "User")
        $env:PATH = "$env:PATH;$scriptsDir"
        Write-Host "Added $scriptsDir to PATH" -ForegroundColor Green
    }

    # Create fcc-server.bat
    $serverBat = @"
@echo off
cd /d "$InstallDir"
uv run uvicorn server:app --host 0.0.0.0 --port 8082
"@
    $serverBat | Out-File -FilePath "$scriptsDir\fcc-server.bat" -Encoding ASCII

    # Create claude-free.bat (auto-starts server if needed + runs claude)
    $claudeFreeBat = @"
@echo off
set ANTHROPIC_AUTH_TOKEN=freecc
set ANTHROPIC_BASE_URL=http://localhost:8082

REM Check if server is running
curl -s http://localhost:8082/health >nul 2>&1
if errorlevel 1 (
    echo Starting Free Claude Code server...
    start /b cmd /c "cd /d $InstallDir && uv run uvicorn server:app --host 0.0.0.0 --port 8082 > nul 2>&1"
    timeout /t 5 /nobreak >nul
)

claude %*
"@
    $claudeFreeBat | Out-File -FilePath "$scriptsDir\claude-free.bat" -Encoding ASCII

    Write-Host "Commands created: fcc-server, claude-free" -ForegroundColor Green
}

function Setup-Autostart {
    Write-Host "Setting up server autostart on login..." -ForegroundColor Yellow

    $startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

    # Use VBScript to run the server completely hidden (no window flash)
    $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c cd /d ""$InstallDir"" && uv run uvicorn server:app --host 0.0.0.0 --port 8082", 0, False
"@
    $vbsContent | Out-File -FilePath "$startupDir\free-claude-code.vbs" -Encoding ASCII

    # Remove old .bat autostart if it exists
    $oldBat = "$startupDir\free-claude-code.bat"
    if (Test-Path $oldBat) { Remove-Item $oldBat -Force }

    Write-Host "Server will auto-start on Windows login" -ForegroundColor Green
}

function Start-ServerNow {
    Write-Host "Starting server..." -ForegroundColor Yellow

    # Check if already running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8082/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "Server already running" -ForegroundColor Green
        return
    } catch {}

    # Start hidden (no visible window)
    Start-Process cmd -ArgumentList "/c", "cd /d $InstallDir && uv run uvicorn server:app --host 0.0.0.0 --port 8082" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    Write-Host "Server running on http://localhost:8082" -ForegroundColor Green
}

function Show-Success {
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "      Installation Complete!           " -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now open ANY terminal, ANY folder, ANY IDE (VS Code, Cursor, etc.) and run:" -ForegroundColor White
    Write-Host ""
    Write-Host "  claude" -ForegroundColor Cyan -NoNewline
    Write-Host "         (works directly - env vars are set globally)"
    Write-Host "  claude-free" -ForegroundColor Cyan -NoNewline
    Write-Host "    (auto-starts server if needed + runs claude)"
    Write-Host ""
    Write-Host "NOTE: Close and reopen your terminal for env vars to take effect." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Server auto-starts on login. To manage manually:" -ForegroundColor White
    Write-Host "  Start:  fcc-server" -ForegroundColor Blue
    Write-Host "  Config: $ConfigDir\.env" -ForegroundColor Blue
}

# Main execution
Write-Banner
Test-Dependencies
Install-ClaudeCLI
Install-UV
Install-Project
Setup-Config
Setup-EnvVariables
Create-ServerScript
Setup-Autostart
Start-ServerNow
Show-Success
