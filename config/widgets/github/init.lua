-- GitHub Widget

local base = require("utils.widget_base")
local fetch = require("widgets.github.fetch")
local render = require("widgets.github.render")

return base.new({
  fetch_interval = 3600000,
  setup = function(state, ctx)
    state.username = ctx.opts.username or env.get("GITHUB_USERNAME") or ""
    state.weeks = {}
    state.total = 0
    state.commit_repos = {}
    state.commit_msgs = {}
    state.commit_dates = {}
    state.commit_lines = {}
    state.commit_langs = {}
    state.commit_count = 0
    state.lang_names = {}
    state.lang_pcts = {}
    state.lang_count = 0
    state.repo_names = {}
    state.repo_descs = {}
    state.repo_visibilities = {}
    state.repo_pushed = {}
    state.repo_lang_names = {}
    state.repo_lang_pcts = {}
    state.repo_lang_colors = {}
    state.repo_lang_counts = {}
    state.repo_count = 0
  end,
  fetch = function(state)
    return fetch.fetch(state)
  end,
  render = function(state, gfx)
    render.render(state, gfx)
  end,
})
