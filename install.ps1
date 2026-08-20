# Cairn Code Windows installer
# Usage: irm https://raw.githubusercontent.com/cairn/cairn/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Repo = "cairn/cairn"
$BinaryName = "cairn.exe"

# Architecture validation
$Arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
switch -Regex ($Arch) {
    '^(AMD64|x86_64|X64)$' {
        $AssetName = "cairn-code-windows-x86_64.exe"
    }
    default {
        Write-Error "Unsupported architecture '$Arch'. Only x86_64 (64-bit) Windows is currently supported."
        exit 1
    }
}

# Determine install directory
if ($env:CAIRN_INSTALL_DIR) {
    $InstallDir = $env:CAIRN_INSTALL_DIR
} elseif ($env:LOCALAPPDATA) {
    $InstallDir = Join-Path $env:LOCALAPPDATA "cairn\bin"
} else {
    $InstallDir = Join-Path $env:USERPROFILE ".cairn\bin"
}

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$DownloadUrl = "https://github.com/$Repo/releases/latest/download/$AssetName"
$TempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + ".exe")

try {
    # Ensure TLS 1.2 is enabled for older PowerShell 5.1 environments
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {}

    Write-Host "Downloading Cairn Code from $DownloadUrl..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing

    $Dest = Join-Path $InstallDir $BinaryName
    Move-Item -Path $TempFile -Destination $Dest -Force

    Write-Host "Installed Cairn Code to $Dest"

    # Verify installation
    try {
        $Version = & $Dest --version
        Write-Host "Successfully installed: $Version"
    } catch {}

    # Add to User PATH if not present
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $PathEntries = if ($UserPath) { $UserPath -split ';' } else { @() }

    if ($PathEntries -notcontains $InstallDir) {
        $NewUserPath = if ($UserPath) { "$UserPath;$InstallDir" } else { $InstallDir }
        [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
        $env:PATH = "$env:PATH;$InstallDir"
        Write-Host "Added '$InstallDir' to your User PATH."
    }
} catch {
    Write-Error "Failed to install Cairn Code: $_"
    exit 1
} finally {
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
    }
}
