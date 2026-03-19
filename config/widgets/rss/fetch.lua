-- RSS Widget: API fetching and response parsing

local M = {}

-- Fetch Miniflux entries and populate state
function M.fetch(state)
  local api_url = env.get("MINIFLUX_URL")
  local api_key = env.get("MINIFLUX_API_KEY")

  if not api_url then
    return false, "No MINIFLUX_URL"
  end

  if not api_key then
    return false, "No API key"
  end

  -- Miniflux API: GET /v1/entries?status=unread&limit=N
  local url = api_url .. "/v1/entries?status=unread&limit=" .. state.limit .. "&direction=desc&order=published_at"

  local headers = {
    ["X-Auth-Token"] = api_key,
  }

  local response = net.http_get(url, headers, 15000)

  if not (response and response.ok and response.body) then
    return false, response and response.error or "Network error"
  end

  local data = net.json_decode(response.body)

  if not (data and data.entries) then
    return false, "Invalid response"
  end

  state.entries = {}
  local idx = 1
  for i = 1, #data.entries do
    local entry = data.entries[i]
    if entry then
      local feed_title = ""
      if entry.feed and entry.feed.title then
        feed_title = entry.feed.title
      end
      state.entries[idx] = {
        id = entry.id,
        title = entry.title or "Untitled",
        feed = feed_title,
        url = entry.url,
      }
      idx = idx + 1
    end
  end

  return true
end

return M
