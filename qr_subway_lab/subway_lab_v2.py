#!/usr/bin/env python3
"""
Glyph Subway QR Lab — v2 (iOS-Compatible)
===========================================
data:text/html URIs are BLOCKED by iOS Safari from QR scans.

This version tests approaches that ACTUALLY WORK on iOS:

Tier 1 — SUBWAY (zero internet, zero network):
  • vCard QR → iOS prompts "Add Contact?" 
    - Photo = thumbnail of the drop
    - Note = the message
    - URL = App Store link (clickable when online later)
  • Plain text QR → iOS shows notification banner

Tier 2 — SAME NETWORK (Wi-Fi / hotspot):
  • URL QR → points to local HTTP server on sender's phone
    - Full HTML5 portal experience in Safari
    - Works over personal hotspot or same Wi-Fi

Tier 3 — HYBRID (subway sticker scenario):
  • vCard with local URL → contact card + "website" points
    to a future server (printed QR sticker scenario)

This script serves a lab page AND acts as a local "Glyph Drop" 
server simultaneously — so you can test the full network flow too.
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
import json
import threading
from datetime import datetime
from PIL import Image, ImageDraw

PORT = 8899
DROP_PORT = 8900  # Separate port simulates the "phone server"

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

def get_local_ip():
    """Get the actual LAN IP, not just hostname resolution."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        try:
            return socket.gethostbyname(socket.gethostname())
        except:
            return "127.0.0.1"


def make_test_thumbnail(size=48):
    """Create a test thumbnail image — Glyph-branded gradient with orb."""
    img = Image.new('RGB', (size, size), color=(10, 10, 20))
    draw = ImageDraw.Draw(img)
    
    # Dark gradient background
    for y in range(size):
        for x in range(size):
            r = int(20 + 80 * (x / size) * (y / size))
            g = int(10 + 40 * (y / size))
            b = int(40 + 140 * ((x + y) / (2 * size)))
            img.putpixel((x, y), (min(r,255), min(g,255), min(b,255)))
    
    # Cyan orb in center
    cx, cy = size // 2, size // 2
    r = size // 4
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(102, 217, 255))
    # Small highlight
    draw.ellipse([cx-r//2, cy-r//2, cx, cy], fill=(180, 240, 255))
    
    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=50)
    return base64.b64encode(buf.getvalue()).decode('ascii')


def make_larger_thumbnail(size=80):
    """Larger thumbnail for network-served pages."""
    img = Image.new('RGB', (size, size), color=(10, 10, 20))
    draw = ImageDraw.Draw(img)
    
    for y in range(size):
        for x in range(size):
            r = int(15 + 60 * (x / size) * (y / size))
            g = int(8 + 30 * (y / size))
            b = int(30 + 160 * ((x + y) / (2 * size)))
            img.putpixel((x, y), (min(r,255), min(g,255), min(b,255)))
    
    cx, cy = size // 2, size // 2
    r = size // 3
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(102, 217, 255))
    draw.ellipse([cx-r//2, cy-r//2-2, cx+2, cy+2], fill=(180, 240, 255))
    
    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=70)
    return base64.b64encode(buf.getvalue()).decode('ascii')


def qr_to_base64_png(data, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=10):
    """Generate QR code and return as base64 PNG."""
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
    byte_len = len(data.encode('utf-8') if isinstance(data, str) else data)
    
    return b64, qr.version, byte_len


# ---------------------------------------------------------------------------
# VCARD GENERATION (SUBWAY MODE)
# ---------------------------------------------------------------------------

def make_vcard(name, message, url, photo_b64=None, sender=None):
    """Generate vCard 3.0 string."""
    escaped = (message
        .replace("\\", "\\\\")
        .replace(",", "\\,")
        .replace(";", "\\;")
        .replace("\n", "\\n"))
    
    lines = [
        "BEGIN:VCARD",
        "VERSION:3.0",
        f"FN:{name}",
        "ORG:Glyph",
    ]
    
    if sender:
        lines.append(f"TITLE:From {sender}")
    
    lines.append(f"NOTE:{escaped}")
    lines.append(f"URL:{url}")
    
    if photo_b64:
        lines.append(f"PHOTO;ENCODING=b;TYPE=JPEG:{photo_b64}")
    
    lines.append("END:VCARD")
    return "\r\n".join(lines)


# ---------------------------------------------------------------------------
# DROP PAGE HTML (NETWORK MODE — served by local HTTP server)
# ---------------------------------------------------------------------------

def make_drop_page_html(message, sender, image_b64=None):
    """
    The full portal HTML page served when someone connects to the
    sender's local server. This can be as large as we want since
    it's served over HTTP, not stuffed into a QR code.
    """
    
    img_tag = ""
    if image_b64:
        img_tag = f"""
        <div class="img-wrap">
            <img src="data:image/jpeg;base64,{image_b64}" alt="Drop Image" />
        </div>"""
    
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>🔮 Glyph Drop</title>
<style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    
    body {{
        background: #0a0a14;
        color: #e0e0e0;
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif;
        min-height: 100vh;
        min-height: 100dvh;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 24px;
        overflow-x: hidden;
    }}
    
    .glow {{
        position: fixed;
        top: -100px;
        left: 50%;
        transform: translateX(-50%);
        width: 300px;
        height: 300px;
        background: radial-gradient(circle, rgba(102,217,255,0.12) 0%, transparent 70%);
        pointer-events: none;
        z-index: 0;
    }}
    
    .content {{
        position: relative;
        z-index: 1;
        width: 100%;
        max-width: 400px;
        display: flex;
        flex-direction: column;
        align-items: center;
    }}
    
    .logo {{
        font-size: 4em;
        margin-top: 40px;
        animation: pulse 2.5s ease-in-out infinite;
        filter: drop-shadow(0 0 20px rgba(102,217,255,0.4));
    }}
    
    @keyframes pulse {{
        0%, 100% {{ transform: scale(1); filter: drop-shadow(0 0 12px rgba(102,217,255,0.3)); }}
        50% {{ transform: scale(1.08); filter: drop-shadow(0 0 25px rgba(102,217,255,0.6)); }}
    }}
    
    h1 {{
        font-size: 2.2em;
        font-weight: 800;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin: 12px 0 4px;
    }}
    
    .tagline {{
        color: #888;
        font-size: 0.95em;
        margin-bottom: 24px;
    }}
    
    .card {{
        background: #12121e;
        border: 1px solid rgba(102,217,255,0.2);
        border-radius: 20px;
        padding: 28px 24px;
        width: 100%;
        margin-bottom: 20px;
        animation: slideUp 0.6s ease-out;
    }}
    
    @keyframes slideUp {{
        from {{ opacity: 0; transform: translateY(20px); }}
        to {{ opacity: 1; transform: translateY(0); }}
    }}
    
    .card-label {{
        font-size: 0.75em;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 1px;
        color: #66d9ff;
        margin-bottom: 12px;
        display: flex;
        align-items: center;
        gap: 8px;
    }}
    
    .card-label .dot {{
        width: 6px;
        height: 6px;
        background: #66d9ff;
        border-radius: 50%;
        animation: blink 1.5s infinite;
    }}
    
    @keyframes blink {{
        0%, 100% {{ opacity: 1; }}
        50% {{ opacity: 0.3; }}
    }}
    
    .message {{
        font-size: 1.2em;
        line-height: 1.65;
        color: #f0f0f0;
    }}
    
    .from {{
        margin-top: 16px;
        padding-top: 14px;
        border-top: 1px solid #222;
        font-size: 0.85em;
        color: #888;
        display: flex;
        align-items: center;
        gap: 8px;
    }}
    
    .from .avatar {{
        width: 28px;
        height: 28px;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.7em;
        color: #000;
        font-weight: 700;
    }}
    
    .img-wrap {{
        margin: 16px 0;
        border-radius: 14px;
        overflow: hidden;
        border: 1px solid #222;
    }}
    
    .img-wrap img {{
        width: 100%;
        display: block;
    }}
    
    .features {{
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
        width: 100%;
        margin-bottom: 20px;
    }}
    
    .feat {{
        background: #12121e;
        border: 1px solid #1a1a2e;
        border-radius: 14px;
        padding: 16px;
        text-align: center;
        animation: slideUp 0.6s ease-out;
    }}
    
    .feat .icon {{ font-size: 1.6em; margin-bottom: 6px; }}
    .feat .label {{ font-size: 0.75em; color: #888; font-weight: 600; }}
    
    .cta {{
        display: block;
        width: 100%;
        padding: 18px;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        color: #000;
        font-weight: 800;
        font-size: 1.1em;
        border: none;
        border-radius: 30px;
        text-align: center;
        text-decoration: none;
        margin-bottom: 12px;
        transition: transform 0.15s, box-shadow 0.15s;
        box-shadow: 0 4px 20px rgba(102,217,255,0.3);
    }}
    
    .cta:active {{
        transform: scale(0.97);
    }}
    
    .secondary {{
        color: #666;
        font-size: 0.78em;
        text-align: center;
        line-height: 1.5;
    }}
    
    .footer {{
        margin-top: 30px;
        padding-top: 20px;
        border-top: 1px solid #1a1a2e;
        text-align: center;
        color: #333;
        font-size: 0.7em;
    }}
</style>
</head>
<body>
    <div class="glow"></div>
    
    <div class="content">
        <div class="logo">🔮</div>
        <h1>Glyph</h1>
        <p class="tagline">Say it. Show it. Gone.</p>
        
        <div class="card">
            <div class="card-label">
                <div class="dot"></div>
                Mystery Drop
            </div>
            {img_tag}
            <p class="message">{message}</p>
            <div class="from">
                <div class="avatar">{sender[0].upper() if sender else "?"}</div>
                <span>From <strong>{sender}</strong> · Dropped nearby · Just now</span>
            </div>
        </div>
        
        <div class="features">
            <div class="feat"><div class="icon">🚇</div><div class="label">Works Offline</div></div>
            <div class="feat"><div class="icon">🔒</div><div class="label">No Servers</div></div>
            <div class="feat"><div class="icon">💨</div><div class="label">Self-Destruct</div></div>
            <div class="feat"><div class="icon">📷</div><div class="label">Send Photos</div></div>
        </div>
        
        <a class="cta" href="https://apps.apple.com/app/glyph/id000000000">
            Download Glyph — It's Free
        </a>
        
        <p class="secondary">
            Leave your own drops for strangers to find.<br>
            No accounts · No tracking · No trace
        </p>
        
        <div class="footer">
            Glyph · Offline Vanishing Messages<br>
            This page was served directly from another phone nearby.<br>
            No internet was used. ✨
        </div>
    </div>
</body>
</html>"""


# ---------------------------------------------------------------------------
# BUILD ALL TEST CASES
# ---------------------------------------------------------------------------

def build_test_cases():
    local_ip = get_local_ip()
    thumb_48 = make_test_thumbnail(48)
    thumb_32 = make_test_thumbnail(32)
    
    cases = []
    
    # =====================================================================
    # TIER 1: SUBWAY MODE (no network)
    # =====================================================================
    
    # --- 1A: vCard with 48px photo ---
    vc1 = make_vcard(
        name="🔮 Glyph Drop",
        message="You found a secret drop in the subway! Someone left this message with no internet. Download Glyph to leave your own. 🚇",
        url="https://apps.apple.com/app/glyph/id000000000",
        photo_b64=thumb_48,
        sender="SubwayGhost"
    )
    cases.append({
        "id": "vcard-48",
        "title": "vCard + Photo (48px)",
        "tier": "subway",
        "raw_data": vc1,
        "expect": "iOS: 'Add Contact?' prompt. Contact has thumbnail photo, message in Notes, App Store link in URL field.",
        "notes": "This is the primary subway delivery method. The contact lives in their address book as a trojan horse.",
    })
    
    # --- 1B: vCard with 32px photo (smaller = easier scan) ---
    vc2 = make_vcard(
        name="🔮 Glyph",
        message="Someone dropped a secret here. 🔮✨ Get the app to decode more.",
        url="https://apps.apple.com/app/glyph/id000000000",
        photo_b64=thumb_32,
    )
    cases.append({
        "id": "vcard-32",
        "title": "vCard + Photo (32px, Short Msg)",
        "tier": "subway",
        "raw_data": vc2,
        "expect": "Same contact prompt but with smaller photo and shorter message. Should scan faster due to lower QR density.",
        "notes": "Tests the sweet spot — enough branding to be intriguing, small enough to scan reliably.",
    })
    
    # --- 1C: vCard NO photo (maximum text) ---
    vc3 = make_vcard(
        name="🔮 Glyph Drop",
        message="You found a secret Glyph! This message was left for you in the subway — no internet was used. "
                "Glyph lets you send self-destructing messages via QR codes. Photos, text, audio — all offline. "
                "Download the app to leave your own drops for strangers to find. The underground network awaits. 🚇🔮✨",
        url="https://apps.apple.com/app/glyph/id000000000",
        sender="Ghost"
    )
    cases.append({
        "id": "vcard-noimg",
        "title": "vCard Text Only (Long Message)",
        "tier": "subway",
        "raw_data": vc3,
        "expect": "Contact with no photo but very long Note field. Tests max text capacity of subway drops.",
        "notes": "No photo = ~1KB saved. Can fit a much longer message or story.",
    })
    
    # --- 1D: vCard minimal (easiest possible scan) ---
    vc4 = make_vcard(
        name="🔮 Glyph",
        message="Secret drop! Get Glyph to decode.",
        url="https://apps.apple.com/app/glyph/id000000000",
    )
    cases.append({
        "id": "vcard-mini",
        "title": "vCard Minimal (Tiniest QR)",
        "tier": "subway",
        "raw_data": vc4,
        "expect": "Tiny QR code. Very fast to scan. Minimal info but enough to plant the seed.",
        "notes": "Good for printed stickers where scanning conditions are bad (subway lighting, motion).",
    })
    
    # =====================================================================
    # TIER 2: NETWORK MODE (same Wi-Fi / hotspot)
    # =====================================================================
    
    # --- 2A: URL to local drop server ---
    drop_url = f"http://{local_ip}:{DROP_PORT}/drop"
    cases.append({
        "id": "url-local",
        "title": "Local Server URL",
        "tier": "network",
        "raw_data": drop_url,
        "expect": f"iOS shows URL banner: '{local_ip}:{DROP_PORT}'. Tap → Safari opens → full Glyph portal page. (Both devices must be on same Wi-Fi!)",
        "notes": f"This is the network-mode experience. Full HTML5 portal served from this machine on port {DROP_PORT}.",
    })
    
    # --- 2B: Wi-Fi QR + URL combo (two-step) ---
    wifi_data = f"WIFI:T:WPA;S:GlyphDrop;P:glyph2026;;"
    cases.append({
        "id": "wifi",
        "title": "Wi-Fi Credentials",
        "tier": "network",
        "raw_data": wifi_data,
        "expect": "iOS prompts: 'Join Wi-Fi network GlyphDrop?' — This is step 1 of the hotspot flow. After joining, scan the URL QR.",
        "notes": "In the real app, the sender creates a personal hotspot. This QR gets the stranger onto it. Then they scan a second QR (the URL one) or a captive portal pops up.",
    })
    
    # =====================================================================
    # TIER 3: HYBRID IDEAS
    # =====================================================================
    
    # --- 3A: vCard with local URL as website ---
    vc_hybrid = make_vcard(
        name="🔮 Glyph Drop",
        message="You found a mystery drop! Open the website link below to see the full message. If you're offline, download Glyph later from the App Store.",
        url=f"http://{local_ip}:{DROP_PORT}/drop",
        photo_b64=thumb_32,
        sender="Ghost"
    )
    cases.append({
        "id": "vcard-hybrid",
        "title": "vCard + Local URL (Hybrid)",
        "tier": "hybrid",
        "raw_data": vc_hybrid,
        "expect": "Contact card where the 'website' field points to the local drop server. If on the same network, tapping the URL opens the full portal.",
        "notes": "Best of both worlds: works offline as a contact, AND if they happen to be on the same network, they can tap the URL for the full experience.",
    })
    
    # --- 3B: Text with embedded instructions ---
    cases.append({
        "id": "text-instruct",
        "title": "Plain Text (Fallback)",
        "tier": "hybrid",
        "raw_data": "🔮 GLYPH DROP 🔮\n\nSomeone left a secret message here!\n\n💬 \"Hello from the underground.\"\n\n📲 Download \"Glyph\" from the App Store to leave your own drops.\n\nNo internet. No accounts. No trace.\nJust QR codes and secrets. ✨",
        "expect": "iOS camera shows a text notification banner. User can copy it. Not as smooth as vCard but universally works.",
        "notes": "Ultimate fallback. Works on every phone, every OS. Just text.",
    })
    
    # Generate QR codes
    for c in cases:
        byte_len = len(c["raw_data"].encode('utf-8'))
        ec = qrcode.constants.ERROR_CORRECT_L if byte_len > 500 else qrcode.constants.ERROR_CORRECT_M
        bs = 6 if byte_len > 1200 else 8 if byte_len > 500 else 10
        b64_png, version, byte_len = qr_to_base64_png(c["raw_data"], error_correction=ec, box_size=bs)
        c["qr_b64"] = b64_png
        c["qr_version"] = version
        c["byte_len"] = byte_len
    
    return cases


# ---------------------------------------------------------------------------
# LAB HTML PAGE
# ---------------------------------------------------------------------------

def build_lab_html(cases):
    tier_colors = {
        "subway": ("#66d9ff", "🚇 SUBWAY"),
        "network": ("#9966ff", "📡 NETWORK"),
        "hybrid": ("#ff9933", "🔀 HYBRID"),
    }
    
    cards = ""
    for c in cases:
        color, badge_text = tier_colors.get(c["tier"], ("#888", "OTHER"))
        
        raw_display = c["raw_data"][:500].replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
        if len(c["raw_data"]) > 500:
            raw_display += f"\n... ({len(c['raw_data'])} total chars)"
        
        pct = min(100, int(c["byte_len"] / 2953 * 100))
        bar_color = "#ff3333" if pct > 95 else "#ff9933" if pct > 75 else "#66d9ff"
        
        cards += f"""
        <div class="card" id="{c['id']}">
            <div class="card-header">
                <span class="badge" style="background:{color}">{badge_text}</span>
                <h2>{c['title']}</h2>
            </div>
            <p class="desc">{c['notes']}</p>
            
            <div class="qr-container">
                <img src="data:image/png;base64,{c['qr_b64']}" alt="QR" class="qr-img" />
            </div>
            
            <div class="cap">
                <div class="cap-row">
                    <span>QR v{c['qr_version']}</span>
                    <span><strong>{c['byte_len']}</strong> bytes</span>
                    <span>{pct}% of QR max</span>
                </div>
                <div class="bar-track"><div class="bar-fill" style="width:{pct}%;background:{bar_color}"></div></div>
            </div>
            
            <div class="expect">
                <strong>📱 When scanned:</strong> {c['expect']}
            </div>
            
            <details>
                <summary>Raw payload</summary>
                <pre>{raw_display}</pre>
            </details>
        </div>"""
    
    local_ip = get_local_ip()
    
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🔮 Glyph Subway Lab v2</title>
<style>
    *{{margin:0;padding:0;box-sizing:border-box}}
    body{{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;padding:20px;max-width:1400px;margin:0 auto}}
    h1{{font-size:2.2em;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:4px}}
    .sub{{color:#777;margin-bottom:16px}}
    .finding{{background:#1a0a0a;border:1px solid #ff333344;border-radius:12px;padding:16px 20px;margin-bottom:16px;font-size:.9em;line-height:1.6}}
    .finding strong{{color:#ff6666}}
    .finding code{{background:#2a1a1a;padding:2px 6px;border-radius:4px;color:#ff9966}}
    .tiers{{display:flex;gap:10px;margin-bottom:20px;flex-wrap:wrap}}
    .tier{{background:#12121e;border:1px solid #333;border-radius:10px;padding:12px 16px;flex:1;min-width:200px}}
    .tier h3{{font-size:1em;margin-bottom:4px}}
    .tier p{{font-size:.8em;color:#888;line-height:1.4}}
    .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(400px,1fr));gap:20px;margin-top:20px}}
    .card{{background:#12121e;border:1px solid #222;border-radius:16px;padding:22px;transition:border-color .2s}}
    .card:hover{{border-color:#66d9ff33}}
    .card-header{{display:flex;align-items:center;gap:10px;margin-bottom:10px;flex-wrap:wrap}}
    .card-header h2{{font-size:1.1em;color:#fff}}
    .badge{{font-size:.6em;font-weight:700;padding:3px 10px;border-radius:16px;color:#000}}
    .desc{{color:#888;font-size:.85em;margin-bottom:14px;line-height:1.5}}
    .qr-container{{background:#fff;border-radius:12px;padding:12px;display:flex;justify-content:center;margin-bottom:14px}}
    .qr-img{{max-width:320px;width:100%;height:auto;image-rendering:pixelated}}
    .cap{{margin-bottom:12px}}
    .cap-row{{display:flex;justify-content:space-between;font-size:.75em;color:#888;margin-bottom:4px}}
    .bar-track{{height:5px;background:#1a1a2e;border-radius:3px;overflow:hidden}}
    .bar-fill{{height:100%;border-radius:3px}}
    .expect{{background:#1a1a2e;border-left:3px solid #9966ff;padding:10px 14px;font-size:.84em;border-radius:0 8px 8px 0;margin-bottom:12px;line-height:1.5}}
    details{{font-size:.78em;color:#666}}
    summary{{cursor:pointer;color:#888;font-weight:600}}
    pre{{background:#0d0d18;padding:10px;border-radius:8px;overflow-x:auto;margin-top:8px;white-space:pre-wrap;word-break:break-all;color:#aaa;font-size:.85em}}
    .info{{background:#1a1a2e;border:1px solid #333;border-radius:12px;padding:14px 18px;margin-bottom:16px;font-size:.88em}}
    .info code{{background:#252540;padding:2px 8px;border-radius:4px;color:#66d9ff}}
    .nav{{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}}
    .nav a{{padding:6px 14px;background:#1a1a2e;color:#66d9ff;text-decoration:none;border-radius:16px;font-size:.8em;font-weight:600;border:1px solid #333}}
    .nav a:hover{{background:#66d9ff11;border-color:#66d9ff44}}
</style>
</head>
<body>
    <h1>🔮 Glyph Subway Lab v2</h1>
    <p class="sub">iOS-compatible QR experiments — scan with your iPhone camera</p>
    
    <div class="finding">
        <strong>📋 Finding from v1:</strong> iOS Safari <strong>blocks</strong> <code>data:text/html</code> URIs from QR scans.
        Self-contained HTML pages cannot be delivered via QR code on iOS.
        <br><br>
        <strong>New strategy:</strong> Use <strong>vCards</strong> for subway mode (trojan horse contact card) and
        <strong>local HTTP server URLs</strong> for network mode (full portal experience).
    </div>
    
    <div class="tiers">
        <div class="tier">
            <h3 style="color:#66d9ff">🚇 Tier 1: Subway</h3>
            <p>Zero internet. vCard QR code saves a contact with your message, photo, and App Store link.</p>
        </div>
        <div class="tier">
            <h3 style="color:#9966ff">📡 Tier 2: Network</h3>
            <p>Same Wi-Fi / hotspot. URL QR opens full branded portal in Safari, served from sender's phone.</p>
        </div>
        <div class="tier">
            <h3 style="color:#ff9933">🔀 Tier 3: Hybrid</h3>
            <p>vCard with local URL. Works offline AND can open portal if on same network.</p>
        </div>
    </div>
    
    <div class="info">
        📱 <strong>Lab page:</strong> <code>http://{local_ip}:{PORT}</code>
        <br>🌐 <strong>Drop server:</strong> <code>http://{local_ip}:{DROP_PORT}/drop</code> — scan the "Local Server URL" QR to test
    </div>
    
    <div class="nav">
        {"".join(f'<a href="#{c["id"]}">{c["title"]}</a>' for c in cases)}
    </div>
    
    <div class="grid">
        {cards}
    </div>
    
    <div style="text-align:center;padding:40px 0;color:#333;font-size:.75em">
        Glyph Subway Lab v2 · {len(cases)} test cases · Ctrl+C to stop
    </div>
</body>
</html>"""


# ---------------------------------------------------------------------------
# SERVERS
# ---------------------------------------------------------------------------

def main():
    print("🔮 Glyph Subway Lab v2 (iOS-Compatible)")
    print("=" * 50)
    
    local_ip = get_local_ip()
    
    print(f"📡 Local IP: {local_ip}")
    print(f"\nGenerating test cases...\n")
    
    cases = build_test_cases()
    
    for c in cases:
        tier_icon = {"subway": "🚇", "network": "📡", "hybrid": "🔀"}.get(c["tier"], "?")
        print(f"  {tier_icon} {c['title']:40s}  v{c['qr_version']:>2d}  {c['byte_len']:>5d} bytes")
    
    lab_html = build_lab_html(cases)
    drop_html = make_drop_page_html(
        message="You discovered a Glyph drop! 🔮 Someone nearby left this message using nothing but light and pixels. No internet. No servers. Just a QR code on a phone screen in the subway. Download Glyph to leave your own secrets in the wild.",
        sender="SubwayGhost",
        image_b64=make_larger_thumbnail(120)
    )
    
    # Save files
    out_dir = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(out_dir, "lab_v2.html"), "w") as f:
        f.write(lab_html)
    with open(os.path.join(out_dir, "drop_page.html"), "w") as f:
        f.write(drop_html)
    print(f"\n📄 Saved lab_v2.html and drop_page.html")
    
    # --- Start Drop Server (port 8900) ---
    class DropHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            # Allow cross-origin for captive portal scenarios
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(drop_html.encode('utf-8'))
        
        def log_message(self, format, *args):
            print(f"  🔮 DROP SERVER: {args[0]}")
    
    drop_server = socketserver.TCPServer(("", DROP_PORT), DropHandler)
    drop_thread = threading.Thread(target=drop_server.serve_forever, daemon=True)
    drop_thread.start()
    print(f"\n🔮 Drop server running at: http://{local_ip}:{DROP_PORT}/drop")
    
    # --- Start Lab Server (port 8899) ---
    class LabHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(lab_html.encode('utf-8'))
        
        def log_message(self, format, *args):
            print(f"  📥 LAB: {args[0]}")
    
    print(f"📋 Lab page running at: http://{local_ip}:{PORT}")
    print(f"\n{'=' * 50}")
    print(f"📱 WHAT TO TEST:")
    print(f"  1. Scan vCard QRs → Does iOS show 'Add Contact'?")
    print(f"  2. Scan Local URL QR → Does Safari open the portal?")
    print(f"  3. Scan Wi-Fi QR → Does iOS prompt to join?")
    print(f"  4. Check contact Notes field for message text")
    print(f"  5. Check contact photo thumbnail")
    print(f"{'=' * 50}")
    print(f"\nPress Ctrl+C to stop both servers\n")
    
    with socketserver.TCPServer(("", PORT), LabHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            drop_server.shutdown()
            print("\n🛑 Both servers stopped.")

if __name__ == "__main__":
    main()
