# Configuration Examples

This directory contains example configurations for Enhanced ATC with Fibocom FM350-GL modem.

## Available Examples

### Carrier-Specific Configurations

- **tmobile-usa.conf** - T-Mobile USA configuration
  - APN: fast.t-mobile.com
  - IPv4/IPv6 dual-stack
  - No authentication

- **att-usa.conf** - AT&T USA configuration
  - APN: broadband
  - IPv4 only
  - No authentication

- **verizon-usa.conf** - Verizon USA configuration
  - APN: vzwinternet
  - IPv4 only
  - No authentication

### Special Purpose Configurations

- **generic-authenticated.conf** - For carriers requiring authentication
  - Shows username/password setup
  - PAP/CHAP configuration

- **debug-mode.conf** - For troubleshooting
  - Enabled debug logging
  - Increased timeouts and retries
  - More frequent monitoring

- **lte-only.conf** - Force LTE-only mode
  - Disable 5G
  - Better compatibility in some areas

## How to Use

### Method 1: Copy to Router

```bash
# Copy example to router
scp tmobile-usa.conf root@192.168.1.1:/tmp/

# Install on router
ssh root@192.168.1.1
cp /tmp/tmobile-usa.conf /etc/config/enhanced_atc
/etc/init.d/network reload
```

### Method 2: Manual Configuration

Open the example file and use the settings as reference when configuring via:
- LuCI web interface (Network → Enhanced ATC)
- UCI commands
- Direct editing of `/etc/config/enhanced_atc`

### Method 3: UCI Commands

```bash
# Example: Configure T-Mobile settings
uci set enhanced_atc.wan.apn='fast.t-mobile.com'
uci set enhanced_atc.wan.pdp='IPV4V6'
uci set enhanced_atc.wan.enabled='1'
uci commit enhanced_atc
/etc/init.d/network reload
```

## Customizing Examples

Before using any example, verify:

1. **Device Path**: Confirm your modem's device path
   ```bash
   ls -l /dev/ttyUSB*
   ```

2. **APN**: Verify correct APN with your carrier
   - Contact carrier support if unsure
   - Check carrier's website for IoT/router APN

3. **Authentication**: Check if your plan requires credentials
   - Most US carriers don't require authentication
   - International carriers often do

4. **Network Mode**: Choose based on coverage
   - 'auto' for best performance
   - 'lte' for compatibility
   - '5g' for maximum speed

## Testing Configuration

After applying configuration:

```bash
# Check modem status
enhanced-atc-cli status

# Check FCC lock
enhanced-atc-cli fcc-status

# View connection logs
tail -f /tmp/atc_logs/INFO.log
```

## Troubleshooting

If connection fails:

1. Enable debug mode (use debug-mode.conf as reference)
2. Check logs: `tail -f /tmp/atc_logs/ERROR.log`
3. Verify APN with carrier
4. Ensure SIM is activated for data
5. Check device path is correct

## Contributing

Have a working configuration for another carrier? Please contribute:
1. Create a new .conf file following the naming pattern
2. Add carrier name and country
3. Include notes about special requirements
4. Submit a pull request

## Need Help?

- Check [INSTALLATION.md](../docs/INSTALLATION.md) for installation help
- See [CONFIGURATION.md](../docs/CONFIGURATION.md) for detailed option explanations
- Report issues on GitHub
