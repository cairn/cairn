#!/bin/sh
set -eu

# Cairn Code installer (Linux & macOS)
# Usage: curl -fsSL https://raw.githubusercontent.com/cairn/cairn/main/install.sh | sh

REPO="cairn/cairn"
BINARY_NAME="cairn"
ASSET_NAME="cairn-code-linux-x86_64"

# Validate OS
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64|amd64)
                ASSET_NAME="cairn-code-linux-x86_64"
                ;;
            aarch64|arm64)
                ASSET_NAME="cairn-code-linux-aarch64"
                ;;
            *)
                echo "Error: Unsupported architecture '${ARCH}' on Linux." >&2
                exit 1
                ;;
        esac
        ;;
    Darwin)
        case "$ARCH" in
            arm64|aarch64)
                ASSET_NAME="cairn-code-macos-aarch64"
                ;;
            x86_64|amd64)
                ASSET_NAME="cairn-code-macos-x86_64"
                ;;
            *)
                echo "Error: Unsupported architecture '${ARCH}' on macOS." >&2
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Error: Unsupported operating system '${OS}'. Cairn Code supports macOS and Linux." >&2
        exit 1
        ;;
esac

# Refuse to install over a Cargo development setup.
#
# Cairn's development builds are installed with `cargo install --path .`
# from the cairn-runtime and cairn-code checkouts, which puts `cairn` and
# `cairn-runtime` in Cargo's bin directory. The release and development
# builds share the `cairn` name, so with both installed, whichever
# directory comes first in PATH silently wins: a developer who runs this
# installer ends up testing the release build without knowing it (this
# has already happened), and the reverse order strands a release user on
# a development build. Refuse while development builds are present.
CARGO_BIN_DIR="${CARGO_HOME:-${HOME}/.cargo}/bin"
DEV_BINARIES=""
for DEV_NAME in cairn cairn-runtime; do
    if [ -x "${CARGO_BIN_DIR}/${DEV_NAME}" ]; then
        DEV_BINARIES="${DEV_BINARIES}  ${CARGO_BIN_DIR}/${DEV_NAME}
"
    fi
done
if [ -n "$DEV_BINARIES" ]; then
    echo "Warning: you are trying to install a public release version of Cairn when" >&2
    echo "you seem to already have developer access. Development builds are already" >&2
    echo "installed in your PATH:" >&2
    printf '%s' "$DEV_BINARIES" >&2
    echo "Please update through git and cargo instead: pull your cairn-runtime and" >&2
    echo "cairn-code checkouts and rebuild them with \`cargo install --path .\`." >&2
    echo "The release and development builds share the cairn name, so with both" >&2
    echo "installed, whichever directory comes first in your PATH silently wins and" >&2
    echo "you end up running the other build without knowing it. Refusing to install." >&2
    echo "" >&2
    echo "To install the release build instead, remove the development binaries first:" >&2
    echo "  rm \"${CARGO_BIN_DIR}/cairn\" \"${CARGO_BIN_DIR}/cairn-runtime\"" >&2
    echo "then run this installer again." >&2
    exit 1
fi

# Require curl
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to download Cairn Code." >&2
    exit 1
fi

# Resolve "latest" to a pinned version tag before downloading anything.
# Fetching the binary and the checksum file from two separate "latest" URLs
# is a TOCTOU race: if a new release is published between the two downloads,
# the checksum will not match the binary and the install fails. Pinning both
# downloads to the same immutable release tag eliminates that window.
echo "Resolving latest release version..."
if ! RELEASE_JSON="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"; then
    echo "Error: Failed to resolve the latest release version from the GitHub API." >&2
    exit 1
fi
TAG="$(printf '%s\n' "$RELEASE_JSON" | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p')"
if [ -z "$TAG" ]; then
    echo "Error: Could not parse a release tag from the GitHub API response." >&2
    echo "Refusing to install an unverified binary." >&2
    exit 1
fi
# The tag is interpolated into download URLs below; reject anything that
# does not look like a version tag.
case "$TAG" in
    *[!A-Za-z0-9._-]*)
        echo "Error: Refusing to use unexpected release tag '${TAG}'." >&2
        exit 1
        ;;
esac
echo "Latest release is ${TAG}."

# Determine install directory
if [ -n "${CAIRN_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="$CAIRN_INSTALL_DIR"
elif [ -w "/usr/local/bin" ] && [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

# Download release binary and checksums, both pinned to the resolved tag
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET_NAME}"
CHECKSUM_URL="https://github.com/${REPO}/releases/download/${TAG}/sha256sum.txt"
TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/cairn.XXXXXX")"
TMP_SUMS="$(mktemp "${TMPDIR:-/tmp}/cairn-sums.XXXXXX")"
trap 'rm -f "$TMP_FILE" "$TMP_SUMS"' EXIT

echo "Downloading Cairn Code from ${DOWNLOAD_URL}..."
if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    echo "Error: Failed to download ${ASSET_NAME} from ${DOWNLOAD_URL}." >&2
    if [ "$OS" = "Darwin" ]; then
        echo "macOS release binaries may not be published yet for release ${TAG}." >&2
    fi
    exit 1
fi

echo "Downloading checksums from ${CHECKSUM_URL}..."
if ! curl -fsSL "$CHECKSUM_URL" -o "$TMP_SUMS"; then
    echo "Error: Failed to download sha256sum.txt from ${CHECKSUM_URL}." >&2
    echo "Refusing to install an unverified binary." >&2
    exit 1
fi

# Verify the binary against the published checksum before installing
echo "Verifying checksum..."
EXPECTED="$(grep " ${ASSET_NAME}$" "$TMP_SUMS" | awk '{print $1}')"
if [ -z "$EXPECTED" ]; then
    echo "Error: No checksum found for ${ASSET_NAME} in sha256sum.txt." >&2
    echo "Refusing to install an unverified binary." >&2
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL="$(sha256sum "$TMP_FILE" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
    ACTUAL="$(shasum -a 256 "$TMP_FILE" | awk '{print $1}')"
else
    echo "Error: Neither sha256sum nor shasum is available to verify the download." >&2
    echo "Refusing to install an unverified binary." >&2
    exit 1
fi

if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "Error: Checksum mismatch for ${ASSET_NAME}." >&2
    echo "  Expected: ${EXPECTED}" >&2
    echo "  Actual:   ${ACTUAL}" >&2
    echo "The download may be corrupted or tampered with. Aborting." >&2
    exit 1
fi
echo "Checksum verified."
chmod +x "$TMP_FILE"

DEST="${INSTALL_DIR}/${BINARY_NAME}"
mv -f "$TMP_FILE" "$DEST"
trap - EXIT

# Clean up the checksums file
rm -f "$TMP_SUMS"

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
