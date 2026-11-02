function ins --description 'packages'
    if not set -q argv[1]
        printf 'Usage: ins <package> [package ...]\n'
        return 2
    end
    if not command -q pkg
        printf 'This command requires Termux.\n' >&2
        return 1
    end

    set -l cyan ''
    set -l green ''
    set -l red ''
    set -l reset ''
    set -l animated 0
    if isatty stdout; and test "$TERM" != dumb; and not set -q NO_COLOR
        set cyan (set_color 89dceb)
        set green (set_color a6e3a1)
        set red (set_color f38ba8)
        set reset (set_color normal)
        set animated 1
    end

    set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
    set -l tick 1
    set -l width 75
    if set -q COLUMNS; and string match -qr '^[0-9]+$' -- "$COLUMNS"
        set width (math "max(8, $COLUMNS - 5)")
    end
    set -l output
    set -l packages (string join ' ' -- $argv)

    command pkg install -y $argv 2>&1 | while read -l raw
        for line in (string split \r -- "$raw")
            set line (string replace -ar '\e\[[0-?]*[ -/]*[@-~]' '' -- "$line" | string trim)
            if test -z "$line"
                continue
            end
            set -a output "$line"
            if test $animated -eq 1
                set -l text (string shorten --max $width -- "$line")
                printf '\r  %s%s%s %s\e[K' "$cyan" "$frames[$tick]" "$reset" "$text"
                set tick (math "$tick % 10 + 1")
            end
        end
    end
    set -l result $pipestatus[1]

    if test $animated -eq 1
        printf '\r'
    end
    if test $result -eq 0
        printf '  %s✓%s Installed: %s' "$green" "$reset" "$packages"
    else
        printf '  %s✗%s Installation failed: %s' "$red" "$reset" "$packages"
    end
    if test $animated -eq 1
        printf '\e[K'
    end
    printf '\n'
    if test $result -ne 0; and set -q output[1]
        printf '%s\n' $output >&2
    end
    return $result
end
