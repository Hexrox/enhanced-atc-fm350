# Enhanced ATC Installation Guide

## Overview
Enhanced ATC is a protocol handler for OpenWrt that provides advanced management for Fibocom FM350-GL modems, including automatic FCC unlock capabilities.

## Prerequisites

- OpenWrt router (tested on 21.02+)
- Fibocom FM350-GL modem
- USB connection to the modem
- Basic knowledge of OpenWrt configuration

## Installation Steps

### 1. Upload Package to Router

```bash
scp enhanced-atc_*.ipk root@192.168.1.1:/tmp/
```

### 2. Install the Package

```bash
ssh root@192.168.1.1
opkg update
opkg install /tmp/enhanced-atc_*.ipk
```

### 3. Verify Installation

Check if the protocol handler is registered:

```bash
ls -l /lib/netifd/proto/atc.sh
ls -l /usr/bin/enhanced-atc-cli
```

### 4. Identify Modem Device

Find your modem's serial device:

```bash
ls -l /dev/ttyUSB*
```

Typically, the AT command interface is on `/dev/ttyUSB3` for FM350-GL.

### 5. Configure via LuCI (Web Interface)

1. Login to LuCI web interface
2. Navigate to **Network** → **Enhanced ATC**
3. Enable FCC Unlock if needed
4. Click on **Status** tab to view modem information
5. Configure interface settings:
   - Device path (e.g., `/dev/ttyUSB3`)
   - APN from your carrier
   - Username/Password if required
   - Authentication type
6. Click **Save & Apply**

### 6. Configure via Command Line

Edit the configuration file:

```bash
vi /etc/config/enhanced_atc
```

Example configuration:

```
config general 'general'
    option fcc_unlock '1'
    option firmware_check '1'
    option atc_debug '0'

config interface 'wan'
    option enabled '1'
    option device '/dev/ttyUSB3'
    option apn 'internet'
    option username ''
    option password ''
    option auth '0'
    option pdp 'IP'
    option delay '5'
    option max_retries '3'
    option preferred_mode 'auto'
```

Apply configuration:

```bash
/etc/init.d/network reload
```

## Verification

### Check FCC Lock Status

```bash
enhanced-atc-cli fcc-status
```

### Unlock FCC (if needed)

```bash
enhanced-atc-cli fcc-unlock
```

### View Modem Information

```bash
enhanced-atc-cli fw-info
```

### Check Connection Status

```bash
enhanced-atc-cli status
```

### View Logs

```bash
tail -f /tmp/atc_logs/INFO.log
tail -f /tmp/atc_logs/FCC.log
tail -f /tmp/atc_logs/ERROR.log
```

## Troubleshooting

### Modem Not Detected

1. Check USB connection
2. Verify device path: `ls -l /dev/ttyUSB*`
3. Check kernel messages: `dmesg | grep ttyUSB`

### FCC Unlock Fails

1. Verify modem model is FM350-GL
2. Check firmware version: `enhanced-atc-cli fw-info`
3. Try manual unlock: `enhanced-atc-cli fcc-unlock`
4. Check logs: `cat /tmp/atc_logs/ERROR.log`

### Connection Fails

1. Verify APN settings with your carrier
2. Check device permissions: `ls -l /dev/ttyUSB3`
3. Enable debug logging in `/etc/config/enhanced_atc`
4. Review logs in `/tmp/atc_logs/`

### Enable Debug Mode

Edit `/etc/config/enhanced_atc`:

```
config general 'general'
    option atc_debug '1'
```

Reload network:

```bash
/etc/init.d/network reload
```

Check debug logs:

```bash
tail -f /tmp/atc_logs/DEBUG.log
```

## Uninstallation

```bash
opkg remove enhanced-atc
rm -rf /tmp/atc_logs
```

## Support

For issues and support:
- GitHub Issues: https://github.com/yourusername/enhanced-atc-fm350/issues
- Check logs in `/tmp/atc_logs/`
- Enable debug mode for detailed information
