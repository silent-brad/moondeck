-- Stocks Widget: API fetching via Yahoo Finance (no API key required)

local M = {}

-- Fetch stock data from Yahoo Finance and populate state
-- Uses /v8/finance/chart which returns current price, previous close,
-- and historical data in a single request per symbol
function M.fetch(state)
  local success_count = 0
  -- Use 7d range on first fetch (to seed history), 1d after that
  local needs_history = false
  for i = 1, #state.symbols do
    local h = state.history[state.symbols[i]]
    if not h or #h < 2 then
      needs_history = true
      break
    end
  end
  local range = needs_history and "7d" or "1d"

  for i = 1, #state.symbols do
    local symbol = state.symbols[i]
    local url = "https://query1.finance.yahoo.com/v8/finance/chart/"
      .. symbol
      .. "?range="
      .. range
      .. "&interval=1h&includePrePost=false"

    local response = net.http_get(url, {}, 15000)

    if response and response.ok and response.body then
      local data = net.json_decode(response.body)

      if data and data.chart and data.chart.result then
        local result = data.chart.result[1]
        if result and result.meta then
          local meta = result.meta
          -- Current price and percent change
          if meta.regularMarketPrice then
            state.prices[symbol] = meta.regularMarketPrice
            if meta.previousClose and meta.previousClose > 0 then
              state.changes[symbol] = (meta.regularMarketPrice - meta.previousClose) / meta.previousClose * 100
            end
            success_count = success_count + 1
          end

          -- Seed history from chart data when history is sparse
          if state.history and (not state.history[symbol] or #state.history[symbol] < 2) then
            if result.timestamp and result.indicators then
              local quote = result.indicators.quote
              if quote then
                local closes = quote[1] and quote[1].close
                if closes then
                  local num_points = #result.timestamp
                  local points = {}
                  for j = 1, num_points do
                    if closes[j] then
                      points[#points + 1] = closes[j]
                    end
                  end
                  if #points > state.max_history then
                    local trimmed = {}
                    local start = #points - state.max_history + 1
                    for j = start, #points do
                      trimmed[#trimmed + 1] = points[j]
                    end
                    points = trimmed
                  end
                  if #points >= 2 then
                    state.history[symbol] = points
                  end
                end
              end
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
