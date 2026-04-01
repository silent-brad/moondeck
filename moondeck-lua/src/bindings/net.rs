use std::collections::HashMap;

use anyhow::Result;
use piccolo::{Callback, CallbackReturn, Lua, String as LuaString, Table, Value};

use super::lua_serde::{json_to_lua, lua_to_json, parse_headers, parse_timeout};

pub fn register_net(lua: &mut Lua) -> Result<()> {
    lua.try_enter(|ctx| {
        let net = Table::new(&ctx);

        // net.http_get(url, headers?, timeout_ms?) -> { ok, body, error?, status }
        net.set(
            ctx,
            "http_get",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (url, headers, timeout): (LuaString, Value, Value) = stack.consume(ctx)?;
                let result = do_http_get(
                    url.to_str().unwrap_or(""),
                    &parse_headers(headers),
                    parse_timeout(timeout),
                );
                stack.replace(ctx, make_response(ctx, result));
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.http_post(url, body, content_type?, headers?, timeout_ms?) -> { ok, body,
        // error?, status }
        net.set(
            ctx,
            "http_post",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (url, body, content_type, headers, timeout): (
                    LuaString,
                    LuaString,
                    LuaString,
                    Value,
                    Value,
                ) = stack.consume(ctx)?;
                let mut header_map = parse_headers(headers);
                header_map.insert(
                    "Content-Type".into(),
                    content_type.to_str().unwrap_or("application/json").into(),
                );
                let result = do_http_post(
                    url.to_str().unwrap_or(""),
                    body.to_str().unwrap_or(""),
                    &header_map,
                    parse_timeout(timeout),
                );
                stack.replace(ctx, make_response(ctx, result));
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.json_decode(json_string) -> table or nil
        net.set(
            ctx,
            "json_decode",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let json_str: LuaString = stack.consume(ctx)?;
                let result = serde_json::from_str(json_str.to_str().unwrap_or(""))
                    .map(|v| json_to_lua(ctx, &v))
                    .unwrap_or(Value::Nil);
                stack.replace(ctx, result);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.json_encode(table) -> string or nil
        net.set(
            ctx,
            "json_encode",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let value: Value = stack.consume(ctx)?;
                let result = serde_json::to_string(&lua_to_json(ctx, value))
                    .map(|s| Value::String(ctx.intern(s.as_bytes())))
                    .unwrap_or(Value::Nil);
                stack.replace(ctx, result);
                Ok(CallbackReturn::Return)
            }),
        )?;

        // net.download(url, path, timeout_ms?) -> { ok, error? }
        net.set(
            ctx,
            "download",
            Callback::from_fn(&ctx, |ctx, _exec, mut stack| {
                let (url, path, timeout): (LuaString, LuaString, Value) = stack.consume(ctx)?;
                let result = do_download(
                    url.to_str().unwrap_or(""),
                    path.to_str().unwrap_or(""),
                    parse_timeout(timeout),
                );
                let response = Table::new(&ctx);
                match result {
                    Ok(()) => {
                        let _ = response.set(ctx, "ok", true);
                    }
                    Err(e) => {
                        let _ = response.set(ctx, "ok", false);
                        let _ = response.set(ctx, "error", ctx.intern(e.as_bytes()));
                    }
                }
                stack.replace(ctx, response);
                Ok(CallbackReturn::Return)
            }),
        )?;

        ctx.set_global("net", net)?;
        Ok(())
    })?;
    Ok(())
}

fn make_response<'gc>(
    ctx: piccolo::Context<'gc>,
    result: Result<(u16, String), String>,
) -> Table<'gc> {
    let response = Table::new(&ctx);
    match result {
        Ok((status, body)) => {
            let _ = response.set(ctx, "ok", (200..300).contains(&status));
            let _ = response.set(ctx, "status", status as i64);
            let _ = response.set(ctx, "body", ctx.intern(body.as_bytes()));
        }
        Err(e) => {
            let _ = response.set(ctx, "ok", false);
            let _ = response.set(ctx, "error", ctx.intern(e.as_bytes()));
            let _ = response.set(ctx, "body", ctx.intern(b""));
        }
    }
    response
}

#[cfg(feature = "esp")]
fn do_http_get(
    url: &str,
    headers: &HashMap<String, String>,
    timeout_ms: u32,
) -> Result<(u16, String), String> {
    use moondeck_hal::HttpClient;
    log::info!("HTTP GET: {}", url);
    let client = HttpClient::with_timeout(timeout_ms);
    let pairs: Vec<_> = headers
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();
    client
        .get_with_headers(url, &pairs)
        .map(|r| {
            log::info!("HTTP {}: {} bytes", r.status, r.body.len());
            (r.status, r.body)
        })
        .map_err(|e| {
            log::error!("HTTP error: {:?}", e);
            format!("{}", e)
        })
}

#[cfg(feature = "esp")]
fn do_http_post(
    url: &str,
    body: &str,
    headers: &HashMap<String, String>,
    timeout_ms: u32,
) -> Result<(u16, String), String> {
    use moondeck_hal::HttpClient;
    log::info!("HTTP POST: {}", url);
    let client = HttpClient::with_timeout(timeout_ms);
    let content_type = headers
        .get("Content-Type")
        .map(|s| s.as_str())
        .unwrap_or("application/json");
    let extra: Vec<(&str, &str)> = headers
        .iter()
        .filter(|(k, _)| k.as_str() != "Content-Type")
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();
    client
        .post_with_headers(url, body, content_type, &extra)
        .map(|r| {
            log::info!("HTTP {}: {} bytes", r.status, r.body.len());
            (r.status, r.body)
        })
        .map_err(|e| {
            log::error!("HTTP error: {:?}", e);
            format!("{}", e)
        })
}

#[cfg(feature = "esp")]
fn do_download(url: &str, path: &str, timeout_ms: u32) -> Result<(), String> {
    use moondeck_hal::HttpClient;
    log::info!("Download: {} -> {}", url, path);
    let client = HttpClient::with_timeout(timeout_ms);

    let mut retries = 3;
    loop {
        let (status, bytes) = client.get_bytes(url).map_err(|e| format!("{}", e))?;
        if status == 429 && retries > 0 {
            retries -= 1;
            log::warn!("HTTP 429 for {}, retrying in 2s ({} left)", url, retries);
            std::thread::sleep(std::time::Duration::from_secs(2));
            continue;
        }
        if !(200..300).contains(&status) {
            return Err(format!("HTTP {}", status));
        }
        std::fs::write(path, &bytes).map_err(|e| format!("Write error: {}", e))?;
        log::info!("Downloaded {} bytes to {}", bytes.len(), path);
        return Ok(());
    }
}

#[cfg(not(feature = "esp"))]
fn do_http_get(_: &str, _: &HashMap<String, String>, _: u32) -> Result<(u16, String), String> {
    Err("HTTP not available in this build".into())
}

#[cfg(not(feature = "esp"))]
fn do_http_post(
    _: &str,
    _: &str,
    _: &HashMap<String, String>,
    _: u32,
) -> Result<(u16, String), String> {
    Err("HTTP not available in this build".into())
}

#[cfg(not(feature = "esp"))]
fn do_download(_: &str, _: &str, _: u32) -> Result<(), String> {
    Err("HTTP not available in this build".into())
}
