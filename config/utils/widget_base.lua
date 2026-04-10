-- Moondeck Widget Base
-- Eliminates boilerplate for standard widget patterns

local Base = {}

-- Create a new widget module from a specification table.
--
-- spec fields:
--   fetch          - function(state) -> ok, err  (for data-fetching widgets)
--   setup          - function(state, ctx)        (custom init logic, called after defaults)
--   update         - function(state, delta_ms)   (custom update, used when no fetch)
--   render         - function(state, gfx)        (required)
--   on_event       - function(state, event) -> bool (optional override)
function Base.new(spec)
  local M = {}

  function M.init(ctx)
    local fetch_interval = ctx.opts.update_interval or spec.fetch_interval or 0
    local state = {
      x = ctx.x,
      y = ctx.y,
      width = ctx.width,
      height = ctx.height,
      loading = spec.fetch ~= nil,
      error = nil,
      last_fetch = fetch_interval,
      fetch_interval = fetch_interval,
    }
    if spec.setup then
      spec.setup(state, ctx)
    end
    return state
  end

  function M.update(state, delta_ms)
    if spec.fetch then
      state.last_fetch = state.last_fetch + delta_ms
      if state.last_fetch >= state.fetch_interval then
        local ok, err = spec.fetch(state)
        if ok then
          state.last_fetch = 0
          state.error = nil
        else
          state.error = err
          state.last_fetch = state.fetch_interval - 10000
        end
        state.loading = false
      end
    elseif spec.update then
      spec.update(state, delta_ms)
    end
  end

  M.render = spec.render

  function M.on_event(state, event)
    if spec.on_event then
      return spec.on_event(state, event)
    end
    if event.type == "tap" and spec.fetch then
      state.last_fetch = state.fetch_interval
      state.loading = true
      return true
    end
    return false
  end

  return M
end

return Base
