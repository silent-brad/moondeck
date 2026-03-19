-- Crypto Widget: API fetching and response parsing

local M = {}

-- Fetch crypto prices from CoinGecko and populate state
function M.fetch(state)
  -- Build coin IDs string
  local ids = ""
  for i = 1, #state.coins do
    if i > 1 then
      ids = ids .. ","
    end
    ids = ids .. state.coins[i]
  end

  -- CoinGecko API URL
  local url = "https://api.coingecko.com/api/v3/simple/price?ids="
    .. ids
    .. "&vs_currencies="
    .. state.currency
    .. "&include_24hr_change=true"

  local response = net.http_get(url, {}, 15000)

  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)
  if not data then
    return false, "Invalid response"
  end

  for i = 1, #state.coins do
    local coin = state.coins[i]
    local coin_data = data[coin]
    if coin_data then
      state.prices[coin] = coin_data[state.currency]
      local change_key = state.currency .. "_24h_change"
      state.changes[coin] = coin_data[change_key]
    end
  end

  return true
end

return M
