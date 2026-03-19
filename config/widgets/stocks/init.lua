-- Stocks Widget
-- Fetches stock prices from Finnhub.io API

local fetch = require("widgets.stocks.fetch")
local render = require("widgets.stocks.render")

local M = {}

function M.init(ctx)
  local symbols = ctx.opts.symbols or { "AAPL", "GOOGL" }

  local fetch_interval = ctx.opts.update_interval or 300000 -- 5 minutes

  return {
    x = ctx.x,
    y = ctx.y,
    width = ctx.width,
    height = ctx.height,
    symbols = symbols,
    prices = {},
    changes = {},
    current_symbol_index = 1,
    last_fetch = fetch_interval,
    fetch_interval = fetch_interval,
    loading = true,
    error = nil,
  }
end

function M.update(state, delta_ms)
  state.last_fetch = state.last_fetch + delta_ms

  if state.last_fetch >= state.fetch_interval then
    state.last_fetch = 0
    local ok, err = fetch.fetch(state)
    if ok then
      state.error = nil
    else
      state.error = err
    end
    state.loading = false
  end
end

function M.render(state, gfx)
  render.render(state, gfx)
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
