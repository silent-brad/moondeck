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

        -- Seed history from candle data on first fetch (when history is sparse)
        if state.history and (not state.history[symbol] or #state.history[symbol] < 2) then
          local now = math.floor(device.seconds() + 946684800)
          local from = now - 86400 * 7
          local candle_url = "https://finnhub.io/api/v1/stock/candle?symbol="
            .. symbol
            .. "&resolution=60&from="
            .. from
            .. "&to="
            .. now
            .. "&token="
            .. api_key

          local candle_resp = net.http_get(candle_url, {}, 10000)
          if candle_resp and candle_resp.ok and candle_resp.body then
            local candle_data = net.json_decode(candle_resp.body)
            if candle_data and candle_data.s == "ok" and candle_data.c then
              local closes = candle_data.c
              local start = #closes > state.max_history and (#closes - state.max_history + 1) or 1
              local points = {}
              for j = start, #closes do
                points[#points + 1] = closes[j]
              end
              state.history[symbol] = points
            end
          end
        end
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
