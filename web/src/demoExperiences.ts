/**
 * Demo experiences — pre-built HTML content matching Swift WebTemplateGenerator output.
 * Each demo showcases a different Glyph experience type.
 */

// ─── Trivia Quiz Demo ────────────────────────────────────────────────

export const TRIVIA_DEMO = {
  title: 'Glyph Knowledge Quiz',
  templateType: 'trivia',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Knowledge Quiz</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;align-items:center;
padding:24px;-webkit-user-select:none;user-select:none}
.hdr{text-align:center;margin-bottom:24px}
.hdr h1{font-size:2em;background:linear-gradient(135deg,#66d9ff,#9966ff);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#888;font-size:.9em;margin-top:4px}
.prog{display:flex;gap:4px;margin:16px 0;width:100%;max-width:360px}
.prog .dot{flex:1;height:4px;border-radius:2px;background:#1a1a2e;transition:background .3s}
.prog .dot.done{background:#66d9ff}
.prog .dot.cur{background:#9966ff}
.card{background:#12121e;border:1px solid #222;border-radius:20px;padding:28px 24px;
width:100%;max-width:360px;animation:slideIn .4s ease}
@keyframes slideIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
.q{font-size:1.2em;font-weight:600;line-height:1.5;margin-bottom:20px;color:#fff}
.qn{font-size:.75em;color:#66d9ff;font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px}
.opts{display:flex;flex-direction:column;gap:10px}
.opt{padding:14px 18px;background:#1a1a2e;border:1px solid #333;border-radius:14px;
font-size:1em;cursor:pointer;transition:all .2s;text-align:left;color:#e0e0e0;
-webkit-tap-highlight-color:transparent}
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
.btn:active{transform:scale(.97)}
.foot{color:#333;font-size:.7em;margin-top:auto;padding-top:24px;text-align:center}
</style>
</head>
<body>
<div class="hdr"><h1>Glyph Knowledge Quiz</h1><p>Delivered via Glyph \u00b7 No internet used</p></div>
<div class="prog" id="prog"></div>
<div id="stage"></div>
<div class="foot">Glyph \u00b7 Offline Experiences</div>
<script>
const Q=[{q:"What encryption does Glyph use?",a:["RSA-2048","AES-256-GCM","Blowfish","Triple DES"],c:1},{q:"What happens after a Glyph message timer expires?",a:["It gets archived","It self-destructs","It gets forwarded","Nothing"],c:1},{q:"How are Glyph messages transmitted?",a:["Bluetooth","Wi-Fi Direct","QR codes","NFC"],c:2},{q:"What does Glyph need from the cloud?",a:["Message storage","User accounts","Push notifications","Nothing at all"],c:3},{q:"What framework powers Glyph\\'s AI agents?",a:["OpenAI API","Apple NaturalLanguage","Google Gemini","Hugging Face"],c:1}];
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
let m=pct===100?'Perfect score!':pct>=70?'Nice work!':pct>=40?'Not bad!':'Keep trying!';
let h='<div class="result"><div class="score">'+sc+'/'+Q.length+'</div>';
h+='<div class="msg">'+m+'</div><div class="sub">'+pct+'% correct</div>';
h+='<button class="btn" onclick="cur=0;sc=0;show();">Play Again</button></div>';
document.getElementById('stage').innerHTML=h;
document.querySelectorAll('.dot').forEach(d=>d.className='dot done');}
init();
</script>
</body>
</html>`,
}

// ─── Article Demo ────────────────────────────────────────────────────

export const ARTICLE_DEMO = {
  title: 'The Future of Invisible Communication',
  templateType: 'article',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>The Future of Invisible Communication</title>
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
.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #222;
color:#444;font-size:.75em;font-family:-apple-system,system-ui,sans-serif}
.footer .glyph{color:#66d9ff}
</style>
</head>
<body>
<div class="header">
<h1>The Future of Invisible Communication</h1>
<p class="subtitle">Why vanishing messages are more honest than permanent ones</p>
<div class="author">by Glyph Labs</div>
<div class="badge">Delivered via Glyph \u00b7 No internet</div>
</div>
<article>
<h2>The Problem with Permanence</h2>
<p>Every message you send today is stored somewhere. On a server. In a database. Backed up to the cloud. Your words outlive the moment they were meant for.</p>
<p>We speak differently when we know we are being recorded. We self-censor. We perform. The knowledge that our words persist changes the words themselves.</p>
<h2>What If Messages Could Breathe?</h2>
<p>Glyph takes a different approach. Messages are encoded into QR codes \u2014 encrypted with AES-256-GCM, the same standard used by intelligence agencies. No server ever sees your content.</p>
<p>When scanned, a timer begins. 10 seconds. 30 seconds. Read once. Then the message is gone. Not deleted from a server \u2014 it was never on one. It simply ceases to exist.</p>
<h2>The QR Code Renaissance</h2>
<p>QR codes are having a moment, but not in the way anyone expected. Instead of linking to websites, they are becoming the medium itself. The entire message \u2014 encrypted, compressed, complete \u2014 lives inside the pattern of black and white squares.</p>
<p>No internet required. No accounts. No phone numbers. Just light, pattern, and proximity.</p>
<h2>What Comes Next</h2>
<p>Imagine classrooms where teachers send vanishing quiz questions. Concerts where artists drop exclusive content in the crowd. Conferences where speakers share slides that disappear after the talk.</p>
<p>The future of communication is not about storing more. It is about choosing what deserves to persist \u2014 and letting everything else vanish.</p>
</article>
<div class="footer">
<span class="glyph">Glyph</span><br>
This entire article was transmitted via QR codes.<br>No servers. No internet. Just light.
</div>
</body>
</html>`,
}

// ─── Adventure Demo ──────────────────────────────────────────────────

export const ADVENTURE_DEMO = {
  title: 'The Encrypted Door',
  templateType: 'adventure',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>The Encrypted Door</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;align-items:center;
justify-content:center;padding:24px;-webkit-user-select:none;user-select:none}
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
font-size:1em;cursor:pointer;transition:all .2s;color:#66d9ff;font-weight:600;
-webkit-tap-highlight-color:transparent}
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
<div class="hdr"><h1>The Encrypted Door</h1><p>An interactive story \u00b7 Delivered via Glyph</p></div>
<div id="stage"></div>
<div class="foot">Glyph \u00b7 Choose your path</div>
<script>
const N={"start":{t:"You find a door with a glowing QR code etched into its surface. The pattern pulses with cyan light. A timer above reads 00:30 and counting down.",c:[{l:"\ud83d\udcf1 Scan the QR code",t:"scan"},{l:"\ud83d\udd11 Look for a key",t:"key"},{l:"\ud83d\udeb6 Walk away",t:"walk"}]},"scan":{t:"Your phone decrypts the code: 'The password is the color of trust.' The door has a keypad with color names. The timer reads 00:18.",c:[{l:"\ud83d\udd35 Type BLUE",t:"blue"},{l:"\ud83d\udfe2 Type CYAN",t:"cyan"},{l:"\ud83d\udfe3 Type VIOLET",t:"violet"}]},"key":{t:"Behind a loose brick, you find a USB drive labeled 'GLYPH-KEY-256.' There is a port beside the door.",c:[{l:"\ud83d\udd0c Insert the drive",t:"usb"},{l:"\ud83d\udcf1 Scan the QR code instead",t:"scan"}]},"walk":{t:"You turn away, but the QR code projects onto the wall ahead of you. The message reads: 'You cannot unsee what was meant for your eyes only.' The door opens behind you.",c:[{l:"\ud83d\udeaa Enter the open door",t:"enter"},{l:"\ud83c\udfc3 Run",t:"run"}]},"cyan":{t:"The keypad glows cyan. The door slides open silently. Inside, a room filled with floating holographic messages \u2014 each one a vanishing glyph, visible for just seconds before dissolving into light. You have found the Archive of Moments.",c:[]},"blue":{t:"Wrong. The keypad flashes red. The QR code scrambles and reforms into a new pattern. The timer hits 00:00. The message self-destructs. The door remains sealed forever.",c:[]},"violet":{t:"Close, but wrong. The door emits a low hum and the QR code fades. A new message appears: 'Almost. Cyan is the color of connection.' You get one more chance.",c:[{l:"\ud83d\udfe2 Type CYAN",t:"cyan"},{l:"\ud83d\udeb6 Give up",t:"walk"}]},"usb":{t:"The drive contains a 256-bit encryption key. The door recognizes it instantly \u2014 AES-256-GCM authenticated. You hear gears turning. The door opens to reveal a garden where QR codes bloom like flowers, each containing a secret message.",c:[]},"enter":{t:"Inside is a mirror. In the reflection, you see yourself holding a phone, reading this very story. A message floats before you: 'Every message is a door. Every scan is a choice. Every moment vanishes.' The mirror cracks and you wake up.",c:[]},"run":{t:"You run, but the QR code follows \u2014 projected by moonlight through the trees. Finally you stop, breathless, and scan it. It reads simply: 'You were always meant to read this.' Then it vanishes.",c:[]}};
const start="start";
function go(id){
let n=N[id];if(!n){document.getElementById('stage').innerHTML='<div class="story"><div class="end"><div class="emoji">\u2726</div><p>The end.</p><button class="btn" onclick="go(\\''+start+'\\')">Start Over</button></div></div>';return;}
let h='<div class="story"><p>'+n.t+'</p>';
if(n.c.length===0){
h+='<div class="end"><div class="emoji">\u2726</div><p>The end.</p><button class="btn" onclick="go(\\''+start+'\\')">Start Over</button></div>';
}else{
h+='<div class="choices">';
n.c.forEach(c=>{h+='<div class="choice" onclick="go(\\''+c.t+'\\')">'+c.l+'</div>';});
h+='</div>';}
h+='</div>';
document.getElementById('stage').innerHTML=h;}
go(start);
</script>
</body>
</html>`,
}

// ─── Interactive Art Demo ────────────────────────────────────────────

export const ART_DEMO = {
  title: 'Glyph Particles',
  templateType: 'art',
  html: '',  // kept for reference, no longer used in ALL_DEMOS
}

// ─── Glyph Draw Demo (paused) ─────────────────────────────────────────
// Draw demo is preserved but removed from ALL_DEMOS.
// To re-enable: uncomment the draw entry in ALL_DEMOS at the bottom.

export const DRAW_DEMO = {
  title: 'Glyph Draw',
  templateType: 'game',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Draw</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;align-items:center;
padding:16px;-webkit-user-select:none;user-select:none;overflow-x:hidden}
.hdr{text-align:center;margin-bottom:8px}
.hdr h1{font-size:1.5em;background:linear-gradient(135deg,#66d9ff,#9966ff);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#888;font-size:.75em;margin-top:2px}
.word{text-align:center;font-size:2em;font-weight:800;color:#66d9ff;
text-transform:uppercase;letter-spacing:2px;margin:6px 0;
text-shadow:0 0 20px #66d9ff44}
.timer{text-align:center;font-size:1.1em;color:#9966ff;font-weight:700;margin-bottom:6px}
.timer.urgent{color:#ff4466;animation:pulse .5s infinite alternate}
@keyframes pulse{from{opacity:1}to{opacity:.5}}
.cw{position:relative;width:100%;max-width:340px;aspect-ratio:1}
canvas{width:100%;height:100%;border-radius:16px;border:2px solid #222;
background:#12121e;display:block;touch-action:none}
.tb{display:flex;gap:5px;align-items:center;justify-content:center;margin:8px 0;flex-wrap:wrap}
.cb{width:26px;height:26px;border-radius:50%;border:2px solid transparent;cursor:pointer}
.cb.act{border-color:#fff;transform:scale(1.15)}
.bb{width:32px;height:32px;border-radius:8px;background:#1a1a2e;border:1px solid #333;
display:flex;align-items:center;justify-content:center;cursor:pointer;color:#888;font-size:1em}
.bb.act{border-color:#66d9ff;color:#66d9ff}
.ab{padding:6px 10px;border-radius:8px;background:#1a1a2e;border:1px solid #333;
cursor:pointer;color:#888;font-size:.95em}
.done{margin:10px 0;padding:14px 48px;background:linear-gradient(135deg,#66d9ff,#9966ff);
color:#000;font-weight:700;border:none;border-radius:30px;font-size:1.05em;cursor:pointer}
.done:active{transform:scale(.97)}
.show-phase{display:flex;flex-direction:column;align-items:center;text-align:center;
animation:fadeUp .4s ease;width:100%}
@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
.show-phase h2{font-size:1.4em;color:#fff;margin-bottom:4px}
.show-phase p{color:#888;font-size:.85em;margin-bottom:16px}
.drawing-display{width:90%;max-width:320px;aspect-ratio:1;border-radius:16px;
border:3px solid #66d9ff;background:#12121e;overflow:hidden;
box-shadow:0 0 40px #66d9ff22}
.drawing-display img{width:100%;height:100%;object-fit:contain}
.secret{margin-top:12px;padding:10px 20px;background:#1a1a2e;border:1px solid #333;
border-radius:12px;font-size:.8em;color:#666}
.secret span{color:#9966ff;font-weight:700}
.retry{margin-top:16px;padding:12px 32px;background:#1a1a2e;border:1px solid #333;
color:#66d9ff;font-weight:600;border-radius:30px;font-size:.9em;cursor:pointer}
.retry:active{transform:scale(.97)}
.foot{color:#333;font-size:.65em;margin-top:auto;padding-top:12px;text-align:center}
</style>
</head>
<body>
<div class="hdr"><h1>Glyph Draw</h1><p>Draw it \u00b7 Show your screen \u00b7 AI guesses</p></div>
<div id="stage"></div>
<div class="foot">Glyph \u00b7 Delivered via QR</div>
<script>
const W=['sun','cat','house','tree','fish','star','heart','moon','boat','key','car','hat','eye','book','cup','bell','bird','flag','shoe','cake','dog','flower','cloud','rain','fire','pizza','apple','snake','robot','crown'];
const C=['#66d9ff','#9966ff','#ff4466','#44dd88','#ffaa33','#ffffff'];
const B=[3,6,12];
let word,strokes=[],cur=null,drawing=false,cc,cx,col=C[0],bsz=B[1],timer=45,tid;

function init(){
word=W[Math.floor(Math.random()*W.length)];
strokes=[];cur=null;timer=45;
let s=document.getElementById('stage');
let h='<div class="word" id="wd">Draw: '+word+'</div>';
h+='<div class="timer" id="tm">45s</div>';
h+='<div class="cw"><canvas id="cv" width="720" height="720"></canvas></div>';
h+='<div class="tb" id="tb">';
C.forEach((c,i)=>{h+='<div class="cb'+(i===0?' act':'')+'" style="background:'+c+'" onclick="pc('+i+',this)"></div>';});
h+='<span style="color:#333">|</span>';
B.forEach((b,i)=>{h+='<div class="bb'+(i===1?' act':'')+'" onclick="pb('+i+',this)"><span style="width:'+(b+2)+'px;height:'+(b+2)+'px;border-radius:50%;background:currentColor;display:block"></span></div>';});
h+='<span style="color:#333">|</span>';
h+='<div class="ab" onclick="undo()">\u21a9</div>';
h+='<div class="ab" onclick="clr()">\u2715</div>';
h+='</div>';
h+='<button class="done" onclick="fin()">Done Drawing</button>';
s.innerHTML=h;
cc=document.getElementById('cv');cx=cc.getContext('2d');
cc.addEventListener('touchstart',ts,{passive:false});
cc.addEventListener('touchmove',tm,{passive:false});
cc.addEventListener('touchend',te);
cc.addEventListener('mousedown',ms);
cc.addEventListener('mousemove',mm);
cc.addEventListener('mouseup',me);
startTimer();}

function startTimer(){
tid=setInterval(()=>{
timer--;
let el=document.getElementById('tm');
if(el){el.textContent=timer+'s';if(timer<=5)el.classList.add('urgent');}
if(timer<=0){clearInterval(tid);fin();}
},1000);}

function gp(e){let r=cc.getBoundingClientRect();let sx=720/r.width,sy=720/r.height;
if(e.touches){let t=e.touches[0];return{x:(t.clientX-r.left)*sx,y:(t.clientY-r.top)*sy};}
return{x:(e.clientX-r.left)*sx,y:(e.clientY-r.top)*sy};}

function ts(e){e.preventDefault();drawing=true;let p=gp(e);cur={pts:[p],c:col,w:bsz};}
function tm(e){e.preventDefault();if(!drawing||!cur)return;cur.pts.push(gp(e));redraw();}
function te(){if(cur)strokes.push(cur);cur=null;drawing=false;redraw();}
function ms(e){drawing=true;let p=gp(e);cur={pts:[p],c:col,w:bsz};}
function mm(e){if(!drawing||!cur)return;cur.pts.push(gp(e));redraw();}
function me(){if(cur)strokes.push(cur);cur=null;drawing=false;redraw();}

function redraw(){
cx.clearRect(0,0,720,720);cx.lineCap='round';cx.lineJoin='round';
let all=cur?[...strokes,cur]:strokes;
all.forEach(s=>{if(s.pts.length<2)return;cx.strokeStyle=s.c;cx.lineWidth=s.w;
cx.beginPath();cx.moveTo(s.pts[0].x,s.pts[0].y);
for(let i=1;i<s.pts.length;i++)cx.lineTo(s.pts[i].x,s.pts[i].y);cx.stroke();});}

function pc(i,el){col=C[i];document.querySelectorAll('.cb').forEach(e=>e.classList.remove('act'));el.classList.add('act');}
function pb(i,el){bsz=B[i];document.querySelectorAll('.bb').forEach(e=>e.classList.remove('act'));el.classList.add('act');}
function undo(){strokes.pop();redraw();}
function clr(){strokes=[];redraw();}

function fin(){
clearInterval(tid);
let dataUrl=cc.toDataURL('image/png');
let s=document.getElementById('stage');
let h='<div class="show-phase">';
h+='<h2>\ud83c\udfa8 Hold this up!</h2>';
h+='<p>Show your drawing to the website camera.<br>The AI will try to guess it!</p>';
h+='<div class="drawing-display"><img src="'+dataUrl+'" alt="Your drawing"/></div>';
h+='<div class="secret">The word was: <span>'+word+'</span></div>';
h+='<button class="retry" onclick="init()">\ud83c\udfaf Draw Again</button>';
h+='</div>';
s.innerHTML=h;}

init();
</script>
</body>
</html>`,
}

// ─── Void Runner Game Demo ────────────────────────────────────────────

export const VOID_RUNNER_DEMO = {
  title: 'VOID RUNNER',
  templateType: 'art',
  html: `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>VOID RUNNER</title>
<style>
*{margin:0;padding:0}
body{background:#000;overflow:hidden;touch-action:none;-webkit-user-select:none;user-select:none}
canvas{display:block}
#ui{position:fixed;top:0;left:0;right:0;pointer-events:none;padding:16px 20px;display:flex;justify-content:space-between;align-items:flex-start;font-family:-apple-system,system-ui,sans-serif;z-index:2}
#score{font-size:1.8em;font-weight:800;color:#66d9ff;text-shadow:0 0 20px #66d9ff66}
#hi{font-size:.75em;color:#9966ff88}
#lives{font-size:1.2em}
#menu{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;z-index:3;background:#000000ee}
#menu h1{font-size:2.4em;font-weight:900;font-family:-apple-system,system-ui,sans-serif;background:linear-gradient(135deg,#66d9ff,#9966ff,#ff66d9);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:4px}
#menu .sub{color:#888;font-size:.85em;font-family:-apple-system,system-ui,sans-serif;margin-bottom:32px}
#menu .go{padding:16px 48px;background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:800;font-size:1.1em;border:none;border-radius:30px;cursor:pointer;font-family:-apple-system,system-ui,sans-serif;pointer-events:auto}
#menu .tag{position:absolute;bottom:24px;color:#333;font-size:.7em;font-family:-apple-system,system-ui,sans-serif}
#over{display:none;position:fixed;inset:0;flex-direction:column;align-items:center;justify-content:center;z-index:3;background:#000000dd}
#over h2{font-size:2em;font-weight:800;color:#ff3366;font-family:-apple-system,system-ui,sans-serif;margin-bottom:8px}
#over .fs{font-size:3em;font-weight:900;background:linear-gradient(135deg,#66d9ff,#9966ff);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:12px 0}
#over .hs{color:#9966ff;font-size:.9em;margin-bottom:24px;font-family:-apple-system,system-ui,sans-serif}
#over .go{padding:14px 40px;background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;font-weight:800;font-size:1em;border:none;border-radius:30px;cursor:pointer;font-family:-apple-system,system-ui,sans-serif;pointer-events:auto}
</style>
</head>
<body>
<canvas id="c"></canvas>
<div id="ui"><div><div id="score">0</div><div id="hi"></div></div><div id="lives"></div></div>
<div id="menu"><h1>VOID RUNNER</h1><div class="sub">Dodge the void. Collect the light.</div><button class="go" onclick="start()">TAP TO PLAY</button><div class="tag">Delivered via Glyph</div></div>
<div id="over"><h2>VOID CONSUMED</h2><div class="fs" id="fs">0</div><div class="hs" id="hs"></div><button class="go" onclick="start()">PLAY AGAIN</button></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,dpr,player,obs,parts,orbs,score,lives,hi=0,frame,running,speed,trail,shake,combo,lastOrb;
function resize(){dpr=Math.min(window.devicePixelRatio||1,2);W=innerWidth;H=innerHeight;c.width=W*dpr;c.height=H*dpr;c.style.width=W+'px';c.style.height=H+'px';x.setTransform(dpr,0,0,dpr,0,0);}
resize();addEventListener('resize',resize);
function start(){
document.getElementById('menu').style.display='none';
document.getElementById('over').style.display='none';
resize();x.fillStyle='#000';x.fillRect(0,0,W,H);
player={x:W/2,y:H*0.75,r:10,tx:W/2};
obs=[];parts=[];orbs=[];trail=[];
score=0;lives=3;frame=0;speed=2;combo=1;lastOrb=0;shake=0;running=true;
updateUI();loop();
}
function updateUI(){
document.getElementById('score').textContent=score;
document.getElementById('lives').textContent=String.fromCharCode(9679).repeat(lives)+String.fromCharCode(9675).repeat(3-lives);
document.getElementById('hi').textContent=hi>0?'HI '+hi:'';
}
function gameOver(){
running=false;if(score>hi)hi=score;
document.getElementById('fs').textContent=score;
document.getElementById('hs').textContent=score>=hi&&hi>0?'NEW HIGH SCORE':'Best: '+hi;
document.getElementById('over').style.display='flex';
}
function spawnObs(){
let w=30+Math.random()*60;let side=Math.random()<0.5;
obs.push({x:side?-w:W+w,y:-20,w:w,h:14+Math.random()*10,
vx:side?(1+Math.random()*2):-(1+Math.random()*2),vy:speed+Math.random()*2,
color:Math.random()<0.3?'#ff3366':Math.random()<0.5?'#9966ff':'#334'});
}
function spawnOrb(){
orbs.push({x:40+Math.random()*(W-80),y:-20,r:6,vy:speed*0.8+1,pulse:0,
color:Math.random()<0.3?'#ff66d9':'#66d9ff'});
}
function boom(px,py,col,n){
for(let i=0;i<n;i++){let a=Math.random()*Math.PI*2,s=1+Math.random()*4;
parts.push({x:px,y:py,vx:Math.cos(a)*s,vy:Math.sin(a)*s,
r:1+Math.random()*2,life:1,decay:.02+Math.random()*.03,color:col});}
}
function loop(){
if(!running)return;requestAnimationFrame(loop);frame++;
speed=2+frame*0.002;
if(frame%Math.max(10,40-Math.floor(frame/200))===0)spawnObs();
if(frame%70===0)spawnOrb();
player.x+=(player.tx-player.x)*0.12;
player.x=Math.max(player.r,Math.min(W-player.r,player.x));
trail.push({x:player.x,y:player.y,life:1});
if(trail.length>20)trail.shift();
for(let i=obs.length-1;i>=0;i--){
let o=obs[i];o.x+=o.vx;o.y+=o.vy;
if(o.y>H+50){obs.splice(i,1);continue;}
if(player.y>o.y-o.h/2-player.r&&player.y<o.y+o.h/2+player.r&&
player.x>o.x-o.w/2-player.r&&player.x<o.x+o.w/2+player.r){
boom(player.x,player.y,'#ff3366',20);shake=8;combo=1;lives--;updateUI();
obs.splice(i,1);if(lives<=0){gameOver();return;}}}
for(let i=orbs.length-1;i>=0;i--){
let o=orbs[i];o.y+=o.vy;o.pulse+=0.1;
if(o.y>H+30){orbs.splice(i,1);combo=1;continue;}
let dx=player.x-o.x,dy=player.y-o.y,dist=Math.sqrt(dx*dx+dy*dy);
if(dist<player.r+o.r+4){
let pts=10*combo;score+=pts;combo=Math.min(combo+1,8);lastOrb=frame;
boom(o.x,o.y,o.color,12);orbs.splice(i,1);updateUI();}}
for(let i=parts.length-1;i>=0;i--){
let p=parts[i];p.x+=p.vx;p.y+=p.vy;p.vy+=0.05;p.life-=p.decay;
if(p.life<=0)parts.splice(i,1);}
let sx=0,sy=0;
if(shake>0){sx=(Math.random()-.5)*shake;sy=(Math.random()-.5)*shake;shake*=0.8;if(shake<0.5)shake=0;}
x.save();x.translate(sx,sy);
x.fillStyle='rgba(0,0,0,0.15)';x.fillRect(0,0,W,H);
for(let i=0;i<3;i++){let sx2=Math.random()*W,sy2=Math.random()*H;
x.globalAlpha=0.3;x.strokeStyle='#224';x.lineWidth=0.5;
x.beginPath();x.moveTo(sx2,sy2);x.lineTo(sx2,sy2+10+speed*3);x.stroke();}
x.globalAlpha=1;
obs.forEach(o=>{x.fillStyle=o.color;x.shadowColor=o.color;x.shadowBlur=o.color==='#334'?0:15;
x.beginPath();x.rect(o.x-o.w/2,o.y-o.h/2,o.w,o.h);x.fill();x.shadowBlur=0;});
orbs.forEach(o=>{let s=1+Math.sin(o.pulse)*0.2;
x.globalAlpha=0.15;x.fillStyle=o.color;x.beginPath();x.arc(o.x,o.y,o.r*3*s,0,Math.PI*2);x.fill();
x.globalAlpha=0.4;x.beginPath();x.arc(o.x,o.y,o.r*1.8*s,0,Math.PI*2);x.fill();
x.globalAlpha=1;x.fillStyle=o.color;x.shadowColor=o.color;x.shadowBlur=12;
x.beginPath();x.arc(o.x,o.y,o.r*s,0,Math.PI*2);x.fill();x.shadowBlur=0;});
trail.forEach((t,i)=>{let a=i/trail.length;x.globalAlpha=a*0.3;
x.fillStyle=combo>3?'#ff66d9':combo>1?'#9966ff':'#66d9ff';
x.beginPath();x.arc(t.x,t.y,player.r*a*0.6,0,Math.PI*2);x.fill();t.life-=0.05;});
x.globalAlpha=1;
let pc=combo>3?'#ff66d9':combo>1?'#9966ff':'#66d9ff';
x.fillStyle=pc;x.shadowColor=pc;x.shadowBlur=20;
x.beginPath();x.arc(player.x,player.y,player.r,0,Math.PI*2);x.fill();
x.fillStyle='#fff';x.shadowBlur=0;
x.beginPath();x.arc(player.x,player.y,player.r*0.4,0,Math.PI*2);x.fill();
if(frame-lastOrb<15){x.globalAlpha=(15-(frame-lastOrb))/15*0.5;
x.strokeStyle=pc;x.lineWidth=2;
x.beginPath();x.arc(player.x,player.y,player.r+8+(frame-lastOrb),0,Math.PI*2);x.stroke();x.globalAlpha=1;}
parts.forEach(p=>{x.globalAlpha=p.life;x.fillStyle=p.color;
x.beginPath();x.arc(p.x,p.y,p.r*p.life,0,Math.PI*2);x.fill();});
x.globalAlpha=1;
if(combo>1){x.globalAlpha=0.7;x.fillStyle=pc;
x.font='bold 14px -apple-system,system-ui,sans-serif';x.textAlign='center';
x.fillText(combo+'x COMBO',player.x,player.y-24);x.globalAlpha=1;}
x.restore();
}
let touching=false;
function mv(px){if(running&&player)player.tx=px;}
c.addEventListener('touchstart',e=>{e.preventDefault();touching=true;mv(e.touches[0].clientX);},{passive:false});
c.addEventListener('touchmove',e=>{e.preventDefault();if(touching)mv(e.touches[0].clientX);},{passive:false});
c.addEventListener('touchend',()=>{touching=false;});
c.addEventListener('mousemove',e=>{if(e.buttons)mv(e.clientX);});
c.addEventListener('mousedown',e=>{mv(e.clientX);});
if(window.DeviceOrientationEvent){addEventListener('deviceorientation',e=>{
if(running&&player&&e.gamma!=null){player.tx=W/2+e.gamma*(W/90);}});}
</script>
</body>
</html>`,
}

// ─── Drift Game Demo ──────────────────────────────────────────────────

export const DRIFT_DEMO = {
  title: 'DRIFT',
  templateType: 'art',
  html: `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>DRIFT</title>
<style>
*{margin:0;padding:0}
body{background:#0a0a14;overflow:hidden;touch-action:none;-webkit-user-select:none;user-select:none}
canvas{display:block}
#menu{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;z-index:3;background:#0a0a14}
#menu h1{font-size:3em;font-weight:900;font-family:-apple-system,system-ui,sans-serif;background:linear-gradient(135deg,#4af,#a6f,#f4a);-webkit-background-clip:text;-webkit-text-fill-color:transparent;letter-spacing:4px}
#menu .sub{color:#556;font-size:.85em;font-family:-apple-system,system-ui,sans-serif;margin:8px 0 28px}
#menu .go{padding:14px 44px;background:linear-gradient(135deg,#4af,#a6f);color:#000;font-weight:800;font-size:1.1em;border:none;border-radius:30px;cursor:pointer;font-family:-apple-system,system-ui,sans-serif;pointer-events:auto}
#menu .tag{position:absolute;bottom:24px;color:#222;font-size:.7em;font-family:-apple-system,system-ui,sans-serif}
#menu .inst{color:#778;font-size:.8em;font-family:-apple-system,system-ui,sans-serif;margin-bottom:20px;text-align:center;line-height:1.6}
#over{display:none;position:fixed;inset:0;flex-direction:column;align-items:center;justify-content:center;z-index:3;background:#0a0a14dd}
#over h2{font-size:1.8em;font-weight:800;color:#f46;font-family:-apple-system,system-ui,sans-serif;margin-bottom:4px}
#over .fs{font-size:3.5em;font-weight:900;background:linear-gradient(135deg,#4af,#a6f);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin:8px 0}
#over .det{color:#667;font-size:.85em;font-family:-apple-system,system-ui,sans-serif;margin-bottom:20px}
#over .go{padding:12px 36px;background:linear-gradient(135deg,#4af,#a6f);color:#000;font-weight:800;font-size:1em;border:none;border-radius:30px;cursor:pointer;font-family:-apple-system,system-ui,sans-serif;pointer-events:auto}
</style>
</head>
<body>
<canvas id="c"></canvas>
<div id="menu">
<h1>D R I F T</h1>
<div class="sub">A micro-platformer</div>
<div class="inst">Tap to jump / Hold to drift-float / Collect crystals / Dodge hazards</div>
<button class="go" onclick="go()">PLAY</button>
<div class="tag">Delivered via Glyph</div>
</div>
<div id="over"><h2>GAME OVER</h2><div class="fs" id="fs">0</div><div class="det" id="det"></div><button class="go" onclick="go()">RETRY</button></div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,dpr;
function resize(){dpr=Math.min(devicePixelRatio||1,2);W=innerWidth;H=innerHeight;c.width=W*dpr;c.height=H*dpr;c.style.width=W+'px';c.style.height=H+'px';x.setTransform(dpr,0,0,dpr,0,0);}
resize();addEventListener('resize',resize);
let P,cam,plats,crystals,hazards,parts,bg,score,dist,hp,chain,chainT,hi=0,run2=false,hold=false,grav,drift,fr;
const TS=32,G=0.55,JMP=-11,DRIFT_G=0.08,SPD=3;
const C1='#4af',C2='#a6f',C3='#f4a',C4='#4fa';
function go(){
document.getElementById('menu').style.display='none';
document.getElementById('over').style.display='none';
resize();x.fillStyle='#0a0a14';x.fillRect(0,0,W,H);
cam={x:0,y:0};score=0;dist=0;hp=3;chain=1;chainT=0;fr=0;
P={x:80,y:H-120,vy:0,onG:false,r:8,jumps:0};
plats=[];crystals=[];hazards=[];parts=[];
bg=[];for(let i=0;i<40;i++)bg.push({x:Math.random()*W*3,y:Math.random()*H,s:Math.random()*3+1,a:Math.random()*.15+.05,c:i%3===0?C2:C1});
genChunk(0);genChunk(W);genChunk(W*2);
plats.push({x:-100,y:H-40,w:W+200,h:30,t:'ground'});
run2=true;loop();
}
function genChunk(startX){
let y=H-80;
for(let i=0;i<6;i++){
let px=startX+80+i*100+Math.random()*40;
let py=y-Math.random()*120;
let pw=50+Math.random()*60;
let t=Math.random()<.15?'bounce':Math.random()<.1?'crumble':'solid';
plats.push({x:px,y:py,w:pw,h:10,t:t,life:1});
if(Math.random()<.5)crystals.push({x:px+pw/2,y:py-30,r:6,pulse:Math.random()*6,got:false});
if(i>1&&Math.random()<.25)hazards.push({x:px+pw/2,y:py-12,w:pw*.6,h:8});
y=py;}
}
function boom(bx,by,col,n){for(let i=0;i<n;i++){let a=Math.random()*Math.PI*2,s=1+Math.random()*3;parts.push({x:bx,y:by,vx:Math.cos(a)*s,vy:Math.sin(a)*s,r:1+Math.random()*2,life:1,d:.02+Math.random()*.03,c:col});}}
function loop(){
if(!run2)return;requestAnimationFrame(loop);fr++;let dt=1;
if(hold&&P.vy>0)P.vy+=DRIFT_G;else P.vy+=G;
if(P.vy>14)P.vy=14;P.y+=P.vy;
let spd=SPD+dist*0.0003;cam.x+=spd;P.x+=spd;dist+=spd;
P.onG=false;
for(let i=plats.length-1;i>=0;i--){
let pl=plats[i];
if(pl.t==='crumble'&&pl.life<=0){plats.splice(i,1);continue;}
if(pl.x+pl.w<cam.x-100&&pl.t!=='ground'){plats.splice(i,1);continue;}
if(P.vy>=0&&P.x>pl.x-4&&P.x<pl.x+pl.w+4&&P.y+P.r>=pl.y&&P.y+P.r<=pl.y+pl.h+P.vy+2){
P.y=pl.y-P.r;P.vy=0;P.onG=true;P.jumps=0;
if(pl.t==='bounce'){P.vy=JMP*1.4;chain++;chainT=0;boom(P.x,P.y,C4,6);}
if(pl.t==='crumble'){pl.life-=0.02;}}}
for(let i=crystals.length-1;i>=0;i--){
let cr=crystals[i];
if(cr.got){crystals.splice(i,1);continue;}
if(cr.x<cam.x-100){crystals.splice(i,1);continue;}
let dx=P.x-cr.x,dy=P.y-cr.y;
if(Math.sqrt(dx*dx+dy*dy)<P.r+cr.r+4){
cr.got=true;score+=10*chain;chainT=0;if(chain<8)chain++;boom(cr.x,cr.y,C1,8);}}
for(let i=hazards.length-1;i>=0;i--){
let hz=hazards[i];
if(hz.x+hz.w<cam.x-100){hazards.splice(i,1);continue;}
if(P.x>hz.x-P.r&&P.x<hz.x+hz.w+P.r&&P.y+P.r>hz.y&&P.y-P.r<hz.y+hz.h){
hp--;chain=1;boom(P.x,P.y,'#f46',15);P.vy=JMP*0.5;hazards.splice(i,1);
if(hp<=0){die();return;}}}
chainT+=dt;if(chainT>120)chain=1;
if(P.y>cam.y+H+100){die();return;}
let rightEdge=plats.reduce((m,p)=>Math.max(m,p.x+p.w),0);
if(rightEdge<cam.x+W*2)genChunk(rightEdge+60);
for(let i=parts.length-1;i>=0;i--){let p=parts[i];p.x+=p.vx;p.y+=p.vy;p.vy+=.04;p.life-=p.d;if(p.life<=0)parts.splice(i,1);}
let ox=cam.x,oy=cam.y;
x.fillStyle='#0a0a14';x.fillRect(0,0,W,H);
bg.forEach(b=>{x.globalAlpha=b.a;x.fillStyle=b.c;
let bx=(b.x-ox*b.s*.1)%W;if(bx<0)bx+=W;
x.beginPath();x.arc(bx,b.y,b.s,0,Math.PI*2);x.fill();});
x.globalAlpha=1;
plats.forEach(pl=>{let px=pl.x-ox,py=pl.y-oy;
if(px>W+50||px+pl.w<-50)return;
if(pl.t==='ground'){x.fillStyle='#1a1a2e';x.fillRect(px,py,pl.w,pl.h);}
else if(pl.t==='bounce'){x.fillStyle=C4;x.shadowColor=C4;x.shadowBlur=8;x.fillRect(px,py,pl.w,pl.h);x.shadowBlur=0;}
else if(pl.t==='crumble'){x.globalAlpha=pl.life;x.fillStyle='#664';x.fillRect(px,py,pl.w,pl.h);x.globalAlpha=1;}
else{x.fillStyle='#2a2a3e';x.fillRect(px,py,pl.w,pl.h);x.fillStyle='#3a3a5e';x.fillRect(px,py,pl.w,2);}});
hazards.forEach(hz=>{let hx=hz.x-ox,hy=hz.y-oy;
if(hx>W+20||hx+hz.w<-20)return;
x.fillStyle='#f46';x.shadowColor='#f46';x.shadowBlur=6;
for(let i=0;i<hz.w;i+=8){x.beginPath();x.moveTo(hx+i,hy+hz.h);x.lineTo(hx+i+4,hy);x.lineTo(hx+i+8,hy+hz.h);x.fill();}
x.shadowBlur=0;});
crystals.forEach(cr=>{if(cr.got)return;
let cx=cr.x-ox,cy=cr.y-oy;if(cx>W+20||cx<-20)return;
cr.pulse+=.08;let s=1+Math.sin(cr.pulse)*.15;
x.globalAlpha=.12;x.fillStyle=C1;x.beginPath();x.arc(cx,cy,cr.r*3*s,0,Math.PI*2);x.fill();
x.globalAlpha=1;x.fillStyle=C1;x.shadowColor=C1;x.shadowBlur=10;
x.beginPath();x.moveTo(cx,cy-cr.r*s);x.lineTo(cx+cr.r*.7*s,cy);x.lineTo(cx,cy+cr.r*s);x.lineTo(cx-cr.r*.7*s,cy);x.closePath();x.fill();
x.shadowBlur=0;});
let px=P.x-ox,py=P.y-oy;
let pc=chain>4?C3:chain>2?C2:C1;
if(fr%2===0)parts.push({x:P.x,y:P.y+P.r,vx:(Math.random()-.5)*.5,vy:.5,r:2,life:.6,d:.03,c:pc});
if(hold&&!P.onG){x.globalAlpha=.2;x.fillStyle=pc;x.beginPath();x.arc(px,py,P.r*3,0,Math.PI*2);x.fill();x.globalAlpha=1;}
x.fillStyle=pc;x.shadowColor=pc;x.shadowBlur=16;
x.beginPath();x.arc(px,py,P.r,0,Math.PI*2);x.fill();
x.fillStyle='#fff';x.shadowBlur=0;
x.beginPath();x.arc(px,py,P.r*.35,0,Math.PI*2);x.fill();
parts.forEach(p=>{let ppx=p.x-ox,ppy=p.y-oy;
x.globalAlpha=p.life;x.fillStyle=p.c;
x.beginPath();x.arc(ppx,ppy,p.r*p.life,0,Math.PI*2);x.fill();});
x.globalAlpha=1;
x.font='bold 20px -apple-system,system-ui,sans-serif';x.textAlign='left';
for(let i=0;i<3;i++){x.fillStyle=i<hp?'#f46':'#333';x.fillText(String.fromCharCode(9679),16+i*24,32);}
x.fillStyle='#fff';x.textAlign='center';x.fillText(score,W/2,32);
x.fillStyle='#556';x.font='12px -apple-system,system-ui,sans-serif';
x.fillText(Math.floor(dist/10)+'m',W/2,48);
if(chain>1){x.fillStyle=pc;x.font='bold 16px -apple-system,system-ui,sans-serif';x.fillText('x'+chain,W/2,66);}
if(hi>0){x.fillStyle='#336';x.font='11px -apple-system,system-ui,sans-serif';x.textAlign='right';x.fillText('HI '+hi,W-16,32);}
}
function die(){
run2=false;if(score>hi)hi=score;boom(P.x,P.y,'#f46',25);
let pf=0;function deathAnim(){if(pf++>30){
document.getElementById('fs').textContent=score;
document.getElementById('det').textContent=Math.floor(dist/10)+'m - Best: '+hi;
document.getElementById('over').style.display='flex';return;}
requestAnimationFrame(deathAnim);
x.fillStyle='rgba(10,10,20,0.1)';x.fillRect(0,0,W,H);
parts.forEach(p=>{p.x+=p.vx;p.y+=p.vy;p.vy+=.04;p.life-=p.d;
if(p.life>0){x.globalAlpha=p.life;x.fillStyle=p.c;x.beginPath();x.arc(p.x-cam.x,p.y-cam.y,p.r*p.life,0,Math.PI*2);x.fill();}});
x.globalAlpha=1;}deathAnim();
}
c.addEventListener('touchstart',e=>{e.preventDefault();hold=true;if(run2&&P){if(P.onG||P.jumps<2){P.vy=JMP;P.jumps++;P.onG=false;}}},{passive:false});
c.addEventListener('touchend',e=>{hold=false;},{passive:false});
c.addEventListener('mousedown',e=>{hold=true;if(run2&&P){if(P.onG||P.jumps<2){P.vy=JMP;P.jumps++;P.onG=false;}}});
c.addEventListener('mouseup',()=>{hold=false;});
addEventListener('keydown',e=>{if(e.code==='Space'&&!e.repeat){hold=true;if(run2&&P){if(P.onG||P.jumps<2){P.vy=JMP;P.jumps++;P.onG=false;}}}});
addEventListener('keyup',e=>{if(e.code==='Space')hold=false;});
</script>
</body>
</html>`,
}

// ─── All Demos ────────────────────────────────────────────────────────

export interface DemoExperience {
  id: string
  title: string
  icon: string
  description: string
  templateType: string
  html: string
  estimatedFrames: string
}

// ─── Live Translation Demo ───────────────────────────────────────────

export const TRANSLATION_DEMO = {
  title: 'Glyph Translate',
  templateType: 'translate',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Translate</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;
-webkit-user-select:none;user-select:none;overflow-x:hidden}
.hdr{text-align:center;padding:16px 16px 8px}
.hdr h1{font-size:1.5em;background:linear-gradient(135deg,#66d9ff,#44dd88);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#666;font-size:.7em;margin-top:2px}
.lang-bar{display:flex;align-items:center;gap:8px;padding:8px 16px;background:#12121e;
border-top:1px solid #1a1a2e;border-bottom:1px solid #1a1a2e}
.lang-sel{flex:1;display:flex;flex-direction:column;gap:2px}
.lang-sel label{font-size:.65em;color:#888;text-transform:uppercase;letter-spacing:1px}
.lang-sel select{background:#1a1a2e;color:#fff;border:1px solid #333;border-radius:10px;
padding:8px 10px;font-size:.9em;font-family:inherit;-webkit-appearance:none;appearance:none;
background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='%23888'%3E%3Cpath d='M2 4l4 4 4-4'/%3E%3C/svg%3E");
background-repeat:no-repeat;background-position:right 10px center}
.swap-btn{width:36px;height:36px;border-radius:50%;background:#1a1a2e;border:1px solid #333;
color:#66d9ff;font-size:1.2em;cursor:pointer;display:flex;align-items:center;justify-content:center;
margin-top:12px;transition:transform .2s}
.swap-btn:active{transform:rotate(180deg)}
.chat{flex:1;overflow-y:auto;padding:12px 16px;display:flex;flex-direction:column;gap:8px;
-webkit-overflow-scrolling:touch}
.msg{max-width:85%;padding:10px 14px;border-radius:16px;animation:msgIn .3s ease}
@keyframes msgIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.msg.a{align-self:flex-start;background:#1a2a3e;border:1px solid #2a3a4e;border-bottom-left-radius:4px}
.msg.b{align-self:flex-end;background:#2a1a3e;border:1px solid #3a2a4e;border-bottom-right-radius:4px}
.msg .orig{font-size:.95em;line-height:1.4;color:#fff}
.msg .trans{font-size:.85em;line-height:1.3;color:#44dd88;margin-top:4px;padding-top:4px;
border-top:1px solid rgba(68,221,136,.15);font-style:italic}
.msg .lang-tag{font-size:.6em;color:#888;margin-top:2px}
.input-bar{display:flex;gap:8px;padding:12px 16px;background:#12121e;border-top:1px solid #1a1a2e}
.speaker-toggle{display:flex;border-radius:20px;overflow:hidden;border:1px solid #333;flex-shrink:0}
.speaker-toggle button{padding:8px 12px;background:#1a1a2e;border:none;color:#888;
font-size:.8em;font-weight:600;cursor:pointer;transition:all .2s}
.speaker-toggle button.active-a{background:#1a2a3e;color:#66d9ff}
.speaker-toggle button.active-b{background:#2a1a3e;color:#9966ff}
.msg-input{flex:1;background:#1a1a2e;border:1px solid #333;border-radius:20px;padding:10px 14px;
color:#fff;font-size:.95em;font-family:inherit;outline:none;resize:none;min-height:40px;max-height:80px}
.msg-input:focus{border-color:#66d9ff44}
.send-btn{width:40px;height:40px;border-radius:50%;border:none;cursor:pointer;
font-size:1.1em;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:transform .1s}
.send-btn:active{transform:scale(.9)}
.send-btn.a{background:linear-gradient(135deg,#66d9ff,#44dd88);color:#000}
.send-btn.b{background:linear-gradient(135deg,#9966ff,#ff66d9);color:#000}
.empty{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
text-align:center;padding:40px;color:#444}
.empty .icon{font-size:3em;margin-bottom:12px}
.empty p{font-size:.85em;line-height:1.5}
.phrase-bar{display:flex;gap:6px;padding:4px 16px 8px;overflow-x:auto;-webkit-overflow-scrolling:touch}
.phrase-bar::-webkit-scrollbar{display:none}
.phrase{padding:6px 12px;background:#1a1a2e;border:1px solid #333;border-radius:16px;
font-size:.75em;color:#aaa;white-space:nowrap;cursor:pointer;transition:all .2s;flex-shrink:0}
.phrase:active{background:#66d9ff22;border-color:#66d9ff;color:#66d9ff}
.foot{text-align:center;padding:6px;color:#222;font-size:.6em}
</style>
</head>
<body>
<div class="hdr"><h1>\u{1F310} Glyph Translate</h1><p>Offline multilingual conversation \u00b7 Delivered via Glyph</p></div>
<div class="lang-bar">
<div class="lang-sel">
<label>Person A</label>
<select id="langA" onchange="updatePhrases()">
<option value="en">English</option>
<option value="es">Espa\u00f1ol</option>
<option value="fr">Fran\u00e7ais</option>
<option value="de">Deutsch</option>
<option value="it">Italiano</option>
<option value="pt">Portugu\u00eas</option>
<option value="ja">\u65e5\u672c\u8a9e</option>
<option value="ko">\ud55c\uad6d\uc5b4</option>
<option value="zh">\u4e2d\u6587</option>
<option value="ar">\u0627\u0644\u0639\u0631\u0628\u064a\u0629</option>
<option value="hi">\u0939\u093f\u0928\u094d\u0926\u0940</option>
<option value="ru">\u0420\u0443\u0441\u0441\u043a\u0438\u0439</option>
<option value="sw">Kiswahili</option>
<option value="tr">T\u00fcrk\u00e7e</option>
<option value="vi">Ti\u1ebfng Vi\u1ec7t</option>
<option value="th">\u0e44\u0e17\u0e22</option>
<option value="pl">Polski</option>
<option value="uk">\u0423\u043a\u0440\u0430\u0457\u043d\u0441\u044c\u043a\u0430</option>
<option value="nl">Nederlands</option>
<option value="el">\u0395\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac</option>
<option value="he">\u05e2\u05d1\u05e8\u05d9\u05ea</option>
<option value="id">Bahasa Indonesia</option>
<option value="ms">Bahasa Melayu</option>
<option value="tl">Tagalog</option>
<option value="ro">Rom\u00e2n\u0103</option>
<option value="bn">\u09ac\u09be\u0982\u09b2\u09be</option>
<option value="ta">\u0ba4\u0bae\u0bbf\u0bb4\u0bcd</option>
<option value="ur">\u0627\u0631\u062f\u0648</option>
<option value="fa">\u0641\u0627\u0631\u0633\u06cc</option>
<option value="am">\u12a0\u121b\u122d\u129b</option>
<option value="yo">Yor\u00f9b\u00e1</option>
<option value="zu">isiZulu</option>
<option value="ha">Hausa</option>
<option value="ig">Igbo</option>
<option value="rw">Kinyarwanda</option>
<option value="mg">Malagasy</option>
<option value="so">Soomaali</option>
<option value="ne">\u0928\u0947\u092a\u093e\u0932\u0940</option>
<option value="my">\u1019\u103c\u1014\u103a\u1019\u102c</option>
<option value="km">\u1781\u17d2\u1798\u17c2\u179a</option>
<option value="lo">\u0ea5\u0eb2\u0ea7</option>
<option value="ka">\u10e5\u10d0\u10e0\u10d7\u10e3\u10da\u10d8</option>
<option value="hy">\u0540\u0561\u0575\u0565\u0580\u0565\u0576</option>
<option value="mn">\u041c\u043e\u043d\u0433\u043e\u043b</option>
<option value="qu">Quechua</option>
<option value="ay">Aymara</option>
<option value="gn">Ava\u00f1e\\'e\u1ebd</option>
<option value="mi">Te Reo M\u0101ori</option>
<option value="haw">\u02bbOlelo Hawai\u02bbi</option>
<option value="sm">Gagana S\u0101moa</option>
</select>
</div>
<button class="swap-btn" onclick="swapLangs()">\u21c4</button>
<div class="lang-sel">
<label>Person B</label>
<select id="langB" onchange="updatePhrases()">
<option value="es" selected>Espa\u00f1ol</option>
<option value="en">English</option>
<option value="fr">Fran\u00e7ais</option>
<option value="de">Deutsch</option>
<option value="it">Italiano</option>
<option value="pt">Portugu\u00eas</option>
<option value="ja">\u65e5\u672c\u8a9e</option>
<option value="ko">\ud55c\uad6d\uc5b4</option>
<option value="zh">\u4e2d\u6587</option>
<option value="ar">\u0627\u0644\u0639\u0631\u0628\u064a\u0629</option>
<option value="hi">\u0939\u093f\u0928\u094d\u0926\u0940</option>
<option value="ru">\u0420\u0443\u0441\u0441\u043a\u0438\u0439</option>
<option value="sw">Kiswahili</option>
<option value="tr">T\u00fcrk\u00e7e</option>
<option value="vi">Ti\u1ebfng Vi\u1ec7t</option>
<option value="th">\u0e44\u0e17\u0e22</option>
<option value="pl">Polski</option>
<option value="uk">\u0423\u043a\u0440\u0430\u0457\u043d\u0441\u044c\u043a\u0430</option>
<option value="nl">Nederlands</option>
<option value="el">\u0395\u03bb\u03bb\u03b7\u03bd\u03b9\u03ba\u03ac</option>
<option value="he">\u05e2\u05d1\u05e8\u05d9\u05ea</option>
<option value="id">Bahasa Indonesia</option>
<option value="ms">Bahasa Melayu</option>
<option value="tl">Tagalog</option>
<option value="ro">Rom\u00e2n\u0103</option>
<option value="bn">\u09ac\u09be\u0982\u09b2\u09be</option>
<option value="ta">\u0ba4\u0bae\u0bbf\u0bb4\u0bcd</option>
<option value="ur">\u0627\u0631\u062f\u0648</option>
<option value="fa">\u0641\u0627\u0631\u0633\u06cc</option>
<option value="am">\u12a0\u121b\u122d\u129b</option>
<option value="yo">Yor\u00f9b\u00e1</option>
<option value="zu">isiZulu</option>
<option value="ha">Hausa</option>
<option value="ig">Igbo</option>
<option value="rw">Kinyarwanda</option>
<option value="mg">Malagasy</option>
<option value="so">Soomaali</option>
<option value="ne">\u0928\u0947\u092a\u093e\u0932\u0940</option>
<option value="my">\u1019\u103c\u1014\u103a\u1019\u102c</option>
<option value="km">\u1781\u17d2\u1798\u17c2\u179a</option>
<option value="lo">\u0ea5\u0eb2\u0ea7</option>
<option value="ka">\u10e5\u10d0\u10e0\u10d7\u10e3\u10da\u10d8</option>
<option value="hy">\u0540\u0561\u0575\u0565\u0580\u0565\u0576</option>
<option value="mn">\u041c\u043e\u043d\u0433\u043e\u043b</option>
<option value="qu">Quechua</option>
<option value="ay">Aymara</option>
<option value="gn">Ava\u00f1e\\'e\u1ebd</option>
<option value="mi">Te Reo M\u0101ori</option>
<option value="haw">\u02bbOlelo Hawai\u02bbi</option>
<option value="sm">Gagana S\u0101moa</option>
</select>
</div>
</div>
<div class="phrase-bar" id="phrases"></div>
<div class="chat" id="chat">
<div class="empty"><div class="icon">\u{1F310}</div><p>Pick two languages above, then type or tap a phrase below.<br>Each message shows the original + translation.<br><strong>100% offline \u2014 no internet needed.</strong></p></div>
</div>
<div class="input-bar">
<div class="speaker-toggle">
<button id="btnA" class="active-a" onclick="setSpeaker('a')">A</button>
<button id="btnB" onclick="setSpeaker('b')">B</button>
</div>
<textarea class="msg-input" id="inp" rows="1" placeholder="Type a message..." onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();send()}"></textarea>
<button class="send-btn a" id="sendBtn" onclick="send()">\u2191</button>
</div>
<div class="foot">Glyph Translate \u00b7 Offline \u00b7 Encrypted delivery</div>
<script>
var speaker='a',msgs=[];
var D={
en:{hello:"Hello",thanks:"Thank you",yes:"Yes",no:"No",please:"Please",sorry:"Sorry",goodbye:"Goodbye",help:"Help",how_are_you:"How are you?",my_name_is:"My name is...",i_dont_understand:"I don't understand",where_is:"Where is...?",how_much:"How much?",water:"Water",food:"Food",hospital:"Hospital",police:"Police",bathroom:"Bathroom?",left:"Left",right:"Right",straight:"Straight ahead",today:"Today",tomorrow:"Tomorrow",friend:"Friend",welcome:"Welcome",love:"Love",peace:"Peace",beautiful:"Beautiful",danger:"Danger",emergency:"Emergency",thank_you_very_much:"Thank you very much",nice_to_meet_you:"Nice to meet you",speak_slowly:"Please speak slowly",repeat:"Can you repeat?",agree:"I agree",disagree:"I disagree",maybe:"Maybe",later:"Later",now:"Now",family:"Family",home:"Home",work:"Work",happy:"Happy",sad:"Sad"},
es:{hello:"Hola",thanks:"Gracias",yes:"S\u00ed",no:"No",please:"Por favor",sorry:"Lo siento",goodbye:"Adi\u00f3s",help:"Ayuda",how_are_you:"\u00bfC\u00f3mo est\u00e1s?",my_name_is:"Me llamo...",i_dont_understand:"No entiendo",where_is:"\u00bfD\u00f3nde est\u00e1...?",how_much:"\u00bfCu\u00e1nto cuesta?",water:"Agua",food:"Comida",hospital:"Hospital",police:"Polic\u00eda",bathroom:"\u00bfBa\u00f1o?",left:"Izquierda",right:"Derecha",straight:"Derecho",today:"Hoy",tomorrow:"Ma\u00f1ana",friend:"Amigo",welcome:"Bienvenido",love:"Amor",peace:"Paz",beautiful:"Hermoso",danger:"Peligro",emergency:"Emergencia",thank_you_very_much:"Muchas gracias",nice_to_meet_you:"Mucho gusto",speak_slowly:"Hable despacio por favor",repeat:"\u00bfPuede repetir?",agree:"Estoy de acuerdo",disagree:"No estoy de acuerdo",maybe:"Quiz\u00e1s",later:"Luego",now:"Ahora",family:"Familia",home:"Casa",work:"Trabajo",happy:"Feliz",sad:"Triste"},
fr:{hello:"Bonjour",thanks:"Merci",yes:"Oui",no:"Non",please:"S'il vous pla\u00eet",sorry:"D\u00e9sol\u00e9",goodbye:"Au revoir",help:"Aide",how_are_you:"Comment allez-vous?",my_name_is:"Je m'appelle...",i_dont_understand:"Je ne comprends pas",where_is:"O\u00f9 est...?",how_much:"Combien?",water:"Eau",food:"Nourriture",hospital:"H\u00f4pital",police:"Police",bathroom:"Toilettes?",left:"Gauche",right:"Droite",straight:"Tout droit",today:"Aujourd'hui",tomorrow:"Demain",friend:"Ami",welcome:"Bienvenue",love:"Amour",peace:"Paix",beautiful:"Beau",danger:"Danger",emergency:"Urgence",thank_you_very_much:"Merci beaucoup",nice_to_meet_you:"Enchant\u00e9",speak_slowly:"Parlez lentement s'il vous pla\u00eet",repeat:"Pouvez-vous r\u00e9p\u00e9ter?",agree:"Je suis d'accord",disagree:"Je ne suis pas d'accord",maybe:"Peut-\u00eatre",later:"Plus tard",now:"Maintenant",family:"Famille",home:"Maison",work:"Travail",happy:"Heureux",sad:"Triste"},
de:{hello:"Hallo",thanks:"Danke",yes:"Ja",no:"Nein",please:"Bitte",sorry:"Entschuldigung",goodbye:"Auf Wiedersehen",help:"Hilfe",how_are_you:"Wie geht es Ihnen?",my_name_is:"Ich hei\u00dfe...",i_dont_understand:"Ich verstehe nicht",where_is:"Wo ist...?",how_much:"Wie viel?",water:"Wasser",food:"Essen",hospital:"Krankenhaus",police:"Polizei",bathroom:"Toilette?",left:"Links",right:"Rechts",straight:"Geradeaus",today:"Heute",tomorrow:"Morgen",friend:"Freund",welcome:"Willkommen",love:"Liebe",peace:"Frieden",beautiful:"Sch\u00f6n",danger:"Gefahr",emergency:"Notfall",thank_you_very_much:"Vielen Dank",nice_to_meet_you:"Freut mich",speak_slowly:"Bitte sprechen Sie langsam",repeat:"K\u00f6nnen Sie wiederholen?",agree:"Einverstanden",disagree:"Nicht einverstanden",maybe:"Vielleicht",later:"Sp\u00e4ter",now:"Jetzt",family:"Familie",home:"Zuhause",work:"Arbeit",happy:"Gl\u00fccklich",sad:"Traurig"},
it:{hello:"Ciao",thanks:"Grazie",yes:"S\u00ec",no:"No",please:"Per favore",sorry:"Mi dispiace",goodbye:"Arrivederci",help:"Aiuto",how_are_you:"Come stai?",my_name_is:"Mi chiamo...",i_dont_understand:"Non capisco",where_is:"Dov'\u00e8...?",how_much:"Quanto costa?",water:"Acqua",food:"Cibo",hospital:"Ospedale",police:"Polizia",bathroom:"Bagno?",left:"Sinistra",right:"Destra",straight:"Dritto",today:"Oggi",tomorrow:"Domani",friend:"Amico",welcome:"Benvenuto",love:"Amore",peace:"Pace",beautiful:"Bello",danger:"Pericolo",emergency:"Emergenza",thank_you_very_much:"Grazie mille",nice_to_meet_you:"Piacere",speak_slowly:"Parla lentamente per favore",repeat:"Pu\u00f2 ripetere?",agree:"Sono d'accordo",disagree:"Non sono d'accordo",maybe:"Forse",later:"Pi\u00f9 tardi",now:"Adesso",family:"Famiglia",home:"Casa",work:"Lavoro",happy:"Felice",sad:"Triste"},
pt:{hello:"Ol\u00e1",thanks:"Obrigado",yes:"Sim",no:"N\u00e3o",please:"Por favor",sorry:"Desculpe",goodbye:"Tchau",help:"Ajuda",how_are_you:"Como vai?",my_name_is:"Meu nome \u00e9...",i_dont_understand:"N\u00e3o entendo",where_is:"Onde fica...?",how_much:"Quanto custa?",water:"\u00c1gua",food:"Comida",hospital:"Hospital",police:"Pol\u00edcia",bathroom:"Banheiro?",left:"Esquerda",right:"Direita",straight:"Em frente",today:"Hoje",tomorrow:"Amanh\u00e3",friend:"Amigo",welcome:"Bem-vindo",love:"Amor",peace:"Paz",beautiful:"Bonito",danger:"Perigo",emergency:"Emerg\u00eancia",thank_you_very_much:"Muito obrigado",nice_to_meet_you:"Prazer",speak_slowly:"Fale devagar por favor",repeat:"Pode repetir?",agree:"Concordo",disagree:"Discordo",maybe:"Talvez",later:"Depois",now:"Agora",family:"Fam\u00edlia",home:"Casa",work:"Trabalho",happy:"Feliz",sad:"Triste"},
ja:{hello:"\u3053\u3093\u306b\u3061\u306f",thanks:"\u3042\u308a\u304c\u3068\u3046",yes:"\u306f\u3044",no:"\u3044\u3044\u3048",please:"\u304a\u306d\u304c\u3044",sorry:"\u3059\u307f\u307e\u305b\u3093",goodbye:"\u3055\u3088\u3046\u306a\u3089",help:"\u52a9\u3051\u3066",how_are_you:"\u304a\u5143\u6c17\u3067\u3059\u304b?",my_name_is:"\u79c1\u306e\u540d\u524d\u306f...",i_dont_understand:"\u308f\u304b\u308a\u307e\u305b\u3093",where_is:"...\u306f\u3069\u3053?",how_much:"\u3044\u304f\u3089?",water:"\u6c34",food:"\u98df\u3079\u7269",hospital:"\u75c5\u9662",police:"\u8b66\u5bdf",bathroom:"\u30c8\u30a4\u30ec?",left:"\u5de6",right:"\u53f3",straight:"\u307e\u3063\u3059\u3050",today:"\u4eca\u65e5",tomorrow:"\u660e\u65e5",friend:"\u53cb\u9054",welcome:"\u3088\u3046\u3053\u305d",love:"\u611b",peace:"\u5e73\u548c",beautiful:"\u7f8e\u3057\u3044",danger:"\u5371\u967a",emergency:"\u7dca\u6025",thank_you_very_much:"\u3069\u3046\u3082\u3042\u308a\u304c\u3068\u3046",nice_to_meet_you:"\u306f\u3058\u3081\u307e\u3057\u3066",speak_slowly:"\u3086\u3063\u304f\u308a\u8a71\u3057\u3066",repeat:"\u3082\u3046\u4e00\u5ea6?",agree:"\u8cdb\u6210",disagree:"\u53cd\u5bfe",maybe:"\u305f\u3076\u3093",later:"\u5f8c\u3067",now:"\u4eca",family:"\u5bb6\u65cf",home:"\u5bb6",work:"\u4ed5\u4e8b",happy:"\u5b09\u3057\u3044",sad:"\u60b2\u3057\u3044"},
ko:{hello:"\uc548\ub155\ud558\uc138\uc694",thanks:"\uac10\uc0ac\ud569\ub2c8\ub2e4",yes:"\ub124",no:"\uc544\ub2c8\uc694",please:"\ubd80\ud0c1\ud569\ub2c8\ub2e4",sorry:"\uc8c4\uc1a1\ud569\ub2c8\ub2e4",goodbye:"\uc548\ub155\ud788 \uac00\uc138\uc694",help:"\ub3c4\uc640\uc8fc\uc138\uc694",how_are_you:"\uc5b4\ub5bb\uac8c \uc9c0\ub0b4\uc138\uc694?",my_name_is:"\uc81c \uc774\ub984\uc740...",i_dont_understand:"\uc774\ud574 \ubabb\ud574\uc694",where_is:"...\uc5b4\ub514\uc5d0\uc694?",how_much:"\uc5bc\ub9c8\uc608\uc694?",water:"\ubb3c",food:"\uc74c\uc2dd",hospital:"\ubcd1\uc6d0",police:"\uacbd\ucc30",bathroom:"\ud654\uc7a5\uc2e4?",left:"\uc67c\ucabd",right:"\uc624\ub978\ucabd",straight:"\uc9c1\uc9c4",today:"\uc624\ub298",tomorrow:"\ub0b4\uc77c",friend:"\uce5c\uad6c",welcome:"\ud658\uc601",love:"\uc0ac\ub791",peace:"\ud3c9\ud654",beautiful:"\uc544\ub984\ub2e4\uc6b4",danger:"\uc704\ud5d8",emergency:"\ube44\uc0c1",thank_you_very_much:"\ub300\ub2e8\ud788 \uac10\uc0ac\ud569\ub2c8\ub2e4",nice_to_meet_you:"\ub9cc\ub098\uc11c \ubc18\uac11\uc2b5\ub2c8\ub2e4",speak_slowly:"\ucc9c\ucc9c\ud788 \ub9d0\ud574\uc8fc\uc138\uc694",repeat:"\ub2e4\uc2dc \ub9d0\ud574\uc8fc\uc138\uc694",agree:"\ub3d9\uc758",disagree:"\ub3d9\uc758\ud558\uc9c0 \uc54a\uc544\uc694",maybe:"\uc544\ub9c8",later:"\ub098\uc911\uc5d0",now:"\uc9c0\uae08",family:"\uac00\uc871",home:"\uc9d1",work:"\uc77c",happy:"\ud589\ubcf5\ud55c",sad:"\uc2ac\ud508"},
zh:{hello:"\u4f60\u597d",thanks:"\u8c22\u8c22",yes:"\u662f",no:"\u4e0d",please:"\u8bf7",sorry:"\u5bf9\u4e0d\u8d77",goodbye:"\u518d\u89c1",help:"\u5e2e\u52a9",how_are_you:"\u4f60\u597d\u5417?",my_name_is:"\u6211\u53eb...",i_dont_understand:"\u6211\u4e0d\u61c2",where_is:"...\u5728\u54ea\u91cc?",how_much:"\u591a\u5c11\u94b1?",water:"\u6c34",food:"\u98df\u7269",hospital:"\u533b\u9662",police:"\u8b66\u5bdf",bathroom:"\u536b\u751f\u95f4?",left:"\u5de6",right:"\u53f3",straight:"\u76f4\u8d70",today:"\u4eca\u5929",tomorrow:"\u660e\u5929",friend:"\u670b\u53cb",welcome:"\u6b22\u8fce",love:"\u7231",peace:"\u548c\u5e73",beautiful:"\u7f8e\u4e3d",danger:"\u5371\u9669",emergency:"\u7d27\u6025",thank_you_very_much:"\u975e\u5e38\u611f\u8c22",nice_to_meet_you:"\u5f88\u9ad8\u5174\u8ba4\u8bc6\u4f60",speak_slowly:"\u8bf7\u8bf4\u6162\u4e00\u70b9",repeat:"\u53ef\u4ee5\u91cd\u590d\u5417?",agree:"\u540c\u610f",disagree:"\u4e0d\u540c\u610f",maybe:"\u4e5f\u8bb8",later:"\u4ee5\u540e",now:"\u73b0\u5728",family:"\u5bb6\u4eba",home:"\u5bb6",work:"\u5de5\u4f5c",happy:"\u5f00\u5fc3",sad:"\u4f24\u5fc3"},
ar:{hello:"\u0645\u0631\u062d\u0628\u0627",thanks:"\u0634\u0643\u0631\u0627",yes:"\u0646\u0639\u0645",no:"\u0644\u0627",please:"\u0645\u0646 \u0641\u0636\u0644\u0643",sorry:"\u0622\u0633\u0641",goodbye:"\u0645\u0639 \u0627\u0644\u0633\u0644\u0627\u0645\u0629",help:"\u0645\u0633\u0627\u0639\u062f\u0629",how_are_you:"\u0643\u064a\u0641 \u062d\u0627\u0644\u0643\u061f",my_name_is:"\u0627\u0633\u0645\u064a...",i_dont_understand:"\u0644\u0627 \u0623\u0641\u0647\u0645",where_is:"\u0623\u064a\u0646...?\u061f",how_much:"\u0643\u0645 \u0627\u0644\u0633\u0639\u0631\u061f",water:"\u0645\u0627\u0621",food:"\u0637\u0639\u0627\u0645",hospital:"\u0645\u0633\u062a\u0634\u0641\u0649",police:"\u0634\u0631\u0637\u0629",bathroom:"\u062d\u0645\u0627\u0645\u061f",left:"\u064a\u0633\u0627\u0631",right:"\u064a\u0645\u064a\u0646",straight:"\u0645\u0628\u0627\u0634\u0631\u0629",today:"\u0627\u0644\u064a\u0648\u0645",tomorrow:"\u063a\u062f\u0627",friend:"\u0635\u062f\u064a\u0642",welcome:"\u0623\u0647\u0644\u0627",love:"\u062d\u0628",peace:"\u0633\u0644\u0627\u0645",beautiful:"\u062c\u0645\u064a\u0644",danger:"\u062e\u0637\u0631",emergency:"\u0637\u0648\u0627\u0631\u0626",thank_you_very_much:"\u0634\u0643\u0631\u0627 \u062c\u0632\u064a\u0644\u0627",nice_to_meet_you:"\u062a\u0634\u0631\u0641\u0646\u0627",speak_slowly:"\u062a\u062d\u062f\u062b \u0628\u0628\u0637\u0621",repeat:"\u0623\u0639\u062f \u0645\u0646 \u0641\u0636\u0644\u0643",agree:"\u0645\u0648\u0627\u0641\u0642",disagree:"\u063a\u064a\u0631 \u0645\u0648\u0627\u0641\u0642",maybe:"\u0631\u0628\u0645\u0627",later:"\u0644\u0627\u062d\u0642\u0627",now:"\u0627\u0644\u0622\u0646",family:"\u0639\u0627\u0626\u0644\u0629",home:"\u0628\u064a\u062a",work:"\u0639\u0645\u0644",happy:"\u0633\u0639\u064a\u062f",sad:"\u062d\u0632\u064a\u0646"},
hi:{hello:"\u0928\u092e\u0938\u094d\u0924\u0947",thanks:"\u0927\u0928\u094d\u092f\u0935\u093e\u0926",yes:"\u0939\u093e\u0901",no:"\u0928\u0939\u0940\u0902",please:"\u0915\u0943\u092a\u092f\u093e",sorry:"\u092e\u093e\u092b\u093c \u0915\u0940\u091c\u093f\u090f",goodbye:"\u0905\u0932\u0935\u093f\u0926\u093e",help:"\u092e\u0926\u0926",how_are_you:"\u0906\u092a \u0915\u0948\u0938\u0947 \u0939\u0948\u0902?",my_name_is:"\u092e\u0947\u0930\u093e \u0928\u093e\u092e...",i_dont_understand:"\u0938\u092e\u091d \u0928\u0939\u0940\u0902 \u0906\u092f\u093e",where_is:"...\u0915\u0939\u093e\u0901 \u0939\u0948?",how_much:"\u0915\u093f\u0924\u0928\u0947 \u0915\u093e?",water:"\u092a\u093e\u0928\u0940",food:"\u0916\u093e\u0928\u093e",hospital:"\u0905\u0938\u094d\u092a\u0924\u093e\u0932",police:"\u092a\u0941\u0932\u093f\u0938",bathroom:"\u0936\u094c\u091a\u093e\u0932\u092f?",left:"\u092c\u093e\u090f\u0902",right:"\u0926\u093e\u090f\u0902",straight:"\u0938\u0940\u0927\u0947",today:"\u0906\u091c",tomorrow:"\u0915\u0932",friend:"\u0926\u094b\u0938\u094d\u0924",welcome:"\u0938\u094d\u0935\u093e\u0917\u0924",love:"\u092a\u094d\u092f\u093e\u0930",peace:"\u0936\u093e\u0902\u0924\u093f",beautiful:"\u0938\u0941\u0928\u094d\u0926\u0930",danger:"\u0916\u0924\u0930\u093e",emergency:"\u0906\u092a\u093e\u0924\u0915\u093e\u0932",thank_you_very_much:"\u092c\u0939\u0941\u0924 \u0927\u0928\u094d\u092f\u0935\u093e\u0926",nice_to_meet_you:"\u0906\u092a\u0938\u0947 \u092e\u093f\u0932\u0915\u0930 \u0905\u091a\u094d\u091b\u093e \u0932\u0917\u093e",speak_slowly:"\u0927\u0940\u0930\u0947 \u092c\u094b\u0932\u093f\u090f",repeat:"\u0926\u094b\u092c\u093e\u0930\u093e \u092c\u094b\u0932\u093f\u090f",agree:"\u0938\u0939\u092e\u0924",disagree:"\u0905\u0938\u0939\u092e\u0924",maybe:"\u0936\u093e\u092f\u0926",later:"\u092c\u093e\u0926 \u092e\u0947\u0902",now:"\u0905\u092d\u0940",family:"\u092a\u0930\u093f\u0935\u093e\u0930",home:"\u0918\u0930",work:"\u0915\u093e\u092e",happy:"\u0916\u0941\u0936",sad:"\u0926\u0941\u0916\u0940"},
ru:{hello:"\u041f\u0440\u0438\u0432\u0435\u0442",thanks:"\u0421\u043f\u0430\u0441\u0438\u0431\u043e",yes:"\u0414\u0430",no:"\u041d\u0435\u0442",please:"\u041f\u043e\u0436\u0430\u043b\u0443\u0439\u0441\u0442\u0430",sorry:"\u0418\u0437\u0432\u0438\u043d\u0438\u0442\u0435",goodbye:"\u0414\u043e \u0441\u0432\u0438\u0434\u0430\u043d\u0438\u044f",help:"\u041f\u043e\u043c\u043e\u0449\u044c",how_are_you:"\u041a\u0430\u043a \u0434\u0435\u043b\u0430?",my_name_is:"\u041c\u0435\u043d\u044f \u0437\u043e\u0432\u0443\u0442...",i_dont_understand:"\u042f \u043d\u0435 \u043f\u043e\u043d\u0438\u043c\u0430\u044e",where_is:"\u0413\u0434\u0435...?",how_much:"\u0421\u043a\u043e\u043b\u044c\u043a\u043e?",water:"\u0412\u043e\u0434\u0430",food:"\u0415\u0434\u0430",hospital:"\u0411\u043e\u043b\u044c\u043d\u0438\u0446\u0430",police:"\u041f\u043e\u043b\u0438\u0446\u0438\u044f",bathroom:"\u0422\u0443\u0430\u043b\u0435\u0442?",left:"\u041d\u0430\u043b\u0435\u0432\u043e",right:"\u041d\u0430\u043f\u0440\u0430\u0432\u043e",straight:"\u041f\u0440\u044f\u043c\u043e",today:"\u0421\u0435\u0433\u043e\u0434\u043d\u044f",tomorrow:"\u0417\u0430\u0432\u0442\u0440\u0430",friend:"\u0414\u0440\u0443\u0433",welcome:"\u0414\u043e\u0431\u0440\u043e \u043f\u043e\u0436\u0430\u043b\u043e\u0432\u0430\u0442\u044c",love:"\u041b\u044e\u0431\u043e\u0432\u044c",peace:"\u041c\u0438\u0440",beautiful:"\u041a\u0440\u0430\u0441\u0438\u0432\u043e",danger:"\u041e\u043f\u0430\u0441\u043d\u043e\u0441\u0442\u044c",emergency:"\u0421\u0440\u043e\u0447\u043d\u043e",thank_you_very_much:"\u0411\u043e\u043b\u044c\u0448\u043e\u0435 \u0441\u043f\u0430\u0441\u0438\u0431\u043e",nice_to_meet_you:"\u041f\u0440\u0438\u044f\u0442\u043d\u043e \u043f\u043e\u0437\u043d\u0430\u043a\u043e\u043c\u0438\u0442\u044c\u0441\u044f",speak_slowly:"\u0413\u043e\u0432\u043e\u0440\u0438\u0442\u0435 \u043c\u0435\u0434\u043b\u0435\u043d\u043d\u043e",repeat:"\u041f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u0435?",agree:"\u0421\u043e\u0433\u043b\u0430\u0441\u0435\u043d",disagree:"\u041d\u0435 \u0441\u043e\u0433\u043b\u0430\u0441\u0435\u043d",maybe:"\u041c\u043e\u0436\u0435\u0442 \u0431\u044b\u0442\u044c",later:"\u041f\u043e\u0437\u0436\u0435",now:"\u0421\u0435\u0439\u0447\u0430\u0441",family:"\u0421\u0435\u043c\u044c\u044f",home:"\u0414\u043e\u043c",work:"\u0420\u0430\u0431\u043e\u0442\u0430",happy:"\u0421\u0447\u0430\u0441\u0442\u043b\u0438\u0432\u044b\u0439",sad:"\u0413\u0440\u0443\u0441\u0442\u043d\u044b\u0439"},
sw:{hello:"Hujambo",thanks:"Asante",yes:"Ndiyo",no:"Hapana",please:"Tafadhali",sorry:"Pole",goodbye:"Kwaheri",help:"Msaada",how_are_you:"Habari yako?",my_name_is:"Jina langu ni...",i_dont_understand:"Sielewi",where_is:"...iko wapi?",how_much:"Bei gani?",water:"Maji",food:"Chakula",hospital:"Hospitali",police:"Polisi",bathroom:"Choo?",left:"Kushoto",right:"Kulia",straight:"Moja kwa moja",today:"Leo",tomorrow:"Kesho",friend:"Rafiki",welcome:"Karibu",love:"Upendo",peace:"Amani",beautiful:"Nzuri",danger:"Hatari",emergency:"Dharura",thank_you_very_much:"Asante sana",nice_to_meet_you:"Nafurahi kukuona",speak_slowly:"Sema pole pole",repeat:"Rudia tafadhali",agree:"Nakubaliana",disagree:"Sikubaliani",maybe:"Labda",later:"Baadaye",now:"Sasa",family:"Familia",home:"Nyumba",work:"Kazi",happy:"Furaha",sad:"Huzuni"},
tr:{hello:"Merhaba",thanks:"Te\u015fekk\u00fcrler",yes:"Evet",no:"Hay\u0131r",please:"L\u00fctfen",sorry:"\u00d6z\u00fcr dilerim",goodbye:"Ho\u015f\u00e7a kal",help:"Yard\u0131m",how_are_you:"Nas\u0131ls\u0131n\u0131z?",my_name_is:"Benim ad\u0131m...",i_dont_understand:"Anlam\u0131yorum",where_is:"...nerede?",how_much:"Ne kadar?",water:"Su",food:"Yemek",hospital:"Hastane",police:"Polis",bathroom:"Tuvalet?",left:"Sol",right:"Sa\u011f",straight:"D\u00fcz",today:"Bug\u00fcn",tomorrow:"Yar\u0131n",friend:"Arkada\u015f",welcome:"Ho\u015f geldiniz",love:"A\u015fk",peace:"Bar\u0131\u015f",beautiful:"G\u00fczel",danger:"Tehlike",emergency:"Acil",thank_you_very_much:"\u00c7ok te\u015fekk\u00fcrler",nice_to_meet_you:"Tan\u0131\u015ft\u0131\u011f\u0131m\u0131za memnunum",speak_slowly:"Yava\u015f konu\u015fun l\u00fctfen",repeat:"Tekrar eder misiniz?",agree:"Kat\u0131l\u0131yorum",disagree:"Kat\u0131lm\u0131yorum",maybe:"Belki",later:"Sonra",now:"\u015eimdi",family:"Aile",home:"Ev",work:"\u0130\u015f",happy:"Mutlu",sad:"\u00dczg\u00fcn"}
};
var quickKeys=['hello','thanks','how_are_you','yes','no','please','sorry','goodbye','help','where_is','how_much','water','food','i_dont_understand','speak_slowly','repeat','nice_to_meet_you','emergency'];
function getLang(id){return document.getElementById(id).value}
function getDict(lang){return D[lang]||D.en}
function translate(text,fromLang,toLang){
var fd=getDict(fromLang),td=getDict(toLang);
var key=null;
for(var k in fd){if(fd[k].toLowerCase()===text.toLowerCase()){key=k;break;}}
if(key&&td[key])return td[key];
var fk=null;
for(var k2 in fd){if(text.toLowerCase().indexOf(fd[k2].toLowerCase())!==-1){fk=k2;break;}}
if(fk&&td[fk])return td[fk]+' ('+text+')';
return '['+toLang.toUpperCase()+'] '+text;
}
function updatePhrases(){
var pb=document.getElementById('phrases');
var lang=speaker==='a'?getLang('langA'):getLang('langB');
var d=getDict(lang);
var h='';
quickKeys.forEach(function(k){if(d[k])h+='<div class="phrase" onclick="quickSend(\\''+k+'\\')">'+d[k]+'</div>';});
pb.innerHTML=h;
}
function quickSend(key){
var fromLang=speaker==='a'?getLang('langA'):getLang('langB');
var d=getDict(fromLang);
if(d[key]){document.getElementById('inp').value=d[key];send();}
}
function setSpeaker(s){
speaker=s;
document.getElementById('btnA').className=s==='a'?'active-a':'';
document.getElementById('btnB').className=s==='b'?'active-b':'';
var sb=document.getElementById('sendBtn');
sb.className='send-btn '+(s==='a'?'a':'b');
document.getElementById('inp').placeholder=s==='a'?'Type as Person A...':'Type as Person B...';
updatePhrases();
}
function swapLangs(){
var a=document.getElementById('langA'),b=document.getElementById('langB');
var t=a.value;a.value=b.value;b.value=t;updatePhrases();
}
function send(){
var inp=document.getElementById('inp');
var text=inp.value.trim();if(!text)return;inp.value='';
var fromLang=speaker==='a'?getLang('langA'):getLang('langB');
var toLang=speaker==='a'?getLang('langB'):getLang('langA');
var trans=translate(text,fromLang,toLang);
var names={en:'English',es:'Espa\u00f1ol',fr:'Fran\u00e7ais',de:'Deutsch',it:'Italiano',pt:'Portugu\u00eas',ja:'\u65e5\u672c\u8a9e',ko:'\ud55c\uad6d\uc5b4',zh:'\u4e2d\u6587',ar:'\u0627\u0644\u0639\u0631\u0628\u064a\u0629',hi:'\u0939\u093f\u0928\u094d\u0926\u0940',ru:'\u0420\u0443\u0441\u0441\u043a\u0438\u0439',sw:'Kiswahili',tr:'T\u00fcrk\u00e7e'};
msgs.push({s:speaker,orig:text,trans:trans,from:fromLang,to:toLang});
renderChat();
}
function renderChat(){
var c=document.getElementById('chat');
var h='';
msgs.forEach(function(m){
h+='<div class="msg '+m.s+'">';
h+='<div class="orig">'+esc(m.orig)+'</div>';
h+='<div class="trans">'+esc(m.trans)+'</div>';
h+='<div class="lang-tag">'+m.from.toUpperCase()+' \u2192 '+m.to.toUpperCase()+'</div>';
h+='</div>';
});
c.innerHTML=h;
c.scrollTop=c.scrollHeight;
}
function esc(s){var d=document.createElement('div');d.textContent=s;return d.innerHTML;}
updatePhrases();
</script>
</body>
</html>`,
}

// ─── Glyph Cipher Demo ──────────────────────────────────────────────

export const CIPHER_DEMO = {
  title: 'Glyph Cipher',
  templateType: 'puzzle',
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Cipher</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;align-items:center;
padding:20px;-webkit-user-select:none;user-select:none}
.hdr{text-align:center;margin-bottom:16px}
.hdr h1{font-size:1.6em;background:linear-gradient(135deg,#66d9ff,#ff9966);
-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.hdr p{color:#666;font-size:.75em;margin-top:2px}
.level-bar{display:flex;gap:6px;margin-bottom:12px}
.lvl{padding:6px 14px;border-radius:16px;background:#1a1a2e;border:1px solid #333;
font-size:.8em;color:#888;cursor:pointer;transition:all .2s}
.lvl.active{border-color:#66d9ff;color:#66d9ff;background:#66d9ff11}
.cipher-card{background:#12121e;border:1px solid #222;border-radius:20px;padding:24px 20px;
width:100%;max-width:380px;animation:fadeIn .4s ease}
@keyframes fadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
.cipher-label{font-size:.7em;color:#ff9966;font-weight:700;text-transform:uppercase;
letter-spacing:1px;margin-bottom:8px}
.cipher-text{font-family:'Courier New',monospace;font-size:1.15em;line-height:1.6;
color:#66d9ff;letter-spacing:2px;margin-bottom:16px;word-break:break-all;
padding:12px;background:#0a0a14;border-radius:12px;border:1px solid #1a1a2e;text-align:center}
.hint-box{margin-bottom:16px}
.hint-btn{padding:8px 16px;background:#1a1a2e;border:1px solid #333;border-radius:12px;
color:#888;font-size:.8em;cursor:pointer;transition:all .2s}
.hint-btn:active{border-color:#ff9966;color:#ff9966}
.hint-text{margin-top:8px;font-size:.85em;color:#ff9966;font-style:italic;
animation:fadeIn .3s ease}
.answer-row{display:flex;gap:8px}
.answer-input{flex:1;background:#1a1a2e;border:1px solid #333;border-radius:12px;
padding:12px 14px;color:#fff;font-size:1em;font-family:inherit;outline:none}
.answer-input:focus{border-color:#66d9ff44}
.check-btn{padding:12px 20px;background:linear-gradient(135deg,#66d9ff,#ff9966);
color:#000;font-weight:700;border:none;border-radius:12px;font-size:1em;cursor:pointer}
.check-btn:active{transform:scale(.97)}
.result{margin-top:16px;padding:14px;border-radius:12px;text-align:center;
font-weight:600;animation:fadeIn .3s ease}
.result.correct{background:#44dd8822;border:1px solid #44dd88;color:#44dd88}
.result.wrong{background:#ff446622;border:1px solid #ff4466;color:#ff4466}
.stats{display:flex;gap:16px;justify-content:center;margin:16px 0;font-size:.85em;color:#888}
.stats .val{color:#66d9ff;font-weight:700}
.method{margin-top:12px;padding:10px 16px;background:#1a1a2e;border:1px solid #222;
border-radius:12px;font-size:.75em;color:#666;line-height:1.5}
.method strong{color:#ff9966}
.next-btn{margin-top:16px;padding:12px 32px;background:#1a1a2e;border:1px solid #333;
color:#66d9ff;font-weight:600;border-radius:30px;font-size:.9em;cursor:pointer;
transition:all .2s}
.next-btn:active{transform:scale(.97);border-color:#66d9ff}
.foot{color:#222;font-size:.6em;margin-top:auto;padding-top:16px;text-align:center}
</style>
</head>
<body>
<div class="hdr"><h1>\ud83d\udd10 Glyph Cipher</h1><p>Crack the code \u00b7 Delivered via Glyph</p></div>
<div class="level-bar">
<div class="lvl active" onclick="setLevel(0)">Easy</div>
<div class="lvl" onclick="setLevel(1)">Medium</div>
<div class="lvl" onclick="setLevel(2)">Hard</div>
</div>
<div id="stage"></div>
<div class="stats"><span>Solved: <span class="val" id="solved">0</span></span>
<span>Streak: <span class="val" id="streak">0</span></span></div>
<div class="foot">Glyph Cipher \u00b7 Offline \u00b7 Encrypted delivery</div>
<script>
var phrases=[
['HELLO WORLD','ENCRYPTION IS KEY','VANISHING MESSAGES','QR CODE MAGIC','TRUST NO SERVER',
'PRIVACY MATTERS','SCAN TO REVEAL','DECODE THE FUTURE','OFFLINE FIRST','ZERO KNOWLEDGE'],
['THE BEST ENCRYPTION IS THE ONE NOBODY KNOWS EXISTS','EVERY MESSAGE IS A DOOR EVERY SCAN IS A CHOICE',
'IN A WORLD OF PERMANENT RECORDS CHOOSE TO VANISH','LIGHT PATTERN PROXIMITY NO CLOUD REQUIRED',
'AES TWO FIVE SIX GCM IS THE GOLD STANDARD'],
['CRYPTOGRAPHY IS THE ULTIMATE FORM OF NON VIOLENT DIRECT ACTION','THE ABSENCE OF EVIDENCE IS NOT THE EVIDENCE OF ABSENCE',
'WHAT CAN BE DESTROYED BY THE TRUTH SHOULD BE','IN THE LAND OF THE BLIND THE ONE EYED MAN IS KING',
'THOSE WHO WOULD GIVE UP LIBERTY FOR SECURITY DESERVE NEITHER']
];
var level=0,solved=0,streak=0,curAnswer='',curMethod='',hintUsed=false,hintText='';
function setLevel(l){
level=l;
document.querySelectorAll('.lvl').forEach(function(e,i){e.className=i===l?'lvl active':'lvl';});
newPuzzle();
}
function caesar(text,shift){
return text.split('').map(function(c){
if(c>='A'&&c<='Z')return String.fromCharCode((c.charCodeAt(0)-65+shift)%26+65);
return c;}).join('');
}
function atbash(text){
return text.split('').map(function(c){
if(c>='A'&&c<='Z')return String.fromCharCode(90-(c.charCodeAt(0)-65));
return c;}).join('');
}
function sub(text){
var key='QWERTYUIOPASDFGHJKLZXCVBNM';
return text.split('').map(function(c){
if(c>='A'&&c<='Z')return key[c.charCodeAt(0)-65];
return c;}).join('');
}
function morse(text){
var m={A:'.-',B:'-...',C:'-.-.',D:'-..',E:'.',F:'..-.',G:'--.',H:'....',I:'..',J:'.---',
K:'-.-',L:'.-..',M:'--',N:'-.',O:'---',P:'.--.',Q:'--.-',R:'.-.',S:'...',T:'-',
U:'..-',V:'...-',W:'.--',X:'-..-',Y:'-.--',Z:'--..',' ':' / '};
return text.split('').map(function(c){return m[c]||c}).join(' ');
}
function rail(text,rails){
var fence=[];for(var i=0;i<rails;i++)fence.push([]);
var r=0,dir=1;
for(var j=0;j<text.length;j++){
fence[r].push(text[j]);
if(r===0)dir=1;if(r===rails-1)dir=-1;r+=dir;
}
return fence.map(function(x){return x.join('')}).join('');
}
function newPuzzle(){
var ps=phrases[level];
curAnswer=ps[Math.floor(Math.random()*ps.length)];
hintUsed=false;hintText='';
var methods,ct,mth;
if(level===0){
var shift=Math.floor(Math.random()*23)+3;
ct=caesar(curAnswer,shift);
mth='Caesar Cipher (shift '+shift+')';
hintText='Each letter is shifted by '+shift+' positions in the alphabet. A becomes '+String.fromCharCode(65+shift)+'.';
}else if(level===1){
var r=Math.random();
if(r<0.33){ct=atbash(curAnswer);mth='Atbash Cipher';hintText='The alphabet is reversed: A=Z, B=Y, C=X...';}
else if(r<0.66){ct=morse(curAnswer);mth='Morse Code';hintText='Dots and dashes. / separates words. .- is A, -... is B.';}
else{var sh=Math.floor(Math.random()*20)+5;ct=caesar(curAnswer,sh);mth='Caesar Cipher (shift '+sh+')';hintText='Shifted by '+sh+'. Try working backwards from common words like THE or IS.';}
}else{
var r2=Math.random();
if(r2<0.33){ct=sub(curAnswer);mth='Substitution Cipher';hintText='Each letter maps to a different letter. Look for single-letter words (A, I) and common patterns (THE, IS).';}
else if(r2<0.66){ct=rail(curAnswer,3);mth='Rail Fence (3 rails)';hintText='Letters are written in a zigzag across 3 rows, then read left to right.';}
else{ct=atbash(caesar(curAnswer,7));mth='Double Cipher (Caesar+Atbash)';hintText='Two ciphers applied: first a Caesar shift of 7, then Atbash reversal.';}
}
curMethod=mth;
var s=document.getElementById('stage');
var h='<div class="cipher-card">';
h+='<div class="cipher-label">\ud83d\udd12 Encrypted Message</div>';
h+='<div class="cipher-text" id="ct">'+esc(ct)+'</div>';
h+='<div class="hint-box"><button class="hint-btn" onclick="showHint()">\ud83d\udca1 Show Hint</button><div id="hint"></div></div>';
h+='<div class="answer-row"><input class="answer-input" id="ans" placeholder="Type the decoded message..." onkeydown="if(event.key===\\'Enter\\')checkAns()"><button class="check-btn" onclick="checkAns()">\u2713</button></div>';
h+='<div id="res"></div>';
h+='</div>';
s.innerHTML=h;
document.getElementById('ans').focus();
}
function showHint(){
hintUsed=true;
document.getElementById('hint').innerHTML='<div class="hint-text">'+hintText+'</div>';
}
function esc(s){var d=document.createElement('div');d.textContent=s;return d.innerHTML;}
function checkAns(){
var guess=document.getElementById('ans').value.trim().toUpperCase().replace(/[^A-Z ]/g,'');
var target=curAnswer.replace(/[^A-Z ]/g,'');
var res=document.getElementById('res');
if(guess===target){
solved++;streak++;
document.getElementById('solved').textContent=solved;
document.getElementById('streak').textContent=streak;
res.innerHTML='<div class="result correct">\u2713 Correct!'+(hintUsed?'':' (No hint \u2014 impressive!)')+'</div>';
res.innerHTML+='<div class="method">Method: <strong>'+curMethod+'</strong></div>';
res.innerHTML+='<button class="next-btn" onclick="newPuzzle()">\u2192 Next Puzzle</button>';
}else{
streak=0;
document.getElementById('streak').textContent=0;
res.innerHTML='<div class="result wrong">\u2717 Not quite. Keep trying!</div>';
setTimeout(function(){res.innerHTML='';},1500);
}
}
newPuzzle();
</script>
</body>
</html>`,
}

export const ALL_DEMOS: DemoExperience[] = [
  {
    id: 'translate',
    title: TRANSLATION_DEMO.title,
    icon: '\ud83c\udf10',
    description: 'Real-time multilingual conversation \u2014 completely offline. Two people pick their languages and chat face-to-face with instant translation. 46 languages including endangered & remote.',
    templateType: 'translate',
    html: TRANSLATION_DEMO.html,
    estimatedFrames: '~65 frames',
  },
  {
    id: 'cipher',
    title: CIPHER_DEMO.title,
    icon: '\ud83d\udd10',
    description: 'Crack encrypted messages using real ciphers \u2014 Caesar, Atbash, Morse, Rail Fence, Substitution. Three difficulty levels with hints and streaks.',
    templateType: 'puzzle',
    html: CIPHER_DEMO.html,
    estimatedFrames: '~45 frames',
  },
  {
    id: 'void-runner',
    title: VOID_RUNNER_DEMO.title,
    icon: 'RUN',
    description: 'Dodge the void, collect the light. A full arcade game delivered entirely via QR code. Tilt or swipe to move.',
    templateType: 'game',
    html: VOID_RUNNER_DEMO.html,
    estimatedFrames: '~70 frames',
  },
  {
    id: 'drift',
    title: DRIFT_DEMO.title,
    icon: 'DFT',
    description: 'A micro-platformer. Tap to jump, hold to drift-float. Collect crystals, dodge hazards, go as far as you can.',
    templateType: 'game',
    html: DRIFT_DEMO.html,
    estimatedFrames: '~80 frames',
  },
  // {
  //   id: 'draw',
  //   title: DRAW_DEMO.title,
  //   icon: 'DRW',
  //   description: 'Draw a picture on your phone, then hold it up. The AI on the website will try to guess what you drew!',
  //   templateType: 'game',
  //   html: DRAW_DEMO.html,
  //   estimatedFrames: '~40 frames',
  // },
]
