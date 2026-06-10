#!/data/data/com.termux/files/usr/bin/bash

if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
    echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
fi

pkg update -y
pkg upgrade -y
