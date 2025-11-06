# Analiza i Implementacja: Carrier Aggregation Info & Advanced Band Scanning

## Streszczenie Wykonawcze

Ten dokument przedstawia szczegółową analizę techniczną oraz propozycję implementacji dwóch kluczowych funkcji dla projektu Enhanced ATC FM350-GL:

1. **Carrier Aggregation Info** - wyświetlanie informacji o agregacji nośnych (CA)
2. **Advanced Band Scanning** - zaawansowane skanowanie i analiza dostępnych pasm

---

## 1. Carrier Aggregation Info

### 1.1 Co to jest Carrier Aggregation?

Carrier Aggregation (CA) to technologia w LTE-Advanced i 5G, która pozwala na łączenie wielu pasm częstotliwości (component carriers) w celu zwiększenia przepustowości i prędkości transmisji danych.

**Typy CA:**
- **Intra-band contiguous** - pasma w tym samym zakresie częstotliwości, sąsiadujące
- **Intra-band non-contiguous** - pasma w tym samym zakresie, ale nie sąsiadujące
- **Inter-band** - pasma w różnych zakresach częstotliwości

**Przykład:** Telefon może jednocześnie używać B3 (1800 MHz) + B7 (2600 MHz) = większa prędkość

### 1.2 Dostępne Komendy AT dla FM350-GL

#### 1.2.1 Komenda: AT+QENG="servingcell"

Zwraca szczegółowe informacje o aktualnej komórce obsługującej oraz komórkach sąsiednich.

**Przykładowa odpowiedź dla LTE z CA:**
```
+QENG: "servingcell","NOCONN"
+QENG: "LTE","FDD",260,01,1234567,123,2300,3,5,5,-95,-10,-65,15
+QENG: "SCC",260,01,1234568,123,2600,3,-95,-10,-65,15,78
+QENG: "SCC",260,01,1234569,123,1800,3,-92,-8,-62,14,77

OK
```

**Interpretacja:**
- Pierwsza linia: Primary Component Carrier (PCC) na paśmie 3 (2300 MHz)
- Druga linia: Secondary Component Carrier (SCC) na paśmie 7 (2600 MHz)
- Trzecia linia: Secondary Component Carrier (SCC) na paśmie 3 (1800 MHz)
- **Agregacja:** 3CA (3 component carriers jednocześnie)

#### 1.2.2 Komenda: AT+QCAINFO

Bezpośrednia informacja o Carrier Aggregation (jeśli wspierana przez modem).

**Przykładowa odpowiedź:**
```
+QCAINFO: "PCC",2300,"LTE BAND 3",1,380,-95,-10,-65,15
+QCAINFO: "SCC1",2600,"LTE BAND 7",1,100,-95,-10,-65,15
+QCAINFO: "SCC2",1800,"LTE BAND 3",1,75,-92,-8,-62,14

OK
```

#### 1.2.3 Komenda: AT+QNWINFO

Informacje o aktualnej sieci.

**Przykładowa odpowiedź:**
```
+QNWINFO: "FDD LTE","26001","LTE BAND 3",2300
```

### 1.3 Parsowanie i Wyświetlanie Danych CA

#### Struktura danych do wyświetlenia:

```bash
=== Carrier Aggregation Status ===

Status: ACTIVE (3CA)
Technology: LTE-Advanced

Primary Component Carrier (PCC):
  Band: B3 (1800 MHz)
  Bandwidth: 20 MHz
  EARFCN: 1234567
  RSRP: -95 dBm
  RSRQ: -10 dB
  SINR: 15 dB

Secondary Component Carrier 1 (SCC1):
  Band: B7 (2600 MHz)
  Bandwidth: 10 MHz
  EARFCN: 1234568
  RSRP: -95 dBm
  RSRQ: -10 dB
  SINR: 15 dB

Secondary Component Carrier 2 (SCC2):
  Band: B3 (1800 MHz)
  Bandwidth: 10 MHz
  EARFCN: 1234569
  RSRP: -92 dBm
  RSRQ: -8 dB
  SINR: 14 dB

Total Aggregated Bandwidth: 40 MHz
Estimated Max Throughput: ~320 Mbps (DL)
CA Combination: B3+B7+B3
```

### 1.4 Implementacja w CLI

#### Dodanie komendy `ca-info` do enhanced-atc-cli:

```bash
ca_info() {
    local device=$(get_device)
    log_info "Retrieving Carrier Aggregation info from $device..."

    if [ ! -c "$device" ]; then
        log_error "Device $device not found"
        return 1
    fi

    echo "=== Carrier Aggregation Status ==="
    echo ""

    # Method 1: Try AT+QCAINFO (direct CA info)
    response=$(timeout 5 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+QCAINFO\r\n' > $device
        sleep 1
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$' | grep -E "QCAINFO|OK|ERROR")

    if echo "$response" | grep -q "QCAINFO"; then
        parse_qcainfo "$response"
        return 0
    fi

    # Method 2: Fallback to AT+QENG="servingcell"
    response=$(timeout 5 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+QENG=\"servingcell\"\r\n' > $device
        sleep 1
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$' | grep -E "QENG|OK")

    if echo "$response" | grep -q "QENG"; then
        parse_qeng_ca "$response"
    else
        echo "Status: No CA information available"
        echo "Possible reasons:"
        echo "  - Not connected to LTE/5G network"
        echo "  - Carrier Aggregation not active"
        echo "  - Modem does not support CA info commands"
    fi
}

parse_qcainfo() {
    local data="$1"
    local pcc_count=0
    local scc_count=0
    local total_bw=0

    echo "$data" | while IFS= read -r line; do
        if echo "$line" | grep -q "PCC"; then
            pcc_count=$((pcc_count + 1))
            parse_ca_component "Primary Component Carrier (PCC)" "$line"
        elif echo "$line" | grep -q "SCC"; then
            scc_count=$((scc_count + 1))
            parse_ca_component "Secondary Component Carrier (SCC$scc_count)" "$line"
        fi
    done

    local total_carriers=$((pcc_count + scc_count))
    if [ $total_carriers -gt 1 ]; then
        echo ""
        echo "Status: ACTIVE (${total_carriers}CA)"
        echo "Technology: LTE-Advanced"
    else
        echo "Status: No Carrier Aggregation (single carrier)"
    fi
}

parse_ca_component() {
    local name="$1"
    local data="$2"

    # Parse fields from QCAINFO response
    # Format: +QCAINFO: "PCC",freq,"band_name",bw,earfcn,rsrp,rsrq,rssi,sinr

    local freq=$(echo "$data" | cut -d',' -f2)
    local band=$(echo "$data" | cut -d',' -f3 | tr -d '"')
    local bw=$(echo "$data" | cut -d',' -f4)
    local rsrp=$(echo "$data" | cut -d',' -f6)
    local rsrq=$(echo "$data" | cut -d',' -f7)
    local sinr=$(echo "$data" | cut -d',' -f9)

    echo ""
    echo "$name:"
    echo "  Band: $band"
    echo "  Frequency: $freq MHz"
    echo "  Bandwidth: $bw MHz"
    echo "  RSRP: $rsrp dBm"
    echo "  RSRQ: $rsrq dB"
    echo "  SINR: $sinr dB"
}

parse_qeng_ca() {
    local data="$1"
    local pcc_line=$(echo "$data" | grep "QENG.*LTE" | grep -v "SCC" | head -1)
    local scc_lines=$(echo "$data" | grep "QENG.*SCC")

    if [ -n "$pcc_line" ]; then
        echo "Primary Component Carrier (PCC):"
        parse_qeng_line "$pcc_line"
    fi

    if [ -n "$scc_lines" ]; then
        local scc_num=1
        echo "$scc_lines" | while IFS= read -r line; do
            echo ""
            echo "Secondary Component Carrier (SCC$scc_num):"
            parse_qeng_line "$line"
            scc_num=$((scc_num + 1))
        done

        local scc_count=$(echo "$scc_lines" | wc -l)
        local total=$((scc_count + 1))
        echo ""
        echo "Status: ACTIVE (${total}CA)"
        echo "Technology: LTE-Advanced"
    else
        echo ""
        echo "Status: No Carrier Aggregation detected"
    fi
}

parse_qeng_line() {
    local line="$1"
    # Extract relevant fields from QENG servingcell output
    # This is a simplified parser - actual implementation would be more robust
    echo "  $(echo "$line" | cut -d',' -f5-10)"
}
```

#### Użycie:

```bash
enhanced-atc-cli ca-info
```

---

## 2. Advanced Band Scanning

### 2.1 Cel funkcjonalności

Advanced Band Scanning pozwala na:
- Skanowanie wszystkich dostępnych pasm w otoczeniu
- Wykrywanie siły sygnału dla każdego pasma
- Identyfikację najlepszych pasm do połączenia
- Pomoc w optymalizacji konfiguracji band locking

### 2.2 Dostępne Komendy AT

#### 2.2.1 Komenda: AT+QSCAN

Wykonuje skanowanie sieci (jeśli wspierane).

**Składnia:**
```
AT+QSCAN=<mode>,<interval>
```

#### 2.2.2 Komenda: AT+COPS=?

Skanuje dostępne sieci operatorów (może trwać długo - do 3 minut).

**Przykładowa odpowiedź:**
```
+COPS: (2,"Play","Play","26006",7),(1,"Orange","Orange","26003",7),(1,"Plus","Plus","26001",7),(1,"T-Mobile","T-Mobile","26002",7)
```

#### 2.2.3 Komenda: AT+QENG="neighbourcell"

Wyświetla informacje o komórkach sąsiednich (wszystkich wykrytych pasmach).

**Przykładowa odpowiedź:**
```
+QENG: "neighbourcell intra","LTE",2300,123,-95,-12,0,5,2,6
+QENG: "neighbourcell intra","LTE",2600,123,-98,-14,0,3,1,4
+QENG: "neighbourcell inter","LTE",1800,456,-102,-16,0,7,3,8
+QENG: "neighbourcell inter","LTE",800,789,-88,-10,0,20,5,12

OK
```

### 2.3 Implementacja Band Scanning

#### Strategia skanowania:

1. **Quick Scan (szybkie)** - tylko komórki sąsiednie (~5 sekund)
2. **Medium Scan (średnie)** - komórki sąsiednie + serving cell (~10 sekund)
3. **Full Scan (pełne)** - pełne skanowanie sieci (~180 sekund)

#### Implementacja w CLI:

```bash
band_scan() {
    local device=$(get_device)
    local scan_mode="${1:-quick}"  # quick, medium, full

    log_info "Starting band scan ($scan_mode mode) on $device..."

    if [ ! -c "$device" ]; then
        log_error "Device $device not found"
        return 1
    fi

    case "$scan_mode" in
        quick)
            scan_quick "$device"
            ;;
        medium)
            scan_medium "$device"
            ;;
        full)
            scan_full "$device"
            ;;
        *)
            echo "Unknown scan mode: $scan_mode"
            echo "Usage: enhanced-atc-cli scan [quick|medium|full]"
            return 1
            ;;
    esac
}

scan_quick() {
    local device="$1"

    echo "=== Quick Band Scan ==="
    echo "Scanning neighbour cells (this may take 5-10 seconds)..."
    echo ""

    response=$(timeout 15 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+QENG=\"neighbourcell\"\r\n' > $device
        sleep 3
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$' | grep "QENG")

    if [ -z "$response" ]; then
        echo "No neighbour cells detected"
        return 1
    fi

    parse_neighbour_cells "$response"
}

scan_medium() {
    local device="$1"

    echo "=== Medium Band Scan ==="
    echo "Scanning serving and neighbour cells..."
    echo ""

    # First get serving cell
    echo "Current Connection:"
    response=$(timeout 10 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+QENG=\"servingcell\"\r\n' > $device
        sleep 2
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$' | grep "QENG")

    if [ -n "$response" ]; then
        parse_serving_cell "$response"
    fi

    echo ""
    echo "Detected Bands in Area:"

    # Then get neighbour cells
    response=$(timeout 15 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+QENG=\"neighbourcell\"\r\n' > $device
        sleep 3
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$' | grep "QENG")

    if [ -n "$response" ]; then
        parse_neighbour_cells "$response"
    fi
}

scan_full() {
    local device="$1"

    echo "=== Full Network Scan ==="
    echo "WARNING: This scan will disconnect your modem and may take up to 3 minutes!"
    echo -n "Continue? (y/N): "
    read -r confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Scan cancelled"
        return 0
    fi

    echo ""
    echo "Scanning all available networks (this will take 1-3 minutes)..."

    response=$(timeout 200 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+COPS=?\r\n' > $device
        sleep 180
        cat $device 2>/dev/null
    " | tr -d '\r' | grep -v '^$')

    if echo "$response" | grep -q "COPS"; then
        echo ""
        echo "Available Networks:"
        parse_cops_response "$response"
    else
        echo "Network scan failed or timed out"
        return 1
    fi

    # Reconnect to automatic network
    echo ""
    echo "Reconnecting to network (automatic mode)..."
    timeout 30 sh -c "
        stty -F $device raw -echo 115200 2>/dev/null
        printf 'AT+COPS=0\r\n' > $device
        sleep 10
        cat $device 2>/dev/null
    " >/dev/null 2>&1

    echo "Scan complete. Your modem should reconnect automatically."
}

parse_neighbour_cells() {
    local data="$1"

    echo "Band | Type  | EARFCN | RSRP    | RSRQ   | Quality"
    echo "-----|-------|--------|---------|--------|--------"

    echo "$data" | while IFS= read -r line; do
        if echo "$line" | grep -q "neighbourcell"; then
            # Parse QENG neighbourcell format
            # Format: +QENG: "neighbourcell <type>","LTE",<earfcn>,<pcid>,<rsrp>,<rsrq>,...

            local tech=$(echo "$line" | cut -d',' -f2 | tr -d '"')
            local earfcn=$(echo "$line" | cut -d',' -f3)
            local rsrp=$(echo "$line" | cut -d',' -f5)
            local rsrq=$(echo "$line" | cut -d',' -f6)

            # Convert EARFCN to band (simplified - would need full lookup table)
            local band=$(earfcn_to_band "$earfcn")

            # Determine quality based on RSRP
            local quality="Poor"
            if [ "$rsrp" -gt -90 ]; then
                quality="Excellent"
            elif [ "$rsrp" -gt -100 ]; then
                quality="Good"
            elif [ "$rsrp" -gt -110 ]; then
                quality="Fair"
            fi

            printf "%-4s | %-5s | %-6s | %-7s | %-6s | %s\n" \
                "$band" "$tech" "$earfcn" "${rsrp} dBm" "${rsrq} dB" "$quality"
        fi
    done
}

parse_serving_cell() {
    local data="$1"
    local line=$(echo "$data" | grep "LTE\|NR5G" | grep -v "neighbour" | head -1)

    if [ -n "$line" ]; then
        local tech=$(echo "$line" | cut -d',' -f2 | tr -d '"')
        local band=$(echo "$line" | cut -d',' -f5)
        local rsrp=$(echo "$line" | awk -F',' '{print $(NF-3)}')
        local rsrq=$(echo "$line" | awk -F',' '{print $(NF-2)}')

        echo "  Technology: $tech"
        echo "  Band: B$band"
        echo "  Signal Strength (RSRP): $rsrp dBm"
        echo "  Signal Quality (RSRQ): $rsrq dB"
    fi
}

parse_cops_response() {
    local data="$1"

    echo "Operator     | Status      | Technology"
    echo "-------------|-------------|------------"

    # Parse COPS response
    # Format: (stat,"long","short","numeric",act)
    echo "$data" | grep -o '([^)]*)'  | while IFS= read -r entry; do
        local stat=$(echo "$entry" | cut -d',' -f1 | tr -d '(')
        local name=$(echo "$entry" | cut -d',' -f2 | tr -d '"')
        local numeric=$(echo "$entry" | cut -d',' -f4 | tr -d '"')
        local act=$(echo "$entry" | cut -d',' -f5 | tr -d ')')

        local status="Unknown"
        case "$stat" in
            0) status="Unknown" ;;
            1) status="Available" ;;
            2) status="Current" ;;
            3) status="Forbidden" ;;
        esac

        local tech="Unknown"
        case "$act" in
            0) tech="2G (GSM)" ;;
            2) tech="3G (UMTS)" ;;
            7) tech="4G (LTE)" ;;
            12) tech="5G (NR)" ;;
        esac

        printf "%-12s | %-11s | %s\n" "$name" "$status" "$tech"
    done
}

earfcn_to_band() {
    local earfcn="$1"

    # Simplified EARFCN to band mapping
    # This is a basic implementation - production would need full lookup table

    if [ "$earfcn" -ge 0 ] && [ "$earfcn" -le 599 ]; then
        echo "B1"
    elif [ "$earfcn" -ge 600 ] && [ "$earfcn" -le 1199 ]; then
        echo "B2"
    elif [ "$earfcn" -ge 1200 ] && [ "$earfcn" -le 1949 ]; then
        echo "B3"
    elif [ "$earfcn" -ge 1950 ] && [ "$earfcn" -le 2399 ]; then
        echo "B4"
    elif [ "$earfcn" -ge 2400 ] && [ "$earfcn" -le 2649 ]; then
        echo "B5"
    elif [ "$earfcn" -ge 2650 ] && [ "$earfcn" -le 2749 ]; then
        echo "B6"
    elif [ "$earfcn" -ge 2750 ] && [ "$earfcn" -le 3449 ]; then
        echo "B7"
    elif [ "$earfcn" -ge 3450 ] && [ "$earfcn" -le 3799 ]; then
        echo "B8"
    elif [ "$earfcn" -ge 5010 ] && [ "$earfcn" -le 5179 ]; then
        echo "B12"
    elif [ "$earfcn" -ge 5730 ] && [ "$earfcn" -le 5849 ]; then
        echo "B13"
    elif [ "$earfcn" -ge 5850 ] && [ "$earfcn" -le 5999 ]; then
        echo "B14"
    elif [ "$earfcn" -ge 6000 ] && [ "$earfcn" -le 6149 ]; then
        echo "B17"
    elif [ "$earfcn" -ge 6150 ] && [ "$earfcn" -le 6449 ]; then
        echo "B20"
    else
        echo "B?"
    fi
}
```

#### Użycie:

```bash
# Quick scan (tylko komórki sąsiednie)
enhanced-atc-cli scan quick

# Medium scan (serving + neighbour cells)
enhanced-atc-cli scan medium

# Full scan (wszystkie sieci - rozłącza modem!)
enhanced-atc-cli scan full
```

---

## 3. Integracja z LuCI

### 3.1 Nowa zakładka: "Status & Diagnostics"

Dodanie nowej sekcji w LuCI do wyświetlania:
- Carrier Aggregation status
- Band scan results
- Real-time signal monitoring

### 3.2 Controller Actions (enhanced_atc.lua)

```lua
function action_ca_status()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"

    local result = sys.exec("enhanced-atc-cli ca-info 2>&1")

    local ca_active = result:match("ACTIVE") ~= nil
    local ca_type = result:match("(%dCA)") or "No CA"

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        active = ca_active,
        type = ca_type,
        details = result
    })
end

function action_band_scan()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"
    local http = require "luci.http"

    local mode = http.formvalue("mode") or "quick"

    -- Perform scan (this may take time)
    local result = sys.exec("enhanced-atc-cli scan " .. mode .. " 2>&1")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        mode = mode,
        results = result
    })
end
```

### 3.3 UI Template (status view)

```html
<div class="cbi-section">
    <h3>Carrier Aggregation Status</h3>
    <div id="ca-status" class="cbi-value">
        <button onclick="refreshCAStatus()">Refresh CA Status</button>
        <pre id="ca-output" style="background:#f5f5f5; padding:10px; margin-top:10px;">
Loading...
        </pre>
    </div>
</div>

<div class="cbi-section">
    <h3>Band Scanner</h3>
    <div class="cbi-value">
        <select id="scan-mode">
            <option value="quick">Quick Scan (5-10s)</option>
            <option value="medium">Medium Scan (10-20s)</option>
            <option value="full">Full Scan (1-3min, disconnects!)</option>
        </select>
        <button onclick="startBandScan()">Start Scan</button>
        <pre id="scan-output" style="background:#f5f5f5; padding:10px; margin-top:10px;">
Ready to scan...
        </pre>
    </div>
</div>

<script>
function refreshCAStatus() {
    document.getElementById('ca-output').innerText = 'Loading...';

    XHR.get('/admin/network/enhanced_atc/ca_status', null,
        function(xhr, data) {
            if (data && data.details) {
                document.getElementById('ca-output').innerText = data.details;
            } else {
                document.getElementById('ca-output').innerText = 'Error retrieving CA status';
            }
        }
    );
}

function startBandScan() {
    var mode = document.getElementById('scan-mode').value;
    var output = document.getElementById('scan-output');

    if (mode === 'full') {
        if (!confirm('Full scan will disconnect your modem for 1-3 minutes. Continue?')) {
            return;
        }
    }

    output.innerText = 'Scanning... (this may take a while)';

    XHR.post('/admin/network/enhanced_atc/band_scan', {mode: mode},
        function(xhr, data) {
            if (data && data.results) {
                output.innerText = data.results;
            } else {
                output.innerText = 'Scan failed or timed out';
            }
        }
    );
}

// Auto-refresh CA status every 30 seconds
setInterval(refreshCAStatus, 30000);

// Initial load
refreshCAStatus();
</script>
```

---

## 4. Integracja z Protocol Handler (atc.sh)

### 4.1 Dodanie funkcji do atc.sh

```bash
# Get Carrier Aggregation info
get_ca_info() {
    log_info "Retrieving Carrier Aggregation information..."

    # Try AT+QCAINFO first
    local ca_info=$(at_command "AT+QCAINFO" 10 2 1)

    if echo "$ca_info" | grep -q "QCAINFO"; then
        local ca_count=$(echo "$ca_info" | grep -c "QCAINFO")
        log_info "Carrier Aggregation ACTIVE - ${ca_count} component carriers"
        return 0
    fi

    # Fallback to AT+QENG
    local serving=$(at_command "AT+QENG=\"servingcell\"" 10 2 1)

    if echo "$serving" | grep -q "SCC"; then
        local scc_count=$(echo "$serving" | grep -c "SCC")
        local total=$((scc_count + 1))
        log_info "Carrier Aggregation ACTIVE - ${total}CA detected"
        return 0
    fi

    log_info "Carrier Aggregation: Not active (single carrier)"
    return 1
}

# Monitor and log CA status during connection
monitor_ca_status() {
    local monitor_enabled="${1:-0}"

    if [ "$monitor_enabled" != "1" ]; then
        return 0
    fi

    log_info "Starting Carrier Aggregation monitoring..."

    # Check CA status every 60 seconds (in background)
    while true; do
        get_ca_info
        sleep 60
    done &
}
```

### 4.2 Dodanie do proto_atc_setup

```bash
proto_atc_setup() {
    local interface="$1"
    json_get_vars device apn username password ... ca_monitoring

    # ... existing setup code ...

    # After successful connection, check CA status
    if [ "$ca_monitoring" = "1" ]; then
        log_info "Checking Carrier Aggregation status..."
        get_ca_info
        monitor_ca_status "$ca_monitoring"
    fi

    # ... rest of setup ...
}
```

---

## 5. Konfiguracja UCI

### 5.1 Dodanie opcji do /etc/config/enhanced_atc

```
config general 'general'
    option fcc_unlock '1'
    option firmware_check '1'
    option atc_debug '0'
    option ca_monitoring '0'          # NEW: Monitor CA status
    option ca_log '0'                 # NEW: Log CA changes

config diagnostics 'diagnostics'     # NEW SECTION
    option ca_check_interval '60'    # Check CA every 60s
    option band_scan_startup '0'     # Perform band scan on startup
    option scan_mode 'quick'         # Default scan mode
```

### 5.2 Dodanie do proto_atc_init_config

```bash
proto_atc_init_config() {
    # ... existing config ...
    proto_config_add_boolean "ca_monitoring"
    proto_config_add_boolean "ca_log"
    proto_config_add_int "ca_check_interval"
}
```

---

## 6. Rozbudowa CLI - Pełna Lista Komend

Po implementacji, enhanced-atc-cli będzie miał następujące komendy:

```bash
# Existing commands
enhanced-atc-cli status
enhanced-atc-cli fcc-status
enhanced-atc-cli fcc-unlock
enhanced-atc-cli fw-info
enhanced-atc-cli bands
enhanced-atc-cli band-lock --lte X --5g Y
enhanced-atc-cli band-unlock

# NEW: Carrier Aggregation commands
enhanced-atc-cli ca-info              # Show CA status
enhanced-atc-cli ca-monitor           # Continuous CA monitoring

# NEW: Band scanning commands
enhanced-atc-cli scan quick           # Quick neighbour scan (5-10s)
enhanced-atc-cli scan medium          # Medium scan (10-20s)
enhanced-atc-cli scan full            # Full network scan (1-3min)
enhanced-atc-cli scan-auto            # Auto-detect best bands
```

---

## 7. Roadmap Implementacji

### Faza 1: Carrier Aggregation Info (Priorytet: Wysoki)
**Czas: 2-3 dni**

- [ ] Implementacja funkcji `ca_info()` w CLI
- [ ] Parsowanie odpowiedzi AT+QCAINFO i AT+QENG
- [ ] Dodanie komendy `ca-info` do enhanced-atc-cli
- [ ] Testy na FM350-GL z różnymi operatorami
- [ ] Dokumentacja użytkowania

### Faza 2: Advanced Band Scanning (Priorytet: Średni)
**Czas: 3-4 dni**

- [ ] Implementacja `scan_quick()`, `scan_medium()`, `scan_full()`
- [ ] Parsowanie komórek sąsiednich
- [ ] Implementacja konwersji EARFCN → Band
- [ ] Dodanie formatowania wyników (tabele)
- [ ] Testy z różnymi operatorami
- [ ] Dokumentacja użytkowania

### Faza 3: Integracja LuCI (Priorytet: Średni)
**Czas: 2-3 dni**

- [ ] Dodanie zakładki "Status & Diagnostics"
- [ ] Implementacja AJAX calls dla CA status
- [ ] Dodanie UI dla band scanning
- [ ] Real-time monitoring display
- [ ] Auto-refresh functionality
- [ ] Responsywny design

### Faza 4: Protocol Handler Integration (Priorytet: Niski)
**Czas: 1-2 dni**

- [ ] Dodanie `get_ca_info()` do atc.sh
- [ ] Background CA monitoring
- [ ] Logging CA changes
- [ ] UCI config rozszerzenie

### Faza 5: Optymalizacja & Testowanie (Priorytet: Wysoki)
**Czas: 2-3 dni**

- [ ] Testy wydajnościowe
- [ ] Optymalizacja parsowania
- [ ] Error handling
- [ ] Edge cases testing
- [ ] Multi-operator testing (Play, Orange, Plus, T-Mobile)

### Faza 6: Dokumentacja (Priorytet: Średni)
**Czas: 1-2 dni**

- [ ] User manual update
- [ ] API documentation
- [ ] Troubleshooting guide
- [ ] Examples dla różnych scenariuszy

---

## 8. Przykłady Użycia

### 8.1 Sprawdzenie Carrier Aggregation

```bash
# Via CLI
enhanced-atc-cli ca-info

# Output:
=== Carrier Aggregation Status ===

Status: ACTIVE (3CA)
Technology: LTE-Advanced

Primary Component Carrier (PCC):
  Band: B3 (1800 MHz)
  Bandwidth: 20 MHz
  RSRP: -85 dBm
  RSRQ: -8 dB
  SINR: 18 dB

Secondary Component Carrier 1 (SCC1):
  Band: B7 (2600 MHz)
  Bandwidth: 10 MHz
  RSRP: -90 dBm
  RSRQ: -10 dB
  SINR: 15 dB

Secondary Component Carrier 2 (SCC2):
  Band: B20 (800 MHz)
  Bandwidth: 10 MHz
  RSRP: -78 dBm
  RSRQ: -7 dB
  SINR: 20 dB

Total Aggregated Bandwidth: 40 MHz
CA Combination: B3(20)+B7(10)+B20(10)
```

### 8.2 Szybkie skanowanie pasm

```bash
enhanced-atc-cli scan quick

# Output:
=== Quick Band Scan ===
Scanning neighbour cells (this may take 5-10 seconds)...

Band | Type  | EARFCN | RSRP    | RSRQ   | Quality
-----|-------|--------|---------|--------|--------
B3   | LTE   | 1300   | -85 dBm | -8 dB  | Excellent
B7   | LTE   | 2850   | -90 dBm | -10 dB | Good
B20  | LTE   | 6300   | -78 dBm | -7 dB  | Excellent
B1   | LTE   | 300    | -105 dBm| -15 dB | Fair

Recommendation: B20 has the best signal quality
```

### 8.3 Optymalizacja konfiguracji

```bash
# 1. Wykonaj scan
enhanced-atc-cli scan medium

# 2. Wybierz najlepsze pasma z wyniku
# 3. Zastosuj band locking
enhanced-atc-cli band-lock --lte 3,7,20 --5g 78

# 4. Sprawdź CA status
enhanced-atc-cli ca-info
```

---

## 9. Potencjalne Problemy i Rozwiązania

### 9.1 Problem: Modem nie wspiera AT+QCAINFO

**Rozwiązanie:**
- Fallback do AT+QENG="servingcell"
- Parsowanie SCC entries z odpowiedzi

### 9.2 Problem: Skanowanie zajmuje za długo

**Rozwiązanie:**
- Dodanie timeout'ów
- Implementacja trzech trybów (quick/medium/full)
- Background processing dla full scan

### 9.3 Problem: Nieprawidłowe parsowanie odpowiedzi AT

**Rozwiązanie:**
- Robust error handling
- Validation wszystkich parsed fields
- Fallback values dla missing data

### 9.4 Problem: CA nie jest aktywne w danym momencie

**Rozwiązanie:**
- Wyraźna informacja o braku CA
- Wskazówki optymalizacji (np. band locking)
- Monitoring mode z auto-refresh

---

## 10. Testy Akceptacyjne

### Test 1: CA Info - Single Carrier
```
WHEN: Modem połączony do sieci bez CA
THEN: Status powinien wyświetlać "No Carrier Aggregation (single carrier)"
```

### Test 2: CA Info - 2CA Active
```
WHEN: Modem używa 2 component carriers
THEN: Status powinien wyświetlać "ACTIVE (2CA)" z detalami PCC i SCC1
```

### Test 3: Band Scan - Quick Mode
```
WHEN: Użytkownik uruchomi scan quick
THEN: Scan powinien zakończyć się w < 15 sekund i pokazać neighbour cells
```

### Test 4: Band Scan - Full Mode
```
WHEN: Użytkownik uruchomi scan full
THEN: Scan powinien wymagać potwierdzenia i pokazać wszystkie sieci
```

### Test 5: LuCI Integration
```
WHEN: Użytkownik otworzy zakładkę Status & Diagnostics
THEN: CA status powinien być wyświetlony i auto-odświeżany co 30s
```

---

## 11. Metryki Sukcesu

Po implementacji funkcjonalności, projekt będzie:

1. ✅ **Pełna widoczność CA** - użytkownik widzi czy CA jest aktywne i jakie pasma są używane
2. ✅ **Optymalizacja połączenia** - możliwość identyfikacji najlepszych pasm w okolicy
3. ✅ **Troubleshooting** - łatwe diagnozowanie problemów z sygnałem
4. ✅ **User-friendly** - zarówno CLI jak i GUI interface
5. ✅ **Dokumentacja** - kompletna dokumentacja z przykładami

---

## 12. Bezpieczeństwo i Ograniczenia

### Bezpieczeństwo:
- Wszystkie komendy AT są walidowane przed wysłaniem
- Timeout'y zapobiegają zawieszeniu systemu
- Full scan wymaga potwierdzenia (disconnects modem)
- Rate limiting dla częstych skanów

### Ograniczenia:
- CA info wymaga aktywnego połączenia
- Full scan rozłącza modem na 1-3 minuty
- Niektóre modemы mogą nie wspierać wszystkich komend AT
- Parsing jest specyficzny dla FM350-GL

---

## 13. Podsumowanie

Ta analiza przedstawia kompletny plan implementacji dwóch kluczowych funkcji:

1. **Carrier Aggregation Info** - pełna widoczność agregacji nośnych z detalami każdego component carrier
2. **Advanced Band Scanning** - zaawansowane skanowanie z trzema trybami (quick/medium/full)

Implementacja będzie:
- Kompatybilna z istniejącą strukturą projektu
- Dostępna zarówno przez CLI jak i LuCI
- Dobrze udokumentowana
- Przetestowana z różnymi operatorami
- Zgodna z filozofią projektu (FM350-GL specific features)

**Następne kroki:**
1. Review i akceptacja propozycji
2. Rozpoczęcie implementacji według roadmap'y
3. Iteracyjne testowanie z każdą fazą
4. Finalna dokumentacja i release
