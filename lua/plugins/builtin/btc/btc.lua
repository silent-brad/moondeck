local Plugin = require("plugins.base")
local api = require("plugins.builtin.btc.api")

return Plugin.new({
	name = "btc",
	version = "1.0.0",
	description = "Bitcoin price tracker",
	author = "Moondeck",

	config_schema = {
		currency = { type = "enum", values = { "USD", "EUR", "GBP" }, default = "USD" },
		show_24h_change = { type = "boolean", default = true },
	},

	default_config = {
		currency = "USD",
		show_24h_change = true,
	},

	fetch_interval = 300,

	sizes = { "full", "half_v", "half_h", "quarter" },

	on_init = function(self)
		local cached = self:retrieve("btc_data")
		if cached then
			self.data = cached
		end
	end,

	on_fetch = function(self)
		local data = api.fetch_price(self.config.currency)
		if data then
			self:store("btc_data", data)
		end
		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		local symbol = { USD = "$", EUR = "€", GBP = "£" }
		local prefix = symbol[data.currency] or "$"

		if size == "quarter" then
			display.text_font(x, y, "BTC", theme.colors.accent_tertiary, theme.fonts.title)
			local price_str = string.format("%s%s", prefix, api.format_number(data.price))
			display.text_font(x, y + 25, price_str, theme.colors.text_primary, theme.fonts.body)
		else
			display.text_font(x, y, "Bitcoin", theme.colors.accent_tertiary, theme.fonts.heading)

			local price_str = string.format("%s%s", prefix, api.format_number(data.price))
			display.text_font(x, y + 40, price_str, theme.colors.text_primary, theme.fonts.title)

			if self.config.show_24h_change and data.change_24h then
				local change_color = data.change_24h >= 0 and theme.colors.accent_success or theme.colors.accent_error
				local arrow = data.change_24h >= 0 and "↑" or "↓"
				local change_str = string.format("%s %.2f%%", arrow, math.abs(data.change_24h))
				display.text_font(x, y + 70, change_str, change_color, theme.fonts.body)
			end

			if data.high_24h and data.low_24h then
				local range_str = string.format(
					"H: %s%s  L: %s%s",
					prefix,
					api.format_number(data.high_24h),
					prefix,
					api.format_number(data.low_24h)
				)
				display.text_font(x, y + 95, range_str, theme.colors.text_muted, theme.fonts.small)
			end
		end
	end,
})
