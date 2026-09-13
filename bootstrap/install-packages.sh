#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Użycie: bash bootstrap/install-packages.sh [--dry-run] [--with-aur]

Instaluje zależności dotfiles i budowania Quickshell DE na Arch Linux.
Pakiety systemowe: pacman -Syu --needed (również pełna aktualizacja systemu).
--dry-run   Tylko pokaż polecenia, bez instalowania i aktualizowania pakietów.
--with-aur  Dodaj pakiety AUR; wymaga zainstalowanego paru lub yay.
--help      Pokaż tę pomoc.

Skrypt uruchamiaj jako zwykły użytkownik; pacman skorzysta z sudo.
USAGE
}

die() {
    printf 'Błąd: %s\n' "$*" >&2
    exit 1
}

dry_run=false
with_aur=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --with-aur) with_aur=true ;;
        --help|-h) usage; exit 0 ;;
        *) die "Nieznany argument: $argument" ;;
    esac
done

[[ -r /etc/os-release ]] || die 'Nie znaleziono /etc/os-release.'
# shellcheck source=/dev/null
source /etc/os-release
[[ ${ID:-} == arch ]] || die 'Ten wariant instalatora obsługuje Arch Linux.'
command -v pacman >/dev/null || die 'Nie znaleziono pacmana.'
[[ $EUID -ne 0 ]] || die 'Uruchom skrypt jako zwykły użytkownik, bez sudo.'

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

read_packages() {
    local filename=$1
    local -n result=$2
    local line name extra
    local -A seen=()
    [[ -r $filename ]] || die "Nie można odczytać listy: $filename"
    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%%#*}
        read -r name extra <<< "$line"
        [[ -n $name ]] || continue
        [[ -z $extra && $name =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] ||
            die "Nieprawidłowy wpis na liście $filename: $line"
        if [[ ! -v seen[$name] ]]; then
            result+=("$name")
            seen[$name]=1
        fi
    done < "$filename"
    ((${#result[@]} > 0)) || die "Pusta lista: $filename"
}

packages=()
aur_packages=()
read_packages "$script_directory/packages/arch.txt" packages
read_packages "$script_directory/packages/arch-aur.txt" aur_packages

aur_helper=''
if "$with_aur"; then
    for candidate in paru yay; do
        if command -v "$candidate" >/dev/null; then
            aur_helper=$candidate
            break
        fi
    done
    if [[ -z $aur_helper ]]; then
        if "$dry_run"; then
            aur_helper=paru
            printf 'Podgląd zakłada paru. Przed instalacją AUR zainstaluj paru lub yay.\n'
        else
            die 'Opcja --with-aur wymaga paru lub yay. Nie rozpoczęto instalacji.'
        fi
    fi
fi
if ! "$dry_run"; then
    command -v sudo >/dev/null || die 'Do instalacji pakietów potrzebne jest sudo.'
fi

run() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    if ! "$dry_run"; then
        "$@"
    fi
}

printf 'Arch: %s pakietów. Pacman sprawdzi również aktualizacje całego systemu.\n' "${#packages[@]}"
run sudo pacman -Syu --needed "${packages[@]}"
if "$with_aur"; then
    run "$aur_helper" -S --needed "${aur_packages[@]}"
else
    printf 'Pakiety AUR dostępne z opcją --with-aur: %s\n' "${aur_packages[*]}"
fi

printf '\nBudowanie Quickshella, konfigurację usług i dalsze kroki opisuje README.md w repo.\n'
