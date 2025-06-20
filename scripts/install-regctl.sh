#!/usr/bin/env bash
#
# Install the regctl CLI from regclient.
#
# Usage:
#
#   ./dev/install-regctl.sh [<version>]
#
# If no version is specified, the latest version will be installed.
#
# The installation path can be set using the `REGCTL_INSTALL_DIR` environment variable, but defaults
# to /usr/local/bin.
#
# Loosely derived from https://github.com/regclient/regclient/blob/main/docs/install.md

set -e

install_regctl_cli() {
    REGCTL_INSTALL_DIR="${REGCTL_INSTALL_DIR:-/usr/local/bin}"
    if [[ ! -d "${REGCTL_INSTALL_DIR}" ]]; then
        echo "Installation directory ${REGCTL_INSTALL_DIR} not found"
        exit 1
    fi
    echo "Installing to ${REGCTL_INSTALL_DIR}"
    
    VERSION="$1"

    if [ -z "$VERSION" ]; then
        # Fetch the latest version
        # Strip the leading 'v' from the version number
        VERSION=$(curl -sSfL https://api.github.com/repos/regclient/regclient/releases/latest | jq -r .tag_name | sed 's/^v//')
        echo "Found latest version ${VERSION}"
    fi

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        echo "Operating system not supported yet for this installer: $OSTYPE."
        exit 1
    fi

    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="amd64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    elif [[ "$ARCH" == "armv7l" ]]; then
        ARCH="armv7"
    elif [[ "$ARCH" == "i386" ]] || [[ "$ARCH" == "i686" ]]; then
        ARCH="386"
    elif [[ "$ARCH" == "ppc64le" ]]; then
        ARCH="ppc64le"
    elif [[ "$ARCH" == "s390x" ]]; then
        ARCH="s390x"
    else
        echo "Architecture not supported yet for this installer: $ARCH."
        exit 1
    fi
    
    # Construct filename based on OS
    if [[ "$OS" == "windows" ]]; then
        FILENAME="regctl-${OS}-${ARCH}.exe"
        BINARY_NAME="regctl.exe"
    else
        FILENAME="regctl-${OS}-${ARCH}"
        BINARY_NAME="regctl"
    fi
    
    URL="https://github.com/regclient/regclient/releases/download/v${VERSION}/${FILENAME}"
    echo "Downloading from ${URL}"
    
    # Download the binary directly (regclient releases are not compressed)
    curl -sSfLo "${BINARY_NAME}" "${URL}"
    
    # Make it executable (not needed for Windows)
    if [[ "$OS" != "windows" ]]; then
        chmod +x "${BINARY_NAME}"
    fi
    
    # Move to installation directory
    mv "${BINARY_NAME}" "${REGCTL_INSTALL_DIR}/"
    
    echo "Installed regctl"
}

install_regctl_cli $1
