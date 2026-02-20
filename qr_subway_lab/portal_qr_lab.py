#!/usr/bin/env python3
"""
Glyph Portal QR Experiment
============================
Tests embedding a self-contained HTML page directly inside a QR code
using data URIs. The goal: scan → browser opens → full portal experience.

Approach hierarchy:
1. data:text/html,<html>...  → Self-contained page IN the QR code
2. data:text/html;base64,...  → Same but base64-encoded  
3. Extreme minimal HTML       → Stripped to the bone

QR Code capacity limits (binary mode, error correction L):
- Version 20: ~858 bytes
- Version 25: ~1,292 bytes  
- Version 30: ~1,732 bytes
- Version 35: ~2,188 bytes
- Version 40 (MAX): ~2,953 bytes

So we have ~2,900 bytes to build an ENTIRE webpage.
"""

import qrcode
import qrcode.constants
import base64
import io
import http.server
import socketserver
import socket
import os
import sys
import html as html_lib
import gzip
from datetime import datetime

PORT = 8899

# ---------------------------------------------------------------------------
# PORTAL HTML VARIANTS — Each one tries to fit in a QR code
# ---------------------------------------------------------------------------

def portal_v1_ultra_minimal():
    """
    Ultra-minimal: just enough HTML to show a styled message.
    Target: < 500 bytes (easy QR scan)
    """
    return ("data:text/html,"
        "<body style='background:%230a0a14;color:%23fff;font-family:system-ui;"
        "text-align:center;padding:40px'>"
        "<h1 style='font-size:3em'>🔮</h1>"
        "<h2>Glyph Drop</h2>"
        "<p style='color:%23999'>You found a secret message!</p>"
        "<p style='font-size:1.3em;margin:20px;padding:20px;"
        "background:%2312121e;border-radius:12px'>"
        "Hello from the subway 🚇</p>"
        "<p style='color:%23666;font-size:.8em'>Get Glyph to leave your own</p>"
        "</body>")


def portal_v2_styled():
    """
    More styled version with gradients and animation hint.
    Target: < 1,200 bytes (scannable at QR v25)
    """
    return ("data:text/html,"
        "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,"
        "initial-scale=1'><style>"
        "*{margin:0;padding:0;box-sizing:border-box}"
        "body{background:%230a0a14;color:%23e0e0e0;font-family:system-ui;"
        "min-height:100vh;display:flex;flex-direction:column;"
        "align-items:center;justify-content:center;padding:24px}"
        ".g{font-size:4em;animation:p 2s infinite}@keyframes p{0%,100%{transform:scale(1)}50%{transform:scale(1.1)}}"
        "h1{font-size:2em;background:linear-gradient(135deg,%2366d9ff,%239966ff);"
        "-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:12px 0}"
        ".msg{background:%2312121e;border:1px solid%23333;border-radius:16px;"
        "padding:24px;margin:20px 0;font-size:1.1em;line-height:1.6;max-width:340px;text-align:center}"
        ".cta{display:inline-block;margin-top:20px;padding:14px 32px;"
        "background:linear-gradient(135deg,%2366d9ff,%239966ff);color:%23000;"
        "font-weight:700;border-radius:30px;text-decoration:none;font-size:1em}"
        ".sub{color:%23666;font-size:.75em;margin-top:16px}"
        "</style></head><body>"
        "<div class='g'>🔮</div>"
        "<h1>Glyph</h1>"
        "<p style='color:%23888'>Someone left this for you</p>"
        "<div class='msg'>Hello from underground! This message was dropped "
        "in the subway with no internet. 🚇✨</div>"
        "<a class='cta' href='https://apps.apple.com/app/glyph/id000000000'>Get Glyph</a>"
        "<p class='sub'>Offline · Encrypted · Vanishing</p>"
        "</body></html>")


def portal_v3_full():
    """
    Full portal experience — pushes QR limits.
    Target: < 2,800 bytes (QR v40, maximum)
    """
    return ("data:text/html,"
        "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,"
        "initial-scale=1'><style>"
        "*{margin:0;padding:0;box-sizing:border-box}"
        "body{background:%230a0a14;color:%23e0e0e0;font-family:system-ui;"
        "min-height:100vh;display:flex;flex-direction:column;"
        "align-items:center;padding:24px;overflow-x:hidden}"
        ".logo{font-size:4em;margin-top:40px;animation:pulse 2s ease infinite}"
        "@keyframes pulse{0%,100%{transform:scale(1);filter:drop-shadow(0 0 8px %2366d9ff44)}"
        "50%{transform:scale(1.08);filter:drop-shadow(0 0 20px %2366d9ff88)}}"
        "h1{font-size:2.2em;background:linear-gradient(135deg,%2366d9ff,%239966ff);"
        "-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:10px 0}"
        ".tag{color:%23888;font-size:.95em;margin-bottom:20px}"
        ".card{background:%2312121e;border:1px solid %2366d9ff33;border-radius:16px;"
        "padding:24px;margin:16px 0;width:100%;max-width:360px}"
        ".card h3{color:%2366d9ff;font-size:1em;margin-bottom:8px}"
        ".card p{color:%23ccc;line-height:1.6;font-size:1.05em}"
        ".from{display:flex;align-items:center;gap:10px;margin-top:16px;"
        "padding-top:12px;border-top:1px solid%23333;font-size:.85em;color:%23888}"
        ".dot{width:8px;height:8px;background:%2366d9ff;border-radius:50%;"
        "animation:blink 1.5s infinite}@keyframes blink{0%,100%{opacity:1}50%{opacity:.3}}"
        ".cta{display:block;text-align:center;margin:24px auto 0;"
        "padding:16px 40px;background:linear-gradient(135deg,%2366d9ff,%239966ff);"
        "color:%23000;font-weight:700;border-radius:30px;text-decoration:none;"
        "font-size:1.05em;max-width:300px;transition:transform .2s}"
        ".cta:active{transform:scale(.97)}"
        ".feat{display:grid;grid-template-columns:1fr 1fr;gap:10px;"
        "margin:20px 0;width:100%;max-width:360px}"
        ".feat div{background:%2312121e;border-radius:12px;padding:14px;text-align:center}"
        ".feat .ic{font-size:1.5em;margin-bottom:4px}"
        ".feat .lb{font-size:.75em;color:%23888}"
        ".foot{color:%23444;font-size:.7em;margin-top:30px;text-align:center}"
        "</style></head><body>"
        "<div class='logo'>🔮</div>"
        "<h1>Glyph</h1>"
        "<p class='tag'>Say it. Show it. Gone.</p>"
        "<div class='card'>"
        "<h3>📩 Mystery Drop</h3>"
        "<p>Someone left this secret message in the subway for you to find. "
        "No internet was used. No servers. Just light.</p>"
        "<div class='from'><div class='dot'></div>Dropped nearby · just now</div>"
        "</div>"
        "<div class='feat'>"
        "<div><div class='ic'>🚇</div><div class='lb'>Works Offline</div></div>"
        "<div><div class='ic'>🔒</div><div class='lb'>Encrypted</div></div>"
        "<div><div class='ic'>💨</div><div class='lb'>Self-Destruct</div></div>"
        "<div><div class='ic'>📷</div><div class='lb'>Send Photos</div></div>"
        "</div>"
        "<a class='cta' href='https://apps.apple.com/app/glyph/id000000000'>"
        "Download Glyph Free</a>"
        "<p class='foot'>No accounts · No tracking · No trace<br>"
        "Scan QR codes to exchange secrets ✨</p>"
        "</body></html>")


def portal_v4_custom_message(message="Hello from underground! 🚇", sender="Anonymous"):
    """
    Template version — the message and sender are variables.
    This is what the actual app would generate.
    Target: < 2,000 bytes
    """
    # URL-encode special chars for data URI
    msg_safe = message.replace("'", "%27").replace('"', "%22").replace('\n', '%0A')
    sndr_safe = sender.replace("'", "%27").replace('"', "%22")
    
    return ("data:text/html,"
        "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,"
        "initial-scale=1'><style>"
        "*{margin:0;padding:0;box-sizing:border-box}"
        "body{background:%230a0a14;color:%23e0e0e0;font-family:system-ui;"
        "min-height:100vh;display:flex;flex-direction:column;"
        "align-items:center;justify-content:center;padding:24px}"
        ".g{font-size:4em;animation:p 2s infinite}@keyframes p{0%,100%{transform:scale(1)}"
        "50%{transform:scale(1.1)}}"
        "h1{font-size:2em;background:linear-gradient(135deg,%2366d9ff,%239966ff);"
        "-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:12px 0}"
        ".msg{background:%2312121e;border:1px solid%2366d9ff33;border-radius:16px;"
        "padding:24px;margin:20px 0;max-width:340px;text-align:center}"
        ".msg p{font-size:1.15em;line-height:1.6;color:%23eee}"
        ".msg .f{font-size:.8em;color:%23888;margin-top:12px;"
        "padding-top:10px;border-top:1px solid%23333}"
        ".cta{display:inline-block;margin-top:16px;padding:14px 32px;"
        "background:linear-gradient(135deg,%2366d9ff,%239966ff);color:%23000;"
        "font-weight:700;border-radius:30px;text-decoration:none}"
        ".s{color:%23555;font-size:.7em;margin-top:16px}"
        "</style></head><body>"
        "<div class='g'>🔮</div>"
        "<h1>Glyph</h1>"
        f"<div class='msg'><p>{msg_safe}</p>"
        f"<div class='f'>From: {sndr_safe} · Dropped nearby</div></div>"
        "<a class='cta' href='https://apps.apple.com/app/glyph/id000000000'>Get Glyph</a>"
        "<p class='s'>Offline · Vanishing · No trace</p>"
        "</body></html>")


# ---------------------------------------------------------------------------
# QR GENERATION
# ---------------------------------------------------------------------------

def qr_to_base64_png(data, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=8):
    qr = qrcode.QRCode(
        version=None,
        error_correction=error_correction,
        box_size=box_size,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    
    return b64, qr.version, len(data.encode('utf-8') if isinstance(data, str) else data)


# ---------------------------------------------------------------------------
# BUILD TEST CASES
# ---------------------------------------------------------------------------

def build_test_cases():
    cases = []
    
    # --- V1: Ultra minimal ---
    p1 = portal_v1_ultra_minimal()
    cases.append({
        "id": "portal-v1",
        "title": "Portal V1 — Ultra Minimal",
        "description": "Bare minimum HTML. Dark background, emoji, message, minimal styling. Should be easy to scan.",
        "category": "portal",
        "raw_data": p1,
        "expect": "iOS opens Safari with a dark-themed page showing the glyph emoji and message. NO internet required — the entire page is in the QR code.",
        "size_note": "",
    })
    
    # --- V2: Styled ---
    p2 = portal_v2_styled()
    cases.append({
        "id": "portal-v2",
        "title": "Portal V2 — Styled",
        "description": "Gradient text, pulsing animation, CTA button, proper layout. More data = denser QR.",
        "category": "portal",
        "raw_data": p2,
        "expect": "Full branded page with animated glyph, gradient title, message card, 'Get Glyph' button. All offline.",
        "size_note": "",
    })
    
    # --- V3: Full experience ---
    p3 = portal_v3_full()
    cases.append({
        "id": "portal-v3",
        "title": "Portal V3 — Full Portal",
        "description": "Maximum experience: feature grid, pulsing dot, card UI, CTA. Pushes QR v40 limits (~2,953 byte cap).",
        "category": "portal",
        "raw_data": p3,
        "expect": "Rich landing page with features grid, animations, and download button. This is near the QR capacity limit.",
        "size_note": "⚠️ This is a VERY dense QR code. May need steady hands and good lighting to scan.",
    })
    
    # --- V4: Custom message template ---
    p4 = portal_v4_custom_message(
        message="You discovered a glyph on the L train! 🚇 Someone was here before you. Download the app to leave your own mark.",
        sender="SubwayGhost"
    )
    cases.append({
        "id": "portal-v4",
        "title": "Portal V4 — Custom Message",
        "description": "Template with sender name and custom message. This is what the app would generate dynamically.",
        "category": "portal",
        "raw_data": p4,
        "expect": "Branded page with the custom message and sender name. This is the 'production' version.",
        "size_note": "",
    })
    
    # --- V5: Short message variant (smaller QR) ---
    p5 = portal_v4_custom_message(
        message="👻 Boo!",
        sender="Ghost"
    )
    cases.append({
        "id": "portal-v5",
        "title": "Portal V5 — Short Message",
        "description": "Very short message = smaller QR = easier to scan. Tests the lower bound.",
        "category": "portal",
        "raw_data": p5,
        "expect": "Same portal UI but with just 'Boo!' — should be significantly easier to scan than V3.",
        "size_note": "",
    })

    # Generate QR codes
    for c in cases:
        try:
            b64_png, version, byte_len = qr_to_base64_png(
                c["raw_data"], 
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=6 if byte_len > 2000 else 8 if byte_len > 1000 else 10
            )
        except:
            # First pass to get byte_len
            byte_len = len(c["raw_data"].encode('utf-8'))
            bs = 4 if byte_len > 2000 else 6 if byte_len > 1000 else 10
            b64_png, version, byte_len = qr_to_base64_png(
                c["raw_data"],
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=bs
            )
        
        c["qr_b64"] = b64_png
        c["qr_version"] = version
        c["byte_len"] = byte_len
        
        # Check if it exceeds QR limit
        if byte_len > 2953:
            c["size_note"] = f"🚨 EXCEEDS QR LIMIT ({byte_len} bytes > 2,953 max). This QR will NOT work."
        elif byte_len > 2500:
            c["size_note"] = c.get("size_note", "") + f" ⚠️ Near limit ({byte_len}/2,953 bytes). Very dense QR."
    
    return cases


# ---------------------------------------------------------------------------
# HTML PAGE
# ---------------------------------------------------------------------------

def build_html(cases):
    cards = ""
    for c in cases:
        raw_display = c["raw_data"][:400].replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
        if len(c["raw_data"]) > 400:
            raw_display += f"\n... ({len(c['raw_data'])} total chars)"
        
        size_badge = ""
        if "🚨" in c.get("size_note",""):
            size_badge = '<span style="background:#ff3333;color:#000;padding:2px 8px;border-radius:8px;font-size:.75em;font-weight:700">TOO LARGE</span>'
        elif "⚠️" in c.get("size_note",""):
            size_badge = '<span style="background:#ff9933;color:#000;padding:2px 8px;border-radius:8px;font-size:.75em;font-weight:700">DENSE</span>'
        
        # Calculate a capacity bar
        pct = min(100, int(c["byte_len"] / 2953 * 100))
        bar_color = "#ff3333" if pct > 95 else "#ff9933" if pct > 80 else "#66d9ff"
        
        cards += f"""
        <div class="card" id="{c['id']}">
            <div class="card-header">
                <span class="badge">PORTAL</span>
                {size_badge}
                <h2>{c['title']}</h2>
            </div>
            <p class="desc">{c['description']}</p>
            
            <div class="qr-container">
                <img src="data:image/png;base64,{c['qr_b64']}" alt="QR" class="qr-img" />
            </div>
            
            <div class="capacity-bar">
                <div class="capacity-label">
                    <span>QR Capacity Used</span>
                    <span><strong>{c['byte_len']}</strong> / 2,953 bytes (v{c['qr_version']})</span>
                </div>
                <div class="bar-track">
                    <div class="bar-fill" style="width:{pct}%;background:{bar_color}"></div>
                </div>
            </div>
            
            {f'<div class="warning">{c["size_note"]}</div>' if c.get("size_note") else ""}
            
            <div class="expect">
                <strong>Expected:</strong> {c['expect']}
            </div>
            
            <details>
                <summary>Raw data URI ({c['byte_len']} bytes)</summary>
                <pre>{raw_display}</pre>
            </details>
        </div>
        """

    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except:
        local_ip = "localhost"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🔮 Glyph Portal QR Lab</title>
<style>
    *{{margin:0;padding:0;box-sizing:border-box}}
    body{{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,BlinkMacSystemFont,system-ui,sans-serif;padding:20px;max-width:1400px;margin:0 auto}}
    h1{{font-size:2.4em;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:4px}}
    .subtitle{{color:#777;font-size:1em;margin-bottom:8px}}
    .concept{{background:#12121e;border:1px solid #333;border-radius:12px;padding:20px;margin:16px 0;line-height:1.7;color:#bbb;font-size:.9em}}
    .concept strong{{color:#66d9ff}}
    .concept code{{background:#1a1a2e;padding:2px 6px;border-radius:4px;color:#ff9933;font-size:.9em}}
    .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(420px,1fr));gap:24px;margin-top:24px}}
    .card{{background:#12121e;border:1px solid #222;border-radius:16px;padding:24px;transition:border-color .2s}}
    .card:hover{{border-color:#66d9ff44}}
    .card-header{{display:flex;align-items:center;gap:10px;margin-bottom:12px;flex-wrap:wrap}}
    .card-header h2{{font-size:1.15em;color:#fff}}
    .badge{{font-size:.65em;font-weight:700;padding:3px 10px;border-radius:20px;color:#000;background:#9966ff}}
    .desc{{color:#999;font-size:.88em;margin-bottom:16px;line-height:1.5}}
    .qr-container{{background:white;border-radius:12px;padding:12px;display:flex;justify-content:center;margin-bottom:16px}}
    .qr-img{{width:340px;height:340px;image-rendering:pixelated}}
    .capacity-bar{{margin-bottom:14px}}
    .capacity-label{{display:flex;justify-content:space-between;font-size:.78em;color:#888;margin-bottom:4px}}
    .bar-track{{height:6px;background:#1a1a2e;border-radius:3px;overflow:hidden}}
    .bar-fill{{height:100%;border-radius:3px;transition:width .3s}}
    .expect{{background:#1a1a2e;border-left:3px solid #9966ff;padding:10px 14px;font-size:.85em;border-radius:0 8px 8px 0;margin-bottom:12px;line-height:1.5}}
    .warning{{background:#ff993320;border:1px solid #ff993344;border-radius:8px;padding:10px 14px;font-size:.85em;margin-bottom:12px;color:#ff9933}}
    details{{font-size:.8em;color:#666}}
    summary{{cursor:pointer;color:#888;font-weight:600}}
    pre{{background:#0d0d18;padding:10px;border-radius:8px;overflow-x:auto;margin-top:8px;font-size:.8em;white-space:pre-wrap;word-break:break-all;color:#aaa}}
    .info{{background:#1a1a2e;border:1px solid #333;border-radius:12px;padding:16px 20px;margin-bottom:16px;font-size:.9em}}
    .info code{{background:#252540;padding:2px 8px;border-radius:4px;color:#66d9ff}}
</style>
</head>
<body>
    <h1>🔮 Glyph Portal QR Lab</h1>
    <p class="subtitle">Can we fit an entire web page inside a QR code?</p>
    
    <div class="concept">
        <strong>The Idea:</strong> Instead of linking to a URL (which needs internet), we embed the
        <strong>entire HTML page</strong> directly inside the QR code using a <code>data:text/html,...</code> URI.
        When iOS scans it, Safari opens and renders the page <strong>with zero internet</strong>.
        <br><br>
        <strong>The Constraint:</strong> A QR code (version 40, max) holds <strong>~2,953 bytes</strong>.
        That's our entire budget for HTML + CSS + content. Every byte counts.
        <br><br>
        <strong>The Trade-off:</strong> Bigger payload = denser QR = harder to scan from a phone screen.
        We're testing where the sweet spot is.
    </div>
    
    <div class="info">
        📱 Point your iPhone camera at each QR code. Safari should open with the portal page — <strong>no internet needed</strong>.
        <br>🌐 Also available at: <code>http://{local_ip}:{PORT}</code>
    </div>
    
    <div class="grid">
        {cards}
    </div>
    
    <div style="text-align:center;padding:40px 0;color:#444;font-size:.8em">
        Glyph Portal QR Lab · {len(cases)} variants · Ctrl+C to stop
    </div>
</body>
</html>"""


# ---------------------------------------------------------------------------
# SERVE
# ---------------------------------------------------------------------------

def main():
    print("🔮 Glyph Portal QR Lab")
    print("=" * 50)
    print("Generating portal QR variants...\n")
    
    cases = build_test_cases()
    
    for c in cases:
        status = "🚨 TOO LARGE" if c["byte_len"] > 2953 else "⚠️  DENSE" if c["byte_len"] > 2500 else "✅ OK"
        print(f"  {status}  {c['title']:35s}  v{c['qr_version']:>2d}  {c['byte_len']:>5d}/2953 bytes")
    
    html = build_html(cases)
    
    out_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(out_dir, "portal_lab.html")
    with open(html_path, "w") as f:
        f.write(html)
    print(f"\n📄 Saved to: {html_path}")
    
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except:
        local_ip = "localhost"
    
    print(f"\n🌐 Serving at:")
    print(f"   http://localhost:{PORT}")
    print(f"   http://{local_ip}:{PORT}")
    print(f"\n📱 Scan the QR codes with your iPhone camera")
    print(f"   Each one should open a self-contained webpage in Safari")
    print(f"   Press Ctrl+C to stop\n")
    
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(html.encode('utf-8'))
        
        def log_message(self, format, *args):
            print(f"  📥 {args[0]}")
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped.")

if __name__ == "__main__":
    main()
