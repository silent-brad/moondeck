-- Weather Widget: Rendering

local M = {}

function M.render(state, gfx)
  local th = theme:get()
  local px, py = 20, 15

  -- Draw card
  components.card(gfx, 0, 0, state.width, state.height)

  -- Title bar
  local title_h = components.title_bar(gfx, px, py, state.width - px * 2, "Weather", {
    accent = th.accent_primary,
  })

  local content_y = py + title_h + 10

  if state.loading then
    components.loading(gfx, px, content_y + 30)
    return
  end

  if state.error then
    components.error(gfx, px, content_y + 10, state.width - px * 2, state.error)
    return
  end

  -- Temperature display (large)
  local temp_str = tostring(state.temperature) .. "°"
  local unit = state.units == "metric" and "C" or "F"

  gfx:text(px, content_y + 15, temp_str, th.text_secondary, "inter", 32)
  gfx:text(px + #temp_str * 14 + 5, content_y + 20, unit, th.text_muted, "inter", 24)

  -- Description
  if state.description then
    gfx:text(px, content_y + 55, state.description, th.text_accent, "inter", 24)
  end

  -- City
  gfx:text(px, content_y + 80, state.city, th.text_muted, "inter", 12)

  -- Additional info (right side or below based on width)
  local info_x = state.width > 300 and (state.width / 2 + 20) or px
  local info_y = state.width > 300 and (content_y + 15) or (content_y + 100)

  if state.feels_like then
    components.item_row(gfx, info_x, info_y, 140, "Feels like", state.feels_like .. "°", {
      label_color = th.text_muted,
    })
    info_y = info_y + 22
  end

  if state.humidity then
    components.item_row(gfx, info_x, info_y, 140, "Humidity", state.humidity .. "%", {
      label_color = th.text_muted,
    })
    info_y = info_y + 22
  end

  if state.wind_speed then
    local wind_unit = state.units == "metric" and "m/s" or "mph"
    components.item_row(gfx, info_x, info_y, 140, "Wind", state.wind_speed .. " " .. wind_unit, {
      label_color = th.text_muted,
    })
  end
end

return M
