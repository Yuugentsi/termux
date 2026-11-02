#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PACKAGES=(git fish nano wget fzf tar unzip zip termux-tools termux-api ripgrep fd)

BOLD=""
ACCENT=""
GREEN=""
DIM=""
RED=""
RESET=""
FAILED_STEPS=()
ANIMATED=false

if [[ -t 1 && -z "${NO_COLOR+x}" && "${TERM:-dumb}" != "dumb" ]]; then
    BOLD=$'\e[1m'
    ACCENT=$'\e[38;2;137;220;235m'
    GREEN=$'\e[38;2;166;227;161m'
    DIM=$'\e[38;2;88;91;112m'
    RED=$'\e[38;2;243;139;168m'
    RESET=$'\e[0m'
    ANIMATED=true
    trap 'printf "\033[?25h"' EXIT
fi

step() {
    printf '  %s◇%s %s\n' "$ACCENT" "$RESET" "$1"
}

render_status() {
    local detail="$1" frame="$2" width="$3"
    local phase package current total percent bar_width filled empty bar trail title_width
    if [[ "$detail" =~ ^(Downloading|Installing)[[:space:]]+([^[:space:]]+)[[:space:]]+·[[:space:]]+([0-9]+)/([0-9]+)([[:space:]]+·[[:space:]]+([0-9]+)%)?$ ]]; then
        phase="${BASH_REMATCH[1]}"
        package="${BASH_REMATCH[2]}"
        current="${BASH_REMATCH[3]}"
        total="${BASH_REMATCH[4]}"
        percent="${BASH_REMATCH[6]:-100}"
        bar_width=12
        title_width=$((width - 49))
        if ((title_width < 8)); then
            printf '  %s%s%s %.*s %s%s%%%s' "$ACCENT" "$frame" "$RESET" "$((width - 12))" "$package" "$DIM" "$percent" "$RESET"
            return
        fi
        ((title_width > 30)) && title_width=30
        filled=$((percent * bar_width / 100))
        empty=$((bar_width - filled))
        printf -v bar '%*s' "$filled" ''
        printf -v trail '%*s' "$empty" ''
        bar="${bar// /━}"
        trail="${trail// /─}"
        printf '  %s%s%s %s%-*.*s%s  %s%s%s%s%s  %3s%%  %s%2s/%-2s  %s%s' \
            "$ACCENT" "$frame" "$RESET" "$BOLD" "$title_width" "$title_width" "$package" "$RESET" \
            "$ACCENT" "$bar" "$DIM" "$trail" "$RESET" "$percent" "$DIM" "$current" "$total" "$phase" "$RESET"
    else
        printf '  %s%s%s %.*s' "$ACCENT" "$frame" "$RESET" "$((width - 5))" "$detail"
    fi
}

run() {
    local label="$1" log_file pid frame=0 result=0 detail width rendered
    width=${COLUMNS:-80}
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    ((width > 8)) || width=80
    local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    shift
    log_file=$(mktemp)
    (
        set -euo pipefail
        "$@"
    ) >"$log_file" 2>&1 &
    pid=$!
    if "$ANIMATED"; then
        printf '\033[?25l'
        while kill -0 "$pid" 2>/dev/null; do
            detail=$(tail -c 2048 "$log_file" | tr '\r' '\n' | sed -E '/^[[:space:]]*$/d; /[Nn]o changes? (required|needed|made)/d; /[Tt]here is nothing to do/d' | tail -n 1 | LC_ALL=C tr -d '\000-\010\013-\037\177')
            detail="${detail:-$label}"
            rendered=$(render_status "$detail" "${frames[frame % 10]}" "$width")
            printf '\r%s\033[K' "$rendered"
            frame=$((frame + 1))
            sleep 0.08
        done
    fi
    wait "$pid" || result=$?
    if "$ANIMATED"; then
        printf '\r\033[?25h'
    fi
    if ((result == 0)); then
        printf '  %s✓%s %s' "$GREEN" "$RESET" "$label"
        if "$ANIMATED"; then printf '\033[K'; fi
        printf '\n'
    else
        printf '  %s✗%s %s' "$RED" "$RESET" "$label" >&2
        if "$ANIMATED"; then printf '\033[K'; fi
        printf '\n' >&2
        FAILED_STEPS+=("$label")
        cat "$log_file" >&2
    fi
    rm -f "$log_file"
    return 0
}

finish() {
    if ((${#FAILED_STEPS[@]})); then
        printf '\n  %sSetup finished with %s failed step(s):%s\n' "$RED" "${#FAILED_STEPS[@]}" "$RESET" >&2
        printf '  ✗ %s\n' "${FAILED_STEPS[@]}" >&2
        return 1
    fi
    printf '\n  %s✓%s Setup complete.\n\n' "$GREEN" "$RESET"
}

header() {
    printf '\n  %s%s◈  termux%s  %s/  %s%s\n\n' "$BOLD" "$ACCENT" "$RESET" "$DIM" "$1" "$RESET"
}

select_mirror() {
    local probe_dir arch mirror i pid result best speed bytes
    local -a pids=() mirrors=(
        https://packages.termux.dev/apt/termux-main
        https://packages-cf.termux.dev/apt/termux-main
        https://grimler.se/termux/termux-main
        https://mirror.ufscar.br/termux/termux-main
    )

    command -v curl &>/dev/null || return 0
    arch=$(dpkg --print-architecture) || return 1
    probe_dir=$(mktemp -d) || return 1
    printf 'Testing download mirrors…\n'

    for i in "${!mirrors[@]}"; do
        mirror=${mirrors[$i]}
        (
            result=$(LC_ALL=C curl --fail --silent --location \
                --connect-timeout 3 --max-time 8 --range 0-262143 \
                --output /dev/null --write-out '%{speed_download} %{size_download}' \
                "$mirror/dists/stable/main/binary-$arch/Packages.xz") || exit 0
            read -r speed bytes <<< "$result"
            LC_ALL=C awk -v speed="$speed" -v bytes="$bytes" -v mirror="$mirror" \
                'BEGIN { if (speed > 0 && bytes >= 262144) print speed, mirror }' > "$probe_dir/$i"
        ) &
        pids+=("$!")
    done

    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    best=$(LC_ALL=C sort -k1,1nr "$probe_dir"/* 2>/dev/null | head -n 1) || best=""
    rm -rf "$probe_dir"
    if [ -z "$best" ]; then
        printf '  %s↻ Keeping current mirror%s\n' "$DIM" "$RESET"
        return 0
    fi

    read -r speed mirror <<< "$best"
    if [ -f "$PREFIX/etc/apt/sources.list.d/main.sources" ]; then
        sed -i "s|^[[:space:]]*URIs:.*|URIs: $mirror|" "$PREFIX/etc/apt/sources.list.d/main.sources" || return 1
    else
        printf 'deb %s stable main\n' "$mirror" > "$PREFIX/etc/apt/sources.list" || return 1
    fi
    export TERMUX_PKG_NO_MIRROR_SELECT=true
    printf '  %s✓%s %s%s\n' "$ACCENT" "$RESET" "$mirror" "$RESET"
}

prepare_termux() {
    mkdir -p "$PREFIX/etc/apt/apt.conf.d"
    printf '%s\n' 'Dpkg::Options {"--force-confdef"; "--force-confold";};' > "$PREFIX/etc/apt/apt.conf.d/99force-conf"
    touch "$HOME/.hushlogin"
}

apply_config() {
    local source_dir script_dir download_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    if [[ -d "$script_dir/.config" ]]; then
        source_dir="$script_dir"
    else
        download_dir=$(mktemp -d)
        git clone --depth 1 https://github.com/Yuugentsi/termux "$download_dir/repo"
        source_dir="$download_dir/repo"
    fi
    mkdir -p "$HOME/.config"
    cp -r "$source_dir/.config/." "$HOME/.config/"
    if [[ -n "${download_dir:-}" ]]; then
        rm -rf -- "$download_dir"
    fi
}

install_apps() {
    local package
    for package in "$@"; do
        run "Installing $package" pkg install -y "$package"
    done
}

simulate_apps() {
    local package percent index=0 total=${#PACKAGES[@]}
    for package in "${PACKAGES[@]}"; do
        index=$((index + 1))
        for percent in 15 45 75 100; do
            printf 'Downloading %s · %s/%s · %s%%\n' "$package" "$index" "$total" "$percent"
            sleep 0.08
        done
        printf 'Installing %s · %s/%s · 100%%\n' "$package" "$index" "$total"
        sleep 0.12
    done
}

preview() {
    header "preview · simulation"
    run "Fastest mirror selected" sleep 0.5
    run "Package index updated" sleep 0.5
    run "Apps installed" simulate_apps
    run "Fish configured" sleep 0.5
    run "Configuration applied" sleep 0.5
    printf '\n  %s✓%s Preview complete.\n\n' "$GREEN" "$RESET"
}

case "${1:-}" in
    --preview) preview; exit 0 ;;
    --help|-h)
        printf 'Usage: bash %s [--preview | --help]\n' "$0"
        exit 0
        ;;
    "") ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
esac

if [[ -z "${PREFIX:-}" ]] || ! command -v pkg >/dev/null 2>&1; then
    printf 'Run this installer inside Termux, or use --preview.\n' >&2
    exit 1
fi

header "setup"
printf '  %s01%s  Full setup\n' "$ACCENT" "$RESET"
printf '  %s02%s  Mirror and updates\n' "$ACCENT" "$RESET"
printf '  %s03%s  Apply configuration\n' "$ACCENT" "$RESET"
printf '  %s04%s  Choose apps\n' "$ACCENT" "$RESET"
printf '  %s05%s  Set up Fish\n\n' "$ACCENT" "$RESET"
printf '  %s›%s ' "$ACCENT" "$RESET"
read -r choice
printf '\n'

case "$choice" in
    1|2|3|4|5) ;;
    *) printf 'Invalid option. Choose 1–5.\n' >&2; exit 1 ;;
esac

selected=()
if [[ "$choice" == 4 ]]; then
    for i in "${!PACKAGES[@]}"; do
        printf '  %s%2d%s  %s\n' "$ACCENT" "$((i + 1))" "$RESET" "${PACKAGES[$i]}"
    done
    printf '\n  %sSelect numbers (e.g. 1 3 5), or all:%s ' "$DIM" "$RESET"
    read -r selection
    if [[ "$selection" == all ]]; then
        selected=("${PACKAGES[@]}")
    else
        read -r -a indices <<< "$selection"
        for number in "${indices[@]}"; do
            if [[ ! "$number" =~ ^[0-9]{1,2}$ ]]; then
                printf 'Invalid package number: %s\n' "$number" >&2
                exit 1
            fi
            index=$((10#$number - 1))
            if ((index < 0 || index >= ${#PACKAGES[@]})); then
                printf 'Invalid package number: %s\n' "$number" >&2
                exit 1
            fi
            selected+=("${PACKAGES[$index]}")
        done
    fi
    if ((${#selected[@]} == 0)); then
        printf 'No apps selected.\n'
        exit 0
    fi
    printf '\n'
fi

export DEBIAN_FRONTEND=noninteractive TERMUX_PKG_NO_MIRROR_SELECT=true
run "Preparing Termux" prepare_termux

case "$choice" in
    1)
        if [[ ! -d "$HOME/storage" ]]; then
            step "Grant storage access in the Android prompt"
            run "Storage access requested" termux-setup-storage
        fi
        run "Selecting fastest mirror" select_mirror
        run "Updating package index" pkg update -y
        run "Upgrading packages" pkg upgrade -y
        install_apps "${PACKAGES[@]}"
        run "Setting Fish as default shell" chsh -s fish
        run "Applying configuration" apply_config
        ;;
    2)
        run "Selecting fastest mirror" select_mirror
        run "Updating package index" pkg update -y
        run "Upgrading packages" pkg upgrade -y
        ;;
    3)
        if ! command -v git >/dev/null 2>&1; then
            run "Installing Git" pkg install -y git
        fi
        run "Applying configuration" apply_config
        ;;
    4)
        run "Selecting fastest mirror" select_mirror
        run "Updating package index" pkg update -y
        run "Upgrading packages" pkg upgrade -y
        install_apps "${selected[@]}"
        ;;
    5)
        run "Installing Fish" pkg install -y fish
        run "Setting Fish as default shell" chsh -s fish
        ;;
esac

finish
