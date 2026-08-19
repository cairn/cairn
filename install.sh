#!/bin/sh
set -eu

# Cairn Code Linux installer
# Usage: curl -fsSL https://raw.githubusercontent.com/cairn/cairn/main/install.sh | sh

REPO="cairn/cairn"
BINARY_NAME="cairn"
ASSET_NAME="cairn-code-linux-x86_64"

# Validate OS
OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    echo "Error: Cairn Code installer currently supports Linux x86_64." >&2
    if [ "$OS" = "Darwin" ]; then
        echo "macOS is not built yet. Star or watch https://github.com/${REPO} for updates." >&2
    fi
    exit 1
fi

# Validate architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        ;;
    *)
        echo "Error: Unsupported architecture '${ARCH}'. Only x86_64 is currently supported." >&2
        exit 1
        ;;
esac

# Require curl
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to download Cairn Code." >&2
    exit 1
fi

# Determine install directory
if [ -n "${CAIRN_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$CAIRN_INSTALL_DIR"
elif [ -w "/usr/local/bin" ] && [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

# Download release binary
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"
TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/cairn.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading Cairn Code from ${DOWNLOAD_URL}..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"

DEST="${INSTALL_DIR}/${BINARY_NAME}"
mv -f "$TMP_FILE" "$DEST"
trap - EXIT

echo "Installed Cairn Code to ${DEST}"

# Verify installation
if "$DEST" --version >/dev/null 2>&1; then
    VERSION="$("$DEST" --version)"
    echo "Successfully installed: ${VERSION}"
fi

# Check PATH
case ":${PATH}:" in
    *:"${INSTALL_DIR}":*)
        ;;
    *)
        echo ""
        echo "Note: '${INSTALL_DIR}' is not in your PATH."
        echo "Add it to your shell configuration (e.g. ~/.bashrc or ~/.zshrc):"
        echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
        ;;
esac
