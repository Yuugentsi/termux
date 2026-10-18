#!/data/data/com.termux/files/usr/bin/bash

export DEBIAN_FRONTEND=noninteractive
mkdir -p "$PREFIX/etc/apt/apt.conf.d"
echo 'Dpkg::Options {"--force-confdef"; "--force-confold";};' > "$PREFIX/etc/apt/apt.conf.d/99force-conf"

touch "$HOME/.hushlogin"

[ -d "$HOME/storage" ] || termux-setup-storage

cyan='' white='' dim='' reset=''
if [ -t 1 ] && [ "${TERM:-}" != dumb ] && [ -z "${NO_COLOR+x}" ]; then
    cyan=$'\e[38;2;137;220;235m'
    white=$'\e[38;2;205;214;244m'
    dim=$'\e[38;2;88;91;112m'
    reset=$'\e[0m'
fi

printf '\n  %s◈ %stermux%s\n\n' "$cyan" "$white" "$reset"
printf '  %s%s  %s%s %s%s%s\n' \
    "$dim" 1 "$cyan" '✦' "$white" all "$reset" \
    "$dim" 2 "$cyan" '↻' "$white" mirror "$reset" \
    "$dim" 3 "$cyan" '◇' "$white" config "$reset" \
    "$dim" 4 "$cyan" '↓' "$white" apps "$reset" \
    "$dim" 5 "$cyan" '›' "$white" fish "$reset"
printf '\n  %s❯%s ' "$cyan" "$reset"
read -r choice
echo ""

case "$choice" in
    1)
        if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
            echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
        fi

        clone_pid=""
        if command -v git &>/dev/null; then
            rm -rf "$HOME/.termux-config"
            git clone --depth 1 https://github.com/Yuugentsi/termux "$HOME/.termux-config" &
            clone_pid=$!
        fi

        pkg update -y
        pkg upgrade -y

        pkgs=(git fish nano wget fzf tar unzip zip termux-tools termux-api ripgrep fd)
        pkg install -y "${pkgs[@]}" || {
            for p in "${pkgs[@]}"; do
                pkg install -y "$p" 2>/dev/null || echo "  - $p not found"
            done
        }

        chsh -s fish 2>/dev/null || true

        if [ -n "$clone_pid" ]; then
            wait "$clone_pid" || exit 1
        else
            rm -rf "$HOME/.termux-config"
            git clone --depth 1 https://github.com/Yuugentsi/termux "$HOME/.termux-config" || exit 1
        fi
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
        if ! grep -q "grimler.se" "$PREFIX/etc/apt/sources.list" 2>/dev/null; then
            echo "deb https://grimler.se/termux-packages-24 stable main" > "$PREFIX/etc/apt/sources.list"
        fi

        pkg update -y
        pkg upgrade -y

        pkgs=(fish nano wget fzf tar unzip zip termux-tools termux-api ripgrep fd)

        echo ""
        for i in "${!pkgs[@]}"; do
            printf '  %s%2d  %s%s%s\n' "$cyan" "$((i+1))" "$white" "${pkgs[$i]}" "$reset"
        done
        printf '\n  %s1 3 5 · select packages%s\n' "$dim" "$reset"
        printf '  %s❯%s ' "$cyan" "$reset"
        read -r sel
        echo ""

        selected=()
        for n in $sel; do
            i=$((n-1))
            [ "$i" -ge 0 ] && [ "$i" -lt "${#pkgs[@]}" ] || continue
            selected+=("${pkgs[$i]}")
        done
        if [ "${#selected[@]}" -gt 0 ]; then
            pkg install -y "${selected[@]}" || {
                for p in "${selected[@]}"; do
                    pkg install -y "$p" 2>/dev/null || echo "  - $p not found"
                done
            }
        fi
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
