m = Map("enhanced_atc", translate("Enhanced ATC Configuration"),
    translate("Configuration for Enhanced ATC protocol with FCC unlock support for Fibocom FM350-GL"))

-- General Settings Section
s = m:section(TypedSection, "general", translate("General Settings"))
s.addremove = false
s.anonymous = true

fcc_unlock = s:option(Flag, "fcc_unlock", translate("Enable FCC Unlock"),
    translate("Automatically unlock FCC restrictions on modem startup"))
fcc_unlock.default = "1"
fcc_unlock.rmempty = false

firmware_check = s:option(Flag, "firmware_check", translate("Check Firmware Version"),
    translate("Verify firmware version on modem initialization"))
firmware_check.default = "1"
firmware_check.rmempty = false

atc_debug = s:option(Flag, "atc_debug", translate("Enable Debug Logging"),
    translate("Enable verbose debug logging for troubleshooting"))
atc_debug.default = "0"
atc_debug.rmempty = false

auto_optimize = s:option(Flag, "auto_optimize", translate("Auto Optimization"),
    translate("Automatically optimize connection parameters based on signal quality"))
auto_optimize.default = "0"
auto_optimize.rmempty = false

power_management = s:option(Flag, "power_management", translate("Power Management"),
    translate("Enable power-saving features for the modem"))
power_management.default = "0"
power_management.rmempty = false

-- Interface Configuration Section
i = m:section(TypedSection, "interface", translate("Interface Configuration"))
i.addremove = true
i.anonymous = false
i.template = "cbi/tblsection"

enabled = i:option(Flag, "enabled", translate("Enabled"))
enabled.default = "0"
enabled.rmempty = false

device = i:option(Value, "device", translate("Device Path"),
    translate("Serial device path (e.g., /dev/ttyUSB3)"))
device.placeholder = "/dev/ttyUSB3"
device.rmempty = false

apn = i:option(Value, "apn", translate("APN"),
    translate("Access Point Name provided by your carrier"))
apn.placeholder = "internet"

username = i:option(Value, "username", translate("Username"),
    translate("Authentication username (if required)"))
username.placeholder = ""

password = i:option(Value, "password", translate("Password"),
    translate("Authentication password (if required)"))
password.placeholder = ""
password.password = true

auth = i:option(ListValue, "auth", translate("Authentication Type"))
auth:value("0", translate("None"))
auth:value("1", translate("PAP"))
auth:value("2", translate("CHAP"))
auth:value("3", translate("PAP/CHAP"))
auth.default = "0"

pdp = i:option(ListValue, "pdp", translate("PDP Type"))
pdp:value("IP", "IPv4")
pdp:value("IPV6", "IPv6")
pdp:value("IPV4V6", "IPv4/IPv6")
pdp.default = "IP"

delay = i:option(Value, "delay", translate("Connection Delay (seconds)"),
    translate("Delay before starting connection (0-60 seconds)"))
delay.placeholder = "5"
delay.datatype = "range(0,60)"
delay.default = "5"

max_retries = i:option(Value, "max_retries", translate("Max Retries"),
    translate("Maximum number of connection retry attempts"))
max_retries.placeholder = "3"
max_retries.datatype = "range(1,10)"
max_retries.default = "3"

preferred_mode = i:option(ListValue, "preferred_mode", translate("Preferred Network Mode"))
preferred_mode:value("auto", translate("Auto"))
preferred_mode:value("lte", translate("LTE Only"))
preferred_mode:value("5g", translate("5G Preferred"))
preferred_mode.default = "auto"

signal_threshold = i:option(Value, "signal_threshold", translate("Signal Threshold (dBm)"),
    translate("Minimum acceptable signal strength"))
signal_threshold.placeholder = "-90"
signal_threshold.datatype = "integer"
signal_threshold.default = "-90"

monitor_interval = i:option(Value, "monitor_interval", translate("Monitor Interval (seconds)"),
    translate("How often to check connection status"))
monitor_interval.placeholder = "60"
monitor_interval.datatype = "range(30,300)"
monitor_interval.default = "60"

-- Band Locking Section (Fibocom FM350-GL specific)
b = m:section(TypedSection, "interface", translate("Band Locking (Fibocom FM350-GL)"))
b.addremove = false
b.anonymous = false

band_locking = b:option(Flag, "band_locking", translate("Enable Band Locking"),
    translate("Lock modem to specific frequency bands (FM350-GL only)"))
band_locking.default = "0"
band_locking.rmempty = false

-- LTE Bands
lte_bands = b:option(Value, "lte_bands", translate("LTE Bands"),
    translate("Comma-separated list of LTE bands (e.g., 3,7,20)"))
lte_bands:depends("band_locking", "1")
lte_bands.placeholder = "3,7,20"
lte_bands.datatype = "string"

lte_help = b:option(DummyValue, "_lte_help", translate("Common LTE Bands in Poland:"))
lte_help:depends("band_locking", "1")
lte_help.rawhtml = true
lte_help.value = [[
<ul style="font-size:12px; margin:5px 0; padding-left:20px;">
<li><b>B1</b> (2100 MHz) - Plus</li>
<li><b>B3</b> (1800 MHz) - Play, Orange, Plus, T-Mobile</li>
<li><b>B7</b> (2600 MHz) - Play, Orange, Plus, T-Mobile</li>
<li><b>B20</b> (800 MHz) - Play, Orange, Plus, T-Mobile (rural)</li>
</ul>
<p style="font-size:11px; color:#666; margin:5px 0;">
<b>FM350-GL supported LTE bands:</b><br>
FDD: 1, 2, 3, 4, 5, 7, 8, 12, 13, 14, 17, 18, 19, 20, 25, 26, 28, 29, 30, 32, 66, 71<br>
TDD: 34, 38, 39, 40, 41, 42, 43, 48
</p>
]]

-- 5G SA Bands
nr5g_sa_bands = b:option(Value, "nr5g_sa_bands", translate("5G SA Bands"),
    translate("Comma-separated list of 5G Standalone bands (e.g., 78)"))
nr5g_sa_bands:depends("band_locking", "1")
nr5g_sa_bands.placeholder = "78"
nr5g_sa_bands.datatype = "string"

-- 5G NSA Bands
nr5g_nsa_bands = b:option(Value, "nr5g_nsa_bands", translate("5G NSA Bands"),
    translate("Comma-separated list of 5G Non-Standalone bands (e.g., 78)"))
nr5g_nsa_bands:depends("band_locking", "1")
nr5g_nsa_bands.placeholder = "78"
nr5g_nsa_bands.datatype = "string"

nr5g_help = b:option(DummyValue, "_nr5g_help", translate("Common 5G Bands in Poland:"))
nr5g_help:depends("band_locking", "1")
nr5g_help.rawhtml = true
nr5g_help.value = [[
<ul style="font-size:12px; margin:5px 0; padding-left:20px;">
<li><b>n78</b> (3500 MHz) - Play, Orange, Plus, T-Mobile (primary 5G)</li>
</ul>
<p style="font-size:11px; color:#666; margin:5px 0;">
<b>FM350-GL supported 5G NR bands:</b><br>
n1, n2, n3, n5, n7, n8, n12, n13, n14, n18, n20, n25, n26, n28, n29, n30,<br>
n38, n40, n41, n48, n66, n70, n71, n77, n78, n79
</p>
]]

-- Presets for Polish carriers
band_presets = b:option(ListValue, "_band_preset", translate("Quick Presets"),
    translate("Apply recommended band configuration for Polish carriers"))
band_presets:depends("band_locking", "1")
band_presets:value("", translate("-- Select Preset --"))
band_presets:value("play", "Play (B3,B7,B20 + n78)")
band_presets:value("orange", "Orange (B3,B7,B20 + n78)")
band_presets:value("plus", "Plus (B1,B3,B7,B20 + n78)")
band_presets:value("tmobile", "T-Mobile (B3,B7,B20 + n78)")
band_presets.write = function(self, section, value)
    if value == "play" or value == "orange" or value == "tmobile" then
        self.map:set(section, "lte_bands", "3,7,20")
        self.map:set(section, "nr5g_sa_bands", "78")
        self.map:set(section, "nr5g_nsa_bands", "78")
    elseif value == "plus" then
        self.map:set(section, "lte_bands", "1,3,7,20")
        self.map:set(section, "nr5g_sa_bands", "78")
        self.map:set(section, "nr5g_nsa_bands", "78")
    end
end

-- Warning message
band_warning = b:option(DummyValue, "_warning", " ")
band_warning:depends("band_locking", "1")
band_warning.rawhtml = true
band_warning.value = [[
<div style="background:#fff3cd; border:1px solid #ffc107; padding:10px; border-radius:4px; margin:10px 0;">
<b style="color:#856404;">⚠️ Warning:</b>
<ul style="margin:5px 0; padding-left:20px; color:#856404;">
<li>Band locking is <b>specific to Fibocom FM350-GL</b> modem only</li>
<li>Incorrect band configuration may prevent connection</li>
<li>Locking to unavailable bands will cause connection failure</li>
<li>Leave empty for automatic band selection (recommended for beginners)</li>
<li>Changes require modem restart to take effect</li>
</ul>
</div>
]]

return m
