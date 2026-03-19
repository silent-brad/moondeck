-- Chess Widget: API fetching and response parsing

local M = {}

-- stylua: ignore
local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                 "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- Convert epoch timestamp to "Mon DD, YYYY"
function M.format_epoch(ts)
  if not ts or ts == 0 then
    return ""
  end
  -- Chess.com timestamps are in seconds
  -- Use integer division to extract date components
  -- Days since epoch (Jan 1 1970)
  local days = math.floor(ts / 86400)
  -- Approximate year/month/day from days since epoch
  local y = 1970
  while true do
    local dy = (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 366 or 365
    if days < dy then
      break
    end
    days = days - dy
    y = y + 1
  end
  local mdays = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0) then
    mdays[2] = 29
  end
  local m = 1
  while m <= 12 and days >= mdays[m] do
    days = days - mdays[m]
    m = m + 1
  end
  return months[m] .. " " .. tostring(days + 1) .. ", " .. tostring(y)
end

-- Convert epoch to "Mon DD"
function M.short_epoch(ts)
  if not ts or ts == 0 then
    return ""
  end
  local days = math.floor(ts / 86400)
  local y = 1970
  while true do
    local dy = (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 366 or 365
    if days < dy then
      break
    end
    days = days - dy
    y = y + 1
  end
  local mdays = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0) then
    mdays[2] = 29
  end
  local m = 1
  while m <= 12 and days >= mdays[m] do
    days = days - mdays[m]
    m = m + 1
  end
  return months[m] .. " " .. tostring(days + 1)
end

-- Get current year/month for games archive URL
local function current_ym()
  local now = device.seconds()
  if not now or now == 0 then
    now = 1750000000
  end

  local days = math.floor(now / 86400)
  local y = 1970
  while true do
    local dy = (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 366 or 365
    if days < dy then
      break
    end
    days = days - dy
    y = y + 1
  end
  local mdays = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
  if y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0) then
    mdays[2] = 29
  end
  local m = 1
  while m <= 12 and days >= mdays[m] do
    days = days - mdays[m]
    m = m + 1
  end
  local ms = tostring(m)
  if m < 10 then ms = "0" .. ms end
  return tostring(y), ms
end

-- Fetch player profile (joined, last_online, title)
function M.fetch_profile(state)
  local url = "https://api.chess.com/pub/player/" .. state.username

  local response = net.http_get(url, {}, 15000)
  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)
  if not data then
    return false, "Invalid profile"
  end

  state.title = data.title or ""
  state.joined = data.joined or 0
  state.last_online = data.last_online or 0

  return true
end

-- Fetch player stats (ratings, W/L/D)
function M.fetch_stats(state)
  local url = "https://api.chess.com/pub/player/" .. state.username .. "/stats"

  local response = net.http_get(url, {}, 15000)
  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)
  if not data then
    return false, "Invalid stats"
  end

  local modes = { "chess_rapid", "chess_blitz", "chess_bullet" }
  local display = { chess_rapid = "Rapid", chess_blitz = "Blitz", chess_bullet = "Bullet" }

  state.ratings = {}
  for i = 1, #modes do
    local key = modes[i]
    local mode_data = data[key]
    if mode_data and mode_data.last then
      local record = mode_data.record or {}
      state.ratings[#state.ratings + 1] = {
        name = display[key],
        rating = mode_data.last.rating,
        best = mode_data.best and mode_data.best.rating or nil,
        wins = record.win or 0,
        losses = record.loss or 0,
        draws = record.draw or 0,
      }
    end
  end

  if data.fide then
    state.fide = data.fide
  end

  if data.puzzle_rush and data.puzzle_rush.best then
    state.puzzle_rush = data.puzzle_rush.best.score
  end

  return true
end

-- Fetch recent games (current month) and extract history
function M.fetch_games(state)
  local year, month = current_ym()
  local url = "https://api.chess.com/pub/player/" .. state.username .. "/games/" .. year .. "/" .. month

  local response = net.http_get(url, {}, 15000)
  if not (response and response.ok and response.body) then
    return true -- non-fatal, games are optional
  end

  local data = net.json_decode(response.body)
  if not data or not data.games then
    return true
  end

  local games = data.games
  local uname_lower = string.lower(state.username)

  -- Recent games (last 5)
  state.recent_games = {}
  local start = math.max(1, #games - 4)
  for i = #games, start, -1 do
    local g = games[i]
    local is_white = g.white and string.lower(g.white.username or "") == uname_lower
    local player = is_white and g.white or g.black
    local opponent = is_white and g.black or g.white
    local result = player and player.result or ""

    local display_result = "?"
    if result == "win" then
      display_result = "W"
    elseif result == "resigned" or result == "timeout" or result == "checkmated" or result == "abandoned" then
      display_result = "L"
    elseif
      result == "agreed"
      or result == "repetition"
      or result == "stalemate"
      or result == "insufficient"
      or result == "50move"
      or result == "timevsinsufficient"
    then
      display_result = "D"
    end

    state.recent_games[#state.recent_games + 1] = {
      opponent = opponent and opponent.username or "?",
      result = display_result,
      rating = player and player.rating or 0,
      opp_rating = opponent and opponent.rating or 0,
      time_class = g.time_class or "",
      end_time = g.end_time or 0,
    }
  end

  -- Elo history for graph (blitz ratings over time, sampled)
  state.elo_history = {}
  for i = 1, #games do
    local g = games[i]
    if g.time_class == "blitz" or g.time_class == "bullet" or g.time_class == "rapid" then
      local is_white = g.white and string.lower(g.white.username or "") == uname_lower
      local player = is_white and g.white or g.black
      if player and player.rating then
        state.elo_history[#state.elo_history + 1] = {
          rating = player.rating,
          time = g.end_time or 0,
        }
      end
    end
  end

  return true
end

return M
