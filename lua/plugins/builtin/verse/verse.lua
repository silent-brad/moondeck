local Plugin = require("plugins.base")

return Plugin.new({
	name = "verse",
	version = "1.0.0",
	description = "Daily Bible verse",
	author = "Moondeck",

	config_schema = {
		version = { type = "enum", values = { "KJV", "ESV", "NIV", "NASB" }, default = "KJV" },
		category = { type = "enum", values = { "daily", "random", "hope", "strength" }, default = "daily" },
	},

	default_config = {
		version = "KJV",
		category = "daily",
	},

	fetch_interval = 3600,

	sizes = { "full", "half_v", "half_h" },

	on_init = function(self)
		local cached = self:retrieve("verse_data")
		if cached then
			self.data = cached
		end
	end,

	on_fetch = function(self)
		local verses = {
			{
				text = "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
				reference = "John 3:16",
			},
			{
				text = "Trust in the LORD with all thine heart; and lean not unto thine own understanding.",
				reference = "Proverbs 3:5",
			},
			{
				text = "I can do all things through Christ which strengtheneth me.",
				reference = "Philippians 4:13",
			},
			{
				text = "The LORD is my shepherd; I shall not want.",
				reference = "Psalm 23:1",
			},
			{
				text = "Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.",
				reference = "Joshua 1:9",
			},
		}

		local day_of_year = os.date("*t").yday
		local index = ((day_of_year - 1) % #verses) + 1
		local data = verses[index]
		data.version = self.config.version

		self:store("verse_data", data)
		return data
	end,

	on_render = function(self, x, y, w, h, theme, size)
		local data = self.data

		if not data then
			display.text_font(x, y + 20, "Loading...", theme.colors.text_muted, theme.fonts.body)
			return
		end

		local text = data.text
		local max_chars = math.floor((w - 20) / 8)
		local lines = {}
		local current_line = ""

		for word in text:gmatch("%S+") do
			if #current_line + #word + 1 <= max_chars then
				current_line = current_line == "" and word or (current_line .. " " .. word)
			else
				table.insert(lines, current_line)
				current_line = word
			end
		end
		if current_line ~= "" then
			table.insert(lines, current_line)
		end

		local line_height = 22
		local start_y = y

		for i, line in ipairs(lines) do
			if start_y + (i - 1) * line_height < y + h - 30 then
				display.text_font(x, start_y + (i - 1) * line_height, line, theme.colors.text_primary, theme.fonts.body)
			end
		end

		local ref_y = start_y + #lines * line_height + 10
		if ref_y > y + h - 25 then
			ref_y = y + h - 25
		end

		local ref_str = string.format("— %s (%s)", data.reference, data.version)
		display.text_font(x, ref_y, ref_str, theme.colors.accent_secondary, theme.fonts.small)
	end,
})
