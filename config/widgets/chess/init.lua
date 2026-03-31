-- Chess Widget
-- Fetches account data from Chess.com public API (no API key required)

local fetch = require("widgets.chess.fetch")
local render = require("widgets.chess.render")

local M = {}

function M.init(ctx)
  local fetch_interval = ctx.opts.update_interval or 300000

  return {
    x = ctx.x,
    y = ctx.y,
    width = ctx.width,
    height = ctx.height,
    username = ctx.opts.username or "hikaru",
    title = "",
    joined = 0,
    last_online = 0,
    fide = nil,
    puzzle_rush = nil,
    ratings = {},
    recent_games = {},
    elo_history = {},
    last_fetch = fetch_interval,
    fetch_interval = fetch_interval,
    loading = true,
    error = nil,
    fetch_phase = 0,
  }
end

function M.update(state, delta_ms)
  state.last_fetch = state.last_fetch + delta_ms

  if state.last_fetch >= state.fetch_interval then
    -- Fetch in phases to avoid blocking too long
    -- Phase 0: profile, Phase 1: stats, Phase 2: games
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
end

function M.render(state, gfx)
  render.render(state, gfx)
end

function M.on_event(state, event)
  if event.type == "tap" then
    state.last_fetch = state.fetch_interval
    state.fetch_phase = 0
    state.loading = true
    return true
  end
  return false
end

return M
