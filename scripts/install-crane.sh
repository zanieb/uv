#!/usr/bin/env bash
#
# Install the Crane CLI from go-containerregistry.
#
# Usage:
#
#   ./dev/install-crane.sh [<version>]
#
# If no version is specified, the latest version will be installed.
#
# The installation path can be set using the `CRANE_INSTALL_DIR` environment variable, but defaults
# to /usr/local/bin.
#
# Loosely derived from https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md

set -e

install_crane_cli() {
    CRANE_INSTALL_DIR="${CRANE_INSTALL_DIR:-/usr/local/bin}"
    if [[ ! -d "${CRANE_INSTALL_DIR}" ]]; then
        echo "Installation directory ${CRANE_INSTALL_DIR} not found"
        exit 1
    fi
    echo "Installing to ${CRANE_INSTALL_DIR}"
    
    VERSION="$1"

    if [ -z "$VERSION" ]; then
        # Fetch the latest version
        # Strip the leading 'v' from the version number
        VERSION=$(curl -sSfL https://api.github.com/repos/google/go-containerregistry/releases/latest | jq -r .tag_name | sed 's/^v//')
        echo "Found latest version ${VERSION}"
    fi

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="Darwin"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="Windows"
    else
        echo "Operating system not supported yet for this installer: $OSTYPE."
        exit 1
    fi

    # Detect architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="arm64"
    elif [[ "$ARCH" == "armv6l" ]] || [[ "$ARCH" == "armv7l" ]]; then
        ARCH="armv6"
    elif [[ "$ARCH" == "i386" ]] || [[ "$ARCH" == "i686" ]]; then
        ARCH="i386"
    elif [[ "$ARCH" == "s390x" ]]; then
        ARCH="s390x"
    else
        echo "Architecture not supported: $ARCH."
        exit 1
    fi

    URL="https://github.com/google/go-containerregistry/releases/download/v${VERSION}/go-containerregistry_${OS}_${ARCH}.tar.gz"
    echo "Downloading from ${URL}"
    curl -sSfLo go-containerregistry.tar.gz "${URL}"

    # Extract crane binary
    tar -xzf go-containerregistry.tar.gz crane
    rm go-containerregistry.tar.gz

    # Move to installation directory
    chmod +x crane
    mv crane "${CRANE_INSTALL_DIR}/"

    echo "Installed crane"
}

install_crane_cli $1
