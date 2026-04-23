#!/usr/bin/env bash
cd ~/dotfiles
git init
git branch -m main
git add -A
git commit -m "initial dotfiles"
gh repo create dotfiles --public --source=. --remote=origin --push
