#!/usr/bin/env python3
"""
Glyph QR Wall — a wall of cycling QR codes, nothing else.
Generates a self-contained HTML file and serves it.
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
MAX_CHUNK_BYTES = 800


# --- Encoding pipeline (mirrors Swift) ---

def raw_deflate(data: bytes) -> bytes:
    c = zlib.compressobj(9, zlib.DEFLATED, -15)
    return c.compress(data) + c.flush()


def encode_web_bundle(title, html, template_type=None):
    bundle = {"title": title, "html": html, "templateType": template_type,
              "createdAt": datetime.now().timestamp()}
    jb = json.dumps(bundle, separators=(',', ':')).encode('utf-8')
    comp = raw_deflate(jb)
    b64 = base64.b64encode(comp).decode('ascii')
    return f"GLYW:{b64}", len(jb), len(comp)


def chunk_payload(payload_string, session_id="W0000001"):
    pb = payload_string.encode('utf-8')
    pb64 = base64.b64encode(pb).decode('ascii')
    slices = [pb64[i:i+MAX_CHUNK_BYTES] for i in range(0, len(pb64), MAX_CHUNK_BYTES)]
    total = len(slices)
    chunks = []
    for i, sl in enumerate(slices):
        ch = {"sessionId": session_id, "index": i, "total": total, "data": sl}
        cj = json.dumps(ch, separators=(',', ':')).encode('utf-8')
        chunks.append(f"GLYC:{base64.b64encode(cj).decode('ascii')}")
    return chunks


def qr_to_b64png(data, box=8):
    qr = qrcode.QRCode(version=None, error_correction=qrcode.constants.ERROR_CORRECT_L,
                        box_size=box, border=2)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return base64.b64encode(buf.getvalue()).decode('ascii')


# --- Experiences ---

EXPERIENCES = [
    ("Subway Trivia", "trivia", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no"><title>Subway Trivia</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;min-height:100vh;display:flex;flex-direction:column;align-items:center;padding:24px;-webkit-user-select:none}.hdr{text-align:center;margin-bottom:24px}.hdr h1{font-size:2em;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hdr p{color:#888;font-size:.9em;margin-top:4px}.prog{display:flex;gap:4px;margin:16px 0;width:100%;max-width:360px}.prog .dot{flex:1;height:4px;border-radius:2px;background:#1a1a2e;transition:background .3s}.prog .dot.done{background:#66d9ff}.prog .dot.cur{background:#9966ff}.card{background:#12121e;border:1px solid #222;border-radius:20px;padding:28px 24px;width:100%;max-width:360px;animation:slideIn .4s ease}@keyframes slideIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}.q{font-size:1.2em;font-weight:600;line-height:1.5;margin-bottom:20px;color:#fff}.qn{font-size:.75em;color:#66d9ff;font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px}.opts{display:flex;flex-direction:column;gap:10px}.opt{padding:14px 18px;background:#1a1a2e;border:1px solid #333;border-radius:14px;font-size:1em;cursor:pointer;transition:all .2s;text-align:left;color:#e0e0e0}.opt:active{transform:scale(.98)}.opt.correct{background:#66d9ff22;border-color:#66d9ff;color:#66d9ff}.opt.wrong{background:#ff333322;border-color:#ff3333;color:#ff3333}.opt.dim{opacity:.4;pointer-events:none}.result{text-align:center;animation:slideIn .5s ease}.score{font-size:4em;font-weight:800;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:20px 0}.msg{font-size:1.2em;color:#ccc;margin-bottom:8px}.sub{color:#666;font-size:.85em}.btn{display:inline-block;margin-top:24px;padding:14px 36px;background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:700;border:none;border-radius:30px;font-size:1em;cursor:pointer}</style></head><body><div class="hdr"><h1>🚇 Subway Trivia</h1><p>Delivered via Glyph</p></div><div class="prog" id="prog"></div><div id="stage"></div><script>const Q=[{q:"What year did the NYC subway open?",a:["1894","1904","1914","1924"],c:1},{q:"Which is the longest subway line?",a:["A train","7 train","L train","G train"],c:0},{q:"How many stations are in the NYC subway?",a:["372","422","472","512"],c:2},{q:"What color is the 4/5/6 line?",a:["Blue","Orange","Red","Green"],c:3},{q:"Which borough has no subway?",a:["Queens","Bronx","Staten Island","Brooklyn"],c:2}];let cur=0,sc=0,ans=false;function init(){let p=document.getElementById('prog');p.innerHTML=Q.map((_,i)=>'<div class="dot" id="d'+i+'"></div>').join('');show();}function show(){if(cur>=Q.length){finish();return;}ans=false;document.querySelectorAll('.dot').forEach((d,i)=>{d.className='dot'+(i<cur?' done':i===cur?' cur':'');});let q=Q[cur];let h='<div class="card"><div class="qn">Question '+(cur+1)+' of '+Q.length+'</div><div class="q">'+q.q+'</div><div class="opts">';q.a.forEach((a,i)=>{h+='<div class="opt" onclick="pick('+i+',this)" id="o'+i+'">'+a+'</div>';});h+='</div></div>';document.getElementById('stage').innerHTML=h;}function pick(i,el){if(ans)return;ans=true;let q=Q[cur];if(i===q.c){sc++;el.classList.add('correct');}else{el.classList.add('wrong');document.getElementById('o'+q.c).classList.add('correct');}document.querySelectorAll('.opt').forEach((o,j)=>{if(j!==i&&j!==q.c)o.classList.add('dim');});setTimeout(()=>{cur++;show();},1200);}function finish(){let pct=Math.round(sc/Q.length*100);let m=pct===100?'Perfect! 🎉':pct>=70?'Nice work! 🔥':pct>=40?'Not bad! 💪':'Keep trying! 😅';let h='<div class="result"><div class="score">'+sc+'/'+Q.length+'</div><div class="msg">'+m+'</div><div class="sub">'+pct+'% correct</div><button class="btn" onclick="cur=0;sc=0;show();">Play Again</button></div>';document.getElementById('stage').innerHTML=h;document.querySelectorAll('.dot').forEach(d=>d.className='dot done');}init();</script></body></html>"""),

    ("Underground Signals", "article", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Underground Signals</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#d0d0d0;font-family:Georgia,serif;padding:32px 24px;max-width:480px;margin:0 auto;line-height:1.8}.header{text-align:center;margin-bottom:36px;padding-bottom:24px;border-bottom:1px solid #222}h1{font-size:1.8em;color:#fff;font-family:-apple-system,sans-serif;font-weight:800;line-height:1.3;margin-bottom:8px}.subtitle{color:#888;font-size:1em;font-style:italic}.author{color:#66d9ff;font-size:.85em;font-family:-apple-system,sans-serif;font-weight:600;margin-top:8px}h2{font-size:1.3em;color:#fff;font-family:-apple-system,sans-serif;font-weight:700;margin:32px 0 12px;padding-top:16px;border-top:1px solid #1a1a2e}p{margin-bottom:16px;font-size:1.05em}p:first-of-type::first-letter{float:left;font-size:3.2em;line-height:1;padding-right:8px;color:#66d9ff;font-weight:700;font-family:-apple-system,sans-serif}.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #222;color:#444;font-size:.75em;font-family:-apple-system,sans-serif}</style></head><body><div class="header"><h1>Underground Signals</h1><p class="subtitle">The hidden language of subway QR codes</p><div class="author">by Ghost Writer</div></div><article><p>They started appearing in January. Small, unassuming QR codes stuck to the tile walls of subway stations. Not advertisements. Not MTA notices. Something else entirely.</p><p>The first one was spotted at the Bedford Avenue L station. A commuter, phone already in hand, aimed their camera at the code. What loaded wasn't a website. It was a message.</p><h2>A New Kind of Communication</h2><p>Unlike traditional graffiti, these messages left no physical mark. They existed only in the space between the code and the camera — a pocket dimension of light and data. And they disappeared.</p><p>The technology behind it was surprisingly simple. No servers, no internet connection, no accounts. Just pure, offline data transfer through patterns of black and white squares.</p><h2>The Ghost Network</h2><p>Word spread the way it always does underground: slowly, then all at once. Within weeks, codes appeared at stations across the city. Each one a tiny portal to someone else's thoughts.</p><p>No one knows who started it. And maybe that's the point.</p></article><div class="footer">🔮 Glyph · No servers. No internet. Just light.</div></body></html>"""),

    ("Subway Canvas", "art", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no"><title>Glyph Art</title><style>*{margin:0;padding:0}body{background:#0a0a14;overflow:hidden;touch-action:none}canvas{display:block;width:100vw;height:100vh}.ui{position:fixed;top:0;left:0;right:0;padding:16px 20px;display:flex;justify-content:space-between;align-items:center;z-index:10;background:linear-gradient(#0a0a14cc,transparent)}.ui h1{font-size:1em;color:#fff;font-family:-apple-system,sans-serif;font-weight:700}.ui p{color:#66d9ff88;font-size:.7em;font-family:-apple-system,sans-serif}.hint{position:fixed;bottom:40px;left:0;right:0;text-align:center;color:#ffffff44;font-size:.85em;font-family:-apple-system,sans-serif;pointer-events:none;transition:opacity 1s}</style></head><body><div class="ui"><div><h1>Subway Canvas</h1><p>🔮 Glyph Art</p></div></div><canvas id="c"></canvas><div class="hint" id="hint">Touch anywhere ✨</div><script>const c=document.getElementById('c'),x=c.getContext('2d');let W,H,pts=[],touched=false;function resize(){W=c.width=innerWidth*2;H=c.height=innerHeight*2;c.style.width=innerWidth+'px';c.style.height=innerHeight+'px';x.scale(2,2);}resize();addEventListener('resize',resize);const colors=['#66d9ff','#9966ff','#ff66d9','#66ffaa','#ffaa66'];function addPt(px,py){if(!touched){touched=true;document.getElementById('hint').style.opacity=0;}for(let i=0;i<3;i++){pts.push({x:px,y:py,vx:(Math.random()-.5)*4,vy:(Math.random()-.5)*4,r:Math.random()*3+1,life:1,color:colors[Math.floor(Math.random()*colors.length)],decay:Math.random()*.015+.005});}}function draw(){x.fillStyle='rgba(10,10,20,0.08)';x.fillRect(0,0,W/2,H/2);for(let i=pts.length-1;i>=0;i--){let p=pts[i];p.x+=p.vx;p.y+=p.vy;p.vx*=.99;p.vy*=.99;p.life-=p.decay;if(p.life<=0){pts.splice(i,1);continue;}x.globalAlpha=p.life;x.fillStyle=p.color;x.beginPath();x.arc(p.x,p.y,p.r*p.life,0,Math.PI*2);x.fill();x.globalAlpha=p.life*.3;x.beginPath();x.arc(p.x,p.y,p.r*p.life*3,0,Math.PI*2);x.fill();}x.globalAlpha=1;if(Math.random()<.1){pts.push({x:Math.random()*W/2,y:Math.random()*H/2,vx:0,vy:-.2,r:.5,life:.6,color:colors[Math.floor(Math.random()*colors.length)],decay:.003});}requestAnimationFrame(draw);}function pos(e){let t=e.touches?e.touches[0]:e;return{x:t.clientX,y:t.clientY};}c.addEventListener('touchmove',e=>{e.preventDefault();let p=pos(e);addPt(p.x,p.y);},{passive:false});c.addEventListener('touchstart',e=>{e.preventDefault();let p=pos(e);addPt(p.x,p.y);},{passive:false});c.addEventListener('mousemove',e=>{if(e.buttons)addPt(e.clientX,e.clientY);});c.addEventListener('mousedown',e=>addPt(e.clientX,e.clientY));draw();</script></body></html>"""),

    ("The Subway Ghost", "adventure", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no"><title>The Subway Ghost</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,sans-serif;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px}.hdr{text-align:center;margin-bottom:24px}.hdr h1{font-size:1.8em;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent}.hdr p{color:#666;font-size:.85em;margin-top:4px}.story{background:#12121e;border:1px solid #222;border-radius:20px;padding:28px 24px;width:100%;max-width:380px;animation:fadeIn .5s ease}@keyframes fadeIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}.story p{font-size:1.1em;line-height:1.7;color:#d0d0d0;margin-bottom:20px}.choices{display:flex;flex-direction:column;gap:10px}.choice{padding:14px 18px;background:#1a1a2e;border:1px solid #333;border-radius:14px;font-size:1em;cursor:pointer;transition:all .2s;color:#66d9ff;font-weight:600}.choice:active{transform:scale(.97);background:#66d9ff22;border-color:#66d9ff}.end{text-align:center;padding:20px 0}.end .emoji{font-size:3em;margin-bottom:12px}.end p{color:#888}.btn{display:inline-block;margin-top:16px;padding:12px 28px;background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:700;border:none;border-radius:30px;font-size:.95em;cursor:pointer}</style></head><body><div class="hdr"><h1>The Subway Ghost</h1><p>An interactive story</p></div><div id="stage"></div><script>const N={"start":{t:"You're waiting for the L train at 3am. The platform is empty. A faint cyan glow pulses from behind a column. You step closer and see a QR code etched into the tile wall.",c:[{l:"Scan it",t:"scan"},{l:"Keep waiting",t:"wait"}]},"scan":{t:"Your phone's screen floods with light. A message appears: 'You found me. I've been waiting 47 days for someone to look.' Below it, a countdown timer: 00:00:59...",c:[{l:"Reply before time runs out",t:"reply"},{l:"Screenshot and run",t:"run"}]},"wait":{t:"The train arrives. You board. But through the window, you see the glow intensify. The QR code is now on EVERY column. And the train isn't stopping at the next station.",c:[{l:"Pull the emergency brake",t:"brake"},{l:"Scan through the window",t:"scan2"}]},"reply":{t:"You type: 'Who are you?' The response is instant: 'I'm what's left when the signal dies. Find the next glyph at Union Square. Platform edge. Third tile from the stairs.' The screen goes dark.",c:[{l:"Go to Union Square",t:"end_quest"},{l:"Delete and forget",t:"end_forget"}]},"run":{t:"You bolt up the stairs. At street level, you check your photos. The screenshot is there, but the message has changed. It now reads: 'Running won't help. I'm already in your camera roll.'",c:[]},"brake":{t:"The train screeches to a halt. The lights flicker. When they come back on, every passenger is holding their phone up, scanning something you can't see. One whispers: 'You should have scanned it.'",c:[]},"scan2":{t:"The code resolves instantly despite the motion. Your screen shows a map — not of the subway, but of something beneath it. Tunnels not on any chart. At the center, a pulsing dot: 'YOU ARE HERE.'",c:[]},"end_quest":{t:"You take the next train to Union Square. Platform edge. Third tile. There it is — another glyph, glowing faintly. You're part of the network now.",c:[]},"end_forget":{t:"You delete everything. You try to forget. But every time you pass a QR code in the subway, you wonder... is it watching back?",c:[]}};function go(id){let n=N[id];if(!n)return;let h='<div class="story"><p>'+n.t+'</p>';if(n.c.length===0){h+='<div class="end"><div class="emoji">✨</div><p>The end.</p><button class="btn" onclick="go(\\'start\\')">Start Over</button></div>';}else{h+='<div class="choices">';n.c.forEach(c=>{h+='<div class="choice" onclick="go(\\''+c.t+'\\')">'+c.l+'</div>';});h+='</div>';}h+='</div>';document.getElementById('stage').innerHTML=h;}go('start');</script></body></html>"""),

    ("Pulse Zine", "article", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pulse</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#d0d0d0;font-family:Georgia,serif;padding:32px 24px;max-width:480px;margin:0 auto;line-height:1.8}h1{font-size:2em;color:#fff;font-family:-apple-system,sans-serif;text-align:center;margin-bottom:8px}h2{font-size:1.2em;color:#9966ff;font-family:-apple-system,sans-serif;margin:28px 0 10px;padding-top:14px;border-top:1px solid #1a1a2e}.sub{text-align:center;color:#66d9ff;font-size:.85em;margin-bottom:32px;font-family:-apple-system,sans-serif}p{margin-bottom:14px;font-size:1em}.q{background:#12121e;border-left:3px solid #9966ff;padding:16px 20px;margin:20px 0;border-radius:0 12px 12px 0;font-style:italic;color:#aaa}</style></head><body><h1>Pulse</h1><div class="sub">Issue #001 · The Frequency</div><h2>What Lives Between Stations</h2><p>There's a sound the subway makes between stations that most people never notice. It's not the screech of brakes or the hum of the engine. It's something underneath — a resonance that seems to carry information.</p><div class="q">"Every tunnel has a frequency. You just have to learn how to listen." — Unknown</div><h2>The 40Hz Hypothesis</h2><p>Researchers at Columbia discovered that the NYC subway system produces a consistent 40Hz vibration — the same frequency associated with gamma brain waves and heightened awareness. Coincidence? The trains have been running at this frequency since 1904.</p><p>Some believe the original engineers knew. That the subway was designed not just to move bodies through space, but to synchronize the minds of everyone underground.</p><h2>Tuning In</h2><p>Next time you're between stations, close your eyes. Feel the vibration through the soles of your shoes. Let it rise through your spine. You might hear something in the noise. A pattern. A pulse. A message meant only for you.</p></body></html>"""),

    ("Cipher Game", "trivia", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no"><title>Cipher</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#e0e0e0;font-family:'Courier New',monospace;min-height:100vh;display:flex;flex-direction:column;align-items:center;padding:24px}h1{font-size:1.6em;color:#66d9ff;margin-bottom:4px}.sub{color:#666;font-size:.8em;margin-bottom:24px}.card{background:#12121e;border:1px solid #333;border-radius:16px;padding:24px;width:100%;max-width:360px;margin-bottom:16px;animation:fadeIn .4s}@keyframes fadeIn{from{opacity:0}to{opacity:1}}.cipher{font-size:1.4em;letter-spacing:4px;color:#9966ff;text-align:center;padding:16px;background:#0a0a14;border-radius:12px;margin-bottom:16px;font-weight:700;word-break:break-all}.hint{color:#888;font-size:.85em;margin-bottom:16px;text-align:center}.input-row{display:flex;gap:8px}.input-row input{flex:1;background:#1a1a2e;border:1px solid #444;border-radius:10px;padding:12px;color:#66d9ff;font-family:'Courier New',monospace;font-size:1.1em;text-transform:uppercase;text-align:center;outline:none}.input-row input:focus{border-color:#66d9ff}.input-row button{background:#66d9ff;color:#000;border:none;border-radius:10px;padding:12px 20px;font-weight:700;cursor:pointer;font-family:'Courier New',monospace}.res{text-align:center;padding:12px;margin-top:12px;border-radius:10px;font-weight:700;font-size:1.1em}.ok{background:#66d9ff22;color:#66d9ff}.no{background:#ff333322;color:#ff3333}.score-bar{color:#888;font-size:.8em;text-align:center;margin-top:8px}</style></head><body><h1>⌘ CIPHER</h1><div class="sub">Decode the message</div><div id="stage"></div><script>const P=[{cipher:"HMFQI",answer:"GLYPH",hint:"Shift each letter back by 1",shift:1},{cipher:"WUDLQ",answer:"TRAIN",hint:"Caesar cipher, shift 3",shift:3},{cipher:"XQGHUJURXQG",answer:"UNDERGROUND",hint:"Caesar cipher, shift 3",shift:3},{cipher:"VLJQDO",answer:"SIGNAL",hint:"Caesar cipher, shift 3",shift:3},{cipher:"JKRVW",answer:"GHOST",hint:"Caesar cipher, shift 3",shift:3}];let ci=0,sc=0;function show(){if(ci>=P.length){let pct=Math.round(sc/P.length*100);document.getElementById('stage').innerHTML='<div class="card"><div style="text-align:center;font-size:2.5em;margin:12px 0">'+sc+'/'+P.length+'</div><div class="res ok">'+pct+'% decoded</div><div class="score-bar" style="margin-top:16px"><span style="cursor:pointer;color:#66d9ff" onclick="ci=0;sc=0;show()">↻ Play Again</span></div></div>';return;}let p=P[ci];document.getElementById('stage').innerHTML='<div class="card"><div class="score-bar">Puzzle '+(ci+1)+'/'+P.length+' · Score: '+sc+'</div><div class="cipher">'+p.cipher+'</div><div class="hint">💡 '+p.hint+'</div><div class="input-row"><input id="ans" maxlength="'+p.answer.length+'" placeholder="answer" autocomplete="off" autofocus /><button onclick="check()">→</button></div><div id="res"></div></div>';document.getElementById('ans').addEventListener('keydown',e=>{if(e.key==='Enter')check();});}function check(){let v=document.getElementById('ans').value.trim().toUpperCase();if(!v)return;let p=P[ci];if(v===p.answer){sc++;document.getElementById('res').innerHTML='<div class="res ok">✓ Correct!</div>';setTimeout(()=>{ci++;show();},900);}else{document.getElementById('res').innerHTML='<div class="res no">✗ Try again</div>';}}show();</script></body></html>"""),

    ("Metro Map", "art", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no"><title>Metro Map</title><style>*{margin:0;padding:0}body{background:#0a0a14;overflow:hidden}canvas{display:block;width:100vw;height:100vh}.label{position:fixed;bottom:20px;left:0;right:0;text-align:center;color:#ffffff33;font-size:.75em;font-family:-apple-system,sans-serif}</style></head><body><canvas id="c"></canvas><div class="label">🔮 Generative Metro Map</div><script>const c=document.getElementById('c'),x=c.getContext('2d');let W,H;function resize(){W=c.width=innerWidth;H=c.height=innerHeight;}resize();addEventListener('resize',resize);const lines=[{color:'#66d9ff',y:.2},{color:'#9966ff',y:.4},{color:'#ff66d9',y:.6},{color:'#66ffaa',y:.8},{color:'#ffaa66',y:.5}];let stations=[];function gen(){stations=[];lines.forEach((ln,li)=>{let n=4+Math.floor(Math.random()*5);for(let i=0;i<n;i++){stations.push({x:W*.1+i*(W*.8/(n-1)),y:H*ln.y+(Math.random()-.5)*40,r:3+Math.random()*3,color:ln.color,pulse:Math.random()*Math.PI*2,line:li});}});}gen();function draw(){x.fillStyle='#0a0a14';x.fillRect(0,0,W,H);lines.forEach((ln,li)=>{let pts=stations.filter(s=>s.line===li).sort((a,b)=>a.x-b.x);if(pts.length<2)return;x.strokeStyle=ln.color+'66';x.lineWidth=2;x.beginPath();x.moveTo(pts[0].x,pts[0].y);for(let i=1;i<pts.length;i++){let prev=pts[i-1],cur=pts[i],mx=(prev.x+cur.x)/2;x.bezierCurveTo(mx,prev.y,mx,cur.y,cur.x,cur.y);}x.stroke();});let t=Date.now()/1000;stations.forEach(s=>{let pulse=1+Math.sin(t*2+s.pulse)*.3;x.globalAlpha=.15;x.fillStyle=s.color;x.beginPath();x.arc(s.x,s.y,s.r*3*pulse,0,Math.PI*2);x.fill();x.globalAlpha=1;x.fillStyle=s.color;x.beginPath();x.arc(s.x,s.y,s.r,0,Math.PI*2);x.fill();x.fillStyle='#0a0a14';x.beginPath();x.arc(s.x,s.y,s.r*.4,0,Math.PI*2);x.fill();});requestAnimationFrame(draw);}draw();setInterval(()=>{stations.forEach(s=>{s.x+=((Math.random()-.5)*2);s.y+=((Math.random()-.5)*2);});},100);</script></body></html>"""),

    ("Whisper Wall", "article", """<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Whisper Wall</title><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a14;color:#d0d0d0;font-family:-apple-system,sans-serif;min-height:100vh;padding:40px 24px;display:flex;flex-direction:column;align-items:center}h1{font-size:1.6em;color:#fff;margin-bottom:4px}p.sub{color:#66d9ff88;font-size:.8em;margin-bottom:32px}.wall{width:100%;max-width:400px;display:flex;flex-direction:column;gap:12px}.w{background:#12121e;border:1px solid #222;border-radius:16px;padding:16px 20px;animation:fadeIn .6s ease}@keyframes fadeIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}.w p{font-size:1em;line-height:1.6;margin-bottom:8px}.w .meta{font-size:.7em;color:#666;display:flex;justify-content:space-between}.w.cyan{border-left:3px solid #66d9ff}.w.violet{border-left:3px solid #9966ff}.w.pink{border-left:3px solid #ff66d9}.w.green{border-left:3px solid #66ffaa}</style></head><body><h1>Whisper Wall</h1><p class="sub">Anonymous messages from the underground</p><div class="wall"><div class="w cyan"><p>Left my headphones on the 6 train. If you find them, they have a sticker of a cat astronaut. They mean more than you'd think.</p><div class="meta"><span>Bedford Av</span><span>2 hours ago</span></div></div><div class="w violet"><p>To the person who smiled at me on the F train this morning — you made my whole week. I was having the worst day.</p><div class="meta"><span>14th St</span><span>5 hours ago</span></div></div><div class="w pink"><p>I've been riding the same train at the same time for 3 years. Today I finally said hello. She said hello back. That's it. That's the whole story.</p><div class="meta"><span>Union Sq</span><span>8 hours ago</span></div></div><div class="w green"><p>There's a musician at the Times Square station who plays Debussy on a beat-up keyboard. Nobody stops. But everyone slows down a little.</p><div class="meta"><span>Times Sq</span><span>12 hours ago</span></div></div><div class="w cyan"><p>If you're reading this on your commute: you're doing great. The city is hard. You're still here. That counts.</p><div class="meta"><span>Grand Central</span><span>1 day ago</span></div></div><div class="w violet"><p>Found a paper crane tucked behind the bench at Canal St. Whoever made it — I'm keeping it on my desk. Thank you.</p><div class="meta"><span>Canal St</span><span>1 day ago</span></div></div></div></body></html>"""),
]

# Load Void Runner game from external file (too large to inline nicely)
_script_dir = os.path.dirname(os.path.abspath(__file__))
_void_runner_path = os.path.join(_script_dir, "void_runner.html")
if os.path.exists(_void_runner_path):
    with open(_void_runner_path, 'r') as f:
        EXPERIENCES.append(("Void Runner", "game", f.read()))

_drift_mini_path = os.path.join(_script_dir, "drift_mini.html")
if os.path.exists(_drift_mini_path):
    with open(_drift_mini_path, 'r') as f:
        EXPERIENCES.append(("Drift", "game", f.read()))


def main():
    print("🔮 Glyph QR Wall")
    print("=" * 50)
    print("Generating QR sequences...\n")

    all_sequences = []

    for i, (title, ttype, html) in enumerate(EXPERIENCES):
        payload, json_sz, comp_sz = encode_web_bundle(title, html, ttype)
        sid = f"WALL{i:04d}"
        chunks = chunk_payload(payload, sid)

        frames_b64 = []
        for ch in chunks:
            frames_b64.append(qr_to_b64png(ch, box=8))

        ratio = json_sz / comp_sz if comp_sz else 0
        print(f"  ✓ {title:25s}  {len(html):>5d}B → {comp_sz:>5d}B ({ratio:.1f}:1)  {len(chunks)} frames")

        all_sequences.append({
            "title": title,
            "frames": frames_b64,
            "frame_count": len(chunks),
        })

    total_frames = sum(s["frame_count"] for s in all_sequences)
    print(f"\n  {len(all_sequences)} experiences · {total_frames} total frames\n")

    # Build the HTML — just QR codes cycling on a dark background
    # Each QR code auto-cycles its frames. That's it.
    seq_js_parts = []
    for seq in all_sequences:
        frames_arr = ",".join(f'"{b64}"' for b64 in seq["frames"])
        seq_js_parts.append(f'{{title:"{seq["title"]}",frames:[{frames_arr}]}}')

    sequences_js = ",\n".join(seq_js_parts)

    html_out = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Glyph QR Wall</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{
    background: #050508;
    min-height: 100vh;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    align-content: center;
    gap: 16px;
    padding: 16px;
}}
.qr {{
    position: relative;
    width: 220px;
    height: 220px;
    background: #0a0a12;
    border-radius: 12px;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
}}
.qr img {{
    width: 200px;
    height: 200px;
    image-rendering: pixelated;
    transition: opacity 0.08s;
}}
.qr .pip {{
    position: absolute;
    bottom: 6px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    gap: 3px;
}}
.qr .pip span {{
    width: 4px;
    height: 4px;
    border-radius: 50%;
    background: #333;
    transition: background 0.2s;
}}
.qr .pip span.on {{
    background: #66d9ff;
}}
</style>
</head>
<body>
<script>
const S = [
{sequences_js}
];

// Stagger start times so they don't all flip at the same instant
S.forEach((seq, si) => {{
    const el = document.createElement('div');
    el.className = 'qr';
    
    const img = document.createElement('img');
    img.src = 'data:image/png;base64,' + seq.frames[0];
    el.appendChild(img);
    
    // Dot pips showing which frame is active
    const pipRow = document.createElement('div');
    pipRow.className = 'pip';
    const dots = [];
    for (let i = 0; i < seq.frames.length; i++) {{
        const d = document.createElement('span');
        if (i === 0) d.className = 'on';
        pipRow.appendChild(d);
        dots.push(d);
    }}
    el.appendChild(pipRow);
    
    document.body.appendChild(el);
    
    let fi = 0;
    const delay = 300 + si * 70; // stagger
    
    setInterval(() => {{
        fi = (fi + 1) % seq.frames.length;
        img.src = 'data:image/png;base64,' + seq.frames[fi];
        dots.forEach((d, i) => d.className = i === fi ? 'on' : '');
    }}, delay);
}});
</script>
</body>
</html>"""

    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "qr_wall.html")
    with open(out_path, 'w') as f:
        f.write(html_out)
    print(f"📄 Saved to: {out_path}\n")

    # Serve it
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    print(f"🌐 Serving at:")
    try:
        local_ip = socket.gethostbyname(socket.gethostname())
    except Exception:
        local_ip = "localhost"
    print(f"   http://localhost:{PORT}")
    print(f"   http://{local_ip}:{PORT}")
    print(f"\n   {len(all_sequences)} experiences · {total_frames} QR frames cycling")
    print(f"   Press Ctrl+C to stop\n")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(html_out.encode('utf-8'))

        def log_message(self, format, *args):
            pass  # silent

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Stopped.")
            sys.exit(0)


if __name__ == "__main__":
    main()
