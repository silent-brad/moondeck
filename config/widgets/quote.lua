-- Quote Widget
-- Displays inspirational quotes with elegant styling

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

-- Safe env getter
local function env_get(key)
	if env and type(env.get) == "function" then
		return env.get(key)
	end
	return nil
end

-- Built-in quotes collection
local builtin_quotes = {
	{ text = "The only way to do great work is to love what you do.", author = "Steve Jobs" },
	{ text = "Innovation distinguishes between a leader and a follower.", author = "Steve Jobs" },
	{ text = "Stay hungry, stay foolish.", author = "Steve Jobs" },
	{ text = "The future belongs to those who believe in the beauty of their dreams.", author = "Eleanor Roosevelt" },
	{ text = "It is during our darkest moments that we must focus to see the light.", author = "Aristotle" },
	{ text = "The only thing we have to fear is fear itself.", author = "Franklin D. Roosevelt" },
	{ text = "In the middle of difficulty lies opportunity.", author = "Albert Einstein" },
	{ text = "Life is what happens when you're busy making other plans.", author = "John Lennon" },
	{ text = "The purpose of our lives is to be happy.", author = "Dalai Lama" },
	{ text = "Get busy living or get busy dying.", author = "Stephen King" },
	{ text = "You only live once, but if you do it right, once is enough.", author = "Mae West" },
	{
		text = "Many of life's failures are people who did not realize how close they were to success when they gave up.",
		author = "Thomas Edison",
	},
	{ text = "The mind is everything. What you think you become.", author = "Buddha" },
	{
		text = "The best time to plant a tree was 20 years ago. The second best time is now.",
		author = "Chinese Proverb",
	},
	{ text = "An unexamined life is not worth living.", author = "Socrates" },
	{ text = "Simplicity is the ultimate sophistication.", author = "Leonardo da Vinci" },
	{ text = "The only true wisdom is in knowing you know nothing.", author = "Socrates" },
	{ text = "Do what you can, with what you have, where you are.", author = "Theodore Roosevelt" },
	{ text = "Everything you've ever wanted is on the other side of fear.", author = "George Addair" },
	{
		text = "Success is not final, failure is not fatal: it is the courage to continue that counts.",
		author = "Winston Churchill",
	},
}

function M.init(ctx)
	return {
		x = ctx.x,
		y = ctx.y,
		width = ctx.width,
		height = ctx.height,
		quote_text = nil,
		quote_author = nil,
		quote_index = 1,
		last_change = 0,
		change_interval = ctx.opts.change_interval or 60000, -- 1 minute
		use_api = ctx.opts.use_api or false,
		loading = false,
		error = nil,
	}
end

function M.update(state, delta_ms)
	-- Only do simple arithmetic - no stdlib calls work in piccolo across try_enter
	state.last_change = state.last_change + delta_ms
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
	local px, py = 25, 20

	-- Draw card
	components.card(gfx, 0, 0, state.width, state.height)

	if state.loading then
		components.loading(gfx, px, state.height / 2 - 10)
		return
	end

	if not state.quote_text then
		gfx:text(px, state.height / 2 - 10, "No quote available", th.text_muted, "medium")
		return
	end

	-- Opening quotation mark (decorative)
	gfx:text(px - 5, py + 10, '"', th.accent_primary, "xlarge")

	-- Calculate text layout
	local chars_per_line = math_floor((state.width - px * 2 - 20) / 8)
	local lines = wrap_text(state.quote_text, chars_per_line)

	local line_height = 22
	local text_start_y = py + 20
	local max_lines = math_floor((state.height - text_start_y - 50) / line_height)

	-- Draw quote text
	for i, line in ipairs(lines) do
		if i > max_lines then
			-- Show ellipsis
			gfx:text(px + 15, text_start_y + (max_lines - 1) * line_height, "...", th.text_primary, "medium")
			break
		end
		gfx:text(px + 15, text_start_y + (i - 1) * line_height, line, th.text_primary, "medium")
	end

	-- Author attribution
	if state.quote_author then
		local author_y = state.height - py - 15
		gfx:text(px + 15, author_y, "— " .. state.quote_author, th.text_accent, "medium")
	end

	-- Subtle accent line
	gfx:line(px, state.height - py - 35, px + 3, state.height - py - 35, th.accent_primary, 2)
end

function M.on_event(state, event)
	if event.type == "tap" then
		-- Show next quote by resetting the timer
		state.last_change = state.change_interval
		return true
	end
	return false
end

return M
