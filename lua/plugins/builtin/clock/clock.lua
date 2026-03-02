local Plugin = require("plugins.base")

return Plugin.new({
	name = "clock",
	version = "1.0.0",
	description = "Digital clock with date",
	author = "Moondeck",

	config_schema = {
		format_24h = { type = "boolean", default = false },
		show_seconds = { type = "boolean", default = false },
		show_date = { type = "boolean", default = true },
		timezone = { type = "string", default = "" },
	},

	default_config = {
		format_24h = false,
		show_seconds = false,
		show_date = true,
		timezone = "",
	},

	fetch_interval = 1,

	sizes = { "full", "half_v", "half_h", "quarter" },

	on_fetch = function(self)
		local now = os.date("*t")
		return {
			hour = now.hour,
			min = now.min,
			sec = now.sec,
			day = now.day,
			month = now.month,
			year = now.year,
			wday = now.wday,
		}
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			data = os.date("*t")
		end

		local hour = data.hour
		local period = ""

		if not self.config.format_24h then
			period = hour >= 12 and " PM" or " AM"
			hour = hour % 12
			if hour == 0 then
				hour = 12
			end
		end

		local time_str
		if self.config.show_seconds then
			time_str = string.format("%d:%02d:%02d%s", hour, data.min, data.sec, period)
		else
			time_str = string.format("%d:%02d%s", hour, data.min, period)
		end

		if size == "quarter" then
			display.text_font(x, y, time_str, theme.colors.accent_primary, theme.fonts.title)
		else
			display.text_font(x, y, time_str, theme.colors.accent_primary, theme.fonts.heading)

			if self.config.show_date then
				local weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
				local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

				local date_str =
					string.format("%s, %s %d, %d", weekdays[data.wday], months[data.month], data.day, data.year)
				display.text_font(x, y + 40, date_str, theme.colors.text_secondary, theme.fonts.body)
			end
		end
	end,
})
