# Band Locking Implementation Analysis

## Research Summary

### Existing Solutions in OpenWrt

#### 1. luci-app-modemband (4IceG)
**GitHub:** https://github.com/4IceG/luci-app-modemband

**Features:**
- GUI for band selection (LTE, 5G SA, 5G NSA)
- Works with sms-tool package
- Supports multiple modem types
- LuCI JS interface
- Requires OpenWrt >= 21.02

**Limitations:**
- Not compatible with ModemManager
- Requires separate modemband package
- Generic approach (not modem-specific optimization)

#### 2. Commercial Solutions (Goldenorb, TAKTIKAL)
- Band locking through custom OpenWrt interfaces
- Proprietary implementations
- Focus on user-friendly band selection

### Fibocom FM350-GL Band Support

#### LTE Bands (4G):
- **FDD-LTE:** B1, B2, B3, B4, B5, B7, B8, B12, B13, B14, B17, B18, B19, B20, B25, B26, B28, B29, B30, B32, B66, B71
- **TDD-LTE:** B34, B38, B39, B40, B41, B42, B43, B48

#### 5G NR Bands:
- **Sub-6 GHz:** n1, n2, n3, n5, n7, n8, n12, n13, n14, n18, n20, n25, n26, n28, n29, n30, n38, n40, n41, n48, n66, n70, n71, n77, n78, n79

### AT Commands for FM350-GL

Based on Fibocom FM350 AT Commands Manual:

#### Band Configuration Commands:

##### 1. Read Current Band Configuration
```
AT+QNWPREFCFG="lte_band"
Response: +QNWPREFCFG: "lte_band",1:2:3:4:5:7:8:12:13:14:17:18:19:20:25:26:28:29:30:32:34:38:39:40:41:42:43:48:66:71
OK

AT+QNWPREFCFG="nsa_nr5g_band"
Response: +QNWPREFCFG: "nsa_nr5g_band",1:2:3:5:7:8:12:13:14:18:20:25:26:28:29:30:38:40:41:48:66:70:71:77:78:79
OK

AT+QNWPREFCFG="nr5g_band"
Response: +QNWPREFCFG: "nr5g_band",1:2:3:5:7:8:12:13:14:18:20:25:26:28:29:30:38:40:41:48:66:70:71:77:78:79
OK
```

##### 2. Set LTE Bands
```
AT+QNWPREFCFG="lte_band",<band_list>

Example - Lock to B2, B4, B12, B66:
AT+QNWPREFCFG="lte_band",2:4:12:66
```

##### 3. Set 5G NSA Bands
```
AT+QNWPREFCFG="nsa_nr5g_band",<band_list>

Example - Lock to n2, n41, n71:
AT+QNWPREFCFG="nsa_nr5g_band",2:41:71
```

##### 4. Set 5G SA Bands
```
AT+QNWPREFCFG="nr5g_band",<band_list>

Example - Lock to n41, n77, n78:
AT+QNWPREFCFG="nr5g_band",41:77:78
```

##### 5. Reset to All Bands (Automatic)
```
AT+QNWPREFCFG="lte_band",0
AT+QNWPREFCFG="nsa_nr5g_band",0
AT+QNWPREFCFG="nr5g_band",0
```

##### 6. Network Mode Selection
```
AT+QNWPREFCFG="mode_pref",<mode>

Modes:
- AUTO (automatic selection)
- LTE (LTE only)
- NR5G (5G only)
- LTE:NR5G (LTE and 5G)
```

## Implementation Design for Enhanced ATC

### 1. Configuration Structure

Add to `/etc/config/enhanced_atc`:

```
config band_settings 'bands'
    option enabled '0'                    # Enable band locking
    option lte_bands ''                   # Comma-separated: 2,4,12,66
    option nr5g_sa_bands ''              # Comma-separated: 41,77,78
    option nr5g_nsa_bands ''             # Comma-separated: 2,41,71
    option auto_switch '0'               # Auto switch based on signal
    option preferred_band ''             # Preferred band for camping
```

### 2. Band Database

Create band information database for UI:

```lua
-- Band definitions for FM350-GL
BANDS_LTE_FDD = {
    {id=1, freq="2100 MHz", region="Europe, Asia"},
    {id=2, freq="1900 MHz", region="Americas"},
    {id=3, freq="1800 MHz", region="Europe, Asia"},
    {id=4, freq="AWS 1700/2100 MHz", region="Americas"},
    {id=5, freq="850 MHz", region="Americas, Asia"},
    {id=7, freq="2600 MHz", region="Europe, Asia"},
    {id=8, freq="900 MHz", region="Europe, Asia"},
    {id=12, freq="700 MHz", region="USA"},
    {id=13, freq="700c MHz", region="USA (Verizon)"},
    {id=14, freq="700 PS", region="USA (FirstNet)"},
    {id=17, freq="700b MHz", region="USA (AT&T)"},
    {id=20, freq="800 DD", region="Europe"},
    {id=25, freq="1900 MHz", region="USA"},
    {id=26, freq="850 MHz", region="USA"},
    {id=28, freq="700 APT", region="Asia Pacific"},
    {id=66, freq="AWS 1700/2100 MHz", region="Americas"},
    {id=71, freq="600 MHz", region="USA"},
}

BANDS_LTE_TDD = {
    {id=34, freq="2010-2025 MHz"},
    {id=38, freq="2570-2620 MHz"},
    {id=39, freq="1880-1920 MHz"},
    {id=40, freq="2300-2400 MHz"},
    {id=41, freq="2496-2690 MHz"},
    {id=42, freq="3400-3600 MHz"},
    {id=43, freq="3600-3800 MHz"},
    {id=48, freq="3550-3700 MHz"},
}

BANDS_5G_NR = {
    {id=1, freq="2100 MHz", type="FDD"},
    {id=2, freq="1900 MHz", type="FDD"},
    {id=3, freq="1800 MHz", type="FDD"},
    {id=5, freq="850 MHz", type="FDD"},
    {id=7, freq="2600 MHz", type="FDD"},
    {id=8, freq="900 MHz", type="FDD"},
    {id=12, freq="700 MHz", type="FDD"},
    {id=13, freq="700c MHz", type="FDD"},
    {id=20, freq="800 DD", type="FDD"},
    {id=25, freq="1900 MHz", type="FDD"},
    {id=28, freq="700 APT", type="FDD"},
    {id=38, freq="2600 TDD", type="TDD"},
    {id=40, freq="2300 MHz", type="TDD"},
    {id=41, freq="2500 MHz", type="TDD"},
    {id=48, freq="3550 MHz", type="TDD"},
    {id=66, freq="AWS 2100 MHz", type="FDD"},
    {id=70, freq="1995 MHz", type="FDD"},
    {id=71, freq="600 MHz", type="FDD"},
    {id=77, freq="3700 MHz", type="TDD"},
    {id=78, freq="3500 MHz", type="TDD"},
    {id=79, freq="4700 MHz", type="TDD"},
}
```

### 3. Protocol Handler Functions

Add to `/lib/netifd/proto/atc.sh`:

```bash
# Read current band configuration
get_band_config() {
    local type="$1"  # lte_band, nr5g_band, nsa_nr5g_band

    local response=$(at_command "AT+QNWPREFCFG=\"$type\"" 10 2 1)

    if echo "$response" | grep -q "QNWPREFCFG"; then
        # Extract band list from response
        echo "$response" | grep "QNWPREFCFG" | cut -d'"' -f4
        return 0
    fi

    return 1
}

# Set band configuration
set_band_config() {
    local type="$1"      # lte_band, nr5g_band, nsa_nr5g_band
    local bands="$2"     # Colon-separated: 2:4:12:66

    log_info "Setting $type bands: $bands"

    if [ -z "$bands" ] || [ "$bands" = "0" ]; then
        # Reset to automatic
        at_command "AT+QNWPREFCFG=\"$type\",0" 10 3
    else
        at_command "AT+QNWPREFCFG=\"$type\",$bands" 10 3
    fi

    if [ $? -eq 0 ]; then
        log_info "Band configuration applied successfully"
        return 0
    else
        log_error "Failed to apply band configuration"
        return 1
    fi
}

# Convert comma-separated to colon-separated
convert_band_format() {
    local bands="$1"
    echo "$bands" | tr ',' ':'
}

# Apply band locking configuration
apply_band_locking() {
    local band_enabled="${1:-0}"
    local lte_bands="$2"
    local nr5g_sa_bands="$3"
    local nr5g_nsa_bands="$4"

    if [ "$band_enabled" != "1" ]; then
        log_info "Band locking disabled, using automatic selection"
        set_band_config "lte_band" "0"
        set_band_config "nr5g_band" "0"
        set_band_config "nsa_nr5g_band" "0"
        return 0
    fi

    log_info "Applying band locking configuration..."

    # Apply LTE bands
    if [ -n "$lte_bands" ]; then
        local lte_formatted=$(convert_band_format "$lte_bands")
        set_band_config "lte_band" "$lte_formatted"
    fi

    # Apply 5G SA bands
    if [ -n "$nr5g_sa_bands" ]; then
        local sa_formatted=$(convert_band_format "$nr5g_sa_bands")
        set_band_config "nr5g_band" "$sa_formatted"
    fi

    # Apply 5G NSA bands
    if [ -n "$nr5g_nsa_bands" ]; then
        local nsa_formatted=$(convert_band_format "$nr5g_nsa_bands")
        set_band_config "nsa_nr5g_band" "$nsa_formatted"
    fi

    log_info "Band locking applied successfully"
    return 0
}

# Get current active bands
get_current_bands() {
    log_info "Reading current band information..."

    # Get serving cell info
    local serving=$(at_command "AT+QENG=\"servingcell\"" 10 2 1)

    if echo "$serving" | grep -q "LTE"; then
        local band=$(echo "$serving" | grep -o "LTE.*" | awk '{print $2}')
        echo "LTE Band: $band"
    elif echo "$serving" | grep -q "NR5G"; then
        local band=$(echo "$serving" | grep -o "NR5G.*" | awk '{print $2}')
        echo "5G Band: n$band"
    fi
}
```

### 4. CLI Commands

Add to `/usr/bin/enhanced-atc-cli`:

```bash
# Show current bands
show_bands() {
    echo "=== Current Band Configuration ==="

    local lte_bands=$(get_band_config "lte_band")
    local nr5g_bands=$(get_band_config "nr5g_band")
    local nsa_bands=$(get_band_config "nsa_nr5g_band")

    echo "LTE Bands: $lte_bands"
    echo "5G SA Bands: $nr5g_bands"
    echo "5G NSA Bands: $nsa_bands"

    echo ""
    echo "=== Active Band ==="
    get_current_bands
}

# Lock specific bands
lock_bands() {
    echo "Band locking configuration..."
    echo "Usage: enhanced-atc-cli lock-bands --lte 2,4,12,66 --5g 41,77,78"
}
```

### 5. LuCI Interface

Add band selector to LuCI model:

```lua
-- Band Locking Section
b = m:section(TypedSection, "band_settings", translate("Band Locking"))
b.addremove = false
b.anonymous = true

band_enabled = b:option(Flag, "enabled", translate("Enable Band Locking"))
band_enabled.default = "0"
band_enabled.rmempty = false

-- LTE Band Selector (Multi-select)
lte_bands = b:option(DynamicList, "lte_bands", translate("LTE Bands"),
    translate("Select LTE bands to lock (leave empty for automatic)"))
lte_bands:depends("enabled", "1")

-- Add all LTE bands
for _, band in ipairs(BANDS_LTE_FDD) do
    lte_bands:value(band.id, string.format("B%d - %s (%s)",
        band.id, band.freq, band.region))
end

-- 5G SA Band Selector
nr5g_sa_bands = b:option(DynamicList, "nr5g_sa_bands",
    translate("5G SA Bands"),
    translate("Select 5G Standalone bands"))
nr5g_sa_bands:depends("enabled", "1")

-- 5G NSA Band Selector
nr5g_nsa_bands = b:option(DynamicList, "nr5g_nsa_bands",
    translate("5G NSA Bands"),
    translate("Select 5G Non-Standalone bands"))
nr5g_nsa_bands:depends("enabled", "1")
```

## Implementation Priority

### Phase 1: Basic Band Locking
- ✅ Research completed
- ⏳ Add band configuration to UCI
- ⏳ Implement AT command functions
- ⏳ Add CLI commands
- ⏳ Test with FM350-GL

### Phase 2: LuCI Integration
- ⏳ Create band database
- ⏳ Add multi-select interface
- ⏳ Add band information tooltips
- ⏳ Add current band display

### Phase 3: Advanced Features
- ⏳ Auto-switching based on signal quality
- ⏳ Band scanning functionality
- ⏳ Carrier aggregation info
- ⏳ Band strength meter

## Recommended Bands by Carrier (Poland)

### Play
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### Orange
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### Plus
- **LTE:** B1 (2100 MHz), B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

### T-Mobile
- **LTE:** B3 (1800 MHz), B7 (2600 MHz), B20 (800 MHz)
- **5G:** n78 (3500 MHz)

## Testing Checklist

- [ ] Test AT+QNWPREFCFG commands on FM350-GL
- [ ] Verify band locking persists after reboot
- [ ] Test auto/manual mode switching
- [ ] Verify no connection drop during band lock
- [ ] Test with multiple carriers
- [ ] Validate band list parsing
- [ ] Test edge cases (invalid bands, empty list)
- [ ] Performance impact measurement

## Security Considerations

- Validate band numbers (prevent injection)
- Rate limit band switching
- Log all band configuration changes
- Require confirmation for carrier-critical bands
- Prevent locking to unavailable bands

## Documentation Needs

- User guide for band selection
- Carrier-specific recommendations
- Troubleshooting guide
- AT command reference
- Performance optimization tips
