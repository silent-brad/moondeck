-- Weather Widget: API fetching and response parsing

local M = {}

-- URL-encode city name (replace spaces with %20)
local function encode_city(raw_city)
  local city = ""
  for i = 1, #raw_city do
    local c = string.sub(raw_city, i, i)
    if c == " " then
      city = city .. "%20"
    else
      city = city .. c
    end
  end
  return city
end

-- Fetch weather data from OpenWeatherMap and populate state
function M.fetch(state)
  local api_key = env.get("WEATHER_API_KEY")
  if not api_key then
    return false, "No API key"
  end

  local city = encode_city(state.city or "New York")
  local units = state.units or "imperial"
  local url = "https://api.openweathermap.org/data/2.5/weather?q=" .. city .. "&units=" .. units .. "&appid=" .. api_key

  local response = net.http_get(url, {}, 10000)
  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)
  if not (data and data.main) then
    return false, "Invalid API response"
  end

  state.temperature = data.main.temp
  state.feels_like = data.main.feels_like
  state.humidity = data.main.humidity
  if data.weather and data.weather[1] then
    state.description = data.weather[1].description
    state.icon = data.weather[1].icon
  end
  if data.wind then
    state.wind_speed = data.wind.speed
  end

  return true
end

return M
