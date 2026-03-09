-- Crypto Widget
-- Fetches cryptocurrency prices from CoinGecko API (no API key required)

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
	-- Parse coin list from env or opts (simplified to avoid string.gmatch issues)
	local coins_str = ctx.opts.coins or env_get("CRYPTO_COINS") or "bitcoin,ethereum"
	local coins = { "bitcoin", "ethereum" } -- Default coins, simplified parsing

	-- Only try advanced parsing if string_gmatch exists
	if type(string_gmatch) == "function" then
		coins = {}
		for coin in string_gmatch(coins_str, "([^,]+)") do
			-- Simple trim without using string:match method syntax
			local trimmed = string_gsub(coin, "^%s*(.-)%s*$", "%1")
			table_insert(coins, trimmed)
		end
	end

	return {
		x = ctx.x,
		y = ctx.y,
		width = ctx.width,
		height = ctx.height,
		coins = coins,
		currency = ctx.opts.currency or env_get("CRYPTO_CURRENCY") or "usd",
		prices = {},
		changes = {},
		last_fetch = 0,
		fetch_interval = ctx.opts.update_interval or 60000, -- 1 minute
		loading = true,
		error = nil,
	}
end

function M.update(state, delta_ms)
	-- Only do simple arithmetic - no stdlib calls work in piccolo across try_enter
	state.last_fetch = state.last_fetch + delta_ms
end

-- Format price with appropriate precision
local function format_price(price, currency)
	if not price then
		return "—"
	end

	local symbol = currency == "usd" and "$" or currency == "eur" and "€" or currency == "gbp" and "£" or ""

	if price >= 1000 then
		return symbol .. string_format("%.0f", price)
	elseif price >= 1 then
		return symbol .. string_format("%.2f", price)
	else
		return symbol .. string_format("%.4f", price)
	end
end

-- Format change percentage
local function format_change(change)
	if not change then
		return "—", "info"
	end

	local sign = change >= 0 and "+" or ""
	local status = change >= 0 and "ok" or "error"

	return sign .. string_format("%.1f%%", change), status
end

-- Coin display names
local coin_names = {
	bitcoin = "BTC",
	ethereum = "ETH",
	solana = "SOL",
	cardano = "ADA",
	dogecoin = "DOGE",
	ripple = "XRP",
	polkadot = "DOT",
	avalanche = "AVAX",
	chainlink = "LINK",
	polygon = "MATIC",
}

function M.render(state, gfx)
	local th = get_theme()
	local px, py = 20, 15

	-- Draw card
	components.card(gfx, 0, 0, state.width, state.height)

	-- Title bar
	local title_h = components.title_bar(gfx, px, py, state.width - px * 2, "Crypto", {
		accent = th.accent_primary,
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

	-- Display each coin
	local row_height = 30
	local max_rows = math_floor((state.height - content_y - py) / row_height)

	for i, coin in ipairs(state.coins) do
		if i > max_rows then
			break
		end

		local y = content_y + (i - 1) * row_height
		local name = coin_names[coin] or coin:upper():sub(1, 4)
		local price = format_price(state.prices[coin], state.currency)
		local change_str, change_status = format_change(state.changes[coin])

		-- Coin name
		gfx:text(px, y, name, th.text_primary, "medium")

		-- Price (center)
		local price_x = state.width / 2 - 30
		gfx:text(price_x, y, price, th.text_primary, "medium")

		-- Change (right)
		local change_color = change_status == "ok" and th.accent_success
			or change_status == "error" and th.accent_error
			or th.text_muted
		gfx:text(state.width - px - 60, y, change_str, change_color, "small")
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
