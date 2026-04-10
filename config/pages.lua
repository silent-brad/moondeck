-- Moondeck Pages Configuration

local deck = require("utils.dsl")

return deck.config({
  page_switch_interval = env.get("PAGE_SWITCH_INTERVAL") or 60000,

  deck.page("dashboard")({
    layout = "quad",
    deck.widget("sysinfo")({ interval = 1000 }),
    deck.widget("status")({ interval = 1000 }),
    deck.widget("weather")({ interval = 300000 }),
    deck.widget("clock")({
      interval = 1000,
      timezone = env.get("TIMEZONE"),
      show_seconds = true,
      show_date = true,
      format_24h = false,
    }),
  }),

  deck.page("home")({
    layout = "half_half",
    deck.widget("chess")({ interval = 300000, username = env.get("CHESS_USERNAME") }),
    deck.widget("quote")({ interval = 60000 }),
  }),

  deck.page("stocks")({
    layout = "half_half",
    deck.widget("crypto")({ interval = 60000, coins = { "bitcoin", "ethereum", "solana", "monero" } }),
    deck.widget("stocks")({ interval = 60000, symbols = { "AAPL", "GOOGL", "PLTR", "TSLA", "MO" } }),
  }),

  deck.page("reading")({
    layout = "half_half",
    deck.widget("bible")({ interval = 3600000 }),
    deck.widget("rss")({ interval = 300000 }),
  }),

  deck.page("heatmap")({ title = "GitHub Heatmap", deck.widget("github")({ interval = 3000 }) }),

  deck.page("gallery")({
    title = "Lord Leighton",
    deck.widget("slideshow")({
      interval = 1000,
      slide_interval = 10,
      fetch_urls = {
        "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Leighton_The_Painter-s_Honeymoon_1864.jpg/200px-Leighton_The_Painter-s_Honeymoon_1864.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Flaming_June%2C_by_Frederic_Lord_Leighton_%281830-1896%29.jpg/200px-Flaming_June%2C_by_Frederic_Lord_Leighton_%281830-1896%29.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8c/Golden_hours%2C_by_Frederic_Leighton.jpg/200px-Golden_hours%2C_by_Frederic_Leighton.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Amarilla_Leighton.jpg/200px-Amarilla_Leighton.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Frederick_Leighton_-_The_golden_hours.jpg/200px-Frederick_Leighton_-_The_golden_hours.jpg",
      },
    }),
  }),
})
