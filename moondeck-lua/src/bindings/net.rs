use anyhow::Result;
use piccolo::{Callback, CallbackReturn, Lua, String as LuaString, Table, Value};
use std::collections::HashMap;

pub fn register_net(lua: &mut Lua) -> Result<()> {
    lua.try_enter(|ctx| {
        let net_table = Table::new(&ctx);

        // net.http_get(url, headers, timeout_ms) -> { ok, body, error, status }
        net_table.set(
            ctx,
            "http_get",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (url, headers, timeout_ms): (LuaString, Value, Value) = stack.consume(ctx)?;
                let url_str = url.to_str().unwrap_or("").to_string();

                let timeout = match timeout_ms {
                    Value::Integer(ms) => ms as u32,
                    Value::Number(ms) => ms as u32,
                    _ => 10000,
                };

                // Parse optional headers table
                let mut header_map: HashMap<String, String> = HashMap::new();
                if let Value::Table(headers_table) = headers {
                    for (k, v) in headers_table.iter() {
                        if let (Value::String(key), Value::String(val)) = (k, v) {
                            if let (Ok(key_str), Ok(val_str)) = (key.to_str(), val.to_str()) {
                                header_map.insert(key_str.to_string(), val_str.to_string());
                            }
                        }
                    }
                }

                // Perform HTTP GET request
                let result = do_http_get(&url_str, &header_map, timeout);

                // Create response table
                let response = Table::new(&ctx);

                match result {
                    Ok((status, body)) => {
                        let _ = response.set(ctx, "ok", status >= 200 && status < 300);
                        let _ = response.set(ctx, "status", status as i64);
                        let _ = response.set(ctx, "body", ctx.intern(body.as_bytes()));
                    }
                    Err(e) => {
                        let _ = response.set(ctx, "ok", false);
                        let _ = response.set(ctx, "error", ctx.intern(e.as_bytes()));
                        let _ = response.set(ctx, "body", ctx.intern(b""));
                    }
                }

                stack.replace(ctx, response);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.http_post(url, body, content_type, headers, timeout_ms) -> { ok, body, error, status }
        net_table.set(
            ctx,
            "http_post",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (url, body, content_type, headers, timeout_ms): (
                    LuaString,
                    LuaString,
                    LuaString,
                    Value,
                    Value,
                ) = stack.consume(ctx)?;

                let url_str = url.to_str().unwrap_or("").to_string();
                let body_str = body.to_str().unwrap_or("").to_string();
                let content_type_str = content_type.to_str().unwrap_or("application/json").to_string();

                let timeout = match timeout_ms {
                    Value::Integer(ms) => ms as u32,
                    Value::Number(ms) => ms as u32,
                    _ => 10000,
                };

                // Parse optional headers table
                let mut header_map: HashMap<String, String> = HashMap::new();
                header_map.insert("Content-Type".to_string(), content_type_str);
                if let Value::Table(headers_table) = headers {
                    for (k, v) in headers_table.iter() {
                        if let (Value::String(key), Value::String(val)) = (k, v) {
                            if let (Ok(key_str), Ok(val_str)) = (key.to_str(), val.to_str()) {
                                header_map.insert(key_str.to_string(), val_str.to_string());
                            }
                        }
                    }
                }

                // Perform HTTP POST request
                let result = do_http_post(&url_str, &body_str, &header_map, timeout);

                // Create response table
                let response = Table::new(&ctx);

                match result {
                    Ok((status, resp_body)) => {
                        let _ = response.set(ctx, "ok", status >= 200 && status < 300);
                        let _ = response.set(ctx, "status", status as i64);
                        let _ = response.set(ctx, "body", ctx.intern(resp_body.as_bytes()));
                    }
                    Err(e) => {
                        let _ = response.set(ctx, "ok", false);
                        let _ = response.set(ctx, "error", ctx.intern(e.as_bytes()));
                        let _ = response.set(ctx, "body", ctx.intern(b""));
                    }
                }

                stack.replace(ctx, response);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.json_decode(json_string) -> table or nil
        net_table.set(
            ctx,
            "json_decode",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let json_str: LuaString = stack.consume(ctx)?;
                let json = json_str.to_str().unwrap_or("");

                match serde_json::from_str::<serde_json::Value>(json) {
                    Ok(value) => {
                        let lua_value = json_to_lua(ctx, &value);
                        stack.replace(ctx, lua_value);
                    }
                    Err(_) => {
                        stack.replace(ctx, Value::Nil);
                    }
                }

                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.json_encode(table) -> string or nil
        net_table.set(
            ctx,
            "json_encode",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let value: Value = stack.consume(ctx)?;
                let json_value = lua_to_json(ctx, value);

                match serde_json::to_string(&json_value) {
                    Ok(json_str) => {
                        stack.replace(ctx, ctx.intern(json_str.as_bytes()));
                    }
                    Err(_) => {
                        stack.replace(ctx, Value::Nil);
                    }
                }

                Ok(CallbackReturn::Return)
            }),
        )?;

        ctx.set_global("net", net_table)?;
        Ok(())
    })?;

    Ok(())
}

fn json_to_lua<'gc>(ctx: piccolo::Context<'gc>, value: &serde_json::Value) -> Value<'gc> {
    match value {
        serde_json::Value::Null => Value::Nil,
        serde_json::Value::Bool(b) => Value::Boolean(*b),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                Value::Integer(i)
            } else if let Some(f) = n.as_f64() {
                Value::Number(f)
            } else {
                Value::Nil
            }
        }
        serde_json::Value::String(s) => Value::String(ctx.intern(s.as_bytes())),
        serde_json::Value::Array(arr) => {
            let table = Table::new(&ctx);
            for (i, v) in arr.iter().enumerate() {
                let _ = table.set(ctx, (i + 1) as i64, json_to_lua(ctx, v));
            }
            Value::Table(table)
        }
        serde_json::Value::Object(obj) => {
            let table = Table::new(&ctx);
            for (k, v) in obj.iter() {
                let _ = table.set(ctx, ctx.intern(k.as_bytes()), json_to_lua(ctx, v));
            }
            Value::Table(table)
        }
    }
}

fn lua_to_json<'gc>(ctx: piccolo::Context<'gc>, value: Value<'gc>) -> serde_json::Value {
    match value {
        Value::Nil => serde_json::Value::Null,
        Value::Boolean(b) => serde_json::Value::Bool(b),
        Value::Integer(i) => serde_json::json!(i),
        Value::Number(n) => serde_json::json!(n),
        Value::String(s) => {
            serde_json::Value::String(s.to_str().unwrap_or("").to_string())
        }
        Value::Table(t) => {
            // Check if it's an array (has integer keys starting from 1)
            let first_val = t.get_value(Value::Integer(1));
            if !matches!(first_val, Value::Nil) {
                let mut arr = Vec::new();
                let mut idx = 1i64;
                loop {
                    let v = t.get_value(Value::Integer(idx));
                    if matches!(v, Value::Nil) {
                        break;
                    }
                    arr.push(lua_to_json(ctx, v));
                    idx += 1;
                }
                serde_json::Value::Array(arr)
            } else {
                let mut map = serde_json::Map::new();
                for (k, v) in t.iter() {
                    if let Value::String(ks) = k {
                        if let Ok(key_str) = ks.to_str() {
                            map.insert(key_str.to_string(), lua_to_json(ctx, v));
                        }
                    }
                }
                serde_json::Value::Object(map)
            }
        }
        _ => serde_json::Value::Null,
    }
}

#[cfg(feature = "esp")]
fn do_http_get(
    url: &str,
    headers: &HashMap<String, String>,
    timeout_ms: u32,
) -> Result<(u16, String), String> {
    use moondeck_hal::HttpClient;

    let client = HttpClient::with_timeout(timeout_ms);
    let header_pairs: Vec<(&str, &str)> = headers
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();

    match client.get_with_headers(url, &header_pairs) {
        Ok(response) => Ok((response.status, response.body)),
        Err(e) => Err(format!("{}", e)),
    }
}

#[cfg(feature = "esp")]
fn do_http_post(
    url: &str,
    body: &str,
    headers: &HashMap<String, String>,
    timeout_ms: u32,
) -> Result<(u16, String), String> {
    use moondeck_hal::HttpClient;

    let client = HttpClient::with_timeout(timeout_ms);
    let content_type = headers
        .get("Content-Type")
        .map(|s| s.as_str())
        .unwrap_or("application/json");

    match client.post(url, body, content_type) {
        Ok(response) => Ok((response.status, response.body)),
        Err(e) => Err(format!("{}", e)),
    }
}

#[cfg(not(feature = "esp"))]
fn do_http_get(
    _url: &str,
    _headers: &HashMap<String, String>,
    _timeout_ms: u32,
) -> Result<(u16, String), String> {
    // Stub for non-ESP builds (testing)
    Err("HTTP not available in this build".to_string())
}

#[cfg(not(feature = "esp"))]
fn do_http_post(
    _url: &str,
    _body: &str,
    _headers: &HashMap<String, String>,
    _timeout_ms: u32,
) -> Result<(u16, String), String> {
    // Stub for non-ESP builds (testing)
    Err("HTTP not available in this build".to_string())
}
