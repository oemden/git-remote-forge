#!/bin/bash
# gitremote.sh
# A Bash script to install gitremote.sh.
# Will be installed in /usr/local/bin/gitremote

VERSION="0.9.7"
INSTALL_PATH="/usr/local/bin/gitremote"
SCRIPT_SOURCE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gitremote.sh"

# Check if the script source file exists
if [ ! -f "${SCRIPT_SOURCE_PATH}" ]; then
    echo "Error: gitremote.sh not found in the current directory."
    exit 1
fi

# Check if the user has sudo privileges
if ! sudo -v; then
    echo "This script requires sudo privileges. Please run it with a user that has sudo access."
    exit 1
fi

# Install the script
echo "Installing gitremote ${VERSION} to ${INSTALL_PATH} ..."
# Copy the script to the installation path
cp "${SCRIPT_SOURCE_PATH}" "${INSTALL_PATH}"
# Make the script executable
chmod +x "${INSTALL_PATH}"

echo "gitremote has been installed to ${INSTALL_PATH}"
ls -l "${INSTALL_PATH}"

echo "You can run it using the command: gitremote"
echo ""
echo "Installation complete! To use 'gitremote' immediately in this shell, run:"
echo ""
echo "  rehash    (for zsh)"
echo "  hash -r   (for bash)"
echo ""
echo "Or simply open a new terminal window."

exit 0
