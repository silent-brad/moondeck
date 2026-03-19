-- Stocks Widget: API fetching and response parsing

local M = {}

-- Fetch stock quotes from Finnhub API and populate state
function M.fetch(state)
  local api_key = env.get("STOCKS_API_KEY")
  if not api_key then
    return false, "No API key"
  end

  -- Finnhub only supports one symbol per request, fetch all symbols
  local success_count = 0
  for i = 1, #state.symbols do
    local symbol = state.symbols[i]
    local url = "https://finnhub.io/api/v1/quote?symbol=" .. symbol .. "&token=" .. api_key

    local response = net.http_get(url, {}, 10000)

    if response and response.ok and response.body then
      local data = net.json_decode(response.body)

      if data and data.c then
        state.prices[symbol] = data.c -- current price
        state.changes[symbol] = data.dp -- percent change
        success_count = success_count + 1
      end
    end
  end

  if success_count > 0 then
    return true
  else
    return false, "Failed to fetch"
  end
end

return M
