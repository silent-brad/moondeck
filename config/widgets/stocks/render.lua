-- Stocks Widget: Rendering

local M = {}

local function format_price(price)
  if not price then
    return "—"
  end
  return "$" .. util.format("%.2f", price)
end

local function format_change(change)
  if not change then
    return "—", "info"
  end

  local sign = ""
  local status = "info"
  if change >= 0 then
    sign = "+"
    status = "ok"
  else
    status = "error"
  end

  return sign .. util.format("%.2f", change) .. "%", status
end

function M.render(state, gfx)
  local th = theme:get()
  local px, py = 20, 15

  -- Draw card
  components.card(gfx, 0, 0, state.width, state.height)

  -- Title bar
  local title_h = components.title_bar(gfx, px, py, state.width - px * 2, "Stocks", {
    accent = th.accent_secondary,
  })

  local content_y = py + title_h + 25

  if state.loading then
    components.loading(gfx, px, content_y + 20)
    return
  end

  if state.error then
    components.error(gfx, px, content_y + 10, state.width - px * 2, state.error)
    return
  end

  -- Display each stock
  local row_height = 28
  local chart_w = 60
  local chart_h = 18
  local max_rows = math.floor((state.height - content_y - py) / row_height)

  for i = 1, #state.symbols do
    if i > max_rows then
      break
    end

    local symbol = state.symbols[i]
    local y = content_y + (i - 1) * row_height
    local price = format_price(state.prices[symbol])
    local change_str, change_status = format_change(state.changes[symbol])

    -- Symbol
    gfx:text(px, y, symbol, th.text_secondary, "inter", 16)

    -- Mini chart
    local chart_x = px + 50
    local history = state.history and state.history[symbol]
    if history and #history >= 2 then
      local chart_color = th.accent_primary
      if change_status == "ok" then
        chart_color = th.accent_success
      elseif change_status == "error" then
        chart_color = th.accent_error
      end
      components.line_graph(gfx, chart_x, y + 1, chart_w, chart_h, history, {
        color = chart_color,
        thickness = 1,
        fill = true,
        show_grid = true,
      })
    end

    -- Price (after chart)
    local price_x = chart_x + chart_w + 8
    gfx:text(price_x, y, price, th.text_secondary, "inter", 16)

    -- Change (right)
    local change_color = th.text_muted
    if change_status == "ok" then
      change_color = th.accent_success
    elseif change_status == "error" then
      change_color = th.accent_error
    end
    gfx:text(state.width - px - 60, y, change_str, change_color, "inter", 12)
  end

  -- Market status indicator
  local now_hours = math.floor(device.seconds() / 3600) % 24
  local market_open = now_hours >= 14 and now_hours < 21 -- Rough EST market hours in UTC
  local status_text = market_open and "Market Open" or "Market Closed"
  local status_color = market_open and th.accent_success or th.text_muted

  gfx:text(px, state.height - py - 10, status_text, status_color, "inter", 12)
end

return M
