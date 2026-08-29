#!/usr/bin/env python3
"""Patch rustpush/src/util.rs to add proxy support with authentication.

Reads the existing util.rs, inserts get_proxy_from_env() function,
and adds proxy support to REQWEST and CARRIER_REQWEST builders.
"""
import sys
import os

UTIL_PATH = os.path.join("rustpush", "src", "util.rs")

PROXY_FUNC = '''
/// Read proxy config from environment variables or config file.
/// Config file: openbubbles_proxy.json next to the executable, format:
///   {"url":"http://proxy:8080","user":"username","pass":"password"}
/// Env vars: OB_PROXY_URL, OB_PROXY_USER, OB_PROXY_PASS
/// Also falls back to standard HTTPS_PROXY / HTTP_PROXY env vars.
fn get_proxy_from_env() -> Option<Proxy> {
    // Try config file first (next to executable)
    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            let config_path = dir.join("openbubbles_proxy.json");
            if let Ok(content) = std::fs::read_to_string(&config_path) {
                if let Ok(json) = serde_json::from_str::<serde_json::Value>(&content) {
                    let url = json.get("url").and_then(|v| v.as_str()).unwrap_or("");
                    if !url.is_empty() {
                        let user = json.get("user").and_then(|v| v.as_str()).unwrap_or("");
                        let pass = json.get("pass").and_then(|v| v.as_str()).unwrap_or("");
                        info!("Using proxy from config file: {} (auth: {})", url, !user.is_empty());
                        let mut proxy = Proxy::all(url).ok()?;
                        if !user.is_empty() && !pass.is_empty() {
                            proxy = proxy.basic_auth(user, pass);
                        }
                        return Some(proxy);
                    }
                }
            }
        }
    }

    // Fall back to environment variables
    let proxy_url = std::env::var("OB_PROXY_URL")
        .or_else(|_| std::env::var("HTTPS_PROXY"))
        .or_else(|_| std::env::var("https_proxy"))
        .or_else(|_| std::env::var("HTTP_PROXY"))
        .or_else(|_| std::env::var("http_proxy"))
        .ok()?;

    if proxy_url.is_empty() {
        return None;
    }

    let user = std::env::var("OB_PROXY_USER").ok().filter(|s| !s.is_empty());
    let pass = std::env::var("OB_PROXY_PASS").ok().filter(|s| !s.is_empty());

    info!("Using proxy from env: {} (auth: {})", proxy_url, user.is_some());

    let mut proxy = Proxy::all(&proxy_url).ok()?;
    if let (Some(u), Some(p)) = (user, pass) {
        proxy = proxy.basic_auth(&u, &p);
    }
    Some(proxy)
}
'''

def main():
    if not os.path.exists(UTIL_PATH):
        print(f"ERROR: {UTIL_PATH} not found")
        sys.exit(1)

    with open(UTIL_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Check if already patched
    if "get_proxy_from_env" in content:
        print("util.rs already patched with proxy support")
        return

    # 1. Insert get_proxy_from_env() before REQWEST
    reqwest_marker = "pub static REQWEST: LazyLock<Client> = LazyLock::new(|| {"
    if reqwest_marker not in content:
        print("ERROR: REQWEST marker not found")
        sys.exit(1)
    content = content.replace(reqwest_marker, PROXY_FUNC + "\n" + reqwest_marker)
    print("Inserted get_proxy_from_env() function")

    # 2. Add proxy to REQWEST builder
    old_reqwest = """    let mut builder = reqwest::Client::builder()
        .use_rustls_tls()
        .default_headers(headers.clone())
        .http1_title_case_headers();

    for certificate in certificates.into_iter() {"""
    new_reqwest = """    let mut builder = reqwest::Client::builder()
        .use_rustls_tls()
        .default_headers(headers.clone())
        .http1_title_case_headers();

    if let Some(proxy) = get_proxy_from_env() {
        builder = builder.proxy(proxy);
    }

    for certificate in certificates.into_iter() {"""
    if old_reqwest in content:
        content = content.replace(old_reqwest, new_reqwest)
        print("Patched REQWEST builder")
    else:
        print("WARNING: REQWEST builder pattern not found")

    # 3. Add proxy to CARRIER_REQWEST builder
    old_carrier = """    let mut builder = reqwest::Client::builder()
        // we need native TLS because carriers suck at providing modern TLS ciphers (with PFS)
        .use_native_tls()
        .default_headers(headers.clone())
        .http1_title_case_headers();

    builder.build().unwrap()"""
    new_carrier = """    let mut builder = reqwest::Client::builder()
        // we need native TLS because carriers suck at providing modern TLS ciphers (with PFS)
        .use_native_tls()
        .default_headers(headers.clone())
        .http1_title_case_headers();

    if let Some(proxy) = get_proxy_from_env() {
        builder = builder.proxy(proxy);
    }

    builder.build().unwrap()"""
    if old_carrier in content:
        content = content.replace(old_carrier, new_carrier)
        print("Patched CARRIER_REQWEST builder")
    else:
        print("WARNING: CARRIER builder pattern not found")

    with open(UTIL_PATH, "w", encoding="utf-8") as f:
        f.write(content)

    print("util.rs patched successfully!")

if __name__ == "__main__":
    main()
