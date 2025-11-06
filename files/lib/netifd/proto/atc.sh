#!/bin/sh
# Enhanced ATC Protocol for Fibocom FM350-GL with FCC Unlock

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

ATC_VERSION="1.2.0"
LOG_DIR="/tmp/atc_logs"
FCC_STATUS_FILE="/tmp/atc_fcc_status"

proto_atc_init_config() {
    available=1
    no_device=1
    proto_config_add_string "device:device"
    proto_config_add_string "apn"
    proto_config_add_string "username"
    proto_config_add_string "password"
    proto_config_add_string "auth"
    proto_config_add_string "pdp"
    proto_config_add_int "delay"
    proto_config_add_boolean "atc_debug"
    proto_config_add_boolean "auto_optimize"
    proto_config_add_int "signal_threshold"
    proto_config_add_string "preferred_mode"
    proto_config_add_int "monitor_interval"
    proto_config_add_boolean "power_management"
    proto_config_add_int "max_retries"
    proto_config_add_boolean "fcc_unlock"
    proto_config_add_boolean "firmware_check"
    proto_config_add_boolean "skip_fcc_check"
    proto_config_add_boolean "band_locking"
    proto_config_add_string "lte_bands"
    proto_config_add_string "nr5g_sa_bands"
    proto_config_add_string "nr5g_nsa_bands"
}

setup_logging() {
    mkdir -p "$LOG_DIR"
    # Clean old logs (use -exec for better compatibility)
    find "$LOG_DIR" -name "*.log" -type f -mtime +7 -exec rm -f {} \; 2>/dev/null || true
}

validate_device() {
    local device="$1"

    # Check if device path is specified
    if [ -z "$device" ]; then
        log_error "Device path is empty"
        return 1
    fi

    # Validate device path format
    if ! echo "$device" | grep -qE '^/dev/[a-zA-Z0-9_-]+$'; then
        log_error "Invalid device path format: $device"
        return 1
    fi

    # Check if device exists and is a character device
    if [ ! -c "$device" ]; then
        log_error "Device $device is not a valid character device"
        return 1
    fi

    # Check if device is readable and writable
    if [ ! -r "$device" ] || [ ! -w "$device" ]; then
        log_error "Device $device is not readable/writable"
        return 1
    fi

    return 0
}

validate_apn() {
    local apn="$1"

    if [ -z "$apn" ]; then
        return 0  # APN is optional
    fi

    # APN should be alphanumeric with dots, hyphens, underscores
    if ! echo "$apn" | grep -qE '^[a-zA-Z0-9._-]{1,100}$'; then
        log_error "Invalid APN format: $apn"
        return 1
    fi

    return 0
}

validate_delay() {
    local delay="$1"

    if [ -z "$delay" ]; then
        return 0
    fi

    # Check if delay is a number
    if ! echo "$delay" | grep -qE '^[0-9]+$'; then
        log_error "Delay must be a number: $delay"
        return 1
    fi

    # Check if delay is in valid range (0-60)
    if [ "$delay" -lt 0 ] || [ "$delay" -gt 60 ]; then
        log_error "Delay must be between 0 and 60 seconds: $delay"
        return 1
    fi

    return 0
}

validate_retries() {
    local retries="$1"

    if [ -z "$retries" ]; then
        return 0
    fi

    # Check if retries is a number
    if ! echo "$retries" | grep -qE '^[0-9]+$'; then
        log_error "Max retries must be a number: $retries"
        return 1
    fi

    # Check if retries is in valid range (1-10)
    if [ "$retries" -lt 1 ] || [ "$retries" -gt 10 ]; then
        log_error "Max retries must be between 1 and 10: $retries"
        return 1
    fi

    return 0
}

validate_auth_type() {
    local auth="$1"

    if [ -z "$auth" ]; then
        return 0
    fi

    # Auth type should be 0-3
    case "$auth" in
        0|1|2|3) return 0 ;;
        *)
            log_error "Invalid auth type: $auth (must be 0-3)"
            return 1
            ;;
    esac
}

validate_pdp_type() {
    local pdp="$1"

    if [ -z "$pdp" ]; then
        return 0
    fi

    # PDP type should be IP, IPV6, or IPV4V6
    case "$pdp" in
        IP|IPV6|IPV4V6) return 0 ;;
        *)
            log_error "Invalid PDP type: $pdp (must be IP, IPV6, or IPV4V6)"
            return 1
            ;;
    esac
}

validate_config() {
    log_info "Validating configuration..."

    validate_device "$device" || return 1
    validate_apn "$apn" || return 1
    validate_delay "$delay" || return 1
    validate_retries "$max_retries" || return 1
    validate_auth_type "$auth" || return 1
    validate_pdp_type "$pdp" || return 1

    log_info "Configuration validation passed"
    return 0
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/${level}.log"
    case "$level" in
        "ERROR"|"CRITICAL") logger -p daemon.err -t "enhanced-atc" "$message" ;;
        "WARN") logger -p daemon.warn -t "enhanced-atc" "$message" ;;
        "INFO"|"FCC") logger -p daemon.info -t "enhanced-atc" "$message" ;;
        "DEBUG") [ "$atc_debug" = "1" ] && logger -p daemon.debug -t "enhanced-atc" "$message" ;;
    esac
}

log_debug() { log_message "DEBUG" "$1"; }
log_info() { log_message "INFO" "$1"; }
log_warn() { log_message "WARN" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_fcc() { log_message "FCC" "$1"; }

at_command() {
    local cmd="$1"
    local timeout="${2:-15}"
    local retries="${3:-3}"
    local quiet="${4:-0}"
    [ "$quiet" = "0" ] && log_debug "AT: $cmd"
    [ ! -c "$device" ] && { log_error "Device $device not available"; return 1; }
    local attempt=1
    while [ $attempt -le $retries ]; do
        local response=$(timeout "$timeout" sh -c "
            stty -F \"$device\" raw -echo 115200 2>/dev/null || exit 1
            printf '%s\r\n' \"$cmd\" > \"$device\" 2>/dev/null || exit 1
            sleep 2
            dd if=\"$device\" bs=1 count=1024 2>/dev/null | head -c 1024
        " 2>/dev/null | tr -d '\r' | grep -v '^$' | grep -v "^${cmd}$" | head -5)
        if [ -n "$response" ]; then
            [ "$quiet" = "0" ] && log_debug "AT Response: $response"
            echo "$response"
            return 0
        fi
        attempt=$((attempt + 1))
        [ $attempt -le $retries ] && sleep 3
    done
    log_error "AT command failed: $cmd"
    return 1
}

perform_fcc_unlock() {
    log_fcc "Starting FCC unlock procedure"

    # Check current FCC lock status
    local fcc_status=$(at_command "AT+GTFCCLOCK?" 10 2 1)
    if echo "$fcc_status" | grep -q "GTFCCLOCK.*0"; then
        log_fcc "FCC already unlocked"
        echo "1" > "$FCC_STATUS_FILE"
        return 0
    fi

    log_fcc "Attempting FCC unlock..."
    local unlock_response=$(at_command "AT+GTFCCLOCK=0" 15 3)

    if echo "$unlock_response" | grep -q "OK"; then
        log_fcc "FCC unlock successful"
        echo "1" > "$FCC_STATUS_FILE"
        sleep 2
        return 0
    else
        log_error "FCC unlock failed: $unlock_response"
        echo "0" > "$FCC_STATUS_FILE"
        return 1
    fi
}

check_modem_ready() {
    local max_attempts=10
    local attempt=1

    log_info "Waiting for modem to be ready..."

    while [ $attempt -le $max_attempts ]; do
        local response=$(at_command "AT" 5 1 1)
        if echo "$response" | grep -q "OK"; then
            log_info "Modem ready"
            return 0
        fi
        log_debug "Modem not ready, attempt $attempt/$max_attempts"
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Modem not responding after $max_attempts attempts"
    return 1
}

apply_band_locking() {
    local band_enabled="$1"
    local lte_bands="$2"
    local nr5g_sa_bands="$3"
    local nr5g_nsa_bands="$4"

    if [ "$band_enabled" != "1" ]; then
        log_info "Band locking disabled, using automatic band selection"
        return 0
    fi

    log_info "=== Applying Band Locking Configuration ==="

    # Apply LTE bands (Fibocom FM350-GL specific)
    if [ -n "$lte_bands" ]; then
        log_info "Setting LTE bands: $lte_bands"
        # Convert comma-separated to colon-separated (2,4,12 -> 2:4:12)
        local lte_formatted=$(echo "$lte_bands" | tr ',' ':')
        at_command "AT+QNWPREFCFG=\"lte_band\",$lte_formatted" 10 3 || {
            log_error "Failed to set LTE bands"
            return 1
        }
        log_info "LTE bands configured: $lte_formatted"
    else
        log_info "LTE bands: automatic (all bands)"
        at_command "AT+QNWPREFCFG=\"lte_band\",0" 10 2 1
    fi

    # Apply 5G SA bands
    if [ -n "$nr5g_sa_bands" ]; then
        log_info "Setting 5G SA bands: $nr5g_sa_bands"
        local sa_formatted=$(echo "$nr5g_sa_bands" | tr ',' ':')
        at_command "AT+QNWPREFCFG=\"nr5g_band\",$sa_formatted" 10 3 || {
            log_error "Failed to set 5G SA bands"
            return 1
        }
        log_info "5G SA bands configured: $sa_formatted"
    else
        log_info "5G SA bands: automatic (all bands)"
        at_command "AT+QNWPREFCFG=\"nr5g_band\",0" 10 2 1
    fi

    # Apply 5G NSA bands
    if [ -n "$nr5g_nsa_bands" ]; then
        log_info "Setting 5G NSA bands: $nr5g_nsa_bands"
        local nsa_formatted=$(echo "$nr5g_nsa_bands" | tr ',' ':')
        at_command "AT+QNWPREFCFG=\"nsa_nr5g_band\",$nsa_formatted" 10 3 || {
            log_error "Failed to set 5G NSA bands"
            return 1
        }
        log_info "5G NSA bands configured: $nsa_formatted"
    else
        log_info "5G NSA bands: automatic (all bands)"
        at_command "AT+QNWPREFCFG=\"nsa_nr5g_band\",0" 10 2 1
    fi

    log_info "Band locking configuration applied successfully"
    return 0
}

get_current_band_info() {
    log_info "Retrieving current band information..."

    # Get serving cell information (Fibocom FM350-GL specific)
    local serving=$(at_command "AT+QENG=\"servingcell\"" 10 2 1)

    if [ -n "$serving" ]; then
        log_info "Serving cell info: $serving"
        echo "$serving" | grep -i "LTE\|NR5G" | head -3
    fi
}

configure_modem() {
    log_info "Configuring modem..."

    # Set APN
    if [ -n "$apn" ]; then
        log_info "Setting APN: $apn"
        local pdp_type="${pdp:-IP}"
        at_command "AT+CGDCONT=1,\"$pdp_type\",\"$apn\"" || {
            log_error "Failed to set APN"
            return 1
        }
    fi

    # Set authentication if provided
    if [ -n "$username" ] && [ -n "$password" ]; then
        local auth_type="${auth:-0}"
        log_info "Setting authentication (type: $auth_type)"
        at_command "AT\$QCPDPP=1,$auth_type,\"$password\",\"$username\"" || {
            log_warn "Authentication setup failed, continuing anyway"
        }
    fi

    # Set preferred network mode if specified
    if [ -n "$preferred_mode" ]; then
        log_info "Setting preferred mode: $preferred_mode"
        case "$preferred_mode" in
            "auto") at_command "AT+CNMP=2" ;;
            "lte") at_command "AT+CNMP=38" ;;
            "5g") at_command "AT+CNMP=109" ;;
            *) log_warn "Unknown preferred_mode: $preferred_mode" ;;
        esac
    fi

    log_info "Modem configuration completed"
    return 0
}

start_connection() {
    log_info "Starting data connection..."

    # Activate PDP context
    at_command "AT+CGACT=1,1" 15 || {
        log_error "Failed to activate PDP context"
        return 1
    }

    # Start data call
    at_command "AT\$QCRMCALL=1,1" 15 || {
        log_error "Failed to start data call"
        return 1
    }

    log_info "Data connection started successfully"
    return 0
}

proto_atc_setup() {
    local interface="$1"
    json_get_vars device apn username password auth pdp delay atc_debug auto_optimize signal_threshold preferred_mode monitor_interval power_management max_retries fcc_unlock firmware_check skip_fcc_check band_locking lte_bands nr5g_sa_bands nr5g_nsa_bands

    # Set defaults
    [ -z "$fcc_unlock" ] && fcc_unlock="1"
    [ -z "$firmware_check" ] && firmware_check="1"
    [ -z "$delay" ] && delay="0"
    [ -z "$max_retries" ] && max_retries="3"
    [ -z "$atc_debug" ] && atc_debug="0"
    [ -z "$band_locking" ] && band_locking="0"

    setup_logging
    log_info "=== Enhanced ATC v$ATC_VERSION Starting ==="
    log_info "Interface: $interface"
    log_info "Device: $device"

    # Validate configuration
    if ! validate_config; then
        log_error "Configuration validation failed"
        proto_notify_error "$interface" "INVALID_CONFIG"
        proto_block_restart "$interface"
        return 1
    fi

    # Wait for initial delay if specified
    if [ "$delay" -gt 0 ]; then
        log_info "Waiting ${delay}s before starting..."
        sleep "$delay"
    fi

    # Wait for modem to be ready
    if ! check_modem_ready; then
        proto_notify_error "$interface" "MODEM_NOT_READY"
        return 1
    fi

    # Get modem information
    log_info "Getting modem information..."
    local modem_info=$(at_command "ATI" 5 2 1)
    log_info "Modem: $modem_info"

    # Check firmware version if enabled
    if [ "$firmware_check" = "1" ]; then
        log_info "Checking firmware version..."
        local fw_version=$(at_command "AT+CGMR" 5 2 1)
        log_info "Firmware: $fw_version"
    fi

    # Perform FCC unlock if enabled and not skipped
    if [ "$fcc_unlock" = "1" ] && [ "$skip_fcc_check" != "1" ]; then
        if ! perform_fcc_unlock; then
            log_warn "FCC unlock failed, continuing anyway..."
        fi
    else
        log_info "FCC unlock skipped (fcc_unlock=$fcc_unlock, skip_fcc_check=$skip_fcc_check)"
    fi

    # Apply band locking configuration (Fibocom FM350-GL specific)
    if [ "$band_locking" = "1" ]; then
        log_info "Band locking enabled, applying configuration..."
        if ! apply_band_locking "$band_locking" "$lte_bands" "$nr5g_sa_bands" "$nr5g_nsa_bands"; then
            log_warn "Band locking configuration failed, continuing anyway..."
        fi
        # Get current band info after configuration
        get_current_band_info
    else
        log_info "Band locking disabled, using automatic band selection"
    fi

    # Configure modem
    if ! configure_modem; then
        log_error "Modem configuration failed"
        proto_notify_error "$interface" "CONFIG_FAILED"
        return 1
    fi

    # Start connection
    if ! start_connection; then
        log_error "Failed to start connection"
        proto_notify_error "$interface" "CONNECT_FAILED"
        return 1
    fi

    log_info "Connection established successfully"
    proto_init_update "$interface" 1
    proto_send_update "$interface"

    return 0
}

proto_atc_teardown() {
    local interface="$1"
    log_info "Tearing down interface $interface"

    json_get_vars device

    if [ -c "$device" ]; then
        log_info "Stopping data connection..."
        at_command "AT\$QCRMCALL=0,1" 10 1 1 2>/dev/null || true
        at_command "AT+CGACT=0,1" 10 1 1 2>/dev/null || true
    fi

    proto_kill_command "$interface"
    log_info "Interface $interface torn down"
}

add_protocol atc
