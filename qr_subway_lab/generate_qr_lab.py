#!/usr/bin/env python3
"""
Glyph Subway QR Lab
====================
Generates multiple QR code types and serves them on a local HTML page.
Scan each one with your iPhone to see how iOS handles it natively.

Usage:
    python generate_qr_lab.py

Then open http://localhost:8899 in your browser (or scan from iPhone on same Wi-Fi).
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
from datetime import datetime

PORT = 8899

# ---------------------------------------------------------------------------
# 1. SAMPLE DATA
# ---------------------------------------------------------------------------

SAMPLE_MESSAGE = "You found a Glyph drop! 🔮 This secret message was left for you in the subway. Download Glyph to leave your own."

APP_STORE_URL = "https://apps.apple.com/app/glyph/id000000000"

# A tiny 1x1 red pixel JPEG for testing photo embedding
# (Replace with a real small image to test visual rendering)
TINY_JPEG_B64 = None  # We'll generate a real one below

# ---------------------------------------------------------------------------
# 2. GENERATE A REAL TINY TEST IMAGE
# ---------------------------------------------------------------------------

def make_test_thumbnail(size=48):
    """Create a small test image — a gradient square with a glyph symbol."""
    from PIL import Image, ImageDraw, ImageFont
    
    img = Image.new('RGB', (size, size), color=(30, 0, 60))
    draw = ImageDraw.Draw(img)
    
    # Draw a simple gradient/pattern
    for y in range(size):
        for x in range(size):
            r = int(100 * (x / size))
            g = int(50 * (y / size))
            b = int(180 * ((x + y) / (2 * size))) + 60
            img.putpixel((x, y), (r, g, min(b, 255)))
    
    # Draw a circle in the center
    draw.ellipse([size//4, size//4, size*3//4, size*3//4], 
                 fill=(102, 217, 255), outline=(150, 100, 255))
    
    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=60)
    return base64.b64encode(buf.getvalue()).decode('ascii')


# ---------------------------------------------------------------------------
# 3. QR CODE GENERATORS
# ---------------------------------------------------------------------------

def qr_to_base64_png(data: str, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=10) -> str:
    """Generate a QR code and return it as a base64-encoded PNG data URI."""
    qr = qrcode.QRCode(
        version=None,  # auto-size
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
    
    version = qr.version
    data_len = len(data.encode('utf-8'))
    
    return b64, version, data_len


def generate_vcard_with_photo(name, message, url, photo_b64=None):
    """Generate a vCard 3.0 string with optional embedded JPEG photo."""
    escaped_msg = (message
        .replace("\\", "\\\\")
        .replace(",", "\\,")
        .replace(";", "\\;")
        .replace("\n", "\\n"))
    
    lines = [
        "BEGIN:VCARD",
        "VERSION:3.0",
        f"FN:{name}",
        "ORG:Glyph",
        f"NOTE:{escaped_msg}",
        f"URL:{url}",
    ]
    
    if photo_b64:
        lines.append(f"PHOTO;ENCODING=b;TYPE=JPEG:{photo_b64}")
    
    lines.append("END:VCARD")
    return "\r\n".join(lines)


def generate_vcard_minimal(name, message, url):
    """vCard with no photo — maximum text capacity."""
    return generate_vcard_with_photo(name, message, url, photo_b64=None)


def generate_wifi_qr(ssid, password, security="WPA"):
    """Wi-Fi network credentials QR (standard format)."""
    return f"WIFI:T:{security};S:{ssid};P:{password};;"


def generate_mecard(name, note, url):
    """MECARD format — alternative to vCard, also recognized by iOS."""
    return f"MECARD:N:{name};NOTE:{note};URL:{url};;"


# ---------------------------------------------------------------------------
# 4. BUILD ALL TEST CASES
# ---------------------------------------------------------------------------

def build_test_cases():
    thumb_b64 = make_test_thumbnail(48)
    thumb_b64_big = make_test_thumbnail(64)
    
    cases = []
    
    # --- TEST 1: vCard with photo (48px) ---
    vcard1 = generate_vcard_with_photo(
        name="🔮 Glyph Drop",
        message=SAMPLE_MESSAGE,
        url=APP_STORE_URL,
        photo_b64=thumb_b64
    )
    cases.append({
        "id": "vcard-photo-48",
        "title": "vCard + Photo (48px)",
        "description": "Full vCard with 48×48 JPEG thumbnail embedded. iOS should prompt 'Add Contact?' with the photo visible as the contact picture.",
        "category": "subway",
        "raw_data": vcard1,
        "expect": "Contact prompt with thumbnail, message in Notes, URL in website field",
    })
    
    # --- TEST 2: vCard with bigger photo (64px) ---
    vcard2 = generate_vcard_with_photo(
        name="🔮 Glyph Drop",
        message=SAMPLE_MESSAGE,
        url=APP_STORE_URL,
        photo_b64=thumb_b64_big
    )
    cases.append({
        "id": "vcard-photo-64",
        "title": "vCard + Photo (64px)",
        "description": "Larger 64×64 thumbnail. Tests if the QR is still scannable at this density.",
        "category": "subway",
        "raw_data": vcard2,
        "expect": "Same as above but with slightly larger/clearer photo",
    })
    
    # --- TEST 3: vCard NO photo (max text) ---
    long_msg = SAMPLE_MESSAGE + " Reply with your own Glyph drop — scan QR codes to exchange secret messages, art, and audio. No internet needed. No accounts. No trace. 🔮✨"
    vcard3 = generate_vcard_minimal(
        name="🔮 Glyph Drop",
        message=long_msg,
        url=APP_STORE_URL,
    )
    cases.append({
        "id": "vcard-text-only",
        "title": "vCard Text Only (No Photo)",
        "description": "No photo = more space for message text. Tests maximum text capacity.",
        "category": "subway",
        "raw_data": vcard3,
        "expect": "Contact prompt, long message in Notes, no photo",
    })
    
    # --- TEST 4: Plain URL ---
    cases.append({
        "id": "plain-url",
        "title": "Plain URL",
        "description": "Just the App Store URL. iOS opens it in Safari (or App Store) when scanned.",
        "category": "fallback",
        "raw_data": APP_STORE_URL,
        "expect": "Safari opens / App Store prompt",
    })
    
    # --- TEST 5: Wi-Fi credentials ---
    wifi_data = generate_wifi_qr("GlyphDrop", "glyph2026", "WPA")
    cases.append({
        "id": "wifi-creds",
        "title": "Wi-Fi Credentials",
        "description": "Standard Wi-Fi QR. iOS should prompt 'Join Network GlyphDrop?'. Use this for the hotspot/captive portal scenario.",
        "category": "network",
        "raw_data": wifi_data,
        "expect": "'Join Wi-Fi' prompt in iOS. (Won't actually connect unless you have a hotspot named 'GlyphDrop')",
    })
    
    # --- TEST 6: MECARD format ---
    mecard = generate_mecard(
        name="Glyph Drop",
        note="You found a secret Glyph! Download the app to leave your own.",
        url=APP_STORE_URL
    )
    cases.append({
        "id": "mecard",
        "title": "MECARD Format",
        "description": "MECARD is an older format also recognized by many QR scanners. Tests if iOS handles it differently than vCard.",
        "category": "subway",
        "raw_data": mecard,
        "expect": "May show contact prompt or plain text depending on iOS version",
    })
    
    # --- TEST 7: vCard with custom fields ---
    vcard_custom = generate_vcard_with_photo(
        name="🔮 Subway Mystery",
        message="Someone left this for you on the L train. 🚇 What does it mean?",
        url=APP_STORE_URL,
        photo_b64=thumb_b64
    )
    cases.append({
        "id": "vcard-mystery",
        "title": "vCard 'Mystery Drop'",
        "description": "Different branding — 'Subway Mystery'. Tests how the contact name/vibe changes the iOS experience.",
        "category": "subway",
        "raw_data": vcard_custom,
        "expect": "Contact named 'Subway Mystery' with cryptic message",
    })
    
    # --- TEST 8: Plain text (no encoding) ---
    cases.append({
        "id": "plain-text",
        "title": "Plain Text Message",
        "description": "Raw text in QR. iOS camera shows it as a notification banner. No contact prompt, just text.",
        "category": "fallback",
        "raw_data": "🔮 You found a Glyph! A secret message was left here. Download Glyph from the App Store to decode it.",
        "expect": "iOS shows text in a notification-style banner. Tappable but not very actionable.",
    })
    
    # Generate QR images for all cases
    for case_ in cases:
        # Use low error correction for max capacity on dense ones
        ec = qrcode.constants.ERROR_CORRECT_L if case_["category"] == "subway" else qrcode.constants.ERROR_CORRECT_M
        b64_png, version, byte_len = qr_to_base64_png(case_["raw_data"], error_correction=ec)
        case_["qr_b64"] = b64_png
        case_["qr_version"] = version
        case_["byte_len"] = byte_len
    
    return cases


# ---------------------------------------------------------------------------
# 5. HTML PAGE
# ---------------------------------------------------------------------------

def build_html(cases):
    cards_html = ""
    
    for c in cases:
        badge_color = {
            "subway": "#66d9ff",
            "network": "#9966ff",
            "fallback": "#ff9933",
        }.get(c["category"], "#888")
        
        # Escape raw data for display (truncate if long)
        raw_display = c["raw_data"][:300]
        if len(c["raw_data"]) > 300:
            raw_display += f"\n... ({len(c['raw_data'])} total chars)"
        raw_display = raw_display.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        
        cards_html += f"""
        <div class="card" id="{c['id']}">
            <div class="card-header">
                <span class="badge" style="background:{badge_color}">{c['category'].upper()}</span>
                <h2>{c['title']}</h2>
            </div>
            <p class="desc">{c['description']}</p>
            <div class="qr-container">
                <img src="data:image/png;base64,{c['qr_b64']}" alt="QR Code" class="qr-img" />
            </div>
            <div class="stats">
                <span>QR Version: <strong>{c['qr_version']}</strong></span>
                <span>Payload: <strong>{c['byte_len']} bytes</strong></span>
            </div>
            <div class="expect">
                <strong>Expected iOS behavior:</strong> {c['expect']}
            </div>
            <details>
                <summary>Raw payload</summary>
                <pre>{raw_display}</pre>
            </details>
        </div>
        """
    
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except:
        local_ip = "localhost"
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🔮 Glyph Subway QR Lab</title>
<style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
        background: #0a0a14;
        color: #e0e0e0;
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif;
        padding: 20px;
        max-width: 1400px;
        margin: 0 auto;
    }}
    h1 {{
        font-size: 2.2em;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 8px;
    }}
    .subtitle {{
        color: #777;
        font-size: 1em;
        margin-bottom: 30px;
    }}
    .grid {{
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
        gap: 24px;
    }}
    .card {{
        background: #12121e;
        border: 1px solid #222;
        border-radius: 16px;
        padding: 24px;
        transition: border-color 0.2s;
    }}
    .card:hover {{
        border-color: #66d9ff44;
    }}
    .card-header {{
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 12px;
    }}
    .card-header h2 {{
        font-size: 1.2em;
        color: #fff;
    }}
    .badge {{
        font-size: 0.65em;
        font-weight: 700;
        padding: 3px 10px;
        border-radius: 20px;
        color: #000;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }}
    .desc {{
        color: #999;
        font-size: 0.9em;
        margin-bottom: 16px;
        line-height: 1.5;
    }}
    .qr-container {{
        background: white;
        border-radius: 12px;
        padding: 16px;
        display: flex;
        justify-content: center;
        margin-bottom: 16px;
    }}
    .qr-img {{
        width: 280px;
        height: 280px;
        image-rendering: pixelated;
    }}
    .stats {{
        display: flex;
        gap: 20px;
        font-size: 0.8em;
        color: #888;
        margin-bottom: 12px;
    }}
    .stats strong {{
        color: #66d9ff;
    }}
    .expect {{
        background: #1a1a2e;
        border-left: 3px solid #66d9ff;
        padding: 10px 14px;
        font-size: 0.85em;
        border-radius: 0 8px 8px 0;
        margin-bottom: 12px;
        line-height: 1.5;
    }}
    details {{
        font-size: 0.8em;
        color: #666;
    }}
    summary {{
        cursor: pointer;
        color: #888;
        font-weight: 600;
    }}
    pre {{
        background: #0d0d18;
        padding: 10px;
        border-radius: 8px;
        overflow-x: auto;
        margin-top: 8px;
        font-size: 0.85em;
        white-space: pre-wrap;
        word-break: break-all;
        color: #aaa;
    }}
    .header-info {{
        background: #1a1a2e;
        border: 1px solid #333;
        border-radius: 12px;
        padding: 16px 20px;
        margin-bottom: 24px;
        font-size: 0.9em;
    }}
    .header-info code {{
        background: #252540;
        padding: 2px 8px;
        border-radius: 4px;
        color: #66d9ff;
    }}
    .nav {{
        display: flex;
        gap: 10px;
        margin-bottom: 24px;
        flex-wrap: wrap;
    }}
    .nav a {{
        padding: 8px 16px;
        background: #1a1a2e;
        color: #66d9ff;
        text-decoration: none;
        border-radius: 20px;
        font-size: 0.85em;
        font-weight: 600;
        border: 1px solid #333;
        transition: all 0.2s;
    }}
    .nav a:hover {{
        background: #66d9ff22;
        border-color: #66d9ff44;
    }}
</style>
</head>
<body>
    <h1>🔮 Glyph Subway QR Lab</h1>
    <p class="subtitle">Scan each QR code with your iPhone camera to test how iOS handles it natively.</p>
    
    <div class="header-info">
        📱 <strong>Instructions:</strong> Open your iPhone camera, point it at each QR code on this screen.
        Watch what iOS does — does it show a contact card? A URL banner? A Wi-Fi prompt?
        <br><br>
        🌐 This page is also available at: <code>http://{local_ip}:{PORT}</code>
        <br>
        Generated: <code>{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</code>
    </div>
    
    <div class="nav">
        {"".join(f'<a href="#{c["id"]}">{c["title"]}</a>' for c in cases)}
    </div>
    
    <div class="grid">
        {cards_html}
    </div>
    
    <div style="text-align:center; padding: 40px 0; color:#444; font-size:0.8em;">
        Glyph Subway QR Lab · {len(cases)} test cases · Hit Ctrl+C in terminal to stop server
    </div>
</body>
</html>"""
    
    return html


# ---------------------------------------------------------------------------
# 6. SERVE
# ---------------------------------------------------------------------------

def main():
    print("🔮 Glyph Subway QR Lab")
    print("=" * 50)
    print("Generating QR test cases...")
    
    cases = build_test_cases()
    
    for c in cases:
        print(f"  ✓ {c['title']:30s}  v{c['qr_version']}  {c['byte_len']:>5d} bytes")
    
    html = build_html(cases)
    
    # Also save the HTML to disk for reference
    out_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(out_dir, "qr_lab.html")
    with open(html_path, "w") as f:
        f.write(html)
    print(f"\n📄 Saved to: {html_path}")
    
    # Get local IP
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except:
        local_ip = "localhost"
    
    print(f"\n🌐 Serving at:")
    print(f"   http://localhost:{PORT}")
    print(f"   http://{local_ip}:{PORT}")
    print(f"\n📱 Open on iPhone (same Wi-Fi) to scan QR codes")
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
            print("\n\n🛑 Server stopped.")
            sys.exit(0)


if __name__ == "__main__":
    main()
