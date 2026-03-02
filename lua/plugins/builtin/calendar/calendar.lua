local Plugin = require("plugins.base")

return Plugin.new({
	name = "calendar",
	version = "1.0.0",
	description = "Calendar display with events",
	author = "Moondeck",

	config_schema = {
		show_days = { type = "number", default = 7 },
		first_day = { type = "enum", values = { "sunday", "monday" }, default = "sunday" },
		show_events = { type = "boolean", default = true },
	},

	default_config = {
		show_days = 7,
		first_day = "sunday",
		show_events = true,
	},

	fetch_interval = 3600,

	sizes = { "full", "half_v", "half_h" },

	on_init = function(self)
		local cached = self:retrieve("calendar_data")
		if cached then
			self.data = cached
		end
	end,

	on_fetch = function(self)
		local now = os.date("*t")
		local days = {}

		for i = 0, self.config.show_days - 1 do
			local day_time = os.time() + (i * 86400)
			local day = os.date("*t", day_time)
			table.insert(days, {
				day = day.day,
				month = day.month,
				year = day.year,
				wday = day.wday,
				is_today = i == 0,
			})
		end

		local data = {
			current_date = now,
			days = days,
			events = {},
		}

		self:store("calendar_data", data)
		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		local weekdays = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
		local months = {
			"January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December",
		}

		local now = data.current_date
		local header = string.format("%s %d", months[now.month], now.year)
		display.text_font(x, y, header, theme.colors.accent_primary, theme.fonts.heading)

		local cell_w = math.floor((w - 10) / 7)
		local cell_h = 30
		local start_y = y + 40

		for i, day in ipairs(weekdays) do
			local dx = x + (i - 1) * cell_w
			display.text_font(dx, start_y, day, theme.colors.text_muted, theme.fonts.small)
		end

		start_y = start_y + 25

		for i, day_data in ipairs(data.days) do
			if i <= 7 then
				local dx = x + (day_data.wday - 1) * cell_w
				local dy = start_y

				local day_str = tostring(day_data.day)
				local color = day_data.is_today and theme.colors.accent_tertiary or theme.colors.text_primary

				if day_data.is_today then
					display.rect(dx - 2, dy - 2, cell_w - 4, cell_h - 4, theme.colors.accent_tertiary, false)
				end

				display.text_font(dx + 5, dy + 5, day_str, color, theme.fonts.body)
			end
		end
	end,
})
