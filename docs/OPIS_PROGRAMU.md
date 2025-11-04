# Enhanced ATC - Szczegółowy opis działania programu

## Czym jest Enhanced ATC?

Enhanced ATC to zaawansowany pakiet dla routerów OpenWrt, który umożliwia obsługę modemu 5G Fibocom FM350-GL. Program działa jako natywny protokół sieciowy w systemie OpenWrt (podobnie jak PPPoE, DHCP czy QMI), co pozwala na pełną integrację modemu z systemem.

## Główne komponenty programu

### 1. Protocol Handler (`/lib/netifd/proto/atc.sh`)

**Co to jest?**
To najważniejsza część programu - skrypt powłoki (shell script), który komunikuje się bezpośrednio z modemem przez port szeregowy używając komend AT.

**Co robi?**

#### a) Inicjalizacja i walidacja (funkcja `proto_atc_setup()`)
- Sprawdza czy urządzenie modemu istnieje (np. `/dev/ttyUSB3`)
- Waliduje wszystkie parametry konfiguracji (APN, typ autentykacji, itp.)
- Tworzy katalog logów i inicjalizuje system logowania

#### b) Komunikacja z modemem (funkcja `at_command()`)
```
Jak działa komunikacja AT:
1. Program otwiera port szeregowy modemu (np. /dev/ttyUSB3)
2. Ustawia parametry portu (115200 baud, 8N1)
3. Wysyła komendę AT (np. "AT+CGDCONT=1,\"IP\",\"internet\"")
4. Czeka na odpowiedź modemu (max 15 sekund)
5. Przetwarza i zwraca odpowiedź
6. W razie błędu powtarza próbę (domyślnie 3 razy)
```

**Przykładowe komendy AT używane przez program:**
- `AT` - sprawdzenie czy modem odpowiada
- `ATI` - pobranie informacji o modelu modemu
- `AT+CGMR` - pobranie wersji firmware
- `AT+GTFCCLOCK?` - sprawdzenie statusu blokady FCC
- `AT+GTFCCLOCK=0` - odblokowanie FCC
- `AT+CGDCONT=1,"IP","internet"` - ustawienie APN
- `AT$QCPDPP=1,1,"haslo","login"` - ustawienie autentykacji
- `AT+CNMP=38` - ustawienie trybu LTE
- `AT+CGACT=1,1` - aktywacja kontekstu PDP
- `AT$QCRMCALL=1,1` - rozpoczęcie połączenia danych

#### c) Odblokowanie FCC (funkcja `perform_fcc_unlock()`)
```
Sekwencja odblokowywania FCC:
1. Sprawdź aktualny status: AT+GTFCCLOCK?
2. Jeśli już odblokowany (wartość 0) - zakończ
3. Jeśli zablokowany - wyślij: AT+GTFCCLOCK=0
4. Sprawdź odpowiedź modemu (powinno być "OK")
5. Zapisz status do pliku /tmp/atc_fcc_status
6. Zaloguj wynik w /tmp/atc_logs/FCC.log
```

**Dlaczego to ważne?**
Modemy sprzedawane w USA mają blokadę FCC, która ogranicza moc nadawania i pasma częstotliwości. Odblokowanie pozwala na pełną funkcjonalność modemu.

#### d) Konfiguracja modemu (funkcja `configure_modem()`)
```
Kroki konfiguracji:
1. Ustawienie APN operatora (AT+CGDCONT)
2. Konfiguracja autentykacji jeśli wymagana (AT$QCPDPP)
3. Wybór trybu sieci (auto/LTE/5G) (AT+CNMP)
4. Logowanie każdego kroku
```

#### e) Nawiązywanie połączenia (funkcja `start_connection()`)
```
Sekwencja połączenia:
1. Aktywacja kontekstu PDP: AT+CGACT=1,1
   (PDP = Packet Data Protocol - protokół transmisji danych)
2. Uruchomienie połączenia: AT$QCRMCALL=1,1
3. Sprawdzenie czy modem zwrócił "OK"
4. W razie błędu - retry według konfiguracji
```

#### f) Walidacja parametrów
Program sprawdza poprawność wszystkich parametrów przed użyciem:
- **Ścieżka urządzenia**: musi być w formacie `/dev/xxx` i istnieć
- **APN**: 1-100 znaków alfanumerycznych, kropki, myślniki
- **Delay**: 0-60 sekund
- **Retries**: 1-10 prób
- **Auth type**: 0-3 (none, PAP, CHAP, auto)
- **PDP type**: IP, IPV6, lub IPV4V6

### 2. CLI Tool (`/usr/bin/enhanced-atc-cli`)

**Co to jest?**
Narzędzie wiersza poleceń do zarządzania modemem ręcznie, bez potrzeby konfiguracji interfejsu sieciowego.

**Dostępne komendy:**

#### `enhanced-atc-cli status`
```
Co robi:
1. Automatycznie wykrywa modem (przeszukuje /dev/ttyUSB*)
2. Wysyła komendę ATI
3. Wyświetla czy modem odpowiada
4. Pokazuje podstawowe informacje
```

#### `enhanced-atc-cli fcc-status`
```
Co robi:
1. Wysyła AT+GTFCCLOCK?
2. Analizuje odpowiedź:
   - GTFCCLOCK: 0 = odblokowany
   - GTFCCLOCK: 1 = zablokowany
3. Wyświetla status w czytelnej formie
```

#### `enhanced-atc-cli fcc-unlock`
```
Co robi:
1. Wysyła AT+GTFCCLOCK=0
2. Czeka na potwierdzenie (OK)
3. Wyświetla wynik operacji
4. Loguje do /tmp/atc_logs/
```

#### `enhanced-atc-cli fw-info`
```
Co robi:
1. Wysyła AT+CGMR (firmware revision)
2. Wysyła ATI (manufacturer info)
3. Formatuje i wyświetla dane
```

### 3. LuCI Web Interface

**Składa się z trzech części:**

#### a) Controller (`/usr/lib/lua/luci/controller/admin/enhanced_atc.lua`)
```
Co robi:
- Rejestruje ścieżki URL w interfejsie LuCI
- Obsługuje żądania AJAX z przeglądarki
- Wywołuje enhanced-atc-cli i zwraca wyniki jako JSON
```

**Endpointy API:**
- `/admin/network/enhanced_atc/fcc_status` - sprawdza status FCC
- `/admin/network/enhanced_atc/fcc_unlock` - odblokowuje FCC
- `/admin/network/enhanced_atc/modem_info` - pobiera info o modemie
- `/admin/network/enhanced_atc/logs` - zwraca ostatnie logi

#### b) Model CBI (`/usr/lib/lua/luci/model/cbi/admin_network/enhanced_atc.lua`)
```
Co robi:
- Definiuje formularz konfiguracyjny
- Łączy pola formularza z UCI (Unified Configuration Interface)
- Waliduje dane wejściowe
- Zapisuje konfigurację do /etc/config/enhanced_atc
```

**Pola konfiguracyjne:**
- Ustawienia ogólne (FCC unlock, firmware check, debug)
- Konfiguracja interfejsu (device, APN, autentykacja)
- Zaawansowane opcje (tryb sieci, próg sygnału, monitoring)

#### c) View HTML (`/usr/lib/lua/luci/view/admin_network/enhanced_atc.htm`)
```
Co robi:
- Wyświetla dashboard ze statusem modemu
- Przyciski akcji (sprawdź FCC, odblokuj, odśwież)
- Panel logów z automatycznym odświeżaniem
- JavaScript do komunikacji z API
```

### 4. Init Script (`/etc/init.d/enhanced_atc`)

**Co to jest?**
Skrypt uruchamiany przy starcie systemu OpenWrt, zarządzający usługą Enhanced ATC.

**Co robi?**

#### Przy starcie systemu (`start_service()`):
```
1. Sprawdza zależności:
   - Czy wszystkie wymagane narzędzia są zainstalowane
   - Czy istnieje protocol handler
   - Czy wykryto urządzenia USB (/dev/ttyUSB*)
   - Czy istnieje konfiguracja

2. Tworzy strukturę katalogów:
   - mkdir -p /tmp/atc_logs

3. Czyści stare logi:
   - Usuwa pliki starsze niż 7 dni

4. Rejestruje protokół:
   - /etc/init.d/network reload
   - To powoduje że netifd "widzi" protokół 'atc'
```

#### Dodatkowe komendy:
```bash
# Sprawdzenie statusu
/etc/init.d/enhanced_atc status

# Sprawdzenie instalacji
/etc/init.d/enhanced_atc install_check
```

### 5. Configuration File (`/etc/config/enhanced_atc`)

**Format UCI:**
```
config <typ> '<nazwa>'
    option <klucz> '<wartość>'
```

**Sekcje:**

#### General (ustawienia ogólne):
- `fcc_unlock` - czy automatycznie odblokować FCC
- `firmware_check` - czy sprawdzać wersję firmware
- `atc_debug` - czy włączyć szczegółowe logi

#### Interface (konfiguracja interfejsu):
- `device` - ścieżka do urządzenia (np. /dev/ttyUSB3)
- `apn` - Access Point Name operatora
- `username/password` - dane do autentykacji
- `auth` - typ autentykacji (0=brak, 1=PAP, 2=CHAP, 3=auto)
- `pdp` - typ IP (IP=IPv4, IPV6, IPV4V6=dual-stack)
- `delay` - opóźnienie przed połączeniem (sekundy)
- `max_retries` - ile razy powtarzać przy błędzie
- `preferred_mode` - tryb sieci (auto/lte/5g)

## Przepływ danych - jak to wszystko działa razem

### Scenariusz 1: Uruchomienie routera

```
1. System OpenWrt bootuje
   ↓
2. Init system uruchamia /etc/init.d/enhanced_atc
   ↓
3. Enhanced_atc sprawdza zależności
   ↓
4. Tworzy katalog logów /tmp/atc_logs/
   ↓
5. Wykonuje: /etc/init.d/network reload
   ↓
6. Netifd ładuje wszystkie protokoły z /lib/netifd/proto/
   ↓
7. Znajduje atc.sh i rejestruje protokół 'atc'
   ↓
8. Netifd czyta /etc/config/network
   ↓
9. Jeśli znajduje interface z proto='atc':
   ↓
10. Wywołuje proto_atc_setup() z atc.sh
    ↓
11. Protocol handler:
    - Sprawdza czy /dev/ttyUSB3 istnieje
    - Waliduje konfigurację
    - Czeka delay sekund
    - Wysyła AT do modemu (sprawdza czy gotowy)
    - Pobiera info o firmware (ATI, AT+CGMR)
    - Wykonuje FCC unlock (AT+GTFCCLOCK=0)
    - Konfiguruje APN (AT+CGDCONT)
    - Ustawia autentykację (AT$QCPDPP)
    - Ustawia tryb sieci (AT+CNMP)
    - Aktywuje PDP (AT+CGACT=1,1)
    - Uruchamia połączenie (AT$QCRMCALL=1,1)
    ↓
12. Modem nawiązuje połączenie z operatorem
    ↓
13. Modem tworzy interfejs sieciowy (np. wwan0)
    ↓
14. Netifd konfiguruje routing i DNS
    ↓
15. Internet działa!
```

### Scenariusz 2: Użytkownik otwiera panel LuCI

```
1. Przeglądarka: GET /cgi-bin/luci/admin/network/enhanced_atc
   ↓
2. LuCI wywołuje controller: enhanced_atc.lua
   ↓
3. Controller ładuje model CBI: enhanced_atc.lua
   ↓
4. Model CBI czyta konfigurację z UCI
   ↓
5. Generuje formularz HTML
   ↓
6. Użytkownik widzi formularz w przeglądarce
   ↓
7. Użytkownik zmienia APN i klika "Save"
   ↓
8. POST /cgi-bin/luci/admin/network/enhanced_atc
   ↓
9. Model CBI waliduje dane
   ↓
10. Zapisuje do /etc/config/enhanced_atc
    ↓
11. Wywołuje: uci commit enhanced_atc
    ↓
12. Przeładowuje sieć: /etc/init.d/network reload
    ↓
13. Netifd ponownie wywołuje proto_atc_setup()
    ↓
14. Połączenie nawiązane z nowym APN
```

### Scenariusz 3: Ręczne odblokowanie FCC przez CLI

```
1. Użytkownik: enhanced-atc-cli fcc-unlock
   ↓
2. CLI wywołuje funkcję fcc_unlock()
   ↓
3. Wykrywa modem: szuka /dev/ttyUSB* z odpowiedzią na ATI
   ↓
4. Otwiera port szeregowy
   ↓
5. Ustawia parametry: stty -F /dev/ttyUSB3 raw -echo 115200
   ↓
6. Wysyła: printf 'AT+GTFCCLOCK=0\r\n' > /dev/ttyUSB3
   ↓
7. Czeka 2 sekundy
   ↓
8. Czyta odpowiedź: cat /dev/ttyUSB3
   ↓
9. Modem odpowiada: "OK"
   ↓
10. CLI wyświetla: "SUCCESS: FCC unlock completed"
    ↓
11. Zapisuje log: /tmp/atc_logs/FCC.log
```

## System logowania

Program tworzy osobne pliki logów dla różnych poziomów:

```
/tmp/atc_logs/
├── DEBUG.log    - szczegółowe logi (tylko gdy atc_debug=1)
├── INFO.log     - normalne operacje
├── FCC.log      - operacje związane z FCC
├── WARN.log     - ostrzeżenia
└── ERROR.log    - błędy
```

**Format wpisu w logu:**
```
[2025-11-04 15:30:45] [INFO] Starting connection on interface wan with device /dev/ttyUSB3
[2025-11-04 15:30:46] [DEBUG] AT: AT+CGDCONT=1,"IP","internet"
[2025-11-04 15:30:47] [DEBUG] AT Response: OK
[2025-11-04 15:30:50] [FCC] Starting FCC unlock procedure
[2025-11-04 15:30:52] [FCC] FCC unlock successful
```

## Wymagane zależności

### Pakiety systemowe:
- `libuci` - biblioteka do obsługi UCI (konfiguracja OpenWrt)
- `libjson-c` - biblioteka JSON (dla netifd)
- `netifd` - demon zarządzający siecią w OpenWrt

### Narzędzia (zwykle w busybox):
- `stty` - konfiguracja portu szeregowego
- `timeout` - limit czasu wykonania komendy
- `dd` - czytanie z urządzenia
- `grep` - filtrowanie tekstu
- `tr` - transliteracja znaków
- `sed` - edycja strumieni
- `logger` - logowanie do syslog
- `uci` - zarządzanie konfiguracją

### Dla interfejsu LuCI:
- `luci-base` - podstawa LuCI
- `luci-mod-admin-full` - pełny panel administracyjny
- `lua` - interpreter Lua
- `luci.sys` - moduł systemowy LuCI
- `luci.jsonc` - moduł JSON dla LuCI
- `nixio.fs` - moduł dostępu do plików

### Sterowniki jądra:
- `kmod-usb-serial` - obsługa USB serial
- `kmod-usb-serial-option` - sterownik dla modemów
- `kmod-usb-serial-wwan` - WWAN support

## Bezpieczeństwo i walidacja

Program implementuje wielopoziomową walidację:

1. **Walidacja ścieżki urządzenia:**
   - Regex: `^/dev/[a-zA-Z0-9_-]+$`
   - Sprawdzenie czy jest character device
   - Sprawdzenie uprawnień read/write

2. **Walidacja APN:**
   - Regex: `^[a-zA-Z0-9._-]{1,100}$`
   - Max 100 znaków

3. **Walidacja numeryczna:**
   - Delay: 0-60 sekund
   - Retries: 1-10 prób
   - Signal threshold: wartość dBm

4. **Walidacja typu:**
   - Auth: 0-3
   - PDP: IP|IPV6|IPV4V6
   - Mode: auto|lte|5g

5. **Bezpieczeństwo komend AT:**
   - Wszystkie zmienne w cudzysłowach
   - Timeout dla każdej komendy
   - Retry logic przy błędach
   - Logowanie wszystkich operacji

## Różnice od standardowych rozwiązań

### Vs QMI (Qualcomm MSM Interface):
- **Enhanced ATC:** Używa komend AT, uniwersalne, działa z każdym modemem AT
- **QMI:** Specyficzne dla modemów Qualcomm, szybsze, ale wymaga libqmi

### Vs ModemManager:
- **Enhanced ATC:** Lekkie, dedykowane dla FM350-GL, pełna kontrola
- **ModemManager:** Cięższe, obsługuje wiele modemów, mniej kontroli

### Vs Manual AT commands:
- **Enhanced ATC:** Automatyzacja, integracja z OpenWrt, GUI
- **Manual:** Pełna kontrola, ale wymaga wiedzy technicznej

## Podsumowanie

Enhanced ATC to kompletne rozwiązanie składające się z:
- Protocol handler (netifd) - automatyczna konfiguracja
- CLI tool - ręczne zarządzanie
- Web interface (LuCI) - GUI dla użytkownika
- Init script - zarządzanie usługą
- System logowania - diagnostyka
- Walidacja - bezpieczeństwo

Wszystko współpracuje aby zapewnić niezawodne, bezpieczne i łatwe w użyciu połączenie 5G/LTE przez modem Fibocom FM350-GL w systemie OpenWrt.
