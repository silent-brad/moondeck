-- RSS Widget

local base = require("utils.widget_base")
local fetch = require("widgets.rss.fetch")
local render = require("widgets.rss.render")

return base.new({
  fetch_interval = 300000,
  setup = function(state, ctx)
    state.entries = {}
    state.current_index = 1
    state.limit = ctx.opts.limit or 10
  end,
  fetch = function(state)
    return fetch.fetch(state)
  end,
  render = function(state, gfx)
    render.render(state, gfx)
  end,
  on_event = function(state, event)
    if event.type == "tap" then
      if #state.entries > 0 then
        state.current_index = (state.current_index % #state.entries) + 1
      end
      return true
    elseif event.type == "long_press" then
      state.last_fetch = state.fetch_interval
      state.loading = true
      return true
    end
    return false
  end,
})
