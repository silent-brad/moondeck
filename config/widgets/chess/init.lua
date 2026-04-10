-- Chess Widget

local base = require("utils.widget_base")
local fetch = require("widgets.chess.fetch")
local render = require("widgets.chess.render")

return base.new({
  setup = function(state, ctx)
    state.fetch_interval = ctx.opts.update_interval or 300000
    state.last_fetch = state.fetch_interval
    state.username = ctx.opts.username or "hikaru"
    state.title = ""
    state.joined = 0
    state.last_online = 0
    state.fide = nil
    state.puzzle_rush = nil
    state.ratings = {}
    state.recent_games = {}
    state.elo_history = {}
    state.loading = true
    state.fetch_phase = 0
  end,
  update = function(state, delta_ms)
    state.last_fetch = state.last_fetch + delta_ms
    if state.last_fetch >= state.fetch_interval then
      if state.fetch_phase == 0 then
        local ok, err = fetch.fetch_profile(state)
        if not ok then
          state.error = err
          state.last_fetch = state.fetch_interval - 10000
        else
          state.fetch_phase = 1
          state.last_fetch = state.fetch_interval
        end
      elseif state.fetch_phase == 1 then
        local ok, err = fetch.fetch_stats(state)
        if not ok then
          state.error = err
          state.last_fetch = state.fetch_interval - 10000
        else
          state.error = nil
          state.fetch_phase = 2
          state.last_fetch = state.fetch_interval
        end
      else
        fetch.fetch_games(state)
        state.fetch_phase = 0
        state.last_fetch = 0
        state.loading = false
      end
    end
  end,
  render = function(state, gfx)
    render.render(state, gfx)
  end,
  on_event = function(state, event)
    if event.type == "tap" then
      state.last_fetch = state.fetch_interval
      state.fetch_phase = 0
      state.loading = true
      return true
    end
    return false
  end,
})
