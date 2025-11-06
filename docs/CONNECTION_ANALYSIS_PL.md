# Analiza Mechanizmu Połączeń i Protokołów ATC

## Przegląd

Dokument analizuje sposób nawiązywania połączenia przez Enhanced ATC oraz mechanizm instalacji protokołu dla modemu Fibocom FM350-GL.

---

## 1. CZY SKRYPT NAWIĄZUJE POŁĄCZENIE AUTOMATYCZNIE?

### ❌ NIE - domyślnie połączenie NIE jest nawiązywane automatycznie

**Powód:**
```
config interface 'wan'
    option enabled '0'    ← INTERFEJS WYŁĄCZONY DOMYŚLNIE
```

Lokalizacja: `/etc/config/enhanced_atc:10`

### Jak działa mechanizm połączenia:

#### Etap 1: Instalacja i uruchomienie usługi
```bash
opkg install enhanced-atc_*.ipk
```

**Co się dzieje:**
1. Instalowany jest protokół handler: `/lib/netifd/proto/atc.sh`
2. Tworzona jest konfiguracja: `/etc/config/enhanced_atc`
3. Uruchamiana jest usługa init.d: `/etc/init.d/enhanced_atc start`
4. Usługa **tylko** rejestruje protokół w netifd - **NIE nawiązuje połączenia**

```bash
# Z pliku: files/etc/init.d/enhanced_atc:82-83
# Reload netifd to register protocol
/etc/init.d/network reload 2>/dev/null || true
```

#### Etap 2: Konfiguracja (WYMAGANA przez użytkownika)

**Opcja A: Przez interfejs webowy LuCI**
1. Przejdź do: Network → Enhanced ATC
2. Ustaw APN operatora
3. **WŁĄCZ interfejs** (przełącznik Enable)
4. Kliknij "Save & Apply"

**Opcja B: Przez linię poleceń UCI**
```bash
# KRYTYCZNE: Włączenie interfejsu
uci set enhanced_atc.wan.enabled='1'

# Konfiguracja APN
uci set enhanced_atc.wan.apn='internet'

# Zapisanie i zastosowanie
uci commit enhanced_atc
/etc/init.d/network reload
```

#### Etap 3: Automatyczne nawiązywanie połączenia (po włączeniu)

**Kiedy interfejs jest włączony (`enabled='1'`):**

OpenWrt netifd **automatycznie** wywołuje protokół handler:
```bash
proto_atc_setup "$interface"
```

**Sekwencja automatycznych działań** (files/lib/netifd/proto/atc.sh:404-492):

1. **Walidacja konfiguracji** (:422-427)
   - Sprawdzenie urządzenia `/dev/ttyUSB3`
   - Walidacja APN, parametrów połączenia
   - Weryfikacja typów autoryzacji

2. **Oczekiwanie na modem** (:436-439)
   ```bash
   check_modem_ready()  # Max 10 prób, 2s odstęp
   ```

3. **Odblokowanie FCC** (jeśli włączone) (:454-460)
   ```bash
   perform_fcc_unlock()  # AT+GTFCCLOCK=0
   ```

4. **Konfiguracja pasm** (jeśli włączona) (:463-472)
   ```bash
   apply_band_locking()  # AT+QNWPREFCFG commands
   ```

5. **Konfiguracja modemu** (:474-479)
   - Ustawienie APN: `AT+CGDCONT=1,"IP","apn"`
   - Autoryzacja: `AT$QCPDPP=1,type,pass,user`
   - Tryb sieci: `AT+CNMP=2|38|109`

6. **Nawiązanie połączenia** (:481-486)
   - Aktywacja kontekstu PDP: `AT+CGACT=1,1`
   - Start połączenia danych: `AT$QCRMCALL=1,1`

### Podsumowanie: Kiedy połączenie jest nawiązywane?

| Warunek | Czy nawiązuje połączenie? |
|---------|---------------------------|
| Po instalacji pakietu | ❌ NIE |
| Po uruchomieniu usługi init.d | ❌ NIE |
| Z domyślną konfiguracją (enabled='0') | ❌ NIE |
| Po włączeniu interfejsu (enabled='1') | ✅ TAK - automatycznie przy reload network |
| Po restarcie routera (jeśli enabled='1') | ✅ TAK - automatycznie przy starcie systemu |

---

## 2. CZY INSTALOWANE SĄ ODPOWIEDNIE PROTOKOŁY ATC?

### ✅ TAK - instalowany jest dedykowany protokół handler dla FM350-GL

### Czym jest protokół "ATC"?

**UWAGA:** To **NIE jest** standardowy protokół sieciowy (jak PPP, DHCP, czy QMI).

**"ATC"** to:
- Nazwa customowego **protocol handlera** dla OpenWrt netifd
- Handler komunikujący się z modemem przez **komendy AT**
- Dedykowany dla modemu **Fibocom FM350-GL**

### Gdzie jest instalowany protokół?

```bash
/lib/netifd/proto/atc.sh
```

Lokalizacja źródłowa: `files/lib/netifd/proto/atc.sh`

### Integracja z netifd (OpenWrt network daemon)

```bash
# Ostatnia linia pliku atc.sh:511
add_protocol atc
```

**Co robi `add_protocol atc`:**
1. Rejestruje nowy typ protokołu "atc" w netifd
2. Eksportuje funkcje: `proto_atc_init_config()`, `proto_atc_setup()`, `proto_atc_teardown()`
3. Po rejestracji można tworzyć interfejsy typu "proto='atc'"

### Jak działa protokół handler?

#### Funkcja 1: Inicjalizacja konfiguracji (`proto_atc_init_config`)

Definiuje wszystkie opcje konfiguracyjne (:12-36):
```bash
proto_config_add_string "device:device"    # /dev/ttyUSB3
proto_config_add_string "apn"              # internet, plus, orange.pl
proto_config_add_string "username"         # użytkownik APN
proto_config_add_string "password"         # hasło APN
proto_config_add_string "auth"             # 0=NONE, 1=PAP, 2=CHAP, 3=PAP/CHAP
proto_config_add_string "pdp"              # IP, IPV6, IPV4V6
proto_config_add_boolean "fcc_unlock"      # odblokowanie FCC
proto_config_add_boolean "band_locking"    # blokowanie pasm
proto_config_add_string "lte_bands"        # np. "3,7,20"
proto_config_add_string "nr5g_sa_bands"    # np. "78"
proto_config_add_string "nr5g_nsa_bands"   # np. "78"
# ... i więcej opcji
```

#### Funkcja 2: Nawiązywanie połączenia (`proto_atc_setup`)

**Główna funkcja wykonywana przez netifd** (:404-493):

```bash
proto_atc_setup() {
    local interface="$1"

    # 1. Wczytanie konfiguracji z UCI
    json_get_vars device apn username password auth pdp delay ...

    # 2. Walidacja wszystkich parametrów
    validate_config || exit 1

    # 3. Czekanie na gotowość modemu
    check_modem_ready || exit 1

    # 4. Odblokowanie FCC (dla FM350-GL)
    perform_fcc_unlock

    # 5. Konfiguracja pasm (specyficzne dla FM350-GL)
    apply_band_locking "$lte_bands" "$nr5g_sa_bands" "$nr5g_nsa_bands"

    # 6. Konfiguracja modemu (komendy AT)
    configure_modem  # APN, auth, preferred mode

    # 7. Start połączenia
    start_connection  # AT+CGACT, AT$QCRMCALL

    # 8. Powiadomienie netifd o sukcesie
    proto_init_update "$interface" 1
    proto_send_update "$interface"
}
```

#### Funkcja 3: Rozłączanie (`proto_atc_teardown`)

Wywoływana przy zatrzymywaniu interfejsu (:495-509):
```bash
proto_atc_teardown() {
    at_command "AT\$QCRMCALL=0,1"  # Stop data call
    at_command "AT+CGACT=0,1"      # Deactivate PDP context
    proto_kill_command "$interface"
}
```

### Komendy AT specyficzne dla FM350-GL

Protokół używa komend AT **dedykowanych dla Fibocom FM350-GL**:

| Komenda AT | Cel | Lokalizacja w kodzie |
|------------|-----|----------------------|
| `AT+GTFCCLOCK?` | Sprawdzenie blokady FCC | :233 |
| `AT+GTFCCLOCK=0` | Odblokowanie FCC | :241 |
| `AT+QNWPREFCFG="lte_band",<bands>` | Blokowanie pasm LTE | :294 |
| `AT+QNWPREFCFG="nr5g_band",<bands>` | Blokowanie pasm 5G SA | :308 |
| `AT+QNWPREFCFG="nsa_nr5g_band",<bands>` | Blokowanie pasm 5G NSA | :322 |
| `AT+QENG="servingcell"` | Informacje o aktualnej komórce | :340 |
| `AT+CGDCONT=1,"IP","apn"` | Ustawienie APN | :355 |
| `AT$QCPDPP=1,auth,pass,user` | Ustawienie autoryzacji | :365 |
| `AT+CNMP=2|38|109` | Tryb sieci (auto/LTE/5G) | :374-376 |
| `AT+CGACT=1,1` | Aktywacja kontekstu PDP | :389 |
| `AT$QCRMCALL=1,1` | Start połączenia danych | :395 |

**UWAGA:** Te komendy są **specyficzne dla Fibocom** i mogą nie działać z innymi modemami!

### Czy to są "standardowe protokoły ATC"?

**NIE** - to jest **customowy wrapper** używający komend AT do komunikacji z modemem.

**Porównanie z innymi protokołami:**

| Protokół | Typ | Działanie |
|----------|-----|-----------|
| PPP | Standardowy | Bezpośrednie połączenie point-to-point przez serial |
| QMI | Standardowy Qualcomm | Protokół binarny dla chipsetów Qualcomm |
| MBIM | Standardowy | Mobile Broadband Interface Model (USB) |
| **ATC** | **Customowy** | **Shell script wysyłający komendy AT** |

**Zalety customowego rozwiązania ATC:**
- ✅ Pełna kontrola nad procesem połączenia
- ✅ Wsparcie dla unikalnych funkcji FM350-GL (FCC unlock, band locking)
- ✅ Szczegółowe logowanie każdego kroku
- ✅ Elastyczna konfiguracja przez UCI
- ✅ Integracja z LuCI web interface

**Wady:**
- ❌ Tylko dla Fibocom FM350-GL (i kompatybilnych modeli)
- ❌ Wolniejsze niż natywne protokoły (QMI, MBIM)
- ❌ Wymaga dostępu do interfejsu AT (/dev/ttyUSB*)

---

## 3. JAK SKONFIGUROWAĆ AUTOMATYCZNE POŁĄCZENIE?

### Scenariusz: Automatyczne połączenie po starcie systemu

```bash
# 1. Instalacja pakietu
opkg update
opkg install /tmp/enhanced-atc_*.ipk

# 2. Konfiguracja interfejsu
uci set enhanced_atc.wan.enabled='1'           # WŁĄCZ interfejs
uci set enhanced_atc.wan.device='/dev/ttyUSB3' # Port AT
uci set enhanced_atc.wan.apn='internet'        # APN operatora
uci set enhanced_atc.wan.delay='10'            # Opóźnienie startu (opcjonalne)

# 3. Opcjonalnie: Odblokowanie FCC
uci set enhanced_atc.general.fcc_unlock='1'

# 4. Opcjonalnie: Blokowanie pasm
uci set enhanced_atc.general.band_locking='1'
uci set enhanced_atc.wan.lte_bands='3,7,20'
uci set enhanced_atc.wan.nr5g_sa_bands='78'

# 5. Zapisanie i zastosowanie
uci commit enhanced_atc
/etc/init.d/network reload

# 6. Weryfikacja
enhanced-atc-cli status
```

**Po takiej konfiguracji:**
- ✅ Połączenie będzie nawiązywane automatycznie przy starcie systemu
- ✅ Połączenie będzie wznawiany automatycznie po utracie (retry logic)
- ✅ Nie wymaga ręcznej interwencji

### Konfiguracja z opóźnieniem startu

Jeśli modem potrzebuje czasu na inicjalizację:

```bash
uci set enhanced_atc.wan.delay='15'  # Czekaj 15s przed połączeniem
uci commit enhanced_atc
```

### Konfiguracja ponownych prób

```bash
uci set enhanced_atc.wan.max_retries='5'  # 5 prób połączenia (domyślnie 3)
uci commit enhanced_atc
```

---

## 4. SZCZEGÓŁY TECHNICZNE

### Architektura systemu

```
┌─────────────────────────────────────────────────┐
│  OpenWrt System                                  │
│                                                  │
│  ┌────────────────────────────────────────┐    │
│  │ netifd (network daemon)                 │    │
│  │  - Zarządza interfejsami sieciowymi     │    │
│  │  - Rejestruje protocol handlery         │    │
│  └────────────────┬───────────────────────┘    │
│                   │ wywołuje                    │
│  ┌────────────────▼───────────────────────┐    │
│  │ /lib/netifd/proto/atc.sh                │    │
│  │  - proto_atc_setup()                    │    │
│  │  - proto_atc_teardown()                 │    │
│  └────────────────┬───────────────────────┘    │
│                   │ wysyła komendy AT           │
│  ┌────────────────▼───────────────────────┐    │
│  │ /dev/ttyUSB3 (AT command interface)    │    │
│  └────────────────┬───────────────────────┘    │
│                   │                             │
└───────────────────┼─────────────────────────────┘
                    │ USB
┌───────────────────▼─────────────────────────────┐
│  Fibocom FM350-GL Modem                         │
│  - Przetwarza komendy AT                        │
│  - Nawiązuje połączenie komórkowe               │
│  - Zarządza pasmami LTE/5G                      │
└─────────────────────────────────────────────────┘
```

### Proces komunikacji AT

```bash
# Funkcja at_command() - files/lib/netifd/proto/atc.sh:202-227

at_command "AT+CGDCONT=1,\"IP\",\"internet\"" 15 3
    │
    ├─ Timeout: 15 sekund
    ├─ Retries: 3 próby
    │
    ├─ Konfiguracja portu:
    │   stty -F /dev/ttyUSB3 raw -echo 115200
    │
    ├─ Wysłanie komendy:
    │   printf 'AT+CGDCONT=1,"IP","internet"\r\n' > /dev/ttyUSB3
    │
    ├─ Czekanie: sleep 2
    │
    ├─ Odczyt odpowiedzi:
    │   dd if=/dev/ttyUSB3 bs=1 count=1024
    │
    └─ Parsowanie:
        - Usunięcie \r
        - Usunięcie pustych linii
        - Usunięcie echo komendy
        - Zwrot max 5 linii odpowiedzi
```

### Logowanie

**Katalog logów:** `/tmp/atc_logs/`

**Dostępne logi:**
```
DEBUG.log   - Szczegółowe informacje debug (jeśli atc_debug=1)
INFO.log    - Informacje o procesie połączenia
WARN.log    - Ostrzeżenia
ERROR.log   - Błędy
FCC.log     - Log procesu odblokowania FCC
```

**Włączenie trybu debug:**
```bash
uci set enhanced_atc.general.atc_debug='1'
uci commit enhanced_atc
/etc/init.d/network reload

# Podgląd logów na żywo
tail -f /tmp/atc_logs/DEBUG.log
```

### Uruchamianie przy starcie systemu

**Init script:** `/etc/init.d/enhanced_atc`

```bash
START=19  # Priorytet startu (wcześnie, przed network)
STOP=89   # Priorytet zatrzymania (późno, po network)
```

**Co robi init script przy starcie:**
1. Sprawdza zależności (narzędzia: stty, timeout, dd, grep, tr, logger, uci)
2. Sprawdza obecność urządzeń USB (/dev/ttyUSB*)
3. Weryfikuje obecność protocol handlera
4. Tworzy katalog logów
5. **Przeładowuje netifd** aby zarejestrować protokół

**WAŻNE:** Init script **NIE nawiązuje** połączenia - tylko rejestruje protokół!

---

## WNIOSKI

### 1. Automatyczne połączenie - NIE domyślnie

- ❌ Po instalacji pakietu połączenie NIE jest nawiązywane
- ✅ Po włączeniu interfejsu (`enabled='1'`) połączenie jest nawiązywane automatycznie
- ✅ Po restarcie systemu (jeśli enabled='1') połączenie jest wznawiany automatycznie

### 2. Instalacja protokołu ATC - TAK

- ✅ Instalowany jest customowy protocol handler dla OpenWrt netifd
- ✅ Protocol handler jest **specjalnie zaprojektowany dla FM350-GL**
- ✅ Protokół używa komend AT dedykowanych dla Fibocom
- ✅ Pełna integracja z systemem OpenWrt (UCI, LuCI, netifd)

### 3. Wymagane działania użytkownika

**Minimum:**
```bash
uci set enhanced_atc.wan.enabled='1'
uci set enhanced_atc.wan.apn='<apn-operatora>'
uci commit enhanced_atc
/etc/init.d/network reload
```

**Zalecane:**
```bash
# Konfiguracja podstawowa
uci set enhanced_atc.wan.enabled='1'
uci set enhanced_atc.wan.device='/dev/ttyUSB3'
uci set enhanced_atc.wan.apn='<apn-operatora>'
uci set enhanced_atc.wan.delay='10'

# Odblokowanie FCC
uci set enhanced_atc.general.fcc_unlock='1'

# Zaawansowane (opcjonalnie)
uci set enhanced_atc.general.atc_debug='1'       # Debug logging
uci set enhanced_atc.general.band_locking='1'    # Blokowanie pasm
uci set enhanced_atc.wan.lte_bands='3,7,20'      # Pasma LTE
uci set enhanced_atc.wan.nr5g_sa_bands='78'      # Pasma 5G

# Zastosowanie
uci commit enhanced_atc
/etc/init.d/network reload
```

### 4. Weryfikacja

```bash
# Status połączenia
enhanced-atc-cli status

# Status FCC
enhanced-atc-cli fcc-status

# Informacje o modemie
enhanced-atc-cli fw-info

# Aktualne pasma
enhanced-atc-cli bands

# Logi
tail -f /tmp/atc_logs/INFO.log
```

---

## CZĘSTO ZADAWANE PYTANIA

**Q: Czy po instalacji pakietu muszę coś jeszcze zrobić?**
A: TAK - musisz włączyć interfejs (`enabled='1'`) i skonfigurować APN.

**Q: Czy połączenie nawiąże się automatycznie po restarcie?**
A: TAK - jeśli interfejs jest włączony (`enabled='1'`).

**Q: Czy mogę używać tego z innymi modemami?**
A: NIE - protokół jest zaprojektowany specjalnie dla Fibocom FM350-GL. Komendy AT mogą nie działać z innymi modemami.

**Q: Co jeśli mój modem jest na innym porcie niż /dev/ttyUSB3?**
A: Ustaw poprawny port: `uci set enhanced_atc.wan.device='/dev/ttyUSB0'`

**Q: Czy muszę odblokować FCC?**
A: Zależy od regionu. W USA i niektórych krajach modemy mają ograniczenia FCC. W Polsce prawdopodobnie nie jest wymagane, ale nie zaszkodzi.

**Q: Jak sprawdzić czy protokół jest zainstalowany?**
A: `ls -l /lib/netifd/proto/atc.sh` i `/etc/init.d/enhanced_atc status`

**Q: Gdzie znajdę logi błędów?**
A: `/tmp/atc_logs/ERROR.log` i `/tmp/atc_logs/INFO.log`

---

## REFERENCJE

- Kod źródłowy: `/home/user/enhanced-atc-fm350/`
- Protocol handler: `files/lib/netifd/proto/atc.sh`
- Init script: `files/etc/init.d/enhanced_atc`
- Konfiguracja: `files/etc/config/enhanced_atc`
- Dokumentacja: `README.md`, `docs/INSTALLATION.md`, `docs/CONFIGURATION.md`
