-- RSS Widget
-- Fetches feed entries from Miniflux API

local fetch = require("widgets.rss.fetch")
local render = require("widgets.rss.render")

local M = {}

function M.init(ctx)
  local fetch_interval = ctx.opts.update_interval or 300000 -- 5 minutes

  return {
    x = ctx.x,
    y = ctx.y,
    width = ctx.width,
    height = ctx.height,
    entries = {},
    current_index = 1,
    limit = ctx.opts.limit or 10,
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
    -- Cycle through entries or refresh
    if #state.entries > 0 then
      state.current_index = (state.current_index % #state.entries) + 1
    end
    return true
  elseif event.type == "long_press" then
    -- Refresh on long press
    state.last_fetch = state.fetch_interval
    state.loading = true
    return true
  end
  return false
end

return M
