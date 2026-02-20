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
  html: `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Glyph Particles</title>
<style>
*{margin:0;padding:0}
body{background:#0a0a14;overflow:hidden;touch-action:none;-webkit-user-select:none;user-select:none}
canvas{display:block;width:100vw;height:100vh}
.ui{position:fixed;top:0;left:0;right:0;padding:16px 20px;display:flex;justify-content:space-between;
align-items:center;z-index:10;background:linear-gradient(#0a0a14cc,transparent)}
.ui h1{font-size:1em;color:#fff;font-family:-apple-system,system-ui,sans-serif;font-weight:700}
.ui p{color:#66d9ff88;font-size:.7em;font-family:-apple-system,system-ui,sans-serif}
.hint{position:fixed;bottom:40px;left:0;right:0;text-align:center;color:#ffffff44;
font-size:.85em;font-family:-apple-system,system-ui,sans-serif;pointer-events:none;
transition:opacity 1s}
</style>
</head>
<body>
<div class="ui"><div><h1>Glyph Particles</h1><p>Glyph Art \u00b7 Touch to create</p></div></div>
<canvas id="c"></canvas>
<div class="hint" id="hint">Touch anywhere to begin</div>
<script>
const c=document.getElementById('c'),x=c.getContext('2d');
let W,H,pts=[],touched=false;
function resize(){W=c.width=innerWidth*2;H=c.height=innerHeight*2;
c.style.width=innerWidth+'px';c.style.height=innerHeight+'px';
x.scale(2,2);}
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

export const ALL_DEMOS: DemoExperience[] = [
  {
    id: 'trivia',
    title: TRIVIA_DEMO.title,
    icon: 'TRV',
    description: 'A 5-question quiz about Glyph. Answer questions, get scored instantly.',
    templateType: 'trivia',
    html: TRIVIA_DEMO.html,
    estimatedFrames: '~45 frames',
  },
  {
    id: 'article',
    title: ARTICLE_DEMO.title,
    icon: 'ART',
    description: 'A beautifully styled article about vanishing communication. Serif fonts, reading experience.',
    templateType: 'article',
    html: ARTICLE_DEMO.html,
    estimatedFrames: '~35 frames',
  },
  {
    id: 'adventure',
    title: ADVENTURE_DEMO.title,
    icon: 'ADV',
    description: 'A branching choose-your-own-adventure story about encrypted doors and vanishing messages.',
    templateType: 'adventure',
    html: ADVENTURE_DEMO.html,
    estimatedFrames: '~55 frames',
  },
  {
    id: 'art',
    title: ART_DEMO.title,
    icon: 'VIS',
    description: 'Interactive particle art canvas. Touch to create flowing trails in Glyph colors.',
    templateType: 'art',
    html: ART_DEMO.html,
    estimatedFrames: '~30 frames',
  },
]
