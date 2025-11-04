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

return m
