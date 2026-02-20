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

export const ALL_DEMOS: DemoExperience[] = [
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
