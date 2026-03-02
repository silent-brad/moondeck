local Plugin = require("plugins.base")

return Plugin.new({
	name = "todo",
	version = "1.0.0",
	description = "Todo list display",
	author = "Moondeck",

	config_schema = {
		max_items = { type = "number", default = 5 },
		show_completed = { type = "boolean", default = false },
		source = { type = "enum", values = { "local", "todoist", "google_tasks" }, default = "local" },
	},

	default_config = {
		max_items = 5,
		show_completed = false,
		source = "local",
	},

	fetch_interval = 300,

	sizes = { "full", "half_v", "half_h" },

	on_init = function(self)
		local cached = self:retrieve("todo_data")
		if cached then
			self.data = cached
		end
	end,

	on_fetch = function(self)
		local items = self:retrieve("todo_items")
			or {
				{ id = 1, text = "Review project goals", completed = false, priority = 1 },
				{ id = 2, text = "Update documentation", completed = false, priority = 2 },
				{ id = 3, text = "Fix display alignment", completed = true, priority = 2 },
				{ id = 4, text = "Test plugin system", completed = false, priority = 1 },
				{ id = 5, text = "Optimize rendering", completed = false, priority = 3 },
			}

		if not self.config.show_completed then
			local filtered = {}
			for _, item in ipairs(items) do
				if not item.completed then
					table.insert(filtered, item)
				end
			end
			items = filtered
		end

		table.sort(items, function(a, b)
			if a.completed ~= b.completed then
				return not a.completed
			end
			return a.priority < b.priority
		end)

		local data = {
			items = items,
			total = #items,
		}

		self:store("todo_data", data)
		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		display.text_font(x, y, "Todo", theme.colors.accent_primary, theme.fonts.title)

		local count_str = string.format("(%d items)", data.total)
		display.text_font(x + 60, y + 3, count_str, theme.colors.text_muted, theme.fonts.small)

		local line_y = y + 35
		local line_height = 25
		local max_items = math.min(self.config.max_items, #data.items)

		local priority_colors = {
			[1] = theme.colors.accent_error,
			[2] = theme.colors.accent_warning,
			[3] = theme.colors.text_muted,
		}

		for i = 1, max_items do
			local item = data.items[i]
			if not item then
				break
			end

			local checkbox = item.completed and "☑" or "☐"
			local text_color = item.completed and theme.colors.text_muted or theme.colors.text_primary
			local priority_color = priority_colors[item.priority] or theme.colors.text_muted

			display.text_font(x, line_y, checkbox, priority_color, theme.fonts.body)

			local text = item.text
			local max_chars = math.floor((w - 30) / 8)
			if #text > max_chars then
				text = text:sub(1, max_chars - 3) .. "..."
			end

			display.text_font(x + 25, line_y, text, text_color, theme.fonts.body)

			line_y = line_y + line_height
		end

		if #data.items > max_items then
			local more_str = string.format("+%d more", #data.items - max_items)
			display.text_font(x, line_y, more_str, theme.colors.text_muted, theme.fonts.small)
		end
	end,
})
