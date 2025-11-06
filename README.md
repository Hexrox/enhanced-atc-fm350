# Enhanced ATC for Fibocom FM350-GL

Advanced protocol handler for OpenWrt with automatic FCC unlock support for Fibocom FM350-GL 5G modems.

## Features

- **Automatic FCC Unlock**: Automatically unlocks FCC restrictions on modem startup
- **Band Locking**: Lock modem to specific LTE/5G bands for optimal performance (FM350-GL specific)
- **Full Protocol Integration**: Native netifd protocol handler for seamless OpenWrt integration
- **LuCI Web Interface**: Easy-to-use web interface for configuration and monitoring
- **CLI Management Tool**: Command-line tool for status checks and manual operations
- **Advanced Configuration**: Support for multiple authentication types, PDP types, and network modes
- **Comprehensive Logging**: Detailed logs for debugging and monitoring
- **Parameter Validation**: Automatic validation of all configuration parameters
- **Connection Management**: Automatic retry logic and connection monitoring

## Quick Start

### Installation

```bash
# Upload package to router
scp enhanced-atc_*.ipk root@192.168.1.1:/tmp/

# Install on router
ssh root@192.168.1.1
opkg update
opkg install /tmp/enhanced-atc_*.ipk
```

### Basic Configuration

#### Via LuCI (Web Interface)
1. Navigate to **Network** → **Enhanced ATC**
2. Configure your APN and connection settings
3. Enable FCC unlock if needed
4. Save & Apply

#### Via Command Line
```bash
# Edit configuration
vi /etc/config/enhanced_atc

# Set your APN
uci set enhanced_atc.wan.apn='your-apn-here'
uci set enhanced_atc.wan.enabled='1'
uci commit enhanced_atc

# Reload network
/etc/init.d/network reload
```

### Using CLI Tool

```bash
# Check modem status
enhanced-atc-cli status

# Check FCC lock status
enhanced-atc-cli fcc-status

# Unlock FCC restrictions
enhanced-atc-cli fcc-unlock

# View firmware information
enhanced-atc-cli fw-info

# Band locking (FM350-GL specific)
enhanced-atc-cli bands                          # Show current bands
enhanced-atc-cli band-lock --lte 3,7,20 --5g 78 # Lock to specific bands
enhanced-atc-cli band-unlock                    # Unlock all bands (auto)

# Carrier Aggregation info (FM350-GL specific)
enhanced-atc-cli ca-info                        # Show CA status and carriers

# Advanced band scanning (FM350-GL specific)
enhanced-atc-cli scan quick                     # Quick scan (5-10s)
enhanced-atc-cli scan medium                    # Medium scan (10-20s)
enhanced-atc-cli scan full                      # Full scan (1-3min, disconnects!)
```

## Advanced Features (FM350-GL Specific)

### Carrier Aggregation Info

View real-time carrier aggregation status and component carriers:

```bash
enhanced-atc-cli ca-info
```

**Output example:**
```
=== Carrier Aggregation Status ===

Primary Component Carrier (PCC):
  Band: LTE BAND 3
  Frequency: 1800 MHz
  Bandwidth: 20 MHz
  RSRP: -85 dBm
  RSRQ: -8 dB
  SINR: 18 dB

Secondary Component Carrier (SCC1):
  Band: LTE BAND 7
  Frequency: 2600 MHz
  Bandwidth: 10 MHz
  RSRP: -90 dBm
  RSRQ: -10 dB
  SINR: 15 dB

Status: ACTIVE (2CA)
Technology: LTE-Advanced
```

### Advanced Band Scanning

Scan available frequency bands in your area:

**Quick Scan** (5-10 seconds) - Neighbour cells only:
```bash
enhanced-atc-cli scan quick
```

**Medium Scan** (10-20 seconds) - Serving + neighbour cells:
```bash
enhanced-atc-cli scan medium
```

**Full Scan** (1-3 minutes) - Complete network scan (disconnects modem!):
```bash
enhanced-atc-cli scan full
```

**Output example:**
```
Band  | Type  | EARFCN   | RSRP      | RSRQ     | Quality
------|-------|----------|-----------|----------|----------
B3    | LTE   | 1300     | -85 dBm   | -8 dB    | Excellent
B7    | LTE   | 2850     | -90 dBm   | -10 dB   | Good
B20   | LTE   | 6300     | -78 dBm   | -7 dB    | Excellent
```

### LuCI Status & Diagnostics

Access via web interface: **Network** → **Enhanced ATC** → **Status & Diagnostics**

Features:
- Real-time Carrier Aggregation monitoring (auto-refresh every 60s)
- Interactive band scanner with mode selection
- Modem information and firmware details
- FCC lock status and unlock control
- All features accessible through user-friendly web interface

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Configuration Guide](docs/CONFIGURATION.md) - Complete configuration reference
- [Band Locking Analysis](docs/BAND_LOCKING_ANALYSIS.md) - Technical details about band locking
- [CA & Scanning Analysis](docs/CARRIER_AGGREGATION_AND_SCANNING_ANALYSIS.md) - Carrier Aggregation and Band Scanning technical details
- [Examples](examples/) - Configuration examples for common carriers

## Requirements

- OpenWrt 21.02 or newer
- Fibocom FM350-GL modem
- USB connection to modem
- Working LuCI installation (for web interface)

## Supported Features

### Current
- ✅ Automatic FCC unlock
- ✅ Band locking for LTE and 5G (FM350-GL specific)
- ✅ Carrier Aggregation info (FM350-GL specific)
- ✅ Advanced band scanning (FM350-GL specific)
- ✅ LTE/5G connectivity
- ✅ IPv4 and IPv6 support
- ✅ PAP/CHAP authentication
- ✅ Connection monitoring
- ✅ Firmware version checking
- ✅ Web interface (LuCI) with Status & Diagnostics
- ✅ Command-line interface
- ✅ Comprehensive logging
- ✅ Parameter validation

### Planned
- ⏳ Auto-optimization based on signal quality
- ⏳ Power management features
- ⏳ SMS functionality
- ⏳ GPS/GNSS support

## Project Structure

```
enhanced-atc-fm350/
├── files/
│   ├── etc/
│   │   ├── config/
│   │   │   └── enhanced_atc          # Default configuration
│   │   └── init.d/
│   │       └── enhanced_atc          # Init script
│   ├── lib/
│   │   └── netifd/
│   │       └── proto/
│   │           └── atc.sh            # Protocol handler
│   └── usr/
│       ├── bin/
│       │   └── enhanced-atc-cli      # CLI tool
│       └── lib/
│           └── lua/
│               └── luci/             # LuCI integration
├── docs/                             # Documentation
├── examples/                         # Configuration examples
└── README.md                         # This file
```

## Troubleshooting

### Modem not detected
```bash
# Check if modem is recognized
ls -l /dev/ttyUSB*

# Check kernel messages
dmesg | grep ttyUSB
```

### FCC unlock fails
```bash
# Try manual unlock
enhanced-atc-cli fcc-unlock

# Check error logs
cat /tmp/atc_logs/ERROR.log
```

### Connection issues
```bash
# Enable debug mode
uci set enhanced_atc.general.atc_debug='1'
uci commit enhanced_atc
/etc/init.d/network reload

# View debug logs
tail -f /tmp/atc_logs/DEBUG.log
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is open source. See LICENSE file for details.

## Support

- **Issues**: Report bugs via GitHub Issues
- **Logs**: Check `/tmp/atc_logs/` for detailed logs
- **Debug Mode**: Enable in configuration for verbose output

## Acknowledgments

- OpenWrt community
- Fibocom FM350-GL documentation
- LuCI framework developers