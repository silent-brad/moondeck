-- Crypto Widget: Rendering

local M = {}

-- TODO: Move to config
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
  litecoin = "LTC",
  monero = "XMR",
}

-- Format price with appropriate precision
local function format_price(price, currency)
  if not price then
    return "—"
  end

  local symbol = ""
  if currency == "usd" then
    symbol = "$"
  elseif currency == "eur" then
    symbol = "€"
  elseif currency == "gbp" then
    symbol = "£"
  end

  if price >= 1000 then
    return symbol .. util.format("%.0f", price)
  elseif price >= 1 then
    return symbol .. util.format("%.2f", price)
  else
    return symbol .. util.format("%.4f", price)
  end
end

-- Format change percentage
local function format_change(change)
  if not change then
    return "—", "info"
  end

  local sign = ""
  local status = "info"
  if change >= 0 then
    sign = "+"
    status = "ok"
  else
    status = "error"
  end

  return sign .. util.format("%.1f", change) .. "%", status
end

function M.render(state, gfx)
  local th = theme:get()
  local px, py = 20, 15

  -- Draw card
  components.card(gfx, 0, 0, state.width, state.height)

  -- Title bar
  local title_h = components.title_bar(gfx, px, py, state.width - px * 2, "Crypto", {
    accent = th.accent_primary,
  })

  local content_y = py + title_h + 25

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
  local max_rows = math.floor((state.height - content_y - py) / row_height)

  for i = 1, #state.coins do
    if i > max_rows then
      break
    end

    local coin = state.coins[i]
    local y = content_y + (i - 1) * row_height
    local name = coin_names[coin] or coin:upper():sub(1, 4)
    local price = format_price(state.prices[coin], state.currency)
    local change_str, change_status = format_change(state.changes[coin])

    -- Coin name
    gfx:text(px, y, name, th.text_secondary, "inter", 16)

    -- Price (center)
    local price_x = state.width / 2 - 30
    gfx:text(price_x, y, price, th.text_secondary, "inter", 16)

    -- Change (right)
    local change_color = th.text_muted
    if change_status == "ok" then
      change_color = th.accent_success
    elseif change_status == "error" then
      change_color = th.accent_error
    end
    gfx:text(state.width - px - 60, y, change_str, change_color, "inter", 12)
  end
end

return M
