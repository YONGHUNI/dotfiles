#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Dotfiles installer ==="
echo "Source: $DOTFILES_DIR"
echo ""

# Link managed dotfiles.
for f in .bash_profile .bashrc .vimrc .tmux.conf; do
    src="$DOTFILES_DIR/$f"
    dst="$HOME/$f"

    if [[ -f "$src" ]]; then
        if [[ -f "$dst" && ! -L "$dst" ]]; then
            echo "Backing up $dst -> ${dst}.bak"
            cp "$dst" "${dst}.bak"
        fi

        ln -sf "$src" "$dst"
        echo "Linked $f"
    fi
done

# Create Vim's persistent undo directory.
mkdir -p "$HOME/.vim/undodir"

# Install vim-plug and plugins for hosts that are not managing Vim through Nix.
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    echo "Installing vim-plug..."
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "Installing Vim plugins..."
vim +PlugInstall +qall 2>/dev/null

# Detect and report language-tool availability without installing runtimes.
echo ""
echo "=== Language tool status ==="
for cmd in pyright clangd julia R; do
    if command -v "$cmd" &>/dev/null; then
        echo "  [OK] $cmd"
    else
        echo "  [--] $cmd (not found)"
    fi
done

echo ""
echo "Done. Restart your shell or run: source ~/.bashrc"
