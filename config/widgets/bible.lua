-- Bible Verse Widget
-- Fetches Verse of the Day from labs.bible.org API

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
		text_secondary = "#a0a0b0",
		text_muted = "#606070",
		text_accent = "#00d4ff",
		accent_primary = "#00d4ff",
		accent_secondary = "#e94560",
		accent_success = "#00ff88",
		accent_warning = "#ffaa00",
		accent_error = "#ff4466",
		bg_tertiary = "#1a1a2e",
		border_primary = "#2a2a3e",
	}
end

function M.init(ctx)
	return {
		x = ctx.x,
		y = ctx.y,
		width = ctx.width,
		height = ctx.height,
		verse_text = nil,
		verse_ref = nil,
		last_fetch = 0,
		fetch_interval = ctx.opts.update_interval or 3600000, -- 1 hour
		loading = true,
		error = nil,
	}
end

function M.update(state, delta_ms)
	-- Only do simple arithmetic - no stdlib calls work in piccolo across try_enter
	state.last_fetch = state.last_fetch + delta_ms
end

-- Word wrap helper
local function wrap_text(text, max_chars)
	local lines = {}
	local line = ""

	for word in string_gmatch(text, "%S+") do
		if #line + #word + 1 <= max_chars then
			line = line == "" and word or line .. " " .. word
		else
			if line ~= "" then
				table_insert(lines, line)
			end
			line = word
		end
	end

	if line ~= "" then
		table_insert(lines, line)
	end

	return lines
end

function M.render(state, gfx)
	local th = get_theme()
	local px, py = 20, 15

	-- Draw card
	components.card(gfx, 0, 0, state.width, state.height)

	-- Decorative cross icon (simple)
	gfx:line(px + 5, py + 5, px + 5, py + 20, th.accent_primary, 2)
	gfx:line(px, py + 10, px + 10, py + 10, th.accent_primary, 2)

	-- Title
	gfx:text(px + 20, py + 5, "Verse of the Day", th.text_muted, "small")

	local content_y = py + 35

	if state.loading then
		components.loading(gfx, px, content_y + 20)
		return
	end

	if state.error then
		components.error(gfx, px, content_y, state.width - px * 2, state.error)
		return
	end

	if state.verse_text then
		-- Calculate characters per line based on width
		local chars_per_line = math_floor((state.width - px * 2) / 7)
		local lines = wrap_text(state.verse_text, chars_per_line)

		-- Calculate how many lines we can show
		local line_height = 18
		local max_lines = math_floor((state.height - content_y - 40) / line_height)

		-- Draw verse text
		for i, line in ipairs(lines) do
			if i > max_lines then
				-- Show ellipsis on last line
				gfx:text(px, content_y + (max_lines - 1) * line_height, "...", th.text_secondary, "medium")
				break
			end
			gfx:text(px, content_y + (i - 1) * line_height, line, th.text_secondary, "medium")
		end

		-- Draw reference at bottom
		if state.verse_ref then
			gfx:text(px, state.height - py - 15, "— " .. state.verse_ref, th.text_accent, "medium")
		end
	end
end

function M.on_event(state, event)
	if event.type == "tap" then
		state.last_fetch = state.fetch_interval
		state.loading = true
		return true
	end
	return false
end

return M
