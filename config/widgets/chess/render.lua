-- Chess Widget: Rendering

local fetch = require("widgets.chess.fetch")

local M = {}

local function render_elo_graph(gfx, state, th, x, y, w, h)
  if not state.elo_history or #state.elo_history < 2 then
    return
  end

  local pts = state.elo_history
  local n = #pts

  -- Find min/max rating for scale
  local min_r, max_r = pts[1].rating, pts[1].rating
  for i = 2, n do
    if pts[i].rating < min_r then
      min_r = pts[i].rating
    end
    if pts[i].rating > max_r then
      max_r = pts[i].rating
    end
  end

  -- Add padding to range
  local range = max_r - min_r
  if range < 20 then
    range = 20
    min_r = min_r - 10
    max_r = max_r + 10
  end

  -- Draw bounding box
  gfx:line(x, y, x, y + h, th.border_primary, 1)
  gfx:line(x, y + h, x + w, y + h, th.border_primary, 1)

  -- Y-axis labels
  gfx:text(x - 2, y - 2, tostring(max_r), th.text_muted, "inter", 12)
  gfx:text(x - 2, y + h - 8, tostring(min_r), th.text_muted, "inter", 12)

  -- Plot line segments
  local step = w / (n - 1)
  for i = 2, n do
    local x1 = x + (i - 2) * step
    local y1 = y + h - math.floor((pts[i - 1].rating - min_r) / range * h)
    local x2 = x + (i - 1) * step
    local y2 = y + h - math.floor((pts[i].rating - min_r) / range * h)
    gfx:line(x1, y1, x2, y2, th.accent_primary, 1)
  end

  -- Current rating dot at end
  local last_y = y + h - math.floor((pts[n].rating - min_r) / range * h)
  gfx:fill_circle(x + w, last_y, 3, th.accent_primary)
end

function M.render(state, gfx)
  local th = theme:get()
  local px, py = 20, 15

  -- Draw card
  components.card(gfx, 0, 0, state.width, state.height)

  -- Title bar
  local title_text = "Chess"
  if state.title and state.title ~= "" then
    title_text = state.title .. " " .. state.username
  end
  local title_h = components.title_bar(gfx, px, py, state.width - px * 2, title_text, {
    accent = th.accent_secondary,
  })

  local content_y = py + title_h + 20

  if state.loading then
    components.loading(gfx, px, content_y + 20)
    return
  end

  if state.error then
    components.error(gfx, px, content_y + 10, state.width - px * 2, state.error)
    return
  end

  local right_x = state.width / 2 + 10
  local col_w = state.width / 2 - px - 10

  -- Left column: Profile info + Ratings
  -- Joined & Last Online
  if state.joined and state.joined > 0 then
    gfx:text(px, content_y, "Joined: " .. fetch.format_epoch(state.joined), th.text_muted, "inter", 12)
    content_y = content_y + 15
  end
  if state.last_online and state.last_online > 0 then
    gfx:text(px, content_y, "Last on: " .. fetch.short_epoch(state.last_online), th.text_muted, "inter", 12)
    content_y = content_y + 15
  end

  -- FIDE
  if state.fide then
    gfx:text(px, content_y, "FIDE: " .. tostring(state.fide), th.text_accent, "inter", 12)
    content_y = content_y + 15
  end

  content_y = content_y + 5

  -- Ratings
  local row_height = 35
  for i = 1, #state.ratings do
    local r = state.ratings[i]
    local y = content_y + (i - 1) * row_height

    if y + row_height > state.height - py then
      break
    end

    gfx:text(px, y, r.name, th.text_muted, "inter", 12)
    gfx:text(px + 55, y, tostring(r.rating), th.text_secondary, "inter", 16)

    if r.best then
      gfx:text(px + 120, y + 2, "pk " .. tostring(r.best), th.text_muted, "inter", 12)
    end

    local record = r.wins .. "/" .. r.losses .. "/" .. r.draws
    gfx:text(px, y + 16, record, th.text_secondary, "inter", 12)
  end

  -- Right column: Recent Games + Elo Graph
  local ry = py + title_h + 20

  -- Recent Games header
  gfx:text(right_x, ry, "Recent Games", th.text_muted, "inter", 12)
  ry = ry + 16

  if state.recent_games and #state.recent_games > 0 then
    for i = 1, #state.recent_games do
      local g = state.recent_games[i]
      if ry + 16 > state.height - py - 80 then
        break
      end

      -- Result indicator
      local rc = th.text_muted
      if g.result == "W" then
        rc = th.accent_success
      elseif g.result == "L" then
        rc = th.accent_error
      end
      gfx:text(right_x, ry, g.result, rc, "inter", 12)

      -- Opponent and rating
      local opp = g.opponent
      if #opp > 12 then
        opp = string.sub(opp, 1, 11) .. ".."
      end
      gfx:text(right_x + 16, ry, opp, th.text_secondary, "inter", 12)

      -- Ratings
      local info = tostring(g.rating)
      gfx:text(right_x + col_w - 30, ry, info, th.text_muted, "inter", 12)

      ry = ry + 16
    end
  else
    gfx:text(right_x, ry, "No games", th.text_muted, "inter", 12)
    ry = ry + 16
  end

  -- Elo graph at bottom right
  ry = ry + 10
  if state.elo_history and #state.elo_history >= 2 then
    gfx:text(right_x, ry, "Rating Trend", th.text_muted, "inter", 12)
    ry = ry + 16
    local graph_h = state.height - ry - py - 5
    if graph_h > 30 then
      render_elo_graph(gfx, state, th, right_x + 30, ry, col_w - 35, graph_h)
    end
  end

  -- Puzzle Rush at bottom left
  if state.puzzle_rush then
    gfx:text(px, state.height - py - 12, "Puzzle Rush: " .. tostring(state.puzzle_rush), th.text_muted, "inter", 12)
  end
end

return M
