# Enhanced ATC dla Fibocom FM350-GL

Zaawansowany protokół dla OpenWrt z automatycznym odblokowaniem FCC dla modemów 5G Fibocom FM350-GL.

## Funkcje

- **Automatyczne odblokowanie FCC**: Automatycznie odblokowuje ograniczenia FCC przy starcie modemu
- **Pełna integracja z OpenWrt**: Natywny protokół netifd dla bezproblemowej integracji
- **Interfejs webowy LuCI**: Łatwy w użyciu interfejs WWW do konfiguracji i monitorowania
- **Narzędzie CLI**: Narzędzie wiersza poleceń do sprawdzania statusu i ręcznych operacji
- **Zaawansowana konfiguracja**: Obsługa wielu typów autentykacji, PDP i trybów sieci
- **Kompleksowe logowanie**: Szczegółowe logi do debugowania i monitorowania
- **Walidacja parametrów**: Automatyczna walidacja wszystkich parametrów konfiguracji
- **Zarządzanie połączeniem**: Automatyczne ponawianie prób i monitorowanie połączenia
- **Sprawdzanie zależności**: Automatyczne wykrywanie brakujących pakietów i narzędzi

## Szybki start

### Instalacja

```bash
# Wgraj pakiet na router
scp enhanced-atc_*.ipk root@192.168.1.1:/tmp/

# Zainstaluj na routerze
ssh root@192.168.1.1
opkg update
opkg install /tmp/enhanced-atc_*.ipk
```

### Sprawdzenie instalacji

```bash
# Sprawdź czy wszystkie komponenty są zainstalowane
/etc/init.d/enhanced_atc install_check

# Sprawdź status usługi
/etc/init.d/enhanced_atc status
```

### Podstawowa konfiguracja

#### Przez LuCI (interfejs WWW)
1. Przejdź do **Sieć** → **Enhanced ATC**
2. Skonfiguruj APN i ustawienia połączenia
3. Włącz odblokowanie FCC jeśli potrzebne
4. Zapisz i zastosuj

#### Przez wiersz poleceń
```bash
# Edytuj konfigurację
vi /etc/config/enhanced_atc

# Ustaw swój APN
uci set enhanced_atc.wan.apn='internet'
uci set enhanced_atc.wan.enabled='1'
uci commit enhanced_atc

# Przeładuj sieć
/etc/init.d/network reload
```

### Przykłady dla polskich operatorów

#### Play
```bash
uci set enhanced_atc.wan.apn='internet'
uci set enhanced_atc.wan.auth='0'
uci commit enhanced_atc
```

#### Orange
```bash
uci set enhanced_atc.wan.apn='internet'
uci set enhanced_atc.wan.username='internet'
uci set enhanced_atc.wan.password='internet'
uci set enhanced_atc.wan.auth='1'
uci commit enhanced_atc
```

#### Plus
```bash
uci set enhanced_atc.wan.apn='internet'
uci set enhanced_atc.wan.username='plusgsm'
uci set enhanced_atc.wan.password='plusgsm'
uci set enhanced_atc.wan.auth='1'
uci commit enhanced_atc
```

#### T-Mobile
```bash
uci set enhanced_atc.wan.apn='internet'
uci set enhanced_atc.wan.auth='0'
uci commit enhanced_atc
```

### Używanie narzędzia CLI

```bash
# Sprawdź status modemu
enhanced-atc-cli status

# Sprawdź blokadę FCC
enhanced-atc-cli fcc-status

# Odblokuj FCC
enhanced-atc-cli fcc-unlock

# Zobacz informacje o firmware
enhanced-atc-cli fw-info
```

## Wymagania

### System
- OpenWrt 21.02 lub nowszy
- Modem Fibocom FM350-GL
- Połączenie USB do modemu

### Pakiety (zwykle już zainstalowane)
- `libuci` - zarządzanie konfiguracją
- `libjson-c` - obsługa JSON
- `netifd` - demon sieciowy OpenWrt

### Narzędzia (część busybox)
- `stty` - konfiguracja portu szeregowego
- `timeout` - limity czasu
- `dd` - operacje I/O
- `grep`, `tr`, `sed` - przetwarzanie tekstu
- `logger` - logowanie systemowe
- `uci` - interfejs konfiguracji

### Dla interfejsu WWW (opcjonalne)
- `luci-base`
- `luci-mod-admin-full`

### Sterowniki jądra
- `kmod-usb-serial`
- `kmod-usb-serial-option`
- `kmod-usb-serial-wwan`

Sprawdź wszystkie zależności:
```bash
/etc/init.d/enhanced_atc install_check
```

## Dokumentacja

- [Przewodnik instalacji](INSTALLATION.md) - Szczegółowa instrukcja instalacji
- [Przewodnik konfiguracji](CONFIGURATION.md) - Kompletna dokumentacja opcji
- [Opis programu](OPIS_PROGRAMU.md) - Szczegółowy opis jak działa program
- [Przykłady](../examples/) - Przykłady konfiguracji dla różnych operatorów

## Obsługiwane funkcje

### Obecnie dostępne
- ✅ Automatyczne odblokowanie FCC
- ✅ Łączność LTE/5G
- ✅ Obsługa IPv4 i IPv6
- ✅ Autentykacja PAP/CHAP
- ✅ Monitorowanie połączenia
- ✅ Sprawdzanie wersji firmware
- ✅ Interfejs WWW (LuCI)
- ✅ Interfejs wiersza poleceń
- ✅ Kompleksowe logowanie
- ✅ Walidacja parametrów
- ✅ Sprawdzanie zależności

### Planowane
- ⏳ Auto-optymalizacja na podstawie jakości sygnału
- ⏳ Funkcje zarządzania energią
- ⏳ Funkcjonalność SMS
- ⏳ Obsługa GPS/GNSS
- ⏳ Blokowanie pasm
- ⏳ Informacje o agregacji nośnych

## Struktura projektu

```
enhanced-atc-fm350/
├── files/
│   ├── etc/
│   │   ├── config/
│   │   │   └── enhanced_atc          # Domyślna konfiguracja
│   │   └── init.d/
│   │       └── enhanced_atc          # Skrypt startowy
│   ├── lib/
│   │   └── netifd/
│   │       └── proto/
│   │           └── atc.sh            # Protocol handler
│   └── usr/
│       ├── bin/
│       │   └── enhanced-atc-cli      # Narzędzie CLI
│       └── lib/
│           └── lua/
│               └── luci/             # Integracja LuCI
├── docs/                             # Dokumentacja
│   ├── INSTALLATION.md               # Instalacja (EN)
│   ├── CONFIGURATION.md              # Konfiguracja (EN)
│   ├── README_PL.md                  # Ten plik
│   └── OPIS_PROGRAMU.md             # Szczegółowy opis (PL)
├── examples/                         # Przykłady konfiguracji
│   ├── play-polska.conf
│   ├── orange-polska.conf
│   ├── plus-polska.conf
│   ├── tmobile-polska.conf
│   └── ...
└── README.md                         # README (EN)
```

## Diagnostyka

### Modem nie wykryty
```bash
# Sprawdź czy modem jest rozpoznany
ls -l /dev/ttyUSB*

# Sprawdź komunikaty kernela
dmesg | grep ttyUSB

# Sprawdź załadowane moduły
lsmod | grep usb
```

### Odblokowanie FCC nie działa
```bash
# Spróbuj ręcznie
enhanced-atc-cli fcc-unlock

# Sprawdź logi błędów
cat /tmp/atc_logs/ERROR.log

# Sprawdź logi FCC
cat /tmp/atc_logs/FCC.log
```

### Problemy z połączeniem
```bash
# Włącz tryb debugowania
uci set enhanced_atc.general.atc_debug='1'
uci commit enhanced_atc
/etc/init.d/network reload

# Zobacz szczegółowe logi
tail -f /tmp/atc_logs/DEBUG.log
```

### Brakujące zależności
```bash
# Sprawdź co brakuje
/etc/init.d/enhanced_atc install_check

# Zainstaluj brakujące pakiety
opkg update
opkg install <nazwa-pakietu>
```

## Pliki logów

Program tworzy różne pliki logów w `/tmp/atc_logs/`:

```bash
# Logi informacyjne (normalna praca)
tail -f /tmp/atc_logs/INFO.log

# Logi operacji FCC
tail -f /tmp/atc_logs/FCC.log

# Logi błędów
tail -f /tmp/atc_logs/ERROR.log

# Logi ostrzeżeń
tail -f /tmp/atc_logs/WARN.log

# Logi debugowania (tylko gdy atc_debug=1)
tail -f /tmp/atc_logs/DEBUG.log

# Zobacz wszystkie logi
tail -f /tmp/atc_logs/*.log
```

## Typowe problemy i rozwiązania

### 1. Modem nie odpowiada

**Przyczyna:** Port szeregowy jest zajęty lub nieprawidłowy

**Rozwiązanie:**
```bash
# Znajdź prawidłowy port
ls -l /dev/ttyUSB*

# Sprawdź który port odpowiada na komendy AT
for dev in /dev/ttyUSB*; do
    echo "Testing $dev"
    echo -e "ATI\r" > $dev
    timeout 2 cat $dev
done

# Ustaw prawidłowy port w konfiguracji
uci set enhanced_atc.wan.device='/dev/ttyUSB3'
uci commit
```

### 2. Połączenie się nie nawiązuje

**Przyczyna:** Nieprawidłowy APN lub brak aktywacji

**Rozwiązanie:**
```bash
# Sprawdź APN u operatora
# Play: internet
# Orange: internet (użytkownik: internet, hasło: internet)
# Plus: internet (użytkownik: plusgsm, hasło: plusgsm)
# T-Mobile: internet

# Ustaw prawidłowy APN
uci set enhanced_atc.wan.apn='prawidlowy-apn'
uci commit enhanced_atc
/etc/init.d/network reload
```

### 3. Brak internetu mimo połączenia

**Przyczyna:** Problem z routingiem lub DNS

**Rozwiązanie:**
```bash
# Sprawdź interfejs
ifconfig

# Sprawdź routing
ip route

# Sprawdź DNS
cat /etc/resolv.conf

# Spróbuj pingować
ping -c 4 8.8.8.8
ping -c 4 google.com
```

## Wsparcie

- **Problemy:** Zgłaszaj przez GitHub Issues
- **Logi:** Zawsze dołączaj logi z `/tmp/atc_logs/`
- **Debug:** Włącz tryb debugowania przed zgłoszeniem problemu

## Przykłady konfiguracji

Katalog `examples/` zawiera gotowe konfiguracje dla:

### Polscy operatorzy:
- `play-polska.conf` - Play
- `orange-polska.conf` - Orange
- `plus-polska.conf` - Plus
- `tmobile-polska.conf` - T-Mobile
- `netia-mobile.conf` - Netia Mobile
- `virgin-mobile-polska.conf` - Virgin Mobile

### Specjalne:
- `generic-authenticated.conf` - Z autentykacją
- `debug-mode.conf` - Tryb debugowania
- `lte-only.conf` - Tylko LTE (bez 5G)

## Licencja

Projekt open source. Zobacz plik LICENSE.

## Podziękowania

- Społeczność OpenWrt
- Dokumentacja Fibocom FM350-GL
- Twórcy frameworka LuCI
