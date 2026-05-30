#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
    echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
fi

pkg update -y
pkg upgrade -y

pkg install -y git

pkg install -y \
    fish \
    nano \
    wget \
    fzf \
    tar \
    unzip \
    zip \
    yt-dlp \
    gallery-dl \    
    termux-tools \
    termux-api \
    ripgrep \
    fd \
    aria2

command -v fish >/dev/null && chsh -s fish 2>/dev/null || true

if ! grep -q "exec fish" "$HOME/.bashrc" 2>/dev/null; then
    echo "exec fish" >> "$HOME/.bashrc"
fi

if [ -f "$PREFIX/etc/motd" ]; then
    rm -f "$PREFIX/etc/motd"
fi

git clone https://github.com/yuugentsi/termux
mkdir -p "$HOME/.config"
cp -r termux/.config/. "$HOME/.config/"
rm -rf termux

echo "done"
