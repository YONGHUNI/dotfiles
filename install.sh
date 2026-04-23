#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Dotfiles installer ==="
echo "Source: $DOTFILES_DIR"
echo ""

# Link or copy dotfiles
for f in .bashrc .vimrc .tmux.conf; do
    src="$DOTFILES_DIR/$f"
    dst="$HOME/$f"
    if [[ -f "$src" ]]; then
        if [[ -f "$dst" ]] && [[ ! -L "$dst" ]]; then
            echo "Backing up $dst -> ${dst}.bak"
            cp "$dst" "${dst}.bak"
        fi
        ln -sf "$src" "$dst"
        echo "Linked $f"
    fi
done

# Create vim undo directory
mkdir -p ~/.vim/undodir

# Install vim-plug and plugins
if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
echo "Installing vim plugins..."
vim +PlugInstall +qall 2>/dev/null

# Detect and report LSP availability
echo ""
echo "=== LSP Status ==="
for cmd in pyright clangd rust-analyzer julia R; do
    if command -v "$cmd" &>/dev/null; then
        echo "  [OK] $cmd"
    else
        echo "  [--] $cmd (not found)"
    fi
done

echo ""
echo "Done. Restart your shell or run: source ~/.bashrc"
