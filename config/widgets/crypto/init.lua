-- Crypto Widget
-- Fetches cryptocurrency prices from CoinGecko API (no API key required)

local fetch = require("widgets.crypto.fetch")
local render = require("widgets.crypto.render")

local M = {}

function M.init(ctx)
  local coins = ctx.opts.coins or { "bitcoin", "ethereum" }
  local currency = ctx.opts.currency or "usd"

  local fetch_interval = ctx.opts.update_interval or 60000

  return {
    x = ctx.x,
    y = ctx.y,
    width = ctx.width,
    height = ctx.height,
    coins = coins,
    currency = currency,
    prices = {},
    changes = {},
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
