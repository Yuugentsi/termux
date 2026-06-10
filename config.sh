#!/data/data/com.termux/files/usr/bin/bash

export DEBIAN_FRONTEND=noninteractive
mkdir -p "$PREFIX/etc/apt/apt.conf.d"
echo 'Dpkg::Options {"--force-confdef"; "--force-confold";};' > "$PREFIX/etc/apt/apt.conf.d/99force-conf"

if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
    echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
fi

touch "$HOME/.hushlogin"

pkg update -y
pkg upgrade -y

pkg install -y git

rm -rf "$HOME/.termux-config"
git clone --depth 1 https://github.com/Yuugentsi/termux "$HOME/.termux-config" || true
mkdir -p "$HOME/.config"
cp -r "$HOME/.termux-config/.config/." "$HOME/.config/"
rm -rf "$HOME/.termux-config"
