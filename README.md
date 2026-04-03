# 🚀 Claude Free Code

**One-command Claude setup** - No login dashboard, uses your NVIDIA API key!

## ⚡ Quick Start

### Linux/macOS
```bash
git clone https://github.com/iakhileshnanda/freecode.git
cd freecode
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)
```powershell
# Method 1: PowerShell (Recommended)
git clone https://github.com/iakhileshnanda/freecode.git
cd freecode
.\install.ps1

# Method 2: Git Bash (NEW!)
git clone https://github.com/iakhileshnanda/freecode.git
cd freecode
chmod +x install-git-bash.sh
./install-git-bash.sh
```

### Windows Issues? Try this:
```powershell
# Manual Windows setup
$env:ANTHROPIC_AUTH_TOKEN="freecc"
$env:ANTHROPIC_BASE_URL="http://localhost:8082"
claude

# Git Bash users
export ANTHROPIC_AUTH_TOKEN="freecc"
export ANTHROPIC_BASE_URL="http://localhost:8082"
claude
```

## ✅ What You Get
- **No login required** - Bypasses Claude dashboard
- **NVIDIA NIM models** - Premium quality with your API key
- **Cross-platform** - Linux, macOS, Windows
- **Auto-detection** - Smart OS detection

## 🎯 Models
- **Opus**: Kimi K2 (premium reasoning)
- **Sonnet**: Qwen3 Coder (advanced coding) 
- **Haiku**: DeepSeek V3.2 (fast & efficient)

## 🔧 Usage
After install, just run:
```bash
claude-free  # No login required!
```

## 🆘 Troubleshooting
**Windows PowerShell not working?**
1. Run PowerShell as Administrator
2. Set execution policy: `Set-ExecutionPolicy RemoteSigned`
3. Try Git Bash instead

**Get NVIDIA API key:** https://build.nvidia.com/explore