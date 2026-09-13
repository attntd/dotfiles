#!/usr/bin/env bash
# ThinkPad P16 Gen 3 / RTX PRO 3000 Blackwell Laptop (10de:2f38).
# Uruchamiaj z oficjalnego Arch ISO po przygotowaniu szyfrowanego root.
# Pakiety i usługi; konfiguracja rozruchu, LUKS i TPM to następny etap.
set -Eeuo pipefail

die() { printf 'Błąd: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Użycie:
  bash install-p16-hardware.sh --list
  bash install-p16-hardware.sh --install /mnt [opcje]

Bez argumentów: wyświetlenie listy pakietów, bez zmian w systemie.

Opcje:
  --wwan         Modem 4G/5G: ModemManager i usb_modeswitch.
  --smartcard    Czytnik kart chipowych: CCID i pcscd.socket.
  --fingerprint  fprintd; obsługę konkretnego sensora trzeba sprawdzić.
  --npu          Intel NPU: sterownik użytkownika i kompilator modeli.
  -h, --help     Pomoc.

Instalacja wymaga root, środowiska Arch ISO uruchomionego w UEFI,
P16 Gen 3 z GPU 10de:2f38 i świeżego systemu plików pod /mnt,
na urządzeniu z warstwą dm-crypt. LUKS2 przygotuj wcześniej.
EOF
}

check_hardware() {
    local vendor=$1 model=$2 pci=$3
    [[ ${vendor^^} == LENOVO && $model == 'ThinkPad P16 Gen 3' ]] ||
        die "Ten profil jest dla Lenovo ThinkPad P16 Gen 3. Wykryto: $vendor / $model."
    grep -Eq '[[:space:]]03[[:xdigit:]]{2}:[[:space:]]+10de:2f38([[:space:]]|$)' <<< "$pci" ||
        die 'Nie wykryto RTX PRO 3000 Blackwell Laptop (10de:2f38). Sprawdź lspci -nn i ustawienia GPU w UEFI.'
}

check_target() {
    local target=$1 source types
    case "$target" in
        /mnt|/mnt/*) ;;
        *) die 'Cel instalacji musi być zamontowany pod /mnt.' ;;
    esac
    mountpoint -q -- "$target" || die "$target nie jest punktem montowania."
    [[ $(stat -Lc '%d:%i' -- "$target") != "$(stat -Lc '%d:%i' /)" ]] ||
        die 'Cel wskazuje katalog główny działającego systemu.'
    [[ ! -e "$target/etc/os-release" ]] ||
        die 'W celu jest już system. Ten skrypt służy do pierwszego pacstrap; aktualizacje wykonuj przez pacman -Syu w systemie docelowym.'
    source=$(findmnt -nro SOURCE --mountpoint "$target") || die 'Nie można ustalić urządzenia docelowego.'
    # findmnt dopisuje [/@] itp. dla podwolumenów Btrfs.
    source=${source%%\[*}
    [[ -b $source ]] || die 'Root musi znajdować się na lokalnym urządzeniu blokowym.'
    types=$(lsblk -snro TYPE -- "$source") || die 'Nie można sprawdzić warstw urządzenia root.'
    grep -qx crypt <<< "$types" ||
        die 'Pod systemem plików root nie wykryto dm-crypt. Najpierw przygotuj i zamontuj root wewnątrz LUKS2.'
}

main() {
    local mode=list target='' option mode_set=0
    local with_wwan=0 with_smartcard=0 with_fingerprint=0 with_npu=0
    while (($#)); do
        option=$1
        case "$option" in
            --list)
                ((mode_set == 0)) || die 'Wybierz jeden tryb: --list albo --install.'
                mode=list; mode_set=1; shift ;;
            --install)
                ((mode_set == 0)) || die 'Wybierz jeden tryb: --list albo --install.'
                (($# >= 2)) && [[ $2 != --* ]] || die 'Podaj cel, np. --install /mnt.'
                mode=install; mode_set=1; target=$2; shift 2 ;;
            --wwan) with_wwan=1; shift ;;
            --smartcard) with_smartcard=1; shift ;;
            --fingerprint) with_fingerprint=1; shift ;;
            --npu) with_npu=1; shift ;;
            -h|--help) usage; return 0 ;;
            *) die "Nieznana opcja: $option" ;;
        esac
    done

    local -a packages=(
        # Baza i bieżące jądro. nvidia-open jest zbudowane dla pakietu linux.
        base linux mkinitcpio linux-firmware intel-ucode

        # Intel iGPU: OpenGL, Vulkan, sprzętowe dekodowanie wideo.
        mesa vulkan-intel intel-media-driver

        # Blackwell wymaga otwartych modułów jądra NVIDIA.
        nvidia-open nvidia-utils nvidia-prime

        # Intel SOF / SoundWire / Cirrus Logic; firmware Cirrus w linux-firmware.
        sof-firmware alsa-ucm-conf alsa-utils
        pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber

        # Intel Wi-Fi / Ethernet (moduły w jądrze) oraz Bluetooth.
        networkmanager wpa_supplicant wireless-regdb iw bluez bluez-utils

        # Touchpad, TrackPoint, jasność, zasilanie i aktualizacje firmware.
        libinput brightnessctl power-profiles-daemon python-gobject thermald
        fwupd bolt

        # Diagnostyka sprzętu.
        pciutils usbutils nvme-cli smartmontools lm_sensors
        libva-utils vulkan-tools v4l-utils

        # Narzędzia do dalszej konfiguracji LUKS2, TPM2+PIN i podpisanego UKI.
        cryptsetup tpm2-tss tpm2-tools sbctl efibootmgr systemd-ukify
        dosfstools e2fsprogs btrfs-progs lvm2
    )
    local -a services=(
        NetworkManager.service bluetooth.service
        power-profiles-daemon.service thermald.service
    )
    if ((with_wwan)); then
        packages+=(modemmanager usb_modeswitch)
        services+=(ModemManager.service)
    fi
    if ((with_smartcard)); then
        packages+=(pcsclite ccid)
        services+=(pcscd.socket)
    fi
    if ((with_fingerprint)); then packages+=(fprintd); fi
    if ((with_npu)); then packages+=(intel-npu-driver intel-npu-compiler); fi

    if [[ $mode == list ]]; then
        printf '%s\n' "${packages[@]}"
        return 0
    fi

    ((EUID == 0)) || die 'Uruchom instalację jako root w środowisku Arch ISO.'
    [[ -d /run/archiso ]] || die 'Uruchom ten etap z oficjalnego Arch ISO na nowym laptopie.'
    [[ -d /sys/firmware/efi ]] || die 'Uruchom Arch ISO w trybie UEFI.'
    local cmd
    for cmd in pacstrap systemctl realpath mountpoint findmnt lsblk lspci stat grep; do
        command -v "$cmd" >/dev/null || die "Brak wymaganego polecenia: $cmd."
    done
    target=$(realpath -e -- "$target") || die 'Cel nie istnieje.'
    local vendor model pci
    vendor=$(cat /sys/class/dmi/id/sys_vendor) || die 'Nie można odczytać producenta laptopa.'
    model=$(cat /sys/class/dmi/id/product_version) || die 'Nie można odczytać modelu laptopa.'
    pci=$(LC_ALL=C lspci -Dn) || die 'Nie można odczytać urządzeń PCI.'
    check_hardware "$vendor" "$model" "$pci"
    check_target "$target"

    printf 'Sprzęt: %s / %s / RTX PRO 3000 Blackwell Laptop\n' "$vendor" "$model"
    printf 'Cel instalacji: %s\n' "$target"
    printf 'Pakiety (%s):\n' "${#packages[@]}"
    printf '  %s\n' "${packages[@]}"

    # Podpisy pakietów są sprawdzane zgodnie z konfiguracją oficjalnego ISO.
    # Wszystkie nazwy pochodzą z oficjalnych repozytoriów; bez AUR.
    pacstrap -K "$target" "${packages[@]}"

    # Tylko dowiązania w systemie docelowym. Usługi ruszą po jego uruchomieniu.
    systemctl --root="$target" enable "${services[@]}"
    # PipeWire/WirePlumber działają jako usługi użytkownika.
    # fwupd, bolt i fprintd korzystają z aktywacji przez D-Bus.
    # Obsługę uśpienia NVIDIA pozostawiamy bieżącym domyślnym ustawieniom pakietu.

    install -d -m 0755 "$target/var/lib/p16-install"
    printf '%s\n' "${packages[@]}" > "$target/var/lib/p16-install/requested-packages.txt"
    printf '\nPakiety i usługi są przygotowane.\n'
    printf '%s\n' 'Przed restartem dokończ instalację: fstab, użytkownik, initramfs z sd-encrypt, UKI i rozruch.'
    printf '%s\n' 'Secure Boot, TPM2+PIN i szyfrowany swap wymagają osobnej konfiguracji i sprawdzenia.'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
