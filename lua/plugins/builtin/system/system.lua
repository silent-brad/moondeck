local Plugin = require("plugins.base")

local function rssi_to_strength(rssi)
	if rssi >= -50 then
		return "Excellent"
	elseif rssi >= -60 then
		return "Good"
	elseif rssi >= -70 then
		return "Fair"
	else
		return "Weak"
	end
end

local function format_uptime(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)

	if days > 0 then
		return string.format("%dd %dh %dm", days, hours, mins)
	elseif hours > 0 then
		return string.format("%dh %dm", hours, mins)
	else
		return string.format("%dm", mins)
	end
end

return Plugin.new({
	name = "system",
	version = "1.0.0",
	description = "System information (memory, WiFi, battery)",
	author = "Moondeck",

	config_schema = {
		show_memory = { type = "boolean", default = true },
		show_wifi = { type = "boolean", default = true },
		show_battery = { type = "boolean", default = true },
		show_uptime = { type = "boolean", default = true },
	},

	default_config = {
		show_memory = true,
		show_wifi = true,
		show_battery = true,
		show_uptime = true,
	},

	fetch_interval = 10,

	sizes = { "full", "half_v", "half_h", "quarter" },

	on_fetch = function(self)
		local data = {}

		if sys and sys.heap then
			data.free_heap = sys.heap()
			data.total_heap = 512000
		else
			data.free_heap = 256000
			data.total_heap = 512000
		end
		data.heap_percent = math.floor((data.free_heap / data.total_heap) * 100)

		if wifi and wifi.get_rssi then
			data.wifi_rssi = wifi.get_rssi()
			data.wifi_ssid = wifi.get_ssid and wifi.get_ssid() or "Unknown"
			data.wifi_connected = wifi.is_connected and wifi.is_connected() or true
		else
			data.wifi_rssi = -55
			data.wifi_ssid = "Network"
			data.wifi_connected = wifi and wifi.is_connected and wifi.is_connected() or false
		end
		data.wifi_strength = rssi_to_strength(data.wifi_rssi)

		if battery and battery.get_level then
			data.battery_level = battery.get_level()
			data.battery_charging = battery.is_charging and battery.is_charging() or false
		else
			data.battery_level = 100
			data.battery_charging = false
		end

		if sys and sys.uptime then
			data.uptime = sys.uptime()
		else
			data.uptime = os.time() % 86400
		end

		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		local line_y = y
		local line_height = size == "quarter" and 20 or 28

		if size == "quarter" then
			local mem_str = string.format("Mem: %d%%", data.heap_percent)
			display.text_font(x, line_y, mem_str, theme.colors.text_primary, theme.fonts.small)
			line_y = line_y + line_height

			local wifi_icon = data.wifi_connected and "+" or "-"
			local wifi_str = string.format("WiFi: %s %ddBm", wifi_icon, data.wifi_rssi)
			display.text_font(x, line_y, wifi_str, theme.colors.text_primary, theme.fonts.small)
		else
			display.text_font(x, line_y, "System Info", theme.colors.accent_primary, theme.fonts.title)
			line_y = line_y + line_height + 10

			if self.config.show_memory then
				display.text_font(x, line_y, "Memory", theme.colors.text_muted, theme.fonts.small)
				line_y = line_y + 18

				local bar_w = math.min(w - 20, 200)
				local filled_w = math.floor(bar_w * (data.heap_percent / 100))
				display.rect(x, line_y, bar_w, 12, theme.colors.bg_secondary, true)
				display.rect(x, line_y, filled_w, 12, theme.colors.accent_success, true)

				local mem_str = string.format("%dKB free (%d%%)", math.floor(data.free_heap / 1024), data.heap_percent)
				display.text_font(x + bar_w + 10, line_y, mem_str, theme.colors.text_secondary, theme.fonts.small)
				line_y = line_y + line_height
			end

			if self.config.show_wifi then
				display.text_font(x, line_y, "WiFi", theme.colors.text_muted, theme.fonts.small)
				line_y = line_y + 18

				local status = data.wifi_connected and "Connected" or "Disconnected"
				local status_color = data.wifi_connected and theme.colors.accent_success or theme.colors.accent_error
				display.text_font(x, line_y, status, status_color, theme.fonts.body)

				if data.wifi_connected then
					local wifi_str = string.format("(%ddBm, %s)", data.wifi_rssi, data.wifi_strength)
					display.text_font(x + 100, line_y, wifi_str, theme.colors.text_secondary, theme.fonts.small)
				end
				line_y = line_y + line_height
			end

			if self.config.show_battery then
				display.text_font(x, line_y, "Battery", theme.colors.text_muted, theme.fonts.small)
				line_y = line_y + 18

				local bar_w = math.min(w - 20, 100)
				local filled_w = math.floor(bar_w * (data.battery_level / 100))
				local bat_color = data.battery_level > 20 and theme.colors.accent_success or theme.colors.accent_error
				display.rect(x, line_y, bar_w, 12, theme.colors.bg_secondary, true)
				display.rect(x, line_y, filled_w, 12, bat_color, true)

				local bat_str = string.format("%d%%", data.battery_level)
				display.text_font(x + bar_w + 10, line_y, bat_str, theme.colors.text_secondary, theme.fonts.small)
				line_y = line_y + line_height
			end

			if self.config.show_uptime then
				display.text_font(x, line_y, "Uptime", theme.colors.text_muted, theme.fonts.small)
				line_y = line_y + 18

				local uptime_str = format_uptime(data.uptime)
				display.text_font(x, line_y, uptime_str, theme.colors.text_primary, theme.fonts.body)
			end
		end
	end,
})
