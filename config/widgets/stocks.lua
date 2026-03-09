-- Stocks Widget
-- Fetches stock prices from Stockdata.org API

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

function M.init(ctx)
	-- Parse symbol list from env or opts (simplified to avoid string.gmatch issues)
	local symbols_str = ctx.opts.symbols or env_get("STOCKS_SYMBOLS") or "AAPL,GOOGL"
	local symbols = { "AAPL", "GOOGL" } -- Default symbols

	-- Only try advanced parsing if string_gmatch exists
	if type(string_gmatch) == "function" then
		symbols = {}
		for symbol in string_gmatch(symbols_str, "([^,]+)") do
			-- Simple trim and uppercase without method syntax
			local trimmed = string_gsub(symbol, "^%s*(.-)%s*$", "%1")
			table_insert(symbols, string_upper(trimmed))
		end
	end

	return {
		x = ctx.x,
		y = ctx.y,
		width = ctx.width,
		height = ctx.height,
		symbols = symbols,
		prices = {},
		changes = {},
		last_fetch = 0,
		fetch_interval = ctx.opts.update_interval or 300000, -- 5 minutes
		loading = true,
		error = nil,
	}
end

function M.update(state, delta_ms)
	-- Only do simple arithmetic - no stdlib calls work in piccolo across try_enter
	state.last_fetch = state.last_fetch + delta_ms
end

local function format_price(price)
	if not price then
		return "—"
	end
	return "$" .. string_format("%.2f", price)
end

local function format_change(change)
	if not change then
		return "—", "info"
	end

	local sign = change >= 0 and "+" or ""
	local status = change >= 0 and "ok" or "error"

	return sign .. string_format("%.2f%%", change), status
end

function M.render(state, gfx)
	local th = get_theme()
	local px, py = 20, 15

	-- Draw card
	components.card(gfx, 0, 0, state.width, state.height)

	-- Title bar
	local title_h = components.title_bar(gfx, px, py, state.width - px * 2, "Stocks", {
		accent = th.accent_secondary,
	})

	local content_y = py + title_h + 10

	if state.loading then
		components.loading(gfx, px, content_y + 20)
		return
	end

	if state.error then
		components.error(gfx, px, content_y + 10, state.width - px * 2, state.error)
		return
	end

	-- Display each stock
	local row_height = 28
	local max_rows = math_floor((state.height - content_y - py) / row_height)

	for i, symbol in ipairs(state.symbols) do
		if i > max_rows then
			break
		end

		local y = content_y + (i - 1) * row_height
		local price = format_price(state.prices[symbol])
		local change_str, change_status = format_change(state.changes[symbol])

		-- Symbol
		gfx:text(px, y, symbol, th.text_primary, "medium")

		-- Price (center)
		local price_x = state.width / 2 - 30
		gfx:text(price_x, y, price, th.text_primary, "medium")

		-- Change (right)
		local change_color = change_status == "ok" and th.accent_success
			or change_status == "error" and th.accent_error
			or th.text_muted
		gfx:text(state.width - px - 60, y, change_str, change_color, "small")
	end

	-- Market status indicator
	local now_hours = math_floor(device.seconds() / 3600) % 24
	local market_open = now_hours >= 14 and now_hours < 21 -- Rough EST market hours in UTC
	local status_text = market_open and "Market Open" or "Market Closed"
	local status_color = market_open and th.accent_success or th.text_muted

	gfx:text(px, state.height - py - 10, status_text, status_color, "small")
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
