# Dotfiles

Konfiguracje użytkownika zarządzane przez chezmoi: Fish, Starship, SSH,
Kitty, Neovim, Hyprland i sesja Putkin.

Aktualny shell to Putkin ze źródeł `~/projects/putkin`, uruchamiany przez
oficjalny pakiet `quickshell`. Autostart i skróty wskazują lokalne wydanie
`~/.local/share/putkin/releases/20260917-settings-keyboard-cc7addc79750/`.
Konfiguracja Hyprlanda wymaga tego wydania; samo `chezmoi apply` nie
instaluje kodu Putkina. Szczegóły lokalnej instalacji są w
`~/projects/putkin/docs/install.md`. Przywrócenie sesji po usunięciu end-4
19 września 2026 zapisano również w `docs/status.md` tego projektu.

Pomocniki wcześniejszego Quickshell DE w `~/.config/quickshell/scripts`
są nadal używane przez Hypridle i SSH_ASKPASS. Ten katalog pochodzi
z osobnej instalacji i nie jest zarządzany przez chezmoi.

## Zależności na Arch Linux

W `bootstrap/packages/arch.txt` jest lista pakietów systemowych,
a w `bootstrap/packages/arch-aur.txt` programy z AUR. Listy można edytować;
jeden pakiet zajmuje jedną linię, a komentarze zaczynają się od `#`.

Lista obejmuje konfiguracje zapisane w repo oraz zależności budowania
Quickshella i greetera. Uwzględnia między innymi czcionki Kitty/Quickshella,
narzędzia Neovima i Yazi, schowek, zrzuty oraz skróty do Zen i Voxtype.
Hyprpaper nie jest używany. Zachowany `random-wallpaper.sh` jest starszym
pomocnikiem wymagającym hyprpaper; nie stanowi części odtwarzanej sesji.

Z katalogu źródłowego chezmoi:

```sh
chezmoi cd
bash bootstrap/install-packages.sh --dry-run
bash bootstrap/install-packages.sh
```

Pierwsze polecenie skryptu pokazuje plan. Drugie uruchamia
`sudo pacman -Syu --needed`, czyli synchronizację baz, pełną aktualizację
systemu i instalację pakietów z listy. Pacman zachowuje swoje standardowe
pytania o zatwierdzenie transakcji. Pakiety już zainstalowane w odpowiedniej
wersji są pomijane. Ponowne uruchomienie pozwala dodać nowe zależności.

Aby uwzględnić AUR, po zainstalowaniu `paru` albo `yay`:

```sh
bash bootstrap/install-packages.sh --dry-run --with-aur
bash bootstrap/install-packages.sh --with-aur
```

Helper AUR jest uruchamiany jako zwykły użytkownik. Skrypt nie instaluje
helpera. Na świeżym systemie można najpierw zainstalować pakiety systemowe,
następnie helper według jego instrukcji i ponowić skrypt z `--with-aur`.
Brak helpera przy rzeczywistej instalacji z `--with-aur` kończy działanie
jeszcze przed uruchomieniem pacmana.

Skrypt jest uruchamiany ręcznie. `.chezmoiignore` pozostawia `bootstrap/`
i ten README wyłącznie w repo źródłowym; `chezmoi apply` nie uruchamia
instalacji ani nie kopiuje tych plików do katalogu domowego.

## Odtwarzanie nowego komputera

1. Zainstaluj Git i chezmoi oraz skonfiguruj dostęp do repo.
2. Pobierz dotfiles przez `chezmoi init ADRES_REPO`.
3. Uruchom instalator zależności opisany powyżej.
4. Przygotuj instalację Putkina zgodnie z jego `docs/install.md` i dopasuj
   ścieżki wydania w konfiguracji Hyprlanda do nowego komputera. Przywróć
   również wskazane wyżej pomocniki Hypridle i SSH_ASKPASS. Putkin ma
   obecnie procedurę lokalnego przełączenia; przenośny instalator pozostaje
   niewdrożony. Ekran logowania wymaga osobnego przygotowania.
5. Dopasuj `hypr/monitors.lua` do wyjść i rozdzielczości nowego komputera.
   Autostart uruchamia Putkin przez `uwsm app` i `quickshell --path`
   ze wskazaniem opublikowanego wydania. Samą sesję
   można rozpocząć z TTY poleceniem
   `uwsm start -e -D Hyprland hyprland.desktop`. Ekran logowania po restarcie
   wymaga osobnego zainstalowania i aktywowania greetera zgodnie z jego
   instrukcją; instalator pakietów i chezmoi nie wykonują tej aktywacji.
6. Obejrzyj `chezmoi diff`, a następnie wykonaj `chezmoi apply`.

Lista pakietów nie włącza usług systemowych. Sprawdź NetworkManager,
Bluetooth, PipeWire, WirePlumber i usługi zasilania zgodnie z instrukcją
Quickshell DE i konfiguracją nowego systemu. Sterowniki GPU dobierz do
sprzętu; nie są kopiowane z listy pakietów obecnego komputera.

## Dodatkowa konfiguracja aplikacji

- Neovim pobiera wtyczki przez lazy.nvim, a parsery przez Treesitter.
  Wersje wtyczek zapisano w `lazy-lock.json`; instalacja wymaga internetu.
  Skrypt dostarcza Node.js/npm, Ruby, kompilator, Treesitter CLI oraz serwery
  LSP dla Lua, Ruby i Tailwind CSS.
- Wtyczka Swagger Preview uruchamia `npm install -g swagger-ui-watcher`.
  Przed pierwszym uruchomieniem Neovima ustaw zapisywalny prefiks użytkownika:
  `npm config set prefix ~/.local`. Fish już dodaje `~/.local/bin` do PATH.
- CodeCompanion korzysta z CLI Codex, które trzeba zainstalować i zalogować
  oddzielnie. Sesji logowania nie przechowujemy w dotfiles.
- Voxtype wymaga własnej konfiguracji i modelu do rozpoznawania mowy;
  w tym repo zapisany jest obecnie skrót klawiszowy, ale nie model ani
  konfiguracja Voxtype. Sam pakiet nie wystarcza do odtworzenia dyktowania.
- Odciski palców, klucze prywatne SSH oraz dane uwierzytelniania pozostają
  osobnym etapem przygotowania komputera. Repo zawiera tylko konfigurację
  hostów SSH, bez kluczy prywatnych.

## Źródła listy i zachowania instalatora

Lista powstała na podstawie konfiguracji w tym repo, instrukcji
`docs/setup.md` projektu Quickshell DE i nazw dostępnych w bazach pakietów
Archa na komputerze źródłowym. Nie jest eksportem wszystkich zainstalowanych
pakietów ani zamrożeniem ich wersji.

- [Pacman: opcje instalacji i aktualizacji](https://man.archlinux.org/man/pacman.8.en)
- [Arch: utrzymanie systemu](https://wiki.archlinux.org/title/System_maintenance)
- [Chezmoi: pliki ignorowane podczas odtwarzania](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
