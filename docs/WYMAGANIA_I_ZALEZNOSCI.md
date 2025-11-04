# Wymagania i zależności - Enhanced ATC

## Sprawdzanie zależności

Program **automatycznie sprawdza** wszystkie wymagane zależności przy starcie:

```bash
/etc/init.d/enhanced_atc install_check
```

## Wymagane pakiety systemowe

### Podstawowe (WYMAGANE)

| Pakiet | Wersja min. | Opis | Sprawdzenie |
|--------|-------------|------|-------------|
| `libuci` | - | Biblioteka do zarządzania konfiguracją UCI | `opkg list-installed | grep libuci` |
| `libjson-c` | - | Biblioteka JSON dla netifd | `opkg list-installed | grep libjson-c` |
| `netifd` | - | Demon zarządzający siecią w OpenWrt | `which netifd` |

**Instalacja brakujących:**
```bash
opkg update
opkg install libuci libjson-c
```

*Uwaga: netifd jest częścią podstawowej instalacji OpenWrt*

### Narzędzia wiersza poleceń (WYMAGANE)

Wszystkie poniższe narzędzia są **zwykle dostępne** w busybox, który jest częścią OpenWrt.

| Narzędzie | Używane w | Alternatywa |
|-----------|-----------|-------------|
| `stty` | Konfiguracja portu szeregowego | - |
| `timeout` | Limity czasu dla komend AT | coreutils-timeout |
| `dd` | Czytanie z urządzenia modemowego | - |
| `grep` | Filtrowanie odpowiedzi AT | - |
| `tr` | Czyszczenie znaków CR/LF | - |
| `sed` | Przetwarzanie tekstu | - |
| `logger` | Logowanie do syslog | - |
| `uci` | Zarządzanie konfiguracją | - |
| `head` | Limitowanie wyjścia | - |
| `tail` | Czytanie logów | - |
| `cat` | Wyświetlanie plików | - |
| `sleep` | Opóźnienia | - |
| `mkdir` | Tworzenie katalogów | - |
| `find` | Wyszukiwanie plików | - |
| `rm` | Usuwanie plików | - |

**Sprawdzenie dostępności:**
```bash
for tool in stty timeout dd grep tr sed logger uci; do
    if command -v $tool >/dev/null; then
        echo "✓ $tool - OK"
    else
        echo "✗ $tool - BRAK"
    fi
done
```

### Sterowniki kernela (WYMAGANE dla USB)

| Moduł | Opis | Sprawdzenie |
|-------|------|-------------|
| `kmod-usb-serial` | Podstawowa obsługa USB serial | `lsmod | grep usb_serial` |
| `kmod-usb-serial-option` | Sterownik dla modemów 3G/4G/5G | `lsmod | grep option` |
| `kmod-usb-serial-wwan` | Wsparcie WWAN | `lsmod | grep usb_wwan` |

**Instalacja:**
```bash
opkg update
opkg install kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan
```

**Weryfikacja działania:**
```bash
# Po podłączeniu modemu powinny pojawić się urządzenia
ls -l /dev/ttyUSB*

# Sprawdź dmesg
dmesg | grep -i "usb\|ttyUSB\|option"
```

## Opcjonalne (dla interfejsu WWW)

### Pakiety LuCI

| Pakiet | Opis | Wymagane dla |
|--------|------|--------------|
| `luci-base` | Podstawa LuCI | Interfejs WWW |
| `luci-mod-admin-full` | Pełny panel admin | Panel konfiguracyjny |
| `luci-theme-*` | Motyw (dowolny) | Wygląd |

**Instalacja:**
```bash
opkg update
opkg install luci luci-mod-admin-full
```

### Biblioteki Lua

Program używa następujących modułów Lua (dostępne po instalacji LuCI):

| Moduł | Używany w | Funkcja |
|-------|-----------|---------|
| `luci.sys` | Controller | Wykonywanie komend systemowych |
| `luci.jsonc` | Controller | Serializacja JSON |
| `nixio.fs` | Controller | Dostęp do systemu plików |
| `luci.http` | Controller | Obsługa HTTP |
| `luci.cbi` | Model | Tworzenie formularzy |

**Sprawdzenie:**
```bash
lua -e "require 'luci.sys'; print('OK')"
lua -e "require 'luci.jsonc'; print('OK')"
lua -e "require 'nixio.fs'; print('OK')"
```

## Zależności runtime

### Porty szeregowe

Program wymaga dostępu do portu szeregowego modemu:
- Zazwyczaj: `/dev/ttyUSB3` (dla FM350-GL)
- Możliwe: `/dev/ttyUSB0`, `/dev/ttyUSB1`, `/dev/ttyUSB2`

**Automatyczne wykrywanie:**
```bash
enhanced-atc-cli status
# Skrypt automatycznie przeszuka wszystkie /dev/ttyUSB*
```

**Ręczne sprawdzenie:**
```bash
# Lista urządzeń
ls -l /dev/ttyUSB*

# Test każdego portu
for dev in /dev/ttyUSB*; do
    echo "=== Testing $dev ==="
    echo -e "ATI\r" > $dev 2>/dev/null && timeout 2 cat $dev 2>/dev/null
done
```

### Uprawnienia

Program wymaga:
- **root** - do konfiguracji sieci i dostępu do urządzeń
- **r/w** - do `/dev/ttyUSB*`
- **write** - do `/tmp/atc_logs/`
- **write** - do `/etc/config/enhanced_atc`

## Tabela kompatybilności OpenWrt

| Wersja OpenWrt | Status | Uwagi |
|----------------|--------|-------|
| 23.05.x | ✅ Testowane | Zalecane |
| 22.03.x | ✅ Testowane | Stabilne |
| 21.02.x | ✅ Wspierane | Minimalna wersja |
| 19.07.x | ⚠️ Nieprzetestowane | Może działać |
| < 19.07 | ❌ Niewspierane | Zbyt stare |

## Kompatybilność sprzętowa

### Modem

| Model | Status | Uwagi |
|-------|--------|-------|
| Fibocom FM350-GL | ✅ Pełne wsparcie | Główny cel |
| Fibocom FM350 (inne) | ⚠️ Może działać | Zależnie od firmware |
| Inne modemy | ❌ Niewspierane | Wymagane komendy AT mogą się różnić |

### Routery (przykłady testowane)

| Router | CPU | Status |
|--------|-----|--------|
| GL.iNet routers | - | ✅ Testowane |
| Raspberry Pi + OpenWrt | ARM | ✅ Działa |
| x86_64 | x86 | ✅ Działa |

## Minimalne wymagania systemowe

| Zasób | Minimum | Zalecane |
|-------|---------|----------|
| RAM | 32 MB | 64 MB+ |
| Flash | 8 MB | 16 MB+ |
| CPU | 200 MHz | 400 MHz+ |
| Wolne miejsce | 100 KB | 500 KB+ |

## Używane porty i usługi

| Port/Usługa | Protokół | Cel |
|-------------|----------|-----|
| /dev/ttyUSB* | Serial | Komunikacja z modemem |
| LuCI (80/443) | HTTP/HTTPS | Panel WWW (opcjonalny) |
| - | - | Program nie otwiera portów sieciowych |

## Sprawdzenie instalacji krok po kroku

### 1. System OpenWrt
```bash
# Wersja OpenWrt
cat /etc/openwrt_release

# Architektura
uname -m

# Dostępna pamięć
free -h

# Dostępne miejsce
df -h
```

### 2. Pakiety
```bash
# Enhanced ATC zainstalowany?
opkg list-installed | grep enhanced-atc

# Podstawowe zależności
opkg list-installed | grep -E "libuci|libjson"

# LuCI (jeśli używasz GUI)
opkg list-installed | grep luci
```

### 3. Pliki programu
```bash
# Protocol handler
ls -l /lib/netifd/proto/atc.sh

# CLI tool
ls -l /usr/bin/enhanced-atc-cli

# Init script
ls -l /etc/init.d/enhanced_atc

# Config file
ls -l /etc/config/enhanced_atc

# LuCI components (opcjonalnie)
ls -l /usr/lib/lua/luci/controller/admin/enhanced_atc.lua
ls -l /usr/lib/lua/luci/model/cbi/admin_network/enhanced_atc.lua
```

### 4. Modem
```bash
# USB devices
lsusb

# Serial devices
ls -l /dev/ttyUSB*

# Kernel messages
dmesg | grep -i "usb\|option\|ttyUSB"

# Test modemu
enhanced-atc-cli status
```

### 5. Usługa
```bash
# Status usługi
/etc/init.d/enhanced_atc status

# Czy włączona przy starcie
ls -l /etc/rc.d/*enhanced*

# Pełne sprawdzenie
/etc/init.d/enhanced_atc install_check
```

## Rozwiązywanie problemów z zależnościami

### Brak /dev/ttyUSB*

**Przyczyna:** Brak sterowników USB serial

**Rozwiązanie:**
```bash
opkg update
opkg install kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan
reboot
```

### Timeout nie działa

**Przyczyna:** Brak timeout z coreutils

**Rozwiązanie:**
```bash
# Sprawdź wersję
timeout --version

# Jeśli brak lub busybox timeout ma problemy
opkg install coreutils-timeout
```

### LuCI nie pokazuje Enhanced ATC

**Przyczyna:** Brak LuCI lub cache

**Rozwiązanie:**
```bash
# Przeładuj cache LuCI
rm -rf /tmp/luci-*

# Uruchom ponownie uhttpd
/etc/init.d/uhttpd restart

# Wymuś przeładowanie w przeglądarce (Ctrl+F5)
```

### UCI errors

**Przyczyna:** Uszkodzona konfiguracja

**Rozwiązanie:**
```bash
# Sprawdź składnię
uci show enhanced_atc

# Przywróć domyślną
rm /etc/config/enhanced_atc
opkg install --force-reinstall enhanced-atc

# Lub ręcznie napraw
vi /etc/config/enhanced_atc
```

## Automatyczne sprawdzanie przy instalacji

Program automatycznie sprawdza zależności:

**Przy instalacji pakietu:**
```bash
opkg install enhanced-atc_*.ipk
```

**Przy starcie usługi:**
```bash
/etc/init.d/enhanced_atc start
# Automatycznie wywołuje check_dependencies()
```

**Ręczne sprawdzenie:**
```bash
/etc/init.d/enhanced_atc install_check
```

**Output przykładowy:**
```
=== Enhanced ATC Installation Check ===

Checking Enhanced ATC dependencies...
All required dependencies are present.

Checking LuCI components...
  LuCI controller: Installed
  LuCI model: Installed
  CLI tool: Installed

Installation check complete.
```

## Podsumowanie

Program Enhanced ATC:
- ✅ **Automatycznie sprawdza** wszystkie zależności przy starcie
- ✅ **Wymaga minimalnych** zależności (większość już w OpenWrt)
- ✅ **Informuje o brakach** z jasnymi instrukcjami naprawy
- ✅ **Działa bez LuCI** (CLI i protocol handler są niezależne)
- ✅ **Kompatybilny** z większością routerów OpenWrt 21.02+

Większość zależności jest już dostępna w standardowej instalacji OpenWrt. Główne wymaganie to sterowniki USB serial dla modemu.
