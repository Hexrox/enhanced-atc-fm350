# Enhanced ATC Configuration Guide

## Configuration File

The main configuration file is located at `/etc/config/enhanced_atc`.

## Configuration Sections

### General Settings

```
config general 'general'
    option fcc_unlock '1'           # Enable FCC unlock (0=disabled, 1=enabled)
    option firmware_check '1'       # Check firmware version (0=disabled, 1=enabled)
    option atc_debug '0'           # Debug logging (0=disabled, 1=enabled)
    option auto_optimize '0'       # Auto optimization (0=disabled, 1=enabled)
    option power_management '0'    # Power management (0=disabled, 1=enabled)
```

#### Options Explained

- **fcc_unlock**: Automatically unlock FCC restrictions when modem starts
- **firmware_check**: Verify firmware version during initialization
- **atc_debug**: Enable verbose debug logging for troubleshooting
- **auto_optimize**: Automatically optimize connection based on signal (future feature)
- **power_management**: Enable power-saving features (future feature)

### Interface Configuration

```
config interface 'wan'
    option enabled '1'                    # Enable this interface
    option device '/dev/ttyUSB3'         # Serial device path
    option apn 'internet'                # Access Point Name
    option username ''                   # Authentication username (optional)
    option password ''                   # Authentication password (optional)
    option auth '0'                      # Auth type (0=none, 1=PAP, 2=CHAP, 3=PAP/CHAP)
    option pdp 'IP'                      # PDP type (IP, IPV6, IPV4V6)
    option delay '5'                     # Connection delay in seconds (0-60)
    option max_retries '3'               # Max connection retries (1-10)
    option preferred_mode 'auto'         # Network mode (auto, lte, 5g)
    option signal_threshold '-90'        # Min signal strength in dBm
    option monitor_interval '60'         # Status check interval in seconds
```

#### Options Explained

- **enabled**: Enable or disable this interface configuration
- **device**: Path to the modem's AT command interface (usually /dev/ttyUSB3)
- **apn**: Your carrier's Access Point Name (required, contact your carrier)
- **username/password**: Required only if your carrier uses authentication
- **auth**: Authentication protocol type
  - 0 = No authentication
  - 1 = PAP (Password Authentication Protocol)
  - 2 = CHAP (Challenge Handshake Authentication Protocol)
  - 3 = PAP or CHAP (auto-select)
- **pdp**: Packet Data Protocol type
  - IP = IPv4 only
  - IPV6 = IPv6 only
  - IPV4V6 = Dual stack (both IPv4 and IPv6)
- **delay**: Seconds to wait before attempting connection (useful for modem initialization)
- **max_retries**: How many times to retry connection before giving up
- **preferred_mode**: Network mode preference
  - auto = Automatically select best available (LTE/5G)
  - lte = Force LTE only
  - 5g = Prefer 5G when available
- **signal_threshold**: Minimum acceptable signal strength in dBm
- **monitor_interval**: How often to check connection status (30-300 seconds)

## Common Carrier Configurations

### T-Mobile USA

```
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'fast.t-mobile.com'
    option auth '0'
    option pdp 'IPV4V6'
```

### AT&T USA

```
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'broadband'
    option auth '0'
    option pdp 'IP'
```

### Verizon USA

```
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'vzwinternet'
    option auth '0'
    option pdp 'IP'
```

### Generic/International

```
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'internet'      # Replace with your carrier's APN
    option username ''         # Add if required
    option password ''         # Add if required
    option auth '0'            # Change if authentication required
    option pdp 'IP'
```

## Network Interface Integration

To use Enhanced ATC as a network protocol, configure in `/etc/config/network`:

```
config interface 'wan'
    option proto 'atc'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option username ''
    option password ''
    option auth '0'
    option pdp 'IP'
    option delay '5'
    option fcc_unlock '1'
    option firmware_check '1'
    option atc_debug '0'
```

Then reload network:

```bash
/etc/init.d/network reload
```

## Advanced Configuration

### Enable Debug Logging

For troubleshooting connection issues:

```
config general 'general'
    option atc_debug '1'
```

This will create detailed logs in `/tmp/atc_logs/DEBUG.log`.

### Multiple Modems

You can configure multiple modem interfaces:

```
config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'internet'

config interface 'wan2'
    option enabled '1'
    option device '/dev/ttyUSB6'
    option apn 'internet2'
```

### Performance Tuning

For faster connection establishment:

```
config interface 'wan'
    option delay '0'           # No delay (if modem is already initialized)
    option max_retries '5'     # More retry attempts
```

For better reliability:

```
config interface 'wan'
    option delay '10'          # Wait longer for modem initialization
    option max_retries '3'     # Standard retries
    option monitor_interval '30'  # Check status more frequently
```

## Configuration Validation

The system automatically validates configuration parameters:

- Device path must be valid character device in /dev/
- APN must be 1-100 alphanumeric characters
- Delay must be 0-60 seconds
- Max retries must be 1-10
- Auth type must be 0-3
- PDP type must be IP, IPV6, or IPV4V6

Invalid configurations will be logged to `/tmp/atc_logs/ERROR.log`.

## Applying Configuration Changes

After modifying `/etc/config/enhanced_atc`:

### Via LuCI
1. Navigate to Network → Enhanced ATC
2. Modify settings
3. Click "Save & Apply"

### Via Command Line
```bash
# Reload network configuration
/etc/init.d/network reload

# Or restart specific interface
ifdown wan && ifup wan
```

## Viewing Current Configuration

```bash
# View configuration file
cat /etc/config/enhanced_atc

# View active configuration via UCI
uci show enhanced_atc
```

## Resetting to Defaults

```bash
# Backup current config
cp /etc/config/enhanced_atc /etc/config/enhanced_atc.backup

# Remove and reinstall package
opkg remove enhanced-atc
opkg install enhanced-atc

# Or manually restore defaults
vi /etc/config/enhanced_atc
```
