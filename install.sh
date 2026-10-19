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

# Refuse to silently install over a Cargo development setup.
#
# Cairn's development builds are installed with `cargo install --path .`
# from the cairn-runtime and cairn-code checkouts, which puts `cairn` and
# `cairn-runtime` in Cargo's bin directory. The release and development
# builds share the `cairn` name, so with both installed, whichever
# directory comes first in PATH silently wins: a developer who runs this
# installer ends up testing the release build without knowing it (this
# has already happened), and the reverse order strands a release user on
# a development build. So when development builds are present, stop and
# offer the choice: delete the development builds and install the
# release build, or delete the release builds and keep the development
# ones. With no terminal to ask on, refuse and explain.
CARGO_BIN_DIR="${CARGO_HOME:-${HOME}/.cargo}/bin"
DEV_BINARIES=""
DEV_NEWEST_MTIME=0
for DEV_NAME in cairn cairn-runtime; do
    if [ -x "${CARGO_BIN_DIR}/${DEV_NAME}" ]; then
        DEV_BINARIES="${DEV_BINARIES}  ${CARGO_BIN_DIR}/${DEV_NAME}
"
        # stat is not portable: GNU uses -c %Y, BSD and macOS use -f %m.
        DEV_MTIME="$(stat -c %Y "${CARGO_BIN_DIR}/${DEV_NAME}" 2>/dev/null || stat -f %m "${CARGO_BIN_DIR}/${DEV_NAME}" 2>/dev/null || echo 0)"
        case "$DEV_MTIME" in
            ''|*[!0-9]*) DEV_MTIME=0 ;;
        esac
        if [ "$DEV_MTIME" -gt "$DEV_NEWEST_MTIME" ]; then
            DEV_NEWEST_MTIME="$DEV_MTIME"
        fi
    fi
done
# Switching to the development builds is only offered when they are
# recent (newest installed within the last 30 days). An old development
# build is exactly the stale-binary trap this guard exists to prevent,
# so a stale one is never offered as the build to keep.
DEV_RECENT=0
DEV_AGE_DAYS=""
if [ "$DEV_NEWEST_MTIME" -gt 0 ]; then
    DEV_AGE_DAYS=$(( ($(date +%s) - DEV_NEWEST_MTIME) / 86400 ))
    if [ "$DEV_AGE_DAYS" -le 30 ]; then
        DEV_RECENT=1
    fi
fi
if [ -n "$DEV_BINARIES" ]; then
    echo "Warning: you are trying to install a public release version of Cairn when" >&2
    echo "you seem to already have developer access. Development builds are already" >&2
    echo "installed in your PATH:" >&2
    printf '%s' "$DEV_BINARIES" >&2
    echo "Please update through git and cargo instead: pull your cairn-runtime and" >&2
    echo "cairn-code checkouts and rebuild them with `cargo install --path .`." >&2
    echo "The release and development builds share the cairn name, so with both" >&2
    echo "installed, whichever directory comes first in your PATH silently wins and" >&2
    echo "you end up running the other build without knowing it." >&2
    echo "" >&2
    if [ "$DEV_RECENT" -eq 0 ] && [ -n "$DEV_AGE_DAYS" ]; then
        echo "The newest development build here was installed ${DEV_AGE_DAYS} days ago," >&2
        echo "so switching to the development builds is not offered." >&2
        echo "" >&2
    fi
    CHOICE=""
    if [ -r /dev/tty ]; then
        echo "What would you like to do?"
        echo "  1) Remove the development builds and install the release build"
        if [ "$DEV_RECENT" -eq 1 ]; then
            echo "  2) Remove the release builds and keep the development builds"
            echo "  3) Cancel and change nothing"
            printf 'Choose [1/2/3]: '
        else
            echo "  2) Cancel and change nothing"
            printf 'Choose [1/2]: '
        fi
        read -r CHOICE < /dev/tty || CHOICE=""
    fi
    case "${CHOICE}:${DEV_RECENT}" in
        1:*)
            for DEV_NAME in cairn cairn-runtime; do
                rm -f "${CARGO_BIN_DIR}/${DEV_NAME}"
            done
            echo "Removed the development builds from ${CARGO_BIN_DIR}."
            echo "Continuing with the release install."
            ;;
        2:1)
            REMOVED_RELEASE=""
            for RELEASE_BIN in "${HOME}/.local/bin/cairn" "/usr/local/bin/cairn"; do
                if [ -e "$RELEASE_BIN" ]; then
                    if rm -f "$RELEASE_BIN" 2>/dev/null; then
                        REMOVED_RELEASE="${REMOVED_RELEASE}  ${RELEASE_BIN}
"
                    else
                        echo "Could not remove ${RELEASE_BIN}; remove it with:" >&2
                        echo "  sudo rm \"${RELEASE_BIN}\"" >&2
                    fi
                fi
            done
            if [ -n "$REMOVED_RELEASE" ]; then
                echo "Removed the release builds:"
                printf '%s' "$REMOVED_RELEASE"
            else
                echo "No release builds were found in ~/.local/bin or /usr/local/bin."
            fi
            echo "Keeping the development builds. Update them through git and cargo."
            exit 0
            ;;
        *)
            echo "Refusing to install alongside the development builds." >&2
            echo "" >&2
            echo "To install the release build instead, remove the development binaries first:" >&2
            echo "  rm \"${CARGO_BIN_DIR}/cairn\" \"${CARGO_BIN_DIR}/cairn-runtime\"" >&2
            echo "then run this installer again." >&2
            exit 1
            ;;
    esac
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
