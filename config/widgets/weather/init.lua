-- Weather Widget

local base = require("utils.widget_base")
local fetch = require("widgets.weather.fetch")
local render = require("widgets.weather.render")

return base.new({
  fetch_interval = 300000,
  setup = function(state, ctx)
    state.city = ctx.opts.city or env.get("WEATHER_CITY") or "New York"
    state.units = ctx.opts.units or env.get("WEATHER_UNITS") or "imperial"
  end,
  fetch = function(state)
    return fetch.fetch(state)
  end,
  render = function(state, gfx)
    render.render(state, gfx)
  end,
})
