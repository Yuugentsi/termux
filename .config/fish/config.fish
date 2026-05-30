# ─────────── shell ───────────
set -g fish_greeting

# ─────────── functions ───────────
for f in ~/.config/fish/functions/*.fish
    source $f
end

# functions
function c; clear; end
function mkcd; mkdir -p $argv[1]; and cd $argv[1]; end
#function gh; git clone $argv[1]; and cd (basename (string replace -r '\.git$' '' $argv[1])); end
function rd; set -l p (pwd); cd ..; rm -rf $p; end
function empty; set -l n (find (pwd) -type d -empty 2>/dev/null | wc -l); find (pwd) -type d -empty -delete 2>/dev/null; echo "$n folders deleted"; end
function zipast; zip -r (basename $PWD).zip . > /dev/null; clear; du -h (basename $PWD).zip; end
function dt; clear; set -l now (date '+%s'); set -l midnight (date -d 'tomorrow 00:00:00' '+%s'); set -l left (math -s0 "$midnight - $now"); set -l h (math -s0 "$left / 3600"); set -l m (math -s0 "($left % 3600) / 60"); printf "󰔚 %s - 󰑔 %s - 󰕑 %sh%sm\n" (date '+%H:%M:%S') (date '+%m/%d/%Y') $h $m; end

# ─────────── prompt ───────────
function fish_prompt
    set -l last_status $status

    set -l status_color 20d0fc
    if test $last_status -ne 0
        set status_color ff6b8a
    end

    set -l parts (string split / (string replace -r "^$HOME/" "" "$PWD"))
    set -l pwd (string join / $parts[-2..-1])
    string match -q "$HOME" "$PWD"; and set pwd "~"

    echo -n -s \
        (set_color c8b8de --bold) $pwd " " \
        (set_color $status_color --bold) "❯ " \
        (set_color normal)
end

# ─────────── venv ───────────
function venv
    set -l green (set_color green)
    set -l red (set_color red)
    set -l reset (set_color normal)
    set -l env "$HOME/.venv"

    if test -n "$VIRTUAL_ENV"
        deactivate
        clear
        echo -s $red "󰄬 venv off" $reset
    else
        if not test -d "$env"
            python3 -m venv "$env"
        end
        source "$env/bin/activate.fish"
        clear
        echo -s $green "󰄬 venv on" $reset
    end
end

# ─────────── yt-mp3/mp4 ───────────
function __extra_cnf
    if not string match -qr '^https?://(www\.)?(youtube\.com|youtu\.be)/' -- $argv[1]; return 1; end
    if not command -v yt-dlp >/dev/null 2>&1; echo "yt-dlp not found"; return 1; end

    set -l G (set_color green); set -l R (set_color red); set -l N (set_color normal)

    echo "  [1] $G mp3$N  [2] $R mp4$N"
    read -P "→ " c

    set -l id (string match -rg '[?&]v=([^&]+)' -- $argv[1]; or string match -rg 'youtu\.be/([^?&]+)' -- $argv[1])

    if test "$c" = 1
        set -l d /storage/emulated/0/media/music/yt; mkdir -p $d
        yt-dlp --no-config --concurrent-fragments 16 --throttled-rate 100K --embed-thumbnail --add-metadata -x --audio-format mp3 --audio-quality 0 --no-playlist --no-video -o "$d/%(title)s.%(ext)s" $argv[1]
    else if test "$c" = 2
        set -l d /storage/emulated/0/media/videos/yt; mkdir -p $d
        yt-dlp --no-config --concurrent-fragments 16 --throttled-rate 100K --embed-thumbnail --add-metadata --sponsorblock-remove sponsor,selfpromo,interaction,preview,filler,intro,outro -f "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio/best[height<=720]/best" --merge-output-format mp4 --no-playlist -o "$d/%(title)s.%(ext)s" $argv[1]
    else; return 1; end

    clear; echo -s $G "$id 󰄬" $N
end

function fish_command_not_found
    if type -q __extra_cnf; __extra_cnf $argv; and return; end
    if type -q __fish_command_not_found_handler; __fish_command_not_found_handler $argv; else; __fish_default_command_not_found_handler $argv; end
end
# ─────────── fish ─────────── 
