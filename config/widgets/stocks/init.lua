-- Stocks Widget

local base = require("utils.widget_base")
local fetch = require("widgets.stocks.fetch")
local render = require("widgets.stocks.render")

return base.new({
  fetch_interval = 60000,
  setup = function(state, ctx)
    state.symbols = ctx.opts.symbols or { "AAPL", "GOOGL" }
    state.prices = {}
    state.changes = {}
    state.history = {}
    state.max_history = 30
    state.current_symbol_index = 1
    for i = 1, #state.symbols do
      state.history[state.symbols[i]] = {}
    end
  end,
  fetch = function(state)
    local ok, err = fetch.fetch(state)
    if ok then
      for i = 1, #state.symbols do
        local symbol = state.symbols[i]
        if state.prices[symbol] then
          local h = state.history[symbol]
          if not h then
            h = {}
            state.history[symbol] = h
          end
          h[#h + 1] = state.prices[symbol]
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
