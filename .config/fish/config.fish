# ───── shell ─────
set -g fish_greeting

# ───── functions ─────
for f in ~/.config/fish/functions/*.fish
    source $f
end

# --- clear ---
abbr -a c clear

# --- mkcd ---
function mkcd; mkdir -p $argv[1]; and cd $argv[1]; end

# --- rd ---
#function gh; git clone $argv[1]; and cd (basename (string replace -r '\.git$' '' $argv[1])); end
function rd; clear; set -l p (pwd); cd ..; read -l -P "󰅙 rm -rf $p ? [y/N] " confirm; test "$confirm" = y; and rm -rf $p; and clear; and echo "󰄬 deleted $p"; end

# --- empty ---
function empty; set -l n (find (pwd) -type d -empty 2>/dev/null | wc -l); find (pwd) -type d -empty -delete 2>/dev/null; echo "$n folders deleted"; end

# --- zipast ---
function zipast; zip -r (basename $PWD).zip . > /dev/null; clear; du -h (basename $PWD).zip; end

# --- dt ---
function dt; clear; set -l now (date '+%s'); set -l midnight (date -d 'tomorrow 00:00:00' '+%s'); set -l left (math -s0 "$midnight - $now"); set -l h (math -s0 "$left / 3600"); set -l m (math -s0 "($left % 3600) / 60"); printf "󰔚 %s - 󰑔 %s - 󰕑 %sh%sm\n" (date '+%H:%M:%S') (date '+%m/%d/%Y') $h $m; end

# --- min ---
function min; set -l n (date +%s); set -l h (date +%H); set -l nx (math "$h + 1"); set -l nxh (date -d "$nx:00:00" +%s); set -l l (math "$nxh - $n"); set -l m (math -s0 "$l / 60"); set -l s (math -s0 "$l % 60"); clear; echo "󰔚 $m min $s sec"; end

# --- volume ---
function volume; clear; set -q argv[1]; and set p $argv[1]; or set p 100; wpctl set-volume @DEFAULT_AUDIO_SINK@ (math "min(max($p, 30), 110) / 100"); end

# --- bak ---
function bak -d "backup dir to bak/"; set -l d (pwd); if set -q argv[1]; set d (realpath "$argv[1]"); end; mkdir -p "$d/bak"; for f in "$d"/*; test "$f" != "$d/bak"; and cp -r "$f" "$d/bak/"; end; clear; and echo "󰄬 $d/bak"; end

# --- config ---
function config
    set -l G (set_color green); set -l R (set_color red); set -l N (set_color normal)
    
    echo ""
    echo "  [$G 1 $N] aria2"
    echo "  [$G 2 $N] fish"
    echo "  [$G 3 $N] nano"
    echo "  [$G 4 $N] yt-dlp"
    echo ""
    read -P "  → " c
    echo ""
    
    switch $c
        case 1
            nano ~/.config/aria2/aria2.conf
        case 2
            nano ~/.config/fish/config.fish
        case 3
            nano ~/.config/nano/nanorc
        case 4
            nano ~/.config/yt-dlp/config
        case '*'
            echo -e "  [$R!$N] invalid"
            return 1
    end
end

# ───── archives ─────
# --- extract ---
function extract -d "extract archives"
    set -l found 0
    for file in *.zip *.tar *.tar.gz *.tar.xz *.tar.bz2 *.tgz
        test -f "$file"; or continue
        set found 1
        set -l folder (string replace -r '\.(zip|tar\.gz|tar\.xz|tar\.bz2|tgz|tar)$' '' "$file")
        mkdir -p "$folder"
        switch "$file"
            case '*.zip'
                unzip -oq "$file" -d "$folder"
            case '*'
                tar -xf "$file" -C "$folder"
        end
        if test $status -eq 0
            rm -f "$file"
        else
            echo "󰅙 $file"
            return 1
        end
    end
    clear
    if test $found -eq 1
        echo "󰄬 extracted"
    else
        echo "empty"
    end
end

# --- zips ---
function zips -d "zip directory"
    set -l name (basename "$PWD")
    set -l file "$name.zip"
    zip -r "$file" . -x "$file" > /dev/null 2>&1
    if test $status -eq 0
        clear
        echo "󰄬 $file"
    else
        clear
        echo "󰅙"
        return 1
    end
end

# --- cbz ---
function cbz -d "create cbz"
    set -l name (basename "$PWD")
    set -l file "$name.cbz"
    zip -r "$file" . -x "$file" > /dev/null 2>&1
    if test $status -eq 0
        clear
        echo "󰄬 $file"
    else
        clear
        echo "󰅙"
        return 1
    end
end

# ───── prompt ─────
set -g fish_transient_prompt 1
 
function fish_prompt
    if set -q argv[1]
        echo -n "❯ "
        return
    end
 
    set -l last_status $status
 
    set -l status_color f5c2e7
    if test $last_status -ne 0
        set status_color ff6b8a
    end
 
    set -l pwd (string replace -r "^$HOME/" "" "$PWD")
    string match -q "$HOME" "$PWD"; and set pwd "~"
 
    set -l DIM (set_color 7c5cbf)
    set -l DIR (set_color c8b8de --bold)
    set -l N (set_color normal)
 
    echo -s "$DIM╭─$N $DIR$pwd$N"
    echo -n -s "$DIM╰─$N " (set_color $status_color --bold) "❯ " (set_color normal)
end

# ───── venv ─────
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

# ───── youtube ─────
function __extra_cnf
    if not string match -qr '^https?://(www\.)?(youtube\.com|youtu\.be)/' -- $argv[1]; return 1; end
    if not command -v yt-dlp >/dev/null 2>&1; echo "yt-dlp not found"; return 1; end

    set -l G (set_color green); set -l R (set_color red); set -l N (set_color normal)

    echo "  [$G 1 $N] mp3"
    echo "  [$R 2 $N] mp4"
    read -P "  → " c

    set -l id (string match -rg '[?&]v=([^&]+)' -- $argv[1]; or string match -rg 'youtu\.be/([^?&]+)' -- $argv[1])

    if test "$c" = 1
        set -l d /storage/emulated/0/media/music/yt; mkdir -p $d
        yt-dlp --no-config --concurrent-fragments 16 --throttled-rate 100K --embed-thumbnail --add-metadata -x --audio-format mp3 --audio-quality 0 --no-playlist --no-video -o "$d/%(title)s.%(ext)s" "$argv[1]"
    else if test "$c" = 2
        set -l d /storage/emulated/0/media/videos/yt; mkdir -p $d
        yt-dlp --no-config --concurrent-fragments 16 --throttled-rate 100K --embed-thumbnail --add-metadata --sponsorblock-remove sponsor,selfpromo,interaction,preview,filler,intro,outro -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" --no-playlist -o "$d/%(title)s.%(ext)s" "$argv[1]"
    else; return 1; end

    clear; echo -s $G "$id 󰄬" $N
end

# --- command not found ---
function fish_command_not_found
    if type -q __extra_cnf; __extra_cnf $argv; and return; end
    if type -q __fish_command_not_found_handler; __fish_command_not_found_handler $argv; else; __fish_default_command_not_found_handler $argv; end
end
