-- Moondeck Page Config DSL
-- Simplifies pages.lua configuration

local Dsl = {}

-- deck.widget "name" { interval = N, ... }
-- Returns a widget config entry. All fields besides "interval" go into opts.
function Dsl.widget(name)
  return function(opts)
    opts = opts or {}
    local interval = opts.interval
    opts.interval = nil

    return {
      widget = require("widgets." .. name),
      update_interval = interval or 1000,
      opts = opts,
    }
  end
end

-- deck.page "id" { layout = "...", deck.widget(...), ... }
-- Returns a page config entry.
function Dsl.page(id)
  return function(def)
    local widgets = {}
    for i = 1, #def do
      widgets[i] = def[i]
    end

    return {
      id = id,
      title = def.title or string.upper(string.sub(id, 1, 1)) .. string.sub(id, 2),
      layout = def.layout or "full",
      widgets = widgets,
    }
  end
end

-- deck.config { page_switch_interval = N, deck.page(...), ... }
-- Returns the top-level pages config table.
function Dsl.config(def)
  local pages = {}
  for i = 1, #def do
    pages[i] = def[i]
  end

  return {
    page_switch_interval = def.page_switch_interval,
    pages = pages,
  }
end

return Dsl
