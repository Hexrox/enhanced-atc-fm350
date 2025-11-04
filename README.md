# Enhanced ATC for Fibocom FM350-GL

Advanced protocol handler for OpenWrt with automatic FCC unlock support for Fibocom FM350-GL 5G modems.

## Features

- **Automatic FCC Unlock**: Automatically unlocks FCC restrictions on modem startup
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
```

## Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Configuration Guide](docs/CONFIGURATION.md) - Complete configuration reference
- [Examples](examples/) - Configuration examples for common carriers

## Requirements

- OpenWrt 21.02 or newer
- Fibocom FM350-GL modem
- USB connection to modem
- Working LuCI installation (for web interface)

## Supported Features

### Current
- ✅ Automatic FCC unlock
- ✅ LTE/5G connectivity
- ✅ IPv4 and IPv6 support
- ✅ PAP/CHAP authentication
- ✅ Connection monitoring
- ✅ Firmware version checking
- ✅ Web interface (LuCI)
- ✅ Command-line interface
- ✅ Comprehensive logging
- ✅ Parameter validation

### Planned
- ⏳ Auto-optimization based on signal quality
- ⏳ Power management features
- ⏳ SMS functionality
- ⏳ GPS/GNSS support
- ⏳ Band locking
- ⏳ Carrier aggregation info

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