# Cairn Code installer (Windows)
# Usage: irm https://raw.githubusercontent.com/cairn/cairn/main/install.ps1 | iex
#
# This is the Windows counterpart of install.sh and follows the same
# contract: resolve "latest" to a pinned release tag before downloading
# anything, download the binary and its checksums from that same tag,
# verify the SHA-256 before installing, and refuse on any failure.
# It also carries the same development-build guard as install.sh: when
# Cargo development builds share the `cairn` name, stop and offer the
# choice instead of silently installing over them.

$ErrorActionPreference = 'Stop'

$Repo = "cairn/cairn"
$BinaryName = "cairn.exe"
$AssetName = "cairn-code-windows-x86_64.exe"

# Architecture validation: only an x86_64 Windows binary is published.
$Arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
if ($Arch -notmatch '^(AMD64|x86_64|X64)$') {
    throw "Unsupported architecture '$Arch'. Only x86_64 (64-bit) Windows is currently supported."
}

# Ensure TLS 1.2 is enabled for older PowerShell 5.1 environments.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

# ---------------------------------------------------------------------------
# Development-build guard (mirrors install.sh).
#
# Cairn's development builds are installed with `cargo install --path .`
# from the cairn-runtime and cairn-code checkouts, which puts `cairn.exe`
# and `cairn-runtime.exe` in Cargo's bin directory. The release and
# development builds share the `cairn` name, so with both installed,
# whichever directory comes first in PATH silently wins. When development
# builds are present, stop and offer the choice; with no console to ask
# on, refuse and explain.
# ---------------------------------------------------------------------------
$CargoBinDir = if ($env:CARGO_HOME) { Join-Path $env:CARGO_HOME "bin" } else { Join-Path $env:USERPROFILE ".cargo\bin" }
$DevBinaries = @()
$DevNewestTime = $null
foreach ($DevName in @("cairn.exe", "cairn-runtime.exe")) {
    $DevPath = Join-Path $CargoBinDir $DevName
    if (Test-Path $DevPath) {
        $DevBinaries += $DevPath
        $Mtime = (Get-Item $DevPath).LastWriteTime
        if ($null -eq $DevNewestTime -or $Mtime -gt $DevNewestTime) {
            $DevNewestTime = $Mtime
        }
    }
}
# Switching to the development builds is only offered when they are
# recent (newest installed within the last 30 days); a stale development
# build is exactly the trap this guard exists to prevent.
$DevRecent = $false
$DevAgeDays = $null
if ($null -ne $DevNewestTime) {
    $DevAgeDays = [int]((Get-Date) - $DevNewestTime).TotalDays
    if ($DevAgeDays -le 30) {
        $DevRecent = $true
    }
}
if ($DevBinaries.Count -gt 0) {
    Write-Host "Warning: you are trying to install a public release version of Cairn when"
    Write-Host "you seem to already have developer access. Development builds are already"
    Write-Host "installed in your PATH:"
    $DevBinaries | ForEach-Object { Write-Host "  $_" }
    Write-Host "Please update through git and cargo instead: pull your cairn-runtime and"
    Write-Host "cairn-code checkouts and rebuild them with ``cargo install --path .``."
    Write-Host "The release and development builds share the cairn name, so with both"
    Write-Host "installed, whichever directory comes first in your PATH silently wins and"
    Write-Host "you end up running the other build without knowing it."
    Write-Host ""
    if (-not $DevRecent -and $null -ne $DevAgeDays) {
        Write-Host "The newest development build here was installed $DevAgeDays days ago,"
        Write-Host "so switching to the development builds is not offered."
        Write-Host ""
    }
    $Choice = ""
    if (-not [Console]::IsInputRedirected) {
        Write-Host "What would you like to do?"
        Write-Host "  1) Remove the development builds and install the release build"
        if ($DevRecent) {
            Write-Host "  2) Remove the release builds and keep the development builds"
            Write-Host "  3) Cancel and change nothing"
            $Choice = Read-Host "Choose [1/2/3]"
        } else {
            Write-Host "  2) Cancel and change nothing"
            $Choice = Read-Host "Choose [1/2]"
        }
    }
    if ($Choice -eq "1") {
        foreach ($DevName in @("cairn.exe", "cairn-runtime.exe")) {
            Remove-Item (Join-Path $CargoBinDir $DevName) -Force -ErrorAction SilentlyContinue
        }
        Write-Host "Removed the development builds from $CargoBinDir."
        Write-Host "Continuing with the release install."
    } elseif ($Choice -eq "2" -and $DevRecent) {
        $RemovedRelease = @()
        $ReleaseDirs = @()
        if ($env:CAIRN_INSTALL_DIR) { $ReleaseDirs += $env:CAIRN_INSTALL_DIR }
        if ($env:LOCALAPPDATA) { $ReleaseDirs += (Join-Path $env:LOCALAPPDATA "cairn\bin") }
        $ReleaseDirs += (Join-Path $env:USERPROFILE ".cairn\bin")
        foreach ($Dir in $ReleaseDirs) {
            $ReleaseBin = Join-Path $Dir "cairn.exe"
            if (Test-Path $ReleaseBin) {
                Remove-Item $ReleaseBin -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $ReleaseBin)) {
                    $RemovedRelease += $ReleaseBin
                } else {
                    Write-Host "Could not remove $ReleaseBin; remove it manually."
                }
            }
        }
        if ($RemovedRelease.Count -gt 0) {
            Write-Host "Removed the release builds:"
            $RemovedRelease | ForEach-Object { Write-Host "  $_" }
        } else {
            Write-Host "No release builds were found in the install directories."
        }
        Write-Host "Keeping the development builds. Update them through git and cargo."
        return
    } else {
        throw "Refusing to install alongside the development builds. To install the release build instead, remove the development binaries first (Remove-Item `"$CargoBinDir\cairn.exe`", `"$CargoBinDir\cairn-runtime.exe`") and run this installer again."
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

# Resolve "latest" to a pinned version tag before downloading anything.
# Fetching the binary and the checksum file from two separate "latest"
# URLs is a TOCTOU race: if a new release is published between the two
# downloads, the checksum will not match the binary and the install
# fails. Pinning both downloads to the same immutable release tag
# eliminates that window.
Write-Host "Resolving latest release version..."
$Headers = @{ "User-Agent" = "cairn-installer" }
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers -UseBasicParsing
    $Tag = $Release.tag_name
} catch {
    throw "Failed to resolve the latest release version from the GitHub API: $_"
}
if (-not $Tag) {
    throw "Could not parse a release tag from the GitHub API response. Refusing to install an unverified binary."
}
# The tag is interpolated into download URLs below; reject anything that
# does not look like a version tag.
if ($Tag -notmatch '^[A-Za-z0-9._-]+$') {
    throw "Refusing to use unexpected release tag '$Tag'."
}
Write-Host "Latest release is $Tag."

# Download release binary and checksums, both pinned to the resolved tag
$DownloadUrl = "https://github.com/$Repo/releases/download/$Tag/$AssetName"
$ChecksumUrl = "https://github.com/$Repo/releases/download/$Tag/sha256sum.txt"
$TempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + ".exe")
$TempSums = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName() + ".txt")

try {
    Write-Host "Downloading Cairn Code from $DownloadUrl..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -Headers $Headers -UseBasicParsing

    Write-Host "Downloading checksums from $ChecksumUrl..."
    try {
        Invoke-WebRequest -Uri $ChecksumUrl -OutFile $TempSums -Headers $Headers -UseBasicParsing
    } catch {
        throw "Failed to download sha256sum.txt from $ChecksumUrl. Refusing to install an unverified binary."
    }

    # Verify the binary against the published checksum before installing
    Write-Host "Verifying checksum..."
    $Expected = $null
    foreach ($Line in (Get-Content $TempSums)) {
        if ($Line -match '^([0-9a-fA-F]{64})\s+cairn-code-windows-x86_64\.exe$') {
            $Expected = $Matches[1]
        }
    }
    if (-not $Expected) {
        throw "No checksum found for $AssetName in sha256sum.txt. Refusing to install an unverified binary."
    }
    $Actual = (Get-FileHash -Path $TempFile -Algorithm SHA256).Hash
    if ($Actual -ine $Expected) {
        throw "Checksum mismatch for $AssetName. Expected: $Expected Actual: $Actual The download may be corrupted or tampered with. Aborting."
    }
    Write-Host "Checksum verified."

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
} finally {
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $TempSums) {
        Remove-Item -Path $TempSums -Force -ErrorAction SilentlyContinue
    }
}
