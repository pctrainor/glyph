#!/usr/bin/env python3
"""
Glyph Web Experience QR Lab
==============================
Generates web bundle QR code sequences and serves them as
cycling GIFs / auto-playing frames on a local HTML page.

This mirrors the Swift encoding pipeline:
  HTML → GlyphWebBundle JSON → gzip → base64 → GLYW: prefix
  → chunk into GLYC: frames → generate QR images per frame

Usage:
    python generate_web_lab.py

Then open http://localhost:8899 to see the generated experiences.
Each card shows the cycling QR frames, compression stats, and a
live preview of the HTML that would render in the app.
"""

import qrcode
import qrcode.constants
import base64
import io
import json
import zlib
import http.server
import socketserver
import socket
import os
import sys
import math
from datetime import datetime

PORT = 8899
MAX_CHUNK_BYTES = 800  # Matches GlyphChunk.maxChunkBytes in Swift


# ---------------------------------------------------------------------------
# 1. ENCODING PIPELINE (mirrors Swift GlyphWebBundle + GlyphChunkSplitter)
# ---------------------------------------------------------------------------

def gzip_compress(data: bytes) -> bytes:
    """Compress using raw deflate (matches Apple's COMPRESSION_ZLIB / compression_encode_buffer)."""
    c = zlib.compressobj(9, zlib.DEFLATED, -15)  # -15 = raw deflate, no zlib/gzip header
    return c.compress(data) + c.flush()


def gzip_decompress(data: bytes) -> bytes:
    """Decompress raw deflate data."""
    return zlib.decompress(data, -15)  # -15 = raw deflate


def encode_web_bundle(title: str, html: str, template_type: str = None) -> str:
    """
    Encode a web bundle the same way Swift does:
    JSON → gzip → base64 → GLYW: prefix
    """
    bundle = {
        "title": title,
        "html": html,
        "templateType": template_type,
        "createdAt": datetime.now().timestamp()
    }
    json_bytes = json.dumps(bundle, separators=(',', ':')).encode('utf-8')
    compressed = gzip_compress(json_bytes)
    b64 = base64.b64encode(compressed).decode('ascii')
    return f"GLYW:{b64}", len(json_bytes), len(compressed)


def chunk_payload(payload_string: str, session_id: str = "WEB00001") -> list:
    """
    Split a GLYW: payload into GLYC: chunks, matching Swift's GlyphChunkSplitter.
    
    The Swift splitter does:
    1. payload_string (GLYW:...) → UTF-8 Data → base64 → split into slices
    2. Each slice → GlyphChunk JSON → base64 → GLYC: prefix
    """
    # Step 1: base64 the raw payload bytes
    payload_bytes = payload_string.encode('utf-8')
    payload_b64 = base64.b64encode(payload_bytes).decode('ascii')
    
    # Step 2: split into slices
    slices = []
    for i in range(0, len(payload_b64), MAX_CHUNK_BYTES):
        slices.append(payload_b64[i:i + MAX_CHUNK_BYTES])
    
    total = len(slices)
    chunks = []
    
    for i, slice_data in enumerate(slices):
        chunk = {
            "sessionId": session_id,
            "index": i,
            "total": total,
            "data": slice_data
        }
        chunk_json = json.dumps(chunk, separators=(',', ':')).encode('utf-8')
        chunk_b64 = base64.b64encode(chunk_json).decode('ascii')
        chunk_string = f"GLYC:{chunk_b64}"
        chunks.append(chunk_string)
    
    return chunks


def qr_to_base64_png(data: str, box_size=6) -> tuple:
    """Generate a QR code PNG as base64, returns (b64, version, byte_len)."""
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=box_size,
        border=2,
    )
    qr.add_data(data)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    b64 = base64.b64encode(buf.getvalue()).decode('ascii')
    
    return b64, qr.version, len(data.encode('utf-8'))


# ---------------------------------------------------------------------------
# 2. SAMPLE WEB EXPERIENCES
# ---------------------------------------------------------------------------

def trivia_html():
    """A complete trivia quiz — matches WebTemplateGenerator.generateTrivia()."""
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Subway Trivia</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;display:flex;flex-direction:column;align-items:center;
padding:24px;-webkit-user-select:none;user-select:none}
.hdr{text-align:center;margin-bottom:24px}
.hdr h1{font-size:2em;background:linear-gradient(135deg,#66d9ff,#9966ff);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#888;font-size:.9em;margin-top:4px}
.prog{display:flex;gap:4px;margin:16px 0;width:100%;max-width:360px}
.prog .dot{flex:1;height:4px;border-radius:2px;background:#1a1a2e;transition:background .3s}
.prog .dot.done{background:#66d9ff}.prog .dot.cur{background:#9966ff}
.card{background:#12121e;border:1px solid #222;border-radius:20px;padding:28px 24px;
width:100%;max-width:360px;animation:slideIn .4s ease}
@keyframes slideIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
.q{font-size:1.2em;font-weight:600;line-height:1.5;margin-bottom:20px;color:#fff}
.qn{font-size:.75em;color:#66d9ff;font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px}
.opts{display:flex;flex-direction:column;gap:10px}
.opt{padding:14px 18px;background:#1a1a2e;border:1px solid #333;border-radius:14px;
font-size:1em;cursor:pointer;transition:all .2s;text-align:left;color:#e0e0e0}
.opt:active{transform:scale(.98)}
.opt.correct{background:#66d9ff22;border-color:#66d9ff;color:#66d9ff}
.opt.wrong{background:#ff333322;border-color:#ff3333;color:#ff3333}
.opt.dim{opacity:.4;pointer-events:none}
.result{text-align:center;animation:slideIn .5s ease}
.score{font-size:4em;font-weight:800;background:linear-gradient(135deg,#66d9ff,#9966ff);
-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:20px 0}
.msg{font-size:1.2em;color:#ccc;margin-bottom:8px}
.sub{color:#666;font-size:.85em}
.btn{display:inline-block;margin-top:24px;padding:14px 36px;
background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:700;
border:none;border-radius:30px;font-size:1em;cursor:pointer}
.foot{color:#333;font-size:.7em;margin-top:auto;padding-top:24px;text-align:center}
</style>
</head>
<body>
<div class="hdr"><h1>🚇 Subway Trivia</h1><p>Delivered via Glyph · No internet</p></div>
<div class="prog" id="prog"></div>
<div id="stage"></div>
<div class="foot">🔮 Glyph · Offline Experiences</div>
<script>
const Q=[
{q:"What year did the NYC subway open?",a:["1894","1904","1914","1924"],c:1},
{q:"Which is the longest subway line?",a:["A train","7 train","L train","G train"],c:0},
{q:"How many stations are in the NYC subway?",a:["372","422","472","512"],c:2},
{q:"What color is the 4/5/6 line?",a:["Blue","Orange","Red","Green"],c:3},
{q:"Which borough has no subway?",a:["Queens","Bronx","Staten Island","Brooklyn"],c:2}
];
let cur=0,sc=0,ans=false;
function init(){
let p=document.getElementById('prog');
p.innerHTML=Q.map((_,i)=>'<div class="dot" id="d'+i+'"></div>').join('');
show();}
function show(){
if(cur>=Q.length){finish();return;}
ans=false;
document.querySelectorAll('.dot').forEach((d,i)=>{
d.className='dot'+(i<cur?' done':i===cur?' cur':'');});
let q=Q[cur];
let h='<div class="card"><div class="qn">Question '+(cur+1)+' of '+Q.length+'</div>';
h+='<div class="q">'+q.q+'</div><div class="opts">';
q.a.forEach((a,i)=>{h+='<div class="opt" onclick="pick('+i+',this)" id="o'+i+'">'+a+'</div>';});
h+='</div></div>';
document.getElementById('stage').innerHTML=h;}
function pick(i,el){
if(ans)return;ans=true;
let q=Q[cur];
if(i===q.c){sc++;el.classList.add('correct');}
else{el.classList.add('wrong');document.getElementById('o'+q.c).classList.add('correct');}
document.querySelectorAll('.opt').forEach((o,j)=>{if(j!==i&&j!==q.c)o.classList.add('dim');});
setTimeout(()=>{cur++;show();},1200);}
function finish(){
let pct=Math.round(sc/Q.length*100);
let m=pct===100?'Perfect! 🎉':pct>=70?'Nice work! 🔥':pct>=40?'Not bad! 💪':'Keep trying! 😅';
let h='<div class="result"><div class="score">'+sc+'/'+Q.length+'</div>';
h+='<div class="msg">'+m+'</div><div class="sub">'+pct+'% correct</div>';
h+='<button class="btn" onclick="cur=0;sc=0;show();">Play Again</button></div>';
document.getElementById('stage').innerHTML=h;
document.querySelectorAll('.dot').forEach(d=>d.className='dot done');}
init();
</script>
</body>
</html>"""


def article_html():
    """A styled article/zine page."""
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Underground Signals</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#d0d0d0;font-family:Georgia,'Times New Roman',serif;
padding:32px 24px;max-width:480px;margin:0 auto;line-height:1.8}
.header{text-align:center;margin-bottom:36px;padding-bottom:24px;border-bottom:1px solid #222}
h1{font-size:1.8em;color:#fff;font-family:-apple-system,system-ui,sans-serif;
font-weight:800;line-height:1.3;margin-bottom:8px}
.subtitle{color:#888;font-size:1em;font-style:italic;margin-bottom:8px}
.author{color:#66d9ff;font-size:.85em;font-family:-apple-system,system-ui,sans-serif;font-weight:600}
.badge{display:inline-block;margin-top:12px;padding:4px 12px;background:#12121e;
border:1px solid #333;border-radius:20px;font-size:.7em;color:#888;
font-family:-apple-system,system-ui,sans-serif}
h2{font-size:1.3em;color:#fff;font-family:-apple-system,system-ui,sans-serif;
font-weight:700;margin:32px 0 12px;padding-top:16px;border-top:1px solid #1a1a2e}
p{margin-bottom:16px;font-size:1.05em}
p:first-of-type::first-letter{float:left;font-size:3.2em;line-height:1;padding-right:8px;
color:#66d9ff;font-weight:700;font-family:-apple-system,system-ui,sans-serif}
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #222;
color:#444;font-size:.75em;font-family:-apple-system,system-ui,sans-serif}
.footer .glyph{color:#66d9ff}
</style>
</head>
<body>
<div class="header">
<h1>Underground Signals</h1>
<p class="subtitle">The hidden language of subway QR codes</p>
<div class="author">by Ghost Writer</div>
<div class="badge">📖 Delivered via Glyph · No internet</div>
</div>
<article>
<p>They started appearing in January. Small, unassuming QR codes stuck to the tile walls of subway stations. Not advertisements. Not MTA notices. Something else entirely.</p>

<p>The first one was spotted at the Bedford Avenue L station. A commuter, phone already in hand, aimed their camera at the code. What loaded wasn't a website. It was a message: "The underground remembers what the surface forgets."</p>

<h2>A New Kind of Communication</h2>

<p>Unlike traditional graffiti, these messages left no physical mark. They existed only in the space between the code and the camera — a pocket dimension of light and data. And they disappeared. Some lasted hours. Others, minutes.</p>

<p>The technology behind it was surprisingly simple. No servers, no internet connection, no accounts. Just pure, offline data transfer through patterns of black and white squares. The entire message — text, images, even interactive experiences — encoded directly into the QR code itself.</p>

<h2>The Ghost Network</h2>

<p>Word spread the way it always does underground: slowly, then all at once. Within weeks, codes appeared at stations across the city. Each one a tiny portal to someone else's thoughts, left for strangers to find.</p>

<p>No one knows who started it. And maybe that's the point.</p>
</article>
<div class="footer">
<span class="glyph">🔮 Glyph</span><br>
This article was transmitted via QR codes.<br>No servers. No internet. Just light.
</div>
</body>
</html>"""


def art_html():
    """Interactive particle art canvas."""
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Art</title>
<style>
*{margin:0;padding:0}
body{background:#0a0a14;overflow:hidden;touch-action:none;-webkit-user-select:none}
canvas{display:block;width:100vw;height:100vh}
.ui{position:fixed;top:0;left:0;right:0;padding:16px 20px;display:flex;justify-content:space-between;
align-items:center;z-index:10;background:linear-gradient(#0a0a14cc,transparent)}
.ui h1{font-size:1em;color:#fff;font-family:-apple-system,system-ui,sans-serif;font-weight:700}
.ui p{color:#66d9ff88;font-size:.7em;font-family:-apple-system,system-ui,sans-serif}
.hint{position:fixed;bottom:40px;left:0;right:0;text-align:center;color:#ffffff44;
font-size:.85em;font-family:-apple-system,system-ui,sans-serif;pointer-events:none;transition:opacity 1s}
</style>
</head>
<body>
<div class="ui"><div><h1>Subway Canvas</h1><p>🔮 Glyph Art · Touch to create</p></div></div>
<canvas id="c"></canvas>
<div class="hint" id="hint">Touch anywhere to begin ✨</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,pts=[],touched=false;
function resize(){W=c.width=innerWidth*2;H=c.height=innerHeight*2;
c.style.width=innerWidth+'px';c.style.height=innerHeight+'px';x.scale(2,2);}
resize();addEventListener('resize',resize);
const colors=['#66d9ff','#9966ff','#ff66d9','#66ffaa','#ffaa66'];
function addPt(px,py){
if(!touched){touched=true;document.getElementById('hint').style.opacity=0;}
for(let i=0;i<3;i++){
pts.push({x:px,y:py,vx:(Math.random()-.5)*4,vy:(Math.random()-.5)*4,
r:Math.random()*3+1,life:1,color:colors[Math.floor(Math.random()*colors.length)],
decay:Math.random()*.015+.005});}}
function draw(){
x.fillStyle='rgba(10,10,20,0.08)';x.fillRect(0,0,W/2,H/2);
for(let i=pts.length-1;i>=0;i--){
let p=pts[i];p.x+=p.vx;p.y+=p.vy;p.vx*=.99;p.vy*=.99;p.life-=p.decay;
if(p.life<=0){pts.splice(i,1);continue;}
x.globalAlpha=p.life;x.fillStyle=p.color;
x.beginPath();x.arc(p.x,p.y,p.r*p.life,0,Math.PI*2);x.fill();
x.globalAlpha=p.life*.3;x.beginPath();x.arc(p.x,p.y,p.r*p.life*3,0,Math.PI*2);x.fill();}
x.globalAlpha=1;
if(Math.random()<.1){
pts.push({x:Math.random()*W/2,y:Math.random()*H/2,vx:0,vy:-.2,
r:.5,life:.6,color:colors[Math.floor(Math.random()*colors.length)],decay:.003});}
requestAnimationFrame(draw);}
function pos(e){let t=e.touches?e.touches[0]:e;return{x:t.clientX,y:t.clientY};}
c.addEventListener('touchmove',e=>{e.preventDefault();let p=pos(e);addPt(p.x,p.y);},{passive:false});
c.addEventListener('touchstart',e=>{e.preventDefault();let p=pos(e);addPt(p.x,p.y);},{passive:false});
c.addEventListener('mousemove',e=>{if(e.buttons)addPt(e.clientX,e.clientY);});
c.addEventListener('mousedown',e=>addPt(e.clientX,e.clientY));
draw();
</script>
</body>
</html>"""


def adventure_html():
    """A short branching story."""
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>The Subway Ghost</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;display:flex;flex-direction:column;align-items:center;
justify-content:center;padding:24px;-webkit-user-select:none}
.hdr{text-align:center;margin-bottom:24px}
.hdr h1{font-size:1.8em;background:linear-gradient(135deg,#66d9ff,#9966ff);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#666;font-size:.85em;margin-top:4px}
.story{background:#12121e;border:1px solid #222;border-radius:20px;padding:28px 24px;
width:100%;max-width:380px;animation:fadeIn .5s ease}
@keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}
.story p{font-size:1.1em;line-height:1.7;color:#d0d0d0;margin-bottom:20px}
.choices{display:flex;flex-direction:column;gap:10px}
.choice{padding:14px 18px;background:#1a1a2e;border:1px solid #333;border-radius:14px;
font-size:1em;cursor:pointer;transition:all .2s;color:#66d9ff;font-weight:600}
.choice:active{transform:scale(.97);background:#66d9ff22;border-color:#66d9ff}
.end{text-align:center;padding:20px 0}
.end .emoji{font-size:3em;margin-bottom:12px}
.end p{color:#888}
.btn{display:inline-block;margin-top:16px;padding:12px 28px;
background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:700;
border:none;border-radius:30px;font-size:.95em;cursor:pointer}
.foot{color:#333;font-size:.7em;margin-top:auto;padding-top:20px;text-align:center}
</style>
</head>
<body>
<div class="hdr"><h1>The Subway Ghost</h1><p>An interactive story · Delivered via Glyph</p></div>
<div id="stage"></div>
<div class="foot">🔮 Glyph · Choose your path</div>
<script>
const N={
"start":{t:"You're waiting for the L train at 3am. The platform is empty. A faint cyan glow pulses from behind a column. You step closer and see a QR code etched into the tile wall.",c:[{l:"Scan it",t:"scan"},{l:"Keep waiting for the train",t:"wait"}]},
"scan":{t:"Your phone's screen floods with light. A message appears: 'You found me. I've been waiting 47 days for someone to look.' Below it, a countdown timer ticks: 00:00:59...",c:[{l:"Reply before time runs out",t:"reply"},{l:"Screenshot and run",t:"run"}]},
"wait":{t:"The train arrives. You board. But through the window, you see the glow intensify. The QR code is now on EVERY column. And the train... it's not stopping at the next station.",c:[{l:"Pull the emergency brake",t:"brake"},{l:"Scan through the window",t:"scan2"}]},
"reply":{t:"You type: 'Who are you?' The response is instant: 'I'm what's left when the signal dies. Find the next glyph at Union Square. Platform edge. Third tile from the stairs.' The screen goes dark.",c:[{l:"Go to Union Square",t:"end_quest"},{l:"Delete everything and forget",t:"end_forget"}]},
"run":{t:"You bolt up the stairs. At street level, you check your photos. The screenshot is there, but the message has changed. It now reads: 'Running won't help. I'm already in your camera roll.' Your phone buzzes with a new notification...",c:[]},
"brake":{t:"The train screeches to a halt. The lights flicker. When they come back on, every passenger is holding their phone up, scanning something you can't see. One of them turns to you and whispers: 'You should have scanned it when you had the chance.'",c:[]},
"scan2":{t:"The code resolves instantly despite the motion. Your screen shows a map — not of the subway, but of something beneath it. Tunnels that don't appear on any official chart. And at the center, a pulsing dot labeled: 'YOU ARE HERE.'",c:[]},
"end_quest":{t:"You take the next train to Union Square. Platform edge. Third tile from the stairs. There it is — another glyph, glowing faintly. You're part of the network now. There's no going back.",c:[]},
"end_forget":{t:"You delete the screenshot. You delete the app. You try to forget. But every time you pass a QR code in the subway, you wonder... is it watching back?",c:[]}
};
function go(id){
let n=N[id];if(!n){document.getElementById('stage').innerHTML='<div class="story"><div class="end"><div class="emoji">🔮</div><p>The end.</p><button class="btn" onclick="go(\\'start\\')">Start Over</button></div></div>';return;}
let h='<div class="story"><p>'+n.t+'</p>';
if(n.c.length===0){
h+='<div class="end"><div class="emoji">✨</div><p>The end.</p><button class="btn" onclick="go(\\'start\\')">Start Over</button></div>';
}else{
h+='<div class="choices">';
n.c.forEach(c=>{h+='<div class="choice" onclick="go(\\''+c.t+'\\')">'+c.l+'</div>';});
h+='</div>';}
h+='</div>';
document.getElementById('stage').innerHTML=h;}
go('start');
</script>
</body>
</html>"""


# ---------------------------------------------------------------------------
# 3. BUILD TEST CASES
# ---------------------------------------------------------------------------

def build_test_cases():
    cases = []
    
    experiences = [
        ("Subway Trivia", "trivia", trivia_html(), "🧠"),
        ("Underground Signals", "article", article_html(), "📖"),
        ("Subway Canvas", "art", art_html(), "🎨"),
        ("The Subway Ghost", "adventure", adventure_html(), "🗺️"),
    ]
    
    for title, template_type, html, emoji in experiences:
        # Encode using the same pipeline as Swift
        payload, json_size, compressed_size = encode_web_bundle(title, html, template_type)
        
        # Chunk into GLYC: frames
        session_id = f"W{template_type[:3].upper()}001"
        chunks = chunk_payload(payload, session_id)
        
        # Generate QR for each chunk
        qr_frames = []
        max_version = 0
        for chunk_str in chunks:
            b64_png, version, byte_len = qr_to_base64_png(chunk_str, box_size=6)
            qr_frames.append({
                "b64": b64_png,
                "version": version,
                "bytes": byte_len,
            })
            max_version = max(max_version, version)
        
        html_size = len(html.encode('utf-8'))
        ratio = json_size / compressed_size if compressed_size > 0 else 0
        scan_time = len(chunks) * 0.4  # ~400ms per frame
        
        cases.append({
            "id": f"web-{template_type}",
            "title": f"{emoji} {title}",
            "template_type": template_type,
            "emoji": emoji,
            "html_preview": html,
            "stats": {
                "html_bytes": html_size,
                "json_bytes": json_size,
                "compressed_bytes": compressed_size,
                "payload_bytes": len(payload),
                "ratio": ratio,
                "frames": len(chunks),
                "max_qr_version": max_version,
                "scan_time_s": scan_time,
            },
            "qr_frames": qr_frames,
        })
        
        print(f"  ✓ {title:25s}  HTML={html_size:>6d}B  JSON={json_size:>6d}B  "
              f"gzip={compressed_size:>5d}B ({ratio:.1f}:1)  "
              f"frames={len(chunks):>3d}  ~{scan_time:.0f}s scan")
    
    return cases


# ---------------------------------------------------------------------------
# 4. HTML PAGE
# ---------------------------------------------------------------------------

def build_html(cases):
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except Exception:
        local_ip = "localhost"
    
    # Build cards
    cards_html = ""
    for c in cases:
        stats = c["stats"]
        
        # QR frame images as a JS array for cycling
        frames_js = ",".join(
            f'{{b64:"{f["b64"]}",v:{f["version"]},b:{f["bytes"]}}}'
            for f in c["qr_frames"]
        )
        
        # Capacity bar
        pct = min(100, int(stats["frames"] / 100 * 100))  # relative to 100 frames
        bar_color = "#ff3333" if stats["frames"] > 80 else "#ff9933" if stats["frames"] > 40 else "#66d9ff"
        
        # Escape HTML preview for embedding in an iframe srcdoc
        preview_escaped = (c["html_preview"]
            .replace("&", "&amp;")
            .replace('"', "&quot;")
            .replace("<", "&lt;")
            .replace(">", "&gt;"))
        
        cards_html += f"""
        <div class="card" id="{c['id']}">
            <div class="card-header">
                <span class="badge">{c['template_type'].upper()}</span>
                <h2>{c['title']}</h2>
            </div>
            
            <div class="stats-grid">
                <div class="stat">
                    <div class="stat-val">{stats['html_bytes']:,}</div>
                    <div class="stat-lbl">HTML bytes</div>
                </div>
                <div class="stat">
                    <div class="stat-val">{stats['compressed_bytes']:,}</div>
                    <div class="stat-lbl">gzipped</div>
                </div>
                <div class="stat">
                    <div class="stat-val">{stats['ratio']:.1f}:1</div>
                    <div class="stat-lbl">compression</div>
                </div>
                <div class="stat">
                    <div class="stat-val">{stats['frames']}</div>
                    <div class="stat-lbl">QR frames</div>
                </div>
                <div class="stat">
                    <div class="stat-val">~{stats['scan_time_s']:.0f}s</div>
                    <div class="stat-lbl">scan time</div>
                </div>
                <div class="stat">
                    <div class="stat-val">v{stats['max_qr_version']}</div>
                    <div class="stat-lbl">QR version</div>
                </div>
            </div>
            
            <div class="split-view">
                <div class="qr-side">
                    <div class="qr-container">
                        <img id="qr-{c['id']}" class="qr-img" alt="QR" />
                    </div>
                    <div class="qr-controls">
                        <button onclick="toggleCycle('{c['id']}')" id="btn-{c['id']}" class="cycle-btn">▶ Start Cycling</button>
                        <span id="counter-{c['id']}" class="frame-counter">1/{stats['frames']}</span>
                    </div>
                </div>
                <div class="preview-side">
                    <div class="preview-header">
                        <span class="preview-dot"></span>
                        Live Preview
                    </div>
                    <iframe class="preview-frame" srcdoc="{preview_escaped}" sandbox="allow-scripts"></iframe>
                </div>
            </div>
            
            <script>
            (function(){{
                const frames=[{frames_js}];
                let idx=0,timer=null;
                const img=document.getElementById('qr-{c['id']}');
                const counter=document.getElementById('counter-{c['id']}');
                
                // Show first frame
                img.src='data:image/png;base64,'+frames[0].b64;
                
                // Register this card's toggle in a global registry
                if(!window._cycleRegistry) window._cycleRegistry={{}};
                window._cycleRegistry['{c["id"]}']=function(){{
                    const btn=document.getElementById('btn-{c["id"]}');
                    if(timer){{
                        clearInterval(timer);timer=null;
                        btn.textContent='▶ Start Cycling';
                        btn.classList.remove('active');
                    }}else{{
                        timer=setInterval(()=>{{
                            idx=(idx+1)%frames.length;
                            img.src='data:image/png;base64,'+frames[idx].b64;
                            counter.textContent=(idx+1)+'/'+frames.length;
                        }},400);
                        btn.textContent='⏸ Stop';
                        btn.classList.add('active');
                    }}
                }};
                window.toggleCycle=function(id){{
                    if(window._cycleRegistry[id]) window._cycleRegistry[id]();
                }};
            }})();
            </script>
        </div>
        """
    
    # Summary stats
    total_frames = sum(c["stats"]["frames"] for c in cases)
    avg_ratio = sum(c["stats"]["ratio"] for c in cases) / len(cases) if cases else 0
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>🔮 Glyph Web Experience QR Lab</title>
<style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
        background: #0a0a14;
        color: #e0e0e0;
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif;
        padding: 20px;
        max-width: 1600px;
        margin: 0 auto;
    }}
    h1 {{
        font-size: 2.4em;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 4px;
    }}
    .subtitle {{ color: #777; font-size: 1em; margin-bottom: 8px; }}
    
    .concept {{
        background: #12121e;
        border: 1px solid #333;
        border-radius: 12px;
        padding: 20px;
        margin: 16px 0;
        line-height: 1.7;
        color: #bbb;
        font-size: .9em;
    }}
    .concept strong {{ color: #66d9ff; }}
    .concept code {{
        background: #1a1a2e;
        padding: 2px 6px;
        border-radius: 4px;
        color: #ff9933;
        font-size: .9em;
    }}
    
    .summary {{
        display: flex;
        gap: 16px;
        margin: 20px 0;
        flex-wrap: wrap;
    }}
    .summary-stat {{
        background: #12121e;
        border: 1px solid #222;
        border-radius: 12px;
        padding: 16px 24px;
        text-align: center;
    }}
    .summary-stat .val {{
        font-size: 2em;
        font-weight: 800;
        background: linear-gradient(135deg, #66d9ff, #9966ff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }}
    .summary-stat .lbl {{ color: #888; font-size: .8em; margin-top: 4px; }}
    
    .card {{
        background: #12121e;
        border: 1px solid #222;
        border-radius: 16px;
        padding: 24px;
        margin-bottom: 24px;
        transition: border-color 0.2s;
    }}
    .card:hover {{ border-color: #66d9ff44; }}
    .card-header {{
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 16px;
    }}
    .card-header h2 {{ font-size: 1.3em; color: #fff; }}
    .badge {{
        font-size: .65em;
        font-weight: 700;
        padding: 3px 10px;
        border-radius: 20px;
        color: #000;
        background: #9966ff;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }}
    
    .stats-grid {{
        display: grid;
        grid-template-columns: repeat(6, 1fr);
        gap: 10px;
        margin-bottom: 16px;
    }}
    .stat {{
        background: #0d0d18;
        border-radius: 10px;
        padding: 12px;
        text-align: center;
    }}
    .stat-val {{
        font-size: 1.3em;
        font-weight: 700;
        color: #66d9ff;
    }}
    .stat-lbl {{
        font-size: .7em;
        color: #666;
        margin-top: 2px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }}
    
    .split-view {{
        display: grid;
        grid-template-columns: 340px 1fr;
        gap: 20px;
        min-height: 400px;
    }}
    
    .qr-side {{ display: flex; flex-direction: column; gap: 10px; }}
    .qr-container {{
        background: white;
        border-radius: 12px;
        padding: 12px;
        display: flex;
        justify-content: center;
        align-items: center;
    }}
    .qr-img {{
        width: 300px;
        height: 300px;
        image-rendering: pixelated;
    }}
    .qr-controls {{
        display: flex;
        align-items: center;
        gap: 12px;
    }}
    .cycle-btn {{
        padding: 8px 20px;
        background: #1a1a2e;
        color: #66d9ff;
        border: 1px solid #333;
        border-radius: 20px;
        font-size: .85em;
        font-weight: 600;
        cursor: pointer;
        transition: all .2s;
        font-family: inherit;
    }}
    .cycle-btn:hover {{ background: #66d9ff22; border-color: #66d9ff44; }}
    .cycle-btn.active {{ background: #66d9ff22; border-color: #66d9ff; }}
    .frame-counter {{
        font-size: .85em;
        font-weight: 700;
        color: #888;
        font-family: 'SF Mono', monospace;
    }}
    
    .preview-side {{ display: flex; flex-direction: column; }}
    .preview-header {{
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 14px;
        background: #1a1a2e;
        border-radius: 12px 12px 0 0;
        font-size: .8em;
        font-weight: 600;
        color: #888;
    }}
    .preview-dot {{
        width: 8px;
        height: 8px;
        background: #66d9ff;
        border-radius: 50%;
    }}
    .preview-frame {{
        flex: 1;
        border: 1px solid #333;
        border-top: none;
        border-radius: 0 0 12px 12px;
        background: #0a0a14;
        min-height: 380px;
    }}
    
    .info {{
        background: #1a1a2e;
        border: 1px solid #333;
        border-radius: 12px;
        padding: 16px 20px;
        margin-bottom: 16px;
        font-size: .9em;
    }}
    .info code {{
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
        font-size: .85em;
        font-weight: 600;
        border: 1px solid #333;
        transition: all 0.2s;
    }}
    .nav a:hover {{ background: #66d9ff22; border-color: #66d9ff44; }}
    
    @media (max-width: 800px) {{
        .stats-grid {{ grid-template-columns: repeat(3, 1fr); }}
        .split-view {{ grid-template-columns: 1fr; }}
        .qr-img {{ width: 200px; height: 200px; }}
    }}
</style>
</head>
<body>
    <h1>🔮 Glyph Web Experience QR Lab</h1>
    <p class="subtitle">Full interactive web pages transmitted via cycling QR codes — no internet required.</p>
    
    <div class="concept">
        <strong>How it works:</strong> The HTML page is wrapped in a JSON bundle, <code>gzip</code> compressed
        (typically 3-5× reduction), base64-encoded with a <code>GLYW:</code> prefix, then split into 
        <code>GLYC:</code> chunks at 800 bytes each. The Glyph app scans the cycling QR frames, reassembles 
        the chunks, decompresses, and renders the page in a sandboxed WKWebView. The entire experience 
        is self-contained — HTML, CSS, and JS all in one payload.
        <br><br>
        <strong>Encoding pipeline:</strong> 
        <code>HTML → JSON → gzip → base64 → GLYW: → chunk → GLYC: frames → QR codes</code>
    </div>
    
    <div class="summary">
        <div class="summary-stat">
            <div class="val">{len(cases)}</div>
            <div class="lbl">Experiences</div>
        </div>
        <div class="summary-stat">
            <div class="val">{total_frames}</div>
            <div class="lbl">Total QR Frames</div>
        </div>
        <div class="summary-stat">
            <div class="val">{avg_ratio:.1f}:1</div>
            <div class="lbl">Avg Compression</div>
        </div>
    </div>
    
    <div class="info">
        📱 <strong>To test:</strong> Start cycling QR frames, then point your iPhone's Glyph scanner at the screen.
        The app will assemble the chunks and render the experience.
        <br>🌐 Also available at: <code>http://{local_ip}:{PORT}</code>
        <br>Generated: <code>{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</code>
    </div>
    
    <div class="nav">
        {"".join(f'<a href="#{c["id"]}">{c["title"]}</a>' for c in cases)}
    </div>
    
    {cards_html}
    
    <div style="text-align:center; padding: 40px 0; color:#444; font-size:.8em;">
        Glyph Web Experience QR Lab · {len(cases)} experiences · {total_frames} total frames · Ctrl+C to stop
    </div>
</body>
</html>"""
    
    return html


# ---------------------------------------------------------------------------
# 5. SERVE
# ---------------------------------------------------------------------------

def main():
    print("🔮 Glyph Web Experience QR Lab")
    print("=" * 60)
    print("Generating web experience QR sequences...\n")
    
    cases = build_test_cases()
    
    html = build_html(cases)
    
    # Save HTML
    out_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(out_dir, "web_lab.html")
    with open(html_path, "w") as f:
        f.write(html)
    print(f"\n📄 Saved to: {html_path}")
    
    # Get local IP
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except Exception:
        local_ip = "localhost"
    
    total_frames = sum(c["stats"]["frames"] for c in cases)
    
    print(f"\n🌐 Serving at:")
    print(f"   http://localhost:{PORT}")
    print(f"   http://{local_ip}:{PORT}")
    print(f"\n📱 Open on your Mac/iPhone to preview experiences")
    print(f"   {len(cases)} experiences · {total_frames} total QR frames")
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
    
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n🛑 Server stopped.")
            sys.exit(0)


if __name__ == "__main__":
    main()
