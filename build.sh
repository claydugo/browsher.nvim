#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Parse command line arguments
TEST_EXTENSION=false
PACKAGE_EXTENSION=false

for arg in "$@"; do
  case $arg in
    --test)
      TEST_EXTENSION=true
      ;;
    --package)
      PACKAGE_EXTENSION=true
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --test     Launch VSCode with the extension in development mode after building"
      echo "  --package  Package the VSCode extension after building"
      echo "  --help     Display this help message"
      exit 0
      ;;
  esac
done

# Check if fennel is installed
if ! command -v fennel &> /dev/null; then
    echo "Error: fennel not found. Please install fennel first."
    echo "Visit https://fennel-lang.org/setup for installation instructions."
    exit 1
fi

# Create output directories
mkdir -p "${PROJECT_ROOT}/lua/browsher"
mkdir -p "${PROJECT_ROOT}/lua/browsher/platforms"
mkdir -p "${PROJECT_ROOT}/lua/browsher/core"
mkdir -p "${PROJECT_ROOT}/vscode-browsher/lua/browsher/core"
mkdir -p "${PROJECT_ROOT}/vscode-browsher/lua/browsher/platforms"

echo "Building Neovim plugin..."

# Compile Neovim version - config paths
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/config.fnl" > "${PROJECT_ROOT}/lua/browsher/config.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/config.fnl" > "${PROJECT_ROOT}/lua/browsher/core/config.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/git.fnl" > "${PROJECT_ROOT}/lua/browsher/git.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/git.fnl" > "${PROJECT_ROOT}/lua/browsher/core/git.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/url.fnl" > "${PROJECT_ROOT}/lua/browsher/url.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/url.fnl" > "${PROJECT_ROOT}/lua/browsher/core/url.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/init.fnl" > "${PROJECT_ROOT}/lua/browsher/_core.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/core/init.fnl" > "${PROJECT_ROOT}/lua/browsher/core/init.lua"

# Compile platform specific files
fennel --compile "${PROJECT_ROOT}/fennel/browsher/platforms/neovim.fnl" > "${PROJECT_ROOT}/lua/browsher/_platform.lua"
fennel --compile "${PROJECT_ROOT}/fennel/browsher/platforms/neovim.fnl" > "${PROJECT_ROOT}/lua/browsher/platforms/neovim.lua"

# Compile the entry point
fennel --compile "${PROJECT_ROOT}/fennel/browsher/platforms/neovim-entry.fnl" > "${PROJECT_ROOT}/lua/browsher/init.lua"

echo "Building VSCode extension..."

# Create symbolic links to Fennel sources in VSCode extension directory
ln -sf "${PROJECT_ROOT}/fennel/browsher/core/config.fnl" "${PROJECT_ROOT}/vscode-browsher/lua/browsher/core/"
ln -sf "${PROJECT_ROOT}/fennel/browsher/core/git.fnl" "${PROJECT_ROOT}/vscode-browsher/lua/browsher/core/"
ln -sf "${PROJECT_ROOT}/fennel/browsher/core/url.fnl" "${PROJECT_ROOT}/vscode-browsher/lua/browsher/core/"
ln -sf "${PROJECT_ROOT}/fennel/browsher/core/init.fnl" "${PROJECT_ROOT}/vscode-browsher/lua/browsher/core/"
ln -sf "${PROJECT_ROOT}/fennel/browsher/platforms/vscode.fnl" "${PROJECT_ROOT}/vscode-browsher/lua/browsher/platforms/"

# Compile VSCode extension
cd "${PROJECT_ROOT}/vscode-browsher"
npm install
fennel --compile "${PROJECT_ROOT}/vscode-browsher/extension.fnl" > "${PROJECT_ROOT}/vscode-browsher/extension.js"

# Actions based on command line arguments
if [ "$PACKAGE_EXTENSION" = true ]; then
  echo "Packaging VSCode extension..."
  cd "${PROJECT_ROOT}/vscode-browsher"
  npm run package
fi

if [ "$TEST_EXTENSION" = true ]; then
  echo "Launching VSCode with the extension in development mode..."
  
  # Detect a Git repository to use for testing
  TEST_REPO="${PROJECT_ROOT}"
  
  # If the user has a preferred test folder, use that instead
  if [ -n "$BROWSHER_TEST_FOLDER" ] && [ -d "$BROWSHER_TEST_FOLDER" ]; then
    TEST_REPO="$BROWSHER_TEST_FOLDER"
  fi
  
  echo "Using test folder: ${TEST_REPO}"
  
  # Launch VS Code with the extension in development mode
  cd "${PROJECT_ROOT}/vscode-browsher"
  code --extensionDevelopmentPath="$(pwd)" "${TEST_REPO}"
fi

# Return to project root
cd "${PROJECT_ROOT}"

echo "Build completed!"
echo "Neovim plugin: lua/browsher/*.lua"
echo "VSCode extension: vscode-browsher/extension.js"
echo
echo "To test the VSCode extension: ./build.sh --test"
echo "To package the VSCode extension: ./build.sh --package"
