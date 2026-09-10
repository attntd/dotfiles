#!/usr/bin/env bash

set -u

monitor="${1:-eDP-1}"
config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}"
wallpaper_dir="${config_dir}/hypr/backgrounds"

mapfile -d '' wallpapers < <(
    find "${wallpaper_dir}" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jxl' \) \
        -print0
)

if (( ${#wallpapers[@]} == 0 )); then
    exit 1
fi

current="$({ hyprctl hyprpaper listactive 2>/dev/null || true; } | awk -v output="${monitor}" '
    index($0, output ": ") == 1 {
        print substr($0, length(output) + 3)
        exit
    }
')"

candidates=()
for wallpaper in "${wallpapers[@]}"; do
    if [[ "${wallpaper}" != "${current}" || ${#wallpapers[@]} -eq 1 ]]; then
        candidates+=("${wallpaper}")
    fi
done

selected="${candidates[RANDOM % ${#candidates[@]}]}"
exec hyprctl hyprpaper wallpaper "${monitor},${selected},cover"
