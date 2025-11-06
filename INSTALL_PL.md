# Instrukcja Instalacji - Enhanced ATC dla Fibocom FM350-GL

## Wymagania

### System
- **OpenWrt 21.02 lub nowszy**
- Router z modemem **Fibocom FM350-GL** (wymiana M.2)
- Minimalne 10 MB wolnego miejsca w `/overlay`

### Wymagane pakiety OpenWrt
```bash
opkg update
opkg install kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-qualcomm
opkg install luci luci-base luci-compat
```

## Instalacja

### Metoda 1: Ręczna instalacja (Zalecana)

#### Krok 1: Pobierz projekt
```bash
# Na komputerze PC
git clone https://github.com/Hexrox/enhanced-atc-fm350.git
cd enhanced-atc-fm350
```

#### Krok 2: Skopiuj pliki na router
```bash
# Skopiuj przez SCP (zamień 192.168.1.1 na IP routera)
scp -r files/* root@192.168.1.1:/
```

#### Krok 3: Ustaw uprawnienia (na routerze)
```bash
# SSH do routera
ssh root@192.168.1.1

# Ustaw uprawnienia wykonywalne
chmod +x /usr/bin/enhanced-atc-cli
chmod +x /lib/netifd/proto/atc.sh

# Sprawdź czy wszystko działa
enhanced-atc-cli --help
```

#### Krok 4: Skonfiguruj interfejs sieciowy
Edytuj `/etc/config/network`:

```bash
vi /etc/config/network
```

Dodaj konfigurację dla modemu:

```
config interface 'modem'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option fcc_unlock '1'
    option band_locking '0'
    option atc_debug '0'
```

#### Krok 5: Zrestartuj sieć
```bash
/etc/init.d/network restart
```

#### Krok 6: Sprawdź status
```bash
# Sprawdź połączenie
enhanced-atc-cli status

# Sprawdź FCC lock
enhanced-atc-cli fcc-status

# Sprawdź Carrier Aggregation
enhanced-atc-cli ca-info

# Zeskanuj dostępne pasma (szybki skan)
enhanced-atc-cli scan quick
```

#### Krok 7: Dostęp do LuCI
1. Otwórz przeglądarkę: `http://192.168.1.1` (lub IP routera)
2. Przejdź do: **Network → Enhanced ATC**
3. Przejdź do zakładki: **Status & Diagnostics**

### Metoda 2: Instalacja przez OpenWrt Image Builder (Zaawansowana)

Dla zaawansowanych użytkowników - wbudowanie w obraz firmware:

```bash
# Sklonuj repozytorium do feeds/
cd openwrt
mkdir -p feeds/enhanced-atc
cp -r enhanced-atc-fm350/* feeds/enhanced-atc/

# Dodaj do feeds.conf.default
echo "src-link enhanced_atc feeds/enhanced-atc" >> feeds.conf.default

# Aktualizuj feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Zbuduj obraz
make menuconfig  # Wybierz pakiet
make -j$(nproc)
```

## Konfiguracja

### Opcje interfejsu `/etc/config/network`

```
config interface 'modem'
    # === Podstawowe ustawienia ===
    option proto 'atc'                    # Protokół (wymagane)
    option device '/dev/ttyUSB3'          # Ścieżka do urządzenia (wymagane)
    option apn 'internet'                 # APN operatora (wymagane)

    # === Uwierzytelnienie (opcjonalne) ===
    option username ''                    # Login (jeśli wymaga operator)
    option password ''                    # Hasło (jeśli wymaga operator)
    option auth '0'                       # Typ auth: 0=none, 1=PAP, 2=CHAP, 3=PAP+CHAP

    # === Ustawienia PDP ===
    option pdp 'IP'                       # Typ: IP, IPV6, IPV4V6

    # === FCC Unlock ===
    option fcc_unlock '1'                 # 1=auto unlock, 0=wyłącz
    option skip_fcc_check '0'             # 1=pomiń sprawdzenie

    # === Blokada pasm (Band Locking) ===
    option band_locking '0'               # 1=włącz, 0=auto
    option lte_bands '3,7,20'            # Pasma LTE (gdy band_locking=1)
    option nr5g_sa_bands '78'            # Pasma 5G SA (gdy band_locking=1)
    option nr5g_nsa_bands '78'           # Pasma 5G NSA (gdy band_locking=1)

    # === Tryb preferowany ===
    option preferred_mode 'auto'          # auto, lte, 5g

    # === Debugging i retry ===
    option atc_debug '0'                  # 1=włącz logi debug
    option delay '0'                      # Opóźnienie startu (0-60s)
    option max_retries '3'                # Maksymalna liczba prób (1-10)

    # === Dodatkowe (obecnie nieużywane) ===
    option firmware_check '1'             # Sprawdzanie wersji firmware
    option auto_optimize '0'              # Auto optymalizacja (przyszła funkcja)
    option signal_threshold '0'           # Próg sygnału (przyszła funkcja)
    option monitor_interval '0'           # Interwał monitorowania (przyszła funkcja)
    option power_management '0'           # Zarządzanie energią (przyszła funkcja)
```

### Przykładowe konfiguracje

#### Konfiguracja 1: Podstawowa (Orange Polska)
```
config interface 'modem'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option fcc_unlock '1'
```

#### Konfiguracja 2: Z blokadą pasm (tylko LTE B3, B7, B20)
```
config interface 'modem'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option fcc_unlock '1'
    option band_locking '1'
    option lte_bands '3,7,20'
```

#### Konfiguracja 3: Tylko 5G NSA z LTE B3 + 5G n78
```
config interface 'modem'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option fcc_unlock '1'
    option band_locking '1'
    option lte_bands '3'
    option nr5g_nsa_bands '78'
    option preferred_mode '5g'
```

#### Konfiguracja 4: Z uwierzytelnieniem (T-Mobile Biznes)
```
config interface 'modem'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'tm.internet'
    option username 'tm'
    option password 'tm'
    option auth '1'
    option fcc_unlock '1'
```

## Użycie CLI

### Podstawowe komendy

```bash
# Pomoc
enhanced-atc-cli --help

# Status modemu
enhanced-atc-cli status

# Informacje o firmware
enhanced-atc-cli fw-info

# Status FCC lock
enhanced-atc-cli fcc-status

# Odblokowanie FCC (jeśli zablokowane)
enhanced-atc-cli fcc-unlock

# Aktualna konfiguracja pasm
enhanced-atc-cli bands

# Status Carrier Aggregation
enhanced-atc-cli ca-info
```

### Blokada pasm

```bash
# Zablokuj do LTE B3, B7, B20
enhanced-atc-cli band-lock --lte 3,7,20

# Zablokuj do LTE B3 + 5G n78
enhanced-atc-cli band-lock --lte 3 --5g 78

# Odblokuj wszystkie pasma (automatyczny wybór)
enhanced-atc-cli band-unlock
```

### Skanowanie pasm

```bash
# Szybki skan (5-10 sekund) - sąsiednie komórki
enhanced-atc-cli scan quick

# Średni skan (10-20 sekund) - aktualna + sąsiednie
enhanced-atc-cli scan medium

# Pełny skan (1-3 minuty) - UWAGA: rozłącza modem!
enhanced-atc-cli scan full
```

### Tryb verbose (debug)

```bash
# Włącz szczegółowe logi
enhanced-atc-cli -v status
enhanced-atc-cli -v ca-info
enhanced-atc-cli -v scan quick
```

### Określanie urządzenia

```bash
# Użyj innego portu USB
enhanced-atc-cli -d /dev/ttyUSB2 status
```

## Zmienne środowiskowe

Możesz dostosować ścieżki przez zmienne środowiskowe:

```bash
# W CLI
export ATC_DEFAULT_DEVICE="/dev/ttyUSB2"
enhanced-atc-cli status

# W protokole netifd
export ATC_LOG_DIR="/var/log/atc"
export ATC_FCC_STATUS_FILE="/var/run/fcc_status"
```

## Rozwiązywanie problemów

### Modem nie odpowiada

```bash
# Sprawdź czy urządzenie istnieje
ls -l /dev/ttyUSB*

# Sprawdź czy moduły kernela są załadowane
lsmod | grep usb_serial
lsmod | grep qcserial

# Sprawdź logi systemowe
logread | grep enhanced-atc

# Sprawdź logi ATC
cat /tmp/atc_logs/ERROR.log
cat /tmp/atc_logs/INFO.log
```

### Błąd "Missing required commands"

```bash
# Zainstaluj brakujące narzędzia
opkg update
opkg install coreutils-timeout coreutils-stty
```

### FCC unlock nie działa

```bash
# Sprawdź status
enhanced-atc-cli fcc-status

# Ręczny unlock
enhanced-atc-cli fcc-unlock

# Sprawdź logi
cat /tmp/atc_logs/FCC.log
```

### Carrier Aggregation pokazuje "0CA"

```bash
# Sprawdź czy jesteś w obszarze z CA
enhanced-atc-cli scan quick

# Sprawdź sygnał
enhanced-atc-cli status

# Sprawdź konfigurację pasm (CA wymaga >1 pasma)
enhanced-atc-cli bands

# Odblokuj wszystkie pasma
enhanced-atc-cli band-unlock
```

### LuCI nie ładuje strony

```bash
# Sprawdź czy pliki Lua są na miejscu
ls -l /usr/lib/lua/luci/controller/admin/enhanced_atc.lua
ls -l /usr/lib/lua/luci/view/admin_network/enhanced_atc_status.htm

# Wyczyść cache LuCI
rm -rf /tmp/luci-*

# Zrestartuj uhttpd
/etc/init.d/uhttpd restart
```

### Pełny skan (full) zawiesi przeglądarkę

To normalne - pełny skan trwa 1-3 minuty i rozłącza modem. Poczekaj cierpliwie. Jeśli przeglądarka timeout:
1. Odśwież stronę po 3 minutach
2. Użyj CLI zamiast LuCI: `enhanced-atc-cli scan full`

## Deinstalacja

```bash
# Usuń pliki
rm /usr/bin/enhanced-atc-cli
rm /lib/netifd/proto/atc.sh
rm -rf /usr/lib/lua/luci/controller/admin/enhanced_atc.lua
rm -rf /usr/lib/lua/luci/model/cbi/admin_network/enhanced_atc.lua
rm -rf /usr/lib/lua/luci/view/admin_network/enhanced_atc_status.htm

# Usuń logi
rm -rf /tmp/atc_logs
rm -f /tmp/atc_fcc_status

# Usuń konfigurację z /etc/config/network
vi /etc/config/network  # Ręcznie usuń sekcję 'modem'

# Zrestartuj sieć
/etc/init.d/network restart
```

## Wsparcie

### Raportowanie błędów
- GitHub Issues: https://github.com/Hexrox/enhanced-atc-fm350/issues

### Logi do załączenia przy zgłoszeniu
```bash
# Zbierz informacje diagnostyczne
enhanced-atc-cli status > /tmp/atc-debug.txt
enhanced-atc-cli fw-info >> /tmp/atc-debug.txt
enhanced-atc-cli bands >> /tmp/atc-debug.txt
enhanced-atc-cli ca-info >> /tmp/atc-debug.txt
cat /tmp/atc_logs/ERROR.log >> /tmp/atc-debug.txt
logread | grep enhanced-atc >> /tmp/atc-debug.txt

# Skopiuj /tmp/atc-debug.txt i załącz do issue
```

## Licencja

GPL-3.0 License - Zobacz LICENSE w repozytorium.

## Autor

Projekt: Enhanced ATC dla Fibocom FM350-GL
Wersja: 1.2.1
Data: 2025-01-06
