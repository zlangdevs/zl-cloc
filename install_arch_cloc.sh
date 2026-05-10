#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CLOC="$SCRIPT_DIR/cloc"
TARGET_CLOC="/usr/local/bin/cloc"

MODE="install"
if [[ "${1:-}" == "-R" ]]; then
  MODE="remove"
elif [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [-R]"
  echo "  no flag: install custom cloc to $TARGET_CLOC"
  echo "  -R     : fully remove cloc (repo package and $TARGET_CLOC)"
  exit 0
elif [[ $# -gt 0 ]]; then
  echo "Unknown option: $1"
  echo "Usage: $0 [-R]"
  exit 1
fi

if [[ ! -f "$SOURCE_CLOC" ]]; then
  echo "Error: file not found: $SOURCE_CLOC"
  exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
  echo "This script is intended for Arch Linux."
  exit 1
fi

if [[ "$MODE" == "remove" ]]; then
  if [[ -f "$TARGET_CLOC" ]]; then
    sudo rm -f "$TARGET_CLOC"
    echo "Removed $TARGET_CLOC"
  else
    echo "$TARGET_CLOC is not present"
  fi

  if pacman -Q cloc >/dev/null 2>&1; then
    sudo pacman -Rns cloc
    echo "Removed repository cloc package"
  else
    echo "Repository cloc package is not installed"
  fi

  if command -v cloc >/dev/null 2>&1; then
    echo "cloc is still available at $(command -v cloc)"
  else
    echo "Done: cloc fully removed from system PATH"
  fi
  exit 0
fi

if pacman -Q cloc >/dev/null 2>&1; then
  echo "Detected repository-installed cloc package."
  read -r -p "Remove repository cloc before installing this version? [y/N]: " remove_repo_cloc
  if [[ "$remove_repo_cloc" =~ ^[Yy]$ ]]; then
    sudo pacman -Rns cloc
  else
    echo "Continuing without removing repository cloc."
    echo "This version will be installed to $TARGET_CLOC and usually has PATH priority."
  fi
fi

if command -v cloc >/dev/null 2>&1; then
  current_cloc="$(command -v cloc)"
  if [[ "$current_cloc" != "$TARGET_CLOC" ]]; then
    echo "Warning: cloc currently resolves to $current_cloc"
    echo "After installation, ensure /usr/local/bin is earlier in PATH."
  fi
fi

sudo install -Dm755 "$SOURCE_CLOC" "$TARGET_CLOC"

echo "Done: installed $TARGET_CLOC"
echo "Version check:"
"$TARGET_CLOC" --version
