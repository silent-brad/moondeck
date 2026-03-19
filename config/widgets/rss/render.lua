-- RSS Widget: Rendering

local M = {}

-- Truncate text with ellipsis
local function truncate(text, max_len)
  if not text then
    return ""
  end
  if #text <= max_len then
    return text
  end
  local truncated = ""
  for i = 1, max_len - 3 do
    truncated = truncated .. string.sub(text, i, i)
  end
  return truncated .. "..."
end

function M.render(state, gfx)
  local th = theme:get()
  local px, py = 20, 15

  -- Draw card
  components.card(gfx, 0, 0, state.width, state.height)

  -- Title bar with entry count
  local title = "RSS Feed"
  if #state.entries > 0 then
    title = title .. " (" .. #state.entries .. ")"
  end

  local title_h = components.title_bar(gfx, px, py, state.width - px * 2, title, {
    accent = th.accent_primary,
  })

  local content_y = py + title_h + 25

  if state.loading then
    components.loading(gfx, px, content_y + 20)
    return
  end

  if state.error then
    components.error(gfx, px, content_y, state.width - px * 2, state.error)
    return
  end

  if #state.entries == 0 then
    gfx:text(px, content_y + 20, "No unread entries", th.text_muted, "inter", 16)
    return
  end

  -- Display entries as list
  local row_height = 45
  local max_rows = math.floor((state.height - content_y - py - 20) / row_height)
  local title_max_chars = math.floor((state.width - px * 2) / 7)

  for i = 1, #state.entries do
    if i > max_rows then
      break
    end

    local entry = state.entries[i]
    local y = content_y + (i - 1) * row_height

    -- Entry indicator
    gfx:fill_circle(px + 4, y + 8, 3, th.accent_primary)

    -- Title
    local title_text = truncate(entry.title, title_max_chars)
    gfx:text(px + 15, y, title_text, th.text_primary, "inter", 16)

    -- Feed name
    gfx:text(px + 15, y + 18, entry.feed, th.text_muted, "inter", 12)
  end

  -- Navigation hint at bottom
  if #state.entries > max_rows then
    local more = #state.entries - max_rows
    gfx:text(px, state.height - py - 5, "+" .. more .. " more", th.text_muted, "inter", 12)
  end
end

return M
