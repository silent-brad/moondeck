-- components/lua_modules/db/init.lua
local db = {}

local sqlite = nil -- Will be set by C binding

function db.init(path)
	path = path or "/data/moondeck.db"
	sqlite = sqlite_open(path)

	if not sqlite then
		return false, "Failed to open database"
	end

	-- Run migrations
	db.migrate()

	return true
end

function db.migrate()
	local schema = [[
    CREATE TABLE IF NOT EXISTS kv_store (
      key TEXT PRIMARY KEY,
      value TEXT,
      expires_at INTEGER,
      created_at INTEGER DEFAULT (strftime('%s', 'now')),
      updated_at INTEGER DEFAULT (strftime('%s', 'now'))
    );

    CREATE TABLE IF NOT EXISTS api_cache (
      url TEXT PRIMARY KEY,
      response TEXT,
      status_code INTEGER,
      fetched_at INTEGER,
      ttl INTEGER
    );

    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER DEFAULT (strftime('%s', 'now')),
      type TEXT,
      plugin TEXT,
      message TEXT,
      data TEXT
    );
  ]]

	sqlite_exec(sqlite, schema)
end

-- Key-Value Operations
function db.set(key, value, ttl)
	local expires_at = ttl and (os.time() + ttl) or nil
	local val_str = type(value) == "table" and json.encode(value) or tostring(value)

	sqlite_exec(
		sqlite,
		[[
      INSERT OR REPLACE INTO kv_store (key, value, expires_at, updated_at)
      VALUES (?, ?, ?, strftime('%s', 'now'))
    ]],
		key,
		val_str,
		expires_at
	)
end

function db.get(key)
	local row = sqlite_query_one(
		sqlite,
		[[
      SELECT value, expires_at FROM kv_store WHERE key = ?
    ]],
		key
	)

	if not row then
		return nil
	end

	-- Check expiration
	if row.expires_at and row.expires_at < os.time() then
		db.delete(key)
		return nil
	end

	-- Try to decode as JSON
	local ok, decoded = pcall(json.decode, row.value)
	return ok and decoded or row.value
end

function db.delete(key)
	sqlite_exec(sqlite, "DELETE FROM kv_store WHERE key = ?", key)
end

-- Cache Operations
function db.cache_get(url)
	local row = sqlite_query_one(
		sqlite,
		[[
      SELECT response, fetched_at, ttl FROM api_cache WHERE url = ?
    ]],
		url
	)

	if not row then
		return nil
	end

	-- Check if stale
	if row.fetched_at + row.ttl < os.time() then
		return nil, "stale"
	end

	return row.response
end

function db.cache_set(url, response, ttl)
	ttl = ttl or 300
	sqlite_exec(
		sqlite,
		[[
      INSERT OR REPLACE INTO api_cache (url, response, fetched_at, ttl)
      VALUES (?, ?, strftime('%s', 'now'), ?)
    ]],
		url,
		response,
		ttl
	)
end

-- Event Logging
function db.log(type, plugin, message, data)
	local data_str = data and json.encode(data) or nil
	sqlite_exec(
		sqlite,
		[[
      INSERT INTO events (type, plugin, message, data)
      VALUES (?, ?, ?, ?)
    ]],
		type,
		plugin,
		message,
		data_str
	)

	-- Prune old events (keep last 1000)
	sqlite_exec(
		sqlite,
		[[
      DELETE FROM events WHERE id NOT IN (
        SELECT id FROM events ORDER BY timestamp DESC LIMIT 1000
      )
    ]]
	)
end

-- Cleanup expired entries
function db.cleanup()
	sqlite_exec(
		sqlite,
		[[
      DELETE FROM kv_store WHERE expires_at IS NOT NULL AND expires_at < strftime('%s', 'now')
    ]]
	)
end

function db.close()
	if sqlite then
		sqlite_close(sqlite)
		sqlite = nil
	end
end

return db
