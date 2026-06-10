#!/data/data/com.termux/files/usr/bin/bash

export DEBIAN_FRONTEND=noninteractive
mkdir -p "$PREFIX/etc/apt/apt.conf.d"
echo 'Dpkg::Options {"--force-confdef"; "--force-confold";};' > "$PREFIX/etc/apt/apt.conf.d/99force-conf"

touch "$HOME/.hushlogin"

if [ ! -d "$HOME/storage" ]; then
    echo "Run 'termux-setup-storage' first, then run this script again."
    exit 1
fi

echo ""
echo "  > 1. all (mirror, update, config)"
echo "  > 2. mirror (mirror, update)"
echo "  > 3. config ⚙ (clone, config)"
echo "  > 4. apps (install packages)"
echo "  > 5. shell (fish)"
echo ""
read -p "  -> " choice
echo ""

case "$choice" in
    1)
        if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
            echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
        fi

        pkg update -y
        pkg upgrade -y

        pkg install -y git

        rm -rf "$HOME/.termux-config"
        git clone --depth 1 https://github.com/Yuugentsi/termux "$HOME/.termux-config" || true
        mkdir -p "$HOME/.config"
        cp -r "$HOME/.termux-config/.config/." "$HOME/.config/"
        rm -rf "$HOME/.termux-config"

        echo "done"
        ;;
    2)
        if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
            echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
        fi

        pkg update -y
        pkg upgrade -y

        echo "done"
        ;;
    3)
        command -v git &>/dev/null || echo "git not found"

        rm -rf "$HOME/.termux-config"
        git clone --depth 1 https://github.com/Yuugentsi/termux "$HOME/.termux-config" || true
        mkdir -p "$HOME/.config"
        cp -r "$HOME/.termux-config/.config/." "$HOME/.config/"
        rm -rf "$HOME/.termux-config"

        echo "done"
        ;;
    4)
        pkg update -y
        pkg upgrade -y

        for p in fish nano wget fzf tar unzip zip yt-dlp gallery-dl termux-tools termux-api ripgrep fd aria2; do
            pkg install -y "$p" 2>/dev/null || echo "  - $p not found"
        done
        echo "done"
        ;;
    5)
        pkg install -y fish
        chsh -s fish
        echo "done"
        ;;
    *)
        echo "invalid"
        exit 1
        ;;
esac
