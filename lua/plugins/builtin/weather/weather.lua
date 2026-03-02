local Plugin = require("plugins.base")
local api = require("plugins.builtin.weather.api")
local icons = require("plugins.builtin.weather.icons")

return Plugin.new({
	name = "weather",
	version = "1.0.0",
	description = "Current weather and forecast",
	author = "Moondeck",

	config_schema = {
		api_key = { type = "string", required = true, secret = true },
		city = { type = "string", required = true },
		country = { type = "string", default = "US" },
		units = { type = "enum", values = { "imperial", "metric" }, default = "imperial" },
	},

	default_config = {
		units = "imperial",
		country = "US",
	},

	fetch_interval = 600,

	sizes = { "full", "half_v", "half_h", "quarter" },

	on_init = function(self)
		local cached = self:retrieve("weather_data")
		if cached then
			self.data = cached
		end
	end,

	on_fetch = function(self)
		local data = api.fetch_current(self.config.api_key, self.config.city, self.config.country, self.config.units)
		if data then
			self:store("weather_data", data)
		end
		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		if size == "quarter" then
			local temp_str = string.format("%d°", data.temp)
			display.text_font(x, y, temp_str, theme.colors.accent_primary, theme.fonts.heading)
			icons.draw(x + 60, y, data.condition, theme, "small")
		else
			local temp_str = string.format("%d°%s", data.temp, data.units == "imperial" and "F" or "C")
			display.text_font(x, y, temp_str, theme.colors.accent_primary, theme.fonts.heading)

			display.text_font(x, y + 45, data.city, theme.colors.text_primary, theme.fonts.title)
			display.text_font(x, y + 70, data.description, theme.colors.text_secondary, theme.fonts.body)

			local feels_str = string.format("Feels: %d°", data.feels_like)
			display.text_font(x, y + 95, feels_str, theme.colors.text_muted, theme.fonts.small)

			local humid_str = string.format("Humidity: %d%%", data.humidity)
			display.text_font(x, y + 115, humid_str, theme.colors.text_muted, theme.fonts.small)

			icons.draw(x + w - 70, y, data.condition, theme, "large")
		end
	end,
})
