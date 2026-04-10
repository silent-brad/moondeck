-- Crypto Widget

local base = require("utils.widget_base")
local fetch = require("widgets.crypto.fetch")
local render = require("widgets.crypto.render")

return base.new({
  fetch_interval = 60000,
  setup = function(state, ctx)
    state.coins = ctx.opts.coins or { "bitcoin", "ethereum" }
    state.currency = ctx.opts.currency or "usd"
    state.prices = {}
    state.changes = {}
    state.history = {}
    state.max_history = 30
    for i = 1, #state.coins do
      state.history[state.coins[i]] = {}
    end
  end,
  fetch = function(state)
    local ok, err = fetch.fetch(state)
    if ok then
      for i = 1, #state.coins do
        local coin = state.coins[i]
        if state.prices[coin] then
          local h = state.history[coin]
          if not h then
            h = {}
            state.history[coin] = h
          end
          h[#h + 1] = state.prices[coin]
          if #h > state.max_history then
            for j = 1, #h - 1 do
              h[j] = h[j + 1]
            end
            h[#h] = nil
          end
        end
      end
    end
    return ok, err
  end,
  render = function(state, gfx)
    render.render(state, gfx)
  end,
})
