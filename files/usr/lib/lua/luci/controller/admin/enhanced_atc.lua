module("luci.controller.admin.enhanced_atc", package.seeall)

function index()
    entry({"admin", "network", "enhanced_atc"}, cbi("admin_network/enhanced_atc"), _("Enhanced ATC"), 60).dependent = true
    entry({"admin", "network", "enhanced_atc", "status"}, template("admin_network/enhanced_atc_status"), _("Status & Diagnostics"), 61).dependent = true
    entry({"admin", "network", "enhanced_atc", "fcc_status"}, call("action_fcc_status")).leaf = true
    entry({"admin", "network", "enhanced_atc", "fcc_unlock"}, call("action_fcc_unlock")).leaf = true
    entry({"admin", "network", "enhanced_atc", "modem_info"}, call("action_modem_info")).leaf = true
    entry({"admin", "network", "enhanced_atc", "ca_status"}, call("action_ca_status")).leaf = true
    entry({"admin", "network", "enhanced_atc", "band_scan"}, call("action_band_scan")).leaf = true
    entry({"admin", "network", "enhanced_atc", "logs"}, call("action_logs")).leaf = true
end

function action_fcc_status()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"

    local result = sys.exec("enhanced-atc-cli fcc-status 2>&1")
    local status = "Unknown"

    if result:match("UNLOCKED") then
        status = '<span style="color:green;">FCC Unlocked</span>'
    elseif result:match("LOCKED") then
        status = '<span style="color:red;">FCC Locked</span>'
    else
        status = '<span style="color:orange;">Unable to determine</span>'
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        status = status,
        raw = result
    })
end

function action_fcc_unlock()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"

    local result = sys.exec("enhanced-atc-cli fcc-unlock 2>&1")
    local success = result:match("SUCCESS") ~= nil

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = success,
        message = result
    })
end

function action_modem_info()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"

    local status_result = sys.exec("enhanced-atc-cli status 2>&1")
    local fw_result = sys.exec("enhanced-atc-cli fw-info 2>&1")

    local modem_status = "Not Connected"
    if status_result:match("Connected") then
        modem_status = '<span style="color:green;">Connected</span>'
    elseif status_result:match("No response") then
        modem_status = '<span style="color:red;">No Response</span>'
    end

    local firmware = "Unknown"
    if fw_result and fw_result ~= "" then
        firmware = fw_result:gsub("\n", "<br/>")
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        modem_status = modem_status,
        firmware = firmware
    })
end

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

    -- Strict whitelist validation - prevent command injection
    local valid_modes = {
        quick = true,
        medium = true,
        full = true
    }

    if not valid_modes[mode] then
        luci.http.prepare_content("application/json")
        luci.http.write_json({
            success = false,
            error = "Invalid scan mode. Allowed: quick, medium, full"
        })
        return
    end

    -- Safe to execute - mode is validated against whitelist
    local result = sys.exec("enhanced-atc-cli scan " .. mode .. " 2>&1")

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        success = true,
        mode = mode,
        results = result
    })
end

function action_logs()
    local sys = require "luci.sys"
    local fs = require "nixio.fs"

    local log_content = ""
    local log_files = {"/tmp/atc_logs/INFO.log", "/tmp/atc_logs/FCC.log", "/tmp/atc_logs/ERROR.log"}

    for _, log_file in ipairs(log_files) do
        if fs.access(log_file) then
            local content = sys.exec("tail -n 50 " .. log_file .. " 2>/dev/null")
            if content and content ~= "" then
                log_content = log_content .. "=== " .. log_file .. " ===\n" .. content .. "\n\n"
            end
        end
    end

    if log_content == "" then
        log_content = "No logs available yet."
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        logs = log_content
    })
end
