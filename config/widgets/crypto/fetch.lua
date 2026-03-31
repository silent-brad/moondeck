-- Crypto Widget: API fetching and response parsing

local M = {}

-- Fetch crypto prices from CoinGecko and populate state
-- Uses /coins/markets with sparkline=true to get both current prices
-- and 7-day sparkline data in a single API call
function M.fetch(state)
  -- Build coin IDs string
  local ids = ""
  for i = 1, #state.coins do
    if i > 1 then
      ids = ids .. ","
    end
    ids = ids .. state.coins[i]
  end

  -- Use /coins/markets to get price, change, AND sparkline in one call
  local url = "https://api.coingecko.com/api/v3/coins/markets?ids="
    .. ids
    .. "&vs_currency="
    .. state.currency
    .. "&sparkline=true"
    .. "&price_change_percentage=24h"

  local response = net.http_get(url, {}, 15000)

  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)
  if not data or #data == 0 then
    return false, "Invalid response"
  end

  -- data is an array of coin objects
  for i = 1, #data do
    local coin = data[i]
    local coin_id = coin.id
    if coin_id then
      state.prices[coin_id] = coin.current_price
      state.changes[coin_id] = coin.price_change_percentage_24h

      -- Seed history from sparkline on first successful fetch
      local sparkline = coin.sparkline_in_7d
      if sparkline and sparkline.price and #sparkline.price >= 2 then
        if not state.history[coin_id] or #state.history[coin_id] < 2 then
          local prices = sparkline.price
          local start = #prices > state.max_history and (#prices - state.max_history + 1) or 1
          local points = {}
          for j = start, #prices do
            points[#points + 1] = prices[j]
          end
          state.history[coin_id] = points
        end
      end
    end
  end

  return true
end

return M
