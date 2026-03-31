-- Weather Widget
-- Fetches and displays weather data from OpenWeatherMap API

local fetch = require("widgets.weather.fetch")
local render = require("widgets.weather.render")

local M = {}

function M.init(ctx)
  return {
    x = ctx.x,
    y = ctx.y,
    width = ctx.width,
    height = ctx.height,
    city = ctx.opts.city or env.get("WEATHER_CITY") or "New York",
    units = ctx.opts.units or env.get("WEATHER_UNITS") or "imperial",
    temperature = nil,
    feels_like = nil,
    description = nil,
    humidity = nil,
    wind_speed = nil,
    icon = nil,
    fetch_interval = ctx.opts.update_interval or 300000,
    last_fetch = ctx.opts.update_interval or 300000,
    loading = true,
    error = nil,
  }
end

function M.update(state, delta_ms)
  state.last_fetch = state.last_fetch + delta_ms

  if state.last_fetch >= state.fetch_interval then
    local ok, err = fetch.fetch(state)
    if ok then
      state.last_fetch = 0
      state.error = nil
    else
      state.error = err
      state.last_fetch = state.fetch_interval - 10000
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
