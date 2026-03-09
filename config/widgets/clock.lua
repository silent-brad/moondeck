-- Clock Widget
-- Displays current time and date with TRMNL-inspired styling

local theme = require("theme")
local components = require("components")

local M = {}

-- Safe theme getter with fallback
local function get_theme()
	if theme and theme.get then
		local result = theme:get()
		if result then
			return result
		end
	end
	-- Fallback colors
	return {
		text_primary = "#ffffff",
		text_muted = "#606070",
		accent_primary = "#00d4ff",
	}
end

function M.init(ctx)
	return {
		x = ctx.x,
		y = ctx.y,
		width = ctx.width,
		height = ctx.height,
		show_seconds = ctx.opts.show_seconds ~= false,
		show_date = ctx.opts.show_date ~= false,
		format_24h = ctx.opts.format_24h or false,
		last_update = 0,
	}
end

function M.update(state, delta_ms)
	state.last_update = state.last_update + delta_ms
end

-- Safe floor function
local function floor(n)
	if math and math.floor then
		return math.floor(n)
	end
	-- Fallback: truncate towards zero
	local i = n - (n % 1)
	if n < 0 and i ~= n then
		return i - 1
	end
	return i
end

-- Safe string format (for time display)
local function format_time_component(n)
	if n < 10 then
		return "0" .. n
	end
	return "" .. n
end

function M.render(state, gfx)
	local th = get_theme()
	local now = device and device.seconds and device.seconds() or 0

	-- Calculate time components
	local secs = now % 60
	local mins = floor(now / 60) % 60
	local hours = floor(now / 3600) % 24

	-- Draw card background
	components.card(gfx, 0, 0, state.width, state.height)

	-- Padding
	local px, py = 20, 15

	-- Format time
	local display_hours = hours
	local am_pm = ""

	if not state.format_24h then
		am_pm = hours >= 12 and "PM" or "AM"
		display_hours = hours % 12
		if display_hours == 0 then
			display_hours = 12
		end
	end

	-- Build time string
	local time_str
	if state.show_seconds then
		time_str = format_time_component(display_hours) .. ":" .. format_time_component(mins) .. ":" .. format_time_component(secs)
	else
		time_str = format_time_component(display_hours) .. ":" .. format_time_component(mins)
	end

	-- Draw time (centered, large)
	local time_x = state.width / 2 - (#time_str * 14) / 2
	local time_y = state.height / 2 - 10

	if gfx and gfx.text then
		gfx:text(time_x, time_y, time_str, th.text_primary or "#ffffff", "xlarge")

		-- Draw AM/PM indicator
		if not state.format_24h then
			gfx:text(time_x + #time_str * 14 + 10, time_y + 8, am_pm, th.text_muted or "#606070", "medium")
		end

		-- Draw date if enabled
		if state.show_date then
			local days = floor(now / 86400)
			-- Simple day calculation (approximate)
			local weekdays = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
			local weekday = weekdays[(days % 7) + 1]

			local date_str = weekday .. " • Day " .. (days % 365 + 1)
			local date_x = state.width / 2 - (#date_str * 4)

			gfx:text(date_x, time_y + 40, date_str, th.text_muted or "#606070", "medium")
		end
	end

	-- Accent line at top
	if gfx and gfx.line then
		gfx:line(px, py, state.width - px, py, th.accent_primary or "#00d4ff", 2)
	end
end

function M.on_event(state, event)
	if event.type == "tap" then
		state.show_seconds = not state.show_seconds
		return true
	end
	return false
end

return M
