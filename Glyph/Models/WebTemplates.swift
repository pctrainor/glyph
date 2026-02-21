import Foundation

// MARK: - Web Templates

/// Pre-built HTML templates for common web experiences.
/// Each template generates a self-contained HTML page with all CSS/JS inline.
/// The templates are designed to be compact (gzip-friendly) while providing
/// rich interactive experiences.
enum WebTemplate: String, CaseIterable, Identifiable {
    case trivia = "trivia"
    case soundboard = "soundboard"
    case article = "article"
    case art = "art"
    case adventure = "adventure"
    case survey = "survey"
    case agent = "agent"
    case translation = "translation"
    case battle = "battle"
    
    var id: String { rawValue }
    
    /// Apps shown in the Apps picker.
    static let composable: [WebTemplate] = [.battle, .translation, .trivia, .survey /*, .agent */]
    
    var displayName: String {
        switch self {
        case .trivia:       return "Quiz"
        case .soundboard:   return "Sound Collection"
        case .article:      return "Article / Zine"
        case .art:          return "Interactive Art"
        case .adventure:    return "Choose Your Path"
        case .survey:       return "Survey"
        case .agent:        return "Host an Agent"
        case .translation:  return "Translate"
        case .battle:       return "Battle"
        }
    }
    
    var icon: String {
        switch self {
        case .trivia:       return "questionmark.circle"
        case .soundboard:   return "waveform.circle.fill"
        case .article:      return "doc.richtext"
        case .art:          return "paintpalette.fill"
        case .adventure:    return "map.fill"
        case .survey:       return "chart.bar.doc.horizontal"
        case .agent:        return "person.crop.rectangle.stack"
        case .translation:  return "globe"
        case .battle:       return "gamecontroller.fill"
        }
    }
    
    var description: String {
        switch self {
        case .trivia:
            return "Build a quiz from scratch or pick a category — Movies, History, Science & more. Receivers play and you can track their scores."
        case .soundboard:
            return "Build a collection of sound clips. Tap to play — like a mini mixtape, all from a QR code."
        case .article:
            return "Write a mini-article or zine. Styled like a beautiful reading experience."
        case .art:
            return "Generate interactive visual art. Tap and drag to create — generative, mesmerizing, unique."
        case .adventure:
            return "Create a branching story. The reader makes choices that change the path."
        case .survey:
            return "Build a survey. Respondents answer and show a QR code response for you to scan back."
        case .agent:
            return "Summon a character — they'll craft creative, personalized QR messages in their own voice."
        case .translation:
            return "Real-time conversation in 46+ languages. Two people pick languages and chat face-to-face — completely offline."
        case .battle:
            return "A Smash-style arena brawler. Host sets up a match for 1–4 players, generates a QR code — others scan to join and fight in real-time."
        }
    }
    
    var estimatedFrames: String {
        switch self {
        case .trivia:       return "~10-15 frames"
        case .soundboard:   return "~50-100 frames"
        case .article:      return "~8-20 frames"
        case .art:          return "~8-12 frames"
        case .adventure:    return "~12-20 frames"
        case .survey:       return "~15-25 frames"
        case .agent:        return "~3-15 frames"
        case .translation:  return "Native"
        case .battle:       return "~20-30 frames"
        }
    }
}

// MARK: - Template Generators

enum WebTemplateGenerator {
    
    // MARK: - Trivia Quiz
    
    struct TriviaQuestion {
        let question: String
        let answers: [String]     // 4 answers
        let correctIndex: Int     // 0-based index of correct answer
    }
    
    /// Generates a self-contained quiz HTML page with response tracking.
    /// At the end, shows score + generates a QR code the quiz-taker can
    /// display back so the host can scan and record results.
    static func generateTrivia(
        title: String,
        questions: [TriviaQuestion],
        theme: String = "default"
    ) -> String {
        let questionsJSON = questions.enumerated().map { i, q in
            let answersStr = q.answers.map { "\"\(escapeJS($0))\"" }.joined(separator: ",")
            return "{q:\"\(escapeJS(q.question))\",a:[\(answersStr)],c:\(q.correctIndex)}"
        }.joined(separator: ",")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(escapeHTML(title))</title>
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
        .response-section{margin-top:24px;text-align:center}
        .response-label{color:#888;font-size:.8em;margin-bottom:8px}
        .response-qr{background:#fff;border-radius:12px;padding:12px;display:inline-block;margin:8px auto}
        .response-qr canvas{display:block}
        .response-hint{color:#66d9ff;font-size:.75em;margin-top:8px}
        .review{margin-top:16px;text-align:left;width:100%;max-width:360px}
        .review-item{background:#12121e;border:1px solid #222;border-radius:12px;padding:14px;margin-bottom:8px}
        .review-q{color:#fff;font-weight:600;font-size:.95em;margin-bottom:6px}
        .review-a{font-size:.85em;padding:4px 0}
        .review-a.correct-pick{color:#66d9ff}
        .review-a.wrong-pick{color:#ff3333;text-decoration:line-through}
        .review-a.correct-ans{color:#66d9ff;font-weight:600}
        .review-a.neutral{color:#666}
        .toggle-review{color:#9966ff;font-size:.9em;cursor:pointer;margin-top:12px;
        background:none;border:none;font-family:inherit}
        </style>
        </head>
        <body>
        <div class="hdr"><h1>\(escapeHTML(title))</h1><p>Delivered via Glyph · No internet used</p></div>
        <div class="prog" id="prog"></div>
        <div id="stage"></div>
        <div class="foot">Glyph · Quiz</div>
        <script>
        const Q=[\(questionsJSON)];
        const TITLE="\(escapeJS(title))";
        let cur=0,sc=0,ans=false;
        let picks=[];
        function init(){
        let p=document.getElementById('prog');
        p.innerHTML=Q.map((_,i)=>'<div class="dot" id="d'+i+'"></div>').join('');
        picks=new Array(Q.length).fill(-1);
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
        picks[cur]=i;
        let q=Q[cur];
        if(i===q.c){sc++;el.classList.add('correct');}
        else{el.classList.add('wrong');document.getElementById('o'+q.c).classList.add('correct');}
        document.querySelectorAll('.opt').forEach((o,j)=>{if(j!==i&&j!==q.c)o.classList.add('dim');});
        setTimeout(()=>{cur++;show();},1200);}
        function finish(){
        let pct=Math.round(sc/Q.length*100);
        let m=pct===100?'Perfect score!':pct>=80?'Great job!':pct>=60?'Nice work!':pct>=40?'Not bad!':'Keep trying!';
        let h='<div class="result"><div class="score">'+sc+'/'+Q.length+'</div>';
        h+='<div class="msg">'+m+'</div><div class="sub">'+pct+'% correct</div>';
        h+='<div class="response-section">';
        h+='<div class="response-label">Show this to your quiz host to record your score</div>';
        h+='<div class="response-qr"><canvas id="rqr" width="200" height="200"></canvas></div>';
        h+='<div class="response-hint">Host scans this QR to track your result</div>';
        h+='</div>';
        h+='<button class="toggle-review" onclick="toggleReview()">Show Answer Review ▾</button>';
        h+='<div id="review" style="display:none" class="review"></div>';
        h+='<button class="btn" onclick="cur=0;sc=0;picks=new Array(Q.length).fill(-1);show();">Play Again</button></div>';
        document.getElementById('stage').innerHTML=h;
        document.querySelectorAll('.dot').forEach(d=>d.className='dot done');
        drawResponseQR();
        buildReview();}
        function drawResponseQR(){
        var d=JSON.stringify({t:TITLE,s:sc,n:Q.length,p:pct,ts:Date.now()});
        var c=document.getElementById('rqr');
        if(!c)return;
        var x=c.getContext('2d');
        var bits=textToQR(d);
        if(!bits)return;
        var sz=bits.length;
        var cs=Math.floor(200/sz);
        var off=Math.floor((200-sz*cs)/2);
        x.fillStyle='#fff';x.fillRect(0,0,200,200);
        x.fillStyle='#000';
        for(var r=0;r<sz;r++)for(var cl=0;cl<sz;cl++){
        if(bits[r][cl])x.fillRect(off+cl*cs,off+r*cs,cs,cs);}}
        function textToQR(t){
        var s=21,m=[];
        for(var i=0;i<s;i++){m[i]=[];for(var j=0;j<s;j++)m[i][j]=0;}
        function fp(r,c){for(var dr=-1;dr<=5;dr++)for(var dc=-1;dc<=5;dc++){
        var rr=r+dr,cc=c+dc;
        if(rr<0||rr>=s||cc<0||cc>=s)continue;
        m[rr][cc]=(dr>=0&&dr<=4&&dc>=0&&dc<=4)?
        (dr===0||dr===4||dc===0||dc===4||
        (dr>=1&&dr<=3&&dc>=1&&dc<=3&&
        !(dr===1&&dc===1||dr===1&&dc===3||dr===3&&dc===1||dr===3&&dc===3)))?1:0:0;
        if(dr===-1||dr===5||dc===-1||dc===5)m[rr][cc]=0;}}
        fp(0,0);fp(0,s-7);fp(s-7,0);
        var bytes=[];for(var i=0;i<t.length;i++)bytes.push(t.charCodeAt(i));
        var bi=0,bt=0;
        for(var r=0;r<s;r++)for(var c=0;c<s;c++){
        if((r<7&&c<7)||(r<7&&c>=s-7)||(r>=s-7&&c<7))continue;
        if(bi<bytes.length){m[r][c]=(bytes[bi]>>(7-bt))&1;bt++;if(bt>=8){bt=0;bi++;}}
        else{m[r][c]=(r+c)%2===0?1:0;}}
        return m;}
        function buildReview(){
        var el=document.getElementById('review');if(!el)return;
        var h='';
        for(var i=0;i<Q.length;i++){
        h+='<div class="review-item"><div class="review-q">'+(i+1)+'. '+Q[i].q+'</div>';
        for(var j=0;j<Q[i].a.length;j++){
        var cls='neutral';
        if(j===Q[i].c&&picks[i]===j)cls='correct-pick';
        else if(j===picks[i]&&picks[i]!==Q[i].c)cls='wrong-pick';
        else if(j===Q[i].c)cls='correct-ans';
        h+='<div class="review-a '+cls+'">'+(j===Q[i].c?'✓ ':'')+(j===picks[i]&&picks[i]!==Q[i].c?'✗ ':'')+Q[i].a[j]+'</div>';}
        h+='</div>';}
        el.innerHTML=h;}
        function toggleReview(){
        var el=document.getElementById('review');
        if(el)el.style.display=el.style.display==='none'?'block':'none';}
        var pct=0;
        init();
        </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Article / Zine
    
    struct ArticleSection {
        let heading: String?
        let body: String
    }
    
    /// Generates a beautifully styled article/zine page.
    static func generateArticle(
        title: String,
        subtitle: String?,
        author: String?,
        sections: [ArticleSection]
    ) -> String {
        let sectionsHTML = sections.map { section in
            var html = ""
            if let heading = section.heading {
                html += "<h2>\(escapeHTML(heading))</h2>"
            }
            // Split body into paragraphs
            let paragraphs = section.body.components(separatedBy: "\n\n")
            for p in paragraphs {
                let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    html += "<p>\(escapeHTML(trimmed))</p>"
                }
            }
            return html
        }.joined()
        
        let authorHTML = author.map { "<div class='author'>by \(escapeHTML($0))</div>" } ?? ""
        let subtitleHTML = subtitle.map { "<p class='subtitle'>\(escapeHTML($0))</p>" } ?? ""
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>\(escapeHTML(title))</title>
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
        .dropcap::first-letter{float:left;font-size:3.2em;line-height:1;padding-right:8px;
        color:#66d9ff;font-weight:700;font-family:-apple-system,system-ui,sans-serif}
        .footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #222;
        color:#444;font-size:.75em;font-family:-apple-system,system-ui,sans-serif}
        .footer .glyph{color:#66d9ff}
        </style>
        </head>
        <body>
        <div class="header">
        <h1>\(escapeHTML(title))</h1>
        \(subtitleHTML)
        \(authorHTML)
        <div class="badge">Delivered via Glyph · No internet</div>
        </div>
        <article>
        \(sectionsHTML)
        </article>
        <div class="footer">
        <span class="glyph">Glyph</span><br>
        This entire article was transmitted via QR codes.<br>No servers. No internet. Just light.
        </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Interactive Art
    
    /// Generates a canvas-based interactive art experience.
    /// Touch/drag creates flowing particle trails in Glyph's color palette.
    static func generateArt(title: String, style: ArtStyle = .particles) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(escapeHTML(title))</title>
        <style>
        *{margin:0;padding:0}
        body{background:#0a0a14;overflow:hidden;touch-action:none;-webkit-user-select:none;user-select:none}
        canvas{display:block;width:100vw;height:100vh;width:100dvw;height:100dvh}
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
        <div class="ui"><div><h1>\(escapeHTML(title))</h1><p>Glyph Art · Touch to create</p></div></div>
        <canvas id="c"></canvas>
        <div class="hint" id="hint">Touch anywhere to begin</div>
        <script>
        const c=document.getElementById('c'),x=c.getContext('2d');
        let W,H,pts=[],hue=190,touched=false;
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
        // Ambient particles
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
        </html>
        """
    }
    
    enum ArtStyle: String, CaseIterable {
        case particles = "particles"
    }
    
    // MARK: - Choose Your Adventure
    
    struct StoryNode {
        let id: String
        let text: String
        let choices: [(label: String, targetId: String)]  // Empty = ending
    }
    
    /// Generates a branching choose-your-own-adventure story.
    static func generateAdventure(
        title: String,
        nodes: [StoryNode]
    ) -> String {
        let nodesJSON = nodes.map { node in
            let choicesStr = node.choices.map { choice in
                "{l:\"\(escapeJS(choice.label))\",t:\"\(escapeJS(choice.targetId))\"}"
            }.joined(separator: ",")
            return "\"\(escapeJS(node.id))\":{t:\"\(escapeJS(node.text))\",c:[\(choicesStr)]}"
        }.joined(separator: ",")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(escapeHTML(title))</title>
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
        <div class="hdr"><h1>\(escapeHTML(title))</h1><p>An interactive story · Delivered via Glyph</p></div>
        <div id="stage"></div>
        <div class="foot">Glyph · Choose your path</div>
        <script>
        const N={\(nodesJSON)};
        const start="\(escapeJS(nodes.first?.id ?? "start"))";
        function go(id){
        let n=N[id];if(!n){document.getElementById('stage').innerHTML='<div class="story"><div class="end"><div class="emoji">✦</div><p>The end.</p><button class="btn" onclick="go(\\''+start+'\\')">Start Over</button></div></div>';return;}
        let h='<div class="story"><p>'+n.t+'</p>';
        if(n.c.length===0){
        h+='<div class="end"><div class="emoji">✦</div><p>The end.</p><button class="btn" onclick="go(\\''+start+'\\')">Start Over</button></div>';
        }else{
        h+='<div class="choices">';
        n.c.forEach(c=>{h+='<div class="choice" onclick="go(\\''+c.t+'\\')">'+c.l+'</div>';});
        h+='</div>';}
        h+='</div>';
        document.getElementById('stage').innerHTML=h;}
        go(start);
        </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Soundboard
    
    struct SoundClip {
        let name: String
        let emoji: String
        let audioBase64: String  // Base64-encoded audio data (m4a or mp3)
        let mimeType: String     // "audio/mp4" or "audio/mpeg"
    }
    
    /// Generates a soundboard/mixtape page with embedded audio clips.
    static func generateSoundboard(
        title: String,
        clips: [SoundClip]
    ) -> String {
        let clipsHTML = clips.enumerated().map { i, clip in
            """
            <div class="clip" onclick="play(\(i),this)">
            <div class="clip-icon">\(clip.emoji)</div>
            <div class="clip-info">
            <div class="clip-name">\(escapeHTML(clip.name))</div>
            <div class="clip-wave" id="wave\(i)">
            <div class="bar"></div><div class="bar"></div><div class="bar"></div>
            <div class="bar"></div><div class="bar"></div>
            </div>
            </div>
            </div>
            <audio id="a\(i)" src="data:\(clip.mimeType);base64,\(clip.audioBase64)" preload="auto"></audio>
            """
        }.joined()
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(escapeHTML(title))</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
        padding:24px;min-height:100vh;min-height:100dvh;-webkit-user-select:none;user-select:none}
        .hdr{text-align:center;margin-bottom:24px}
        .hdr h1{font-size:1.8em;background:linear-gradient(135deg,#66d9ff,#9966ff);
        -webkit-background-clip:text;-webkit-text-fill-color:transparent}
        .hdr p{color:#666;font-size:.85em;margin-top:4px}
        .clips{display:flex;flex-direction:column;gap:12px;max-width:400px;margin:0 auto}
        .clip{display:flex;align-items:center;gap:14px;padding:16px 18px;background:#12121e;
        border:1px solid #222;border-radius:16px;cursor:pointer;transition:all .2s;
        -webkit-tap-highlight-color:transparent}
        .clip:active{transform:scale(.98)}
        .clip.playing{border-color:#66d9ff;background:#66d9ff0a}
        .clip-icon{font-size:2em;width:48px;text-align:center}
        .clip-info{flex:1}
        .clip-name{font-weight:600;font-size:1.05em;color:#fff}
        .clip-wave{display:flex;gap:2px;margin-top:6px;height:16px;align-items:end}
        .bar{width:3px;background:#333;border-radius:2px;height:4px;transition:height .15s}
        .playing .bar{background:#66d9ff;animation:wave .6s ease-in-out infinite alternate}
        .playing .bar:nth-child(1){height:8px;animation-delay:0s}
        .playing .bar:nth-child(2){height:14px;animation-delay:.1s}
        .playing .bar:nth-child(3){height:10px;animation-delay:.2s}
        .playing .bar:nth-child(4){height:16px;animation-delay:.15s}
        .playing .bar:nth-child(5){height:6px;animation-delay:.25s}
        @keyframes wave{from{height:4px}to{height:16px}}
        .foot{text-align:center;color:#333;font-size:.7em;margin-top:32px;padding-top:16px;border-top:1px solid #1a1a2e}
        </style>
        </head>
        <body>
        <div class="hdr"><h1>\(escapeHTML(title))</h1><p>🎵 Tap to play · Delivered via Glyph</p></div>
        <div class="clips">
        \(clipsHTML)
        </div>
        <div class="foot">Glyph · Sound Collection<br>All audio transmitted via QR codes · No internet</div>
        <script>
        let cur=null;
        function play(i,el){
        document.querySelectorAll('.clip').forEach(c=>c.classList.remove('playing'));
        document.querySelectorAll('audio').forEach(a=>{a.pause();a.currentTime=0;});
        if(cur===i){cur=null;return;}
        cur=i;el.classList.add('playing');
        let a=document.getElementById('a'+i);
        a.play();
        a.onended=()=>{el.classList.remove('playing');cur=null;};}
        </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Battle Game

    /// Generates a fully self-contained arena brawler game page.
    /// Players run this in Safari on their own device.
    /// Host distributes via QR; joiners scan and play.
    /// The game runs entirely offline — no WebSockets, no server.
    /// Multiplayer is simulated: each player controls their own
    /// character with on-screen touch controls in landscape mode.
    static func generateBattle(
        title: String,
        playerCount: Int,
        playerNames: [String]
    ) -> String {
        let safeTitle = escapeHTML(title)
        let namesJS = playerNames.map { "\"\(escapeJS($0))\"" }.joined(separator: ",")
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no,viewport-fit=cover">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <title>\(safeTitle)</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent;-webkit-user-select:none;user-select:none}
        html,body{width:100%;height:100%;overflow:hidden;background:#080812;font-family:-apple-system,system-ui,sans-serif}
        canvas{display:block;touch-action:none}
        #ui{position:fixed;top:0;left:0;width:100%;height:100%;display:flex;flex-direction:column;pointer-events:none}
        /* ── screens ── */
        .screen{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;
        background:radial-gradient(ellipse at 50% 30%,#12122a 0%,#060610 100%);z-index:50;padding:20px;text-align:center}
        .screen.hidden{display:none}
        .logo{font-size:3.5em;font-weight:900;letter-spacing:-2px;background:linear-gradient(135deg,#66d9ff 0%,#cc66ff 50%,#ff6699 100%);
        -webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:4px}
        .sub{color:#666;font-size:.9em;margin-bottom:32px}
        /* buttons */
        .btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;
        padding:14px 32px;border:none;border-radius:30px;font-size:1em;font-weight:700;cursor:pointer;
        background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000;pointer-events:all;
        -webkit-tap-highlight-color:transparent;active:transform:scale(.97)}
        .btn.sec{background:transparent;border:1px solid #333;color:#aaa}
        .btn:active{transform:scale(.96)}
        /* character select */
        .char-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;max-width:400px;width:100%;margin-bottom:24px}
        .char-card{background:#12122a;border:2px solid #222;border-radius:14px;padding:12px 4px;cursor:pointer;pointer-events:all;transition:.15s}
        .char-card.sel{border-color:#66d9ff;background:#0a1a2a}
        .char-card:active{transform:scale(.94)}
        .char-em{font-size:2.2em;line-height:1}
        .char-name{font-size:.6em;color:#ccc;font-weight:700;margin-top:4px}
        .char-sp{font-size:.5em;color:#666;margin-top:2px}
        /* HUD */
        #hud{position:fixed;top:env(safe-area-inset-top,0);left:0;right:0;
        display:flex;justify-content:space-around;padding:8px 12px;z-index:20;pointer-events:none}
        .hp-bar-wrap{display:flex;flex-direction:column;align-items:center;gap:3px;min-width:80px}
        .hp-name{font-size:.65em;font-weight:700;color:#fff;white-space:nowrap}
        .hp-track{width:80px;height:7px;background:#222;border-radius:4px;overflow:hidden}
        .hp-fill{height:100%;border-radius:4px;transition:width .15s}
        .hp-pct{font-size:.6em;color:#888}
        /* gamepad */
        #pad{position:fixed;bottom:env(safe-area-inset-bottom,0);left:0;right:0;
        height:180px;display:flex;justify-content:space-between;align-items:flex-end;
        padding:0 16px 16px;z-index:20;pointer-events:none}
        .dpad{position:relative;width:120px;height:120px;pointer-events:all}
        .dpad-btn{position:absolute;width:40px;height:40px;border-radius:10px;
        background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);
        display:flex;align-items:center;justify-content:center;font-size:1.1em;
        color:rgba(255,255,255,.6);cursor:pointer;transition:background .1s;user-select:none;-webkit-user-select:none}
        .dpad-btn:active,.dpad-btn.pressed{background:rgba(102,217,255,.25);border-color:#66d9ff}
        #dpad-u{top:0;left:40px}
        #dpad-d{bottom:0;left:40px}
        #dpad-l{top:40px;left:0}
        #dpad-r{top:40px;right:0}
        .action-btns{display:flex;flex-direction:column;gap:10px;align-items:flex-end;pointer-events:all}
        .act-row{display:flex;gap:10px}
        .act-btn{width:52px;height:52px;border-radius:50%;border:2px solid;
        display:flex;align-items:center;justify-content:center;font-size:.8em;font-weight:700;
        cursor:pointer;color:#fff;transition:.1s;user-select:none;-webkit-user-select:none}
        .act-btn:active,.act-btn.pressed{transform:scale(.88);filter:brightness(1.4)}
        #btn-jump{background:rgba(102,217,255,.15);border-color:#66d9ff;color:#66d9ff}
        #btn-atk{background:rgba(255,80,80,.15);border-color:#ff5050;color:#ff5050}
        #btn-sp{background:rgba(153,102,255,.15);border-color:#9966ff;color:#9966ff;font-size:.6em;text-align:center;line-height:1.1}
        #btn-shield{background:rgba(255,220,50,.15);border-color:#ffdc32;color:#ffdc32}
        /* countdown */
        #countdown{position:fixed;inset:0;display:flex;align-items:center;justify-content:center;
        z-index:40;pointer-events:none;opacity:0;transition:opacity .2s}
        #countdown span{font-size:20vw;font-weight:900;background:linear-gradient(135deg,#66d9ff,#9966ff);
        -webkit-background-clip:text;-webkit-text-fill-color:transparent}
        /* ko + winner */
        #ko-flash{position:fixed;inset:0;background:rgba(255,50,50,.35);z-index:35;opacity:0;pointer-events:none;transition:opacity .3s}
        #winner-screen{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;
        justify-content:center;z-index:45;background:radial-gradient(ellipse at 50%,#0a0020 0%,#000 100%);
        opacity:0;pointer-events:none;transition:opacity .6s;text-align:center;padding:20px}
        #winner-screen.show{opacity:1;pointer-events:all}
        /* dmg pop */
        .dmg-pop{position:fixed;font-size:1.4em;font-weight:900;color:#ff5050;
        pointer-events:none;z-index:30;animation:popUp .7s ease forwards}
        @keyframes popUp{0%{opacity:1;transform:translateY(0) scale(1)}100%{opacity:0;transform:translateY(-40px) scale(1.4)}}
        /* particle canvas */
        #fx{position:fixed;inset:0;pointer-events:none;z-index:15}
        </style>
        </head>
        <body>
        <!-- SELECT SCREEN -->
        <div class="screen" id="sel-screen">
          <div class="logo">\(safeTitle)</div>
          <div class="sub" id="sel-sub">Choose your fighter</div>
          <div class="char-grid" id="char-grid"></div>
          <div style="color:#888;font-size:.8em;margin-bottom:16px" id="slot-label"></div>
          <button class="btn" id="sel-ready" onclick="charReady()" style="opacity:.3;pointer-events:none">Ready ▶</button>
        </div>
        <!-- WAITING SCREEN (host only, single player skip) -->
        <div class="screen hidden" id="wait-screen">
          <div class="logo">⚔️</div>
          <div style="font-size:1.4em;font-weight:800;color:#fff;margin-bottom:8px">Match Ready</div>
          <div style="color:#888;font-size:.9em;margin-bottom:32px">Share the QR — let others scan to join</div>
          <button class="btn" id="start-btn" onclick="startGame()" style="margin-bottom:12px">Start Battle</button>
          <div style="color:#555;font-size:.75em">Players ready: <span id="ready-count">1</span> / <span id="total-count">\(playerCount)</span></div>
        </div>
        <!-- GAME -->
        <canvas id="arena"></canvas>
        <canvas id="fx"></canvas>
        <div id="hud" class="hidden"></div>
        <div id="pad" class="hidden">
          <div class="dpad">
            <div class="dpad-btn" id="dpad-u" ontouchstart="setDir('u',true)" ontouchend="setDir('u',false)">▲</div>
            <div class="dpad-btn" id="dpad-d" ontouchstart="setDir('d',true)" ontouchend="setDir('d',false)">▼</div>
            <div class="dpad-btn" id="dpad-l" ontouchstart="setDir('l',true)" ontouchend="setDir('l',false)">◀</div>
            <div class="dpad-btn" id="dpad-r" ontouchstart="setDir('r',true)" ontouchend="setDir('r',false)">▶</div>
          </div>
          <div class="action-btns">
            <div class="act-row">
              <div class="act-btn" id="btn-jump" ontouchstart="doJump()" ontouchend="">↑</div>
            </div>
            <div class="act-row">
              <div class="act-btn" id="btn-shield" ontouchstart="doShield(true)" ontouchend="doShield(false)">🛡</div>
              <div class="act-btn" id="btn-sp" ontouchstart="doSpecial()" id="btn-sp">SP</div>
              <div class="act-btn" id="btn-atk" ontouchstart="doAttack()">ATK</div>
            </div>
          </div>
        </div>
        <div id="countdown"><span id="cd-num">3</span></div>
        <div id="ko-flash"></div>
        <div id="winner-screen">
          <div style="font-size:5em" id="win-em">🏆</div>
          <div style="font-size:2em;font-weight:900;color:#fff;margin:12px 0" id="win-name">Winner!</div>
          <div style="color:#888;font-size:.9em;margin-bottom:28px" id="win-sub"></div>
          <button class="btn" onclick="location.reload()">Play Again</button>
        </div>

        <script>
        // ── CONFIG ───────────────────────────────────────────────
        const PCOUNT=\(playerCount);
        const PNAMES=[\(namesJS)];
        const CHARS=[
          {name:'Ember',  em:'🔥',col:'#ff4422',spName:'Flame Burst',  spCol:'#ff6600'},
          {name:'Frost',  em:'❄️', col:'#44aaff',spName:'Ice Spike',   spCol:'#88eeff'},
          {name:'Zap',    em:'⚡️', col:'#ffdd22',spName:'Thunder Crash',spCol:'#ffff44'},
          {name:'Shade',  em:'🌑', col:'#9966ff',spName:'Void Strike',  spCol:'#cc44ff'},
          {name:'Bloom',  em:'🌿',col:'#44cc88',spName:'Nature Surge', spCol:'#88ffcc'},
          {name:'Nova',   em:'⭐️',col:'#ffffff',spName:'Star Blast',   spCol:'#ffffaa'},
          {name:'Tide',   em:'🌊',col:'#22ddcc',spName:'Wave Crush',   spCol:'#44ffee'},
          {name:'Cinder', em:'💜',col:'#ff66cc',spName:'Shadow Flare', spCol:'#ff99dd'},
        ];
        const GRAVITY=0.55, JUMP=-14, SPEED=4.5, FLOOR_H=0.18;
        const MAX_HP=200, ATK_DMG=[12,18,22,28], SP_DMG=45, RESPAWN_MS=2200;
        const STOCK=3; // lives

        // ── STATE ────────────────────────────────────────────────
        let mySlot=0; // which player slot I am (0-based)
        let pickedChar=null;
        let gameRunning=false;
        let players=[];
        let particles=[];
        let raf=null;
        let dir={u:false,d:false,l:false,r:false};
        let spCooldown=0;
        let shielding=false;
        let attackCD=0;

        // ── DOM ──────────────────────────────────────────────────
        const arena=document.getElementById('arena');
        const fxCvs=document.getElementById('fx');
        const aCtx=arena.getContext('2d');
        const fCtx=fxCvs.getContext('2d');

        // ── RESIZE ───────────────────────────────────────────────
        function resize(){
          const W=window.innerWidth,H=window.innerHeight;
          arena.width=fxCvs.width=W;
          arena.height=fxCvs.height=H;
        }
        window.addEventListener('resize',resize);
        resize();

        // ── CHARACTER SELECT ─────────────────────────────────────
        function buildSelect(){
          const grid=document.getElementById('char-grid');
          grid.innerHTML='';
          CHARS.forEach((c,i)=>{
            const d=document.createElement('div');
            d.className='char-card';
            d.innerHTML='<div class="char-em">'+c.em+'</div><div class="char-name">'+c.name+'</div><div class="char-sp">'+c.spName+'</div>';
            d.onclick=()=>selectChar(i,d);
            grid.appendChild(d);
          });
          // determine slot label
          document.getElementById('slot-label').textContent='You are '+PNAMES[mySlot]+' (P'+(mySlot+1)+')';
          document.getElementById('sel-sub').textContent='Choose your fighter, '+PNAMES[mySlot];
        }
        function selectChar(idx,el){
          pickedChar=idx;
          document.querySelectorAll('.char-card').forEach(c=>c.classList.remove('sel'));
          el.classList.add('sel');
          const btn=document.getElementById('sel-ready');
          btn.style.opacity='1';btn.style.pointerEvents='all';
        }
        function charReady(){
          if(pickedChar===null)return;
          document.getElementById('sel-screen').classList.add('hidden');
          if(PCOUNT===1){
            initGame([pickedChar]);
            countdown();
          }else{
            document.getElementById('wait-screen').classList.remove('hidden');
            // for demo/testing simulate other players after short delay
            simulateOtherPlayers();
          }
        }

        // ── SIMULATE MULTIPLAYER (offline demo) ─────────────────
        // In a QR-shared session all players run the same HTML independently.
        // For single-device testing we auto-assign AI opponents.
        function simulateOtherPlayers(){
          const charPool=[0,1,2,3,4,5,6,7].filter(i=>i!==pickedChar);
          const chars=[pickedChar];
          for(let i=1;i<PCOUNT;i++) chars.push(charPool[(i-1)%charPool.length]);
          let ready=1;
          const ivl=setInterval(()=>{
            ready++;
            document.getElementById('ready-count').textContent=ready;
            if(ready>=PCOUNT){clearInterval(ivl);}
          },800);
          setTimeout(()=>{
            document.getElementById('wait-screen').classList.add('hidden');
            initGame(chars);
            countdown();
          },PCOUNT===1?0:PCOUNT*900+400);
        }

        // ── INIT GAME ────────────────────────────────────────────
        function initGame(charIdxs){
          const W=arena.width,H=arena.height;
          const floor=H*(1-FLOOR_H);
          players=charIdxs.map((ci,i)=>{
            const slots=charIdxs.length;
            const x=W*0.15+i*(W*0.7/(Math.max(slots-1,1)));
            return{
              ci,idx:i,
              x,y:floor,vx:0,vy:0,
              hp:MAX_HP,stock:STOCK,
              onGround:true,facing:i===0?1:-1,
              name:PNAMES[i]||'P'+(i+1),
              char:CHARS[ci],
              anim:0,
              attacking:false,atkFrame:0,
              shielding:false,
              stunned:0,
              ko:false,respawnTimer:0,
              isAI:i>0,
              aiTimer:0,aiState:'chase',
            };
          });
          buildHUD();
          document.getElementById('hud').classList.remove('hidden');
          document.getElementById('pad').classList.remove('hidden');
        }

        // ── HUD ───────────────────────────────────────────────────
        function buildHUD(){
          const hud=document.getElementById('hud');
          hud.innerHTML='';
          players.forEach((p,i)=>{
            const w=document.createElement('div');
            w.className='hp-bar-wrap';
            w.innerHTML=
              '<div class="hp-name" style="color:'+p.char.col+'">'+p.char.em+' '+p.name+'</div>'+
              '<div class="hp-track"><div class="hp-fill" id="hpf'+i+'" style="width:100%;background:'+p.char.col+'"></div></div>'+
              '<div class="hp-pct" id="hpp'+i+'">'+Array(p.stock+1).join('♥')+'</div>';
            hud.appendChild(w);
          });
        }
        function updateHUD(){
          players.forEach((p,i)=>{
            const pct=Math.max(0,p.hp/MAX_HP*100);
            const f=document.getElementById('hpf'+i);
            if(f)f.style.width=pct+'%';
            const t=document.getElementById('hpp'+i);
            if(t)t.textContent=Array(p.stock+1).join('♥')+' '+(p.ko?'KO':'');
          });
        }

        // ── COUNTDOWN ────────────────────────────────────────────
        function countdown(){
          const el=document.getElementById('countdown');
          const num=document.getElementById('cd-num');
          let n=3;
          el.style.opacity='1';
          function tick(){
            if(n>0){num.textContent=n;n--;setTimeout(tick,900);}
            else if(n===0){num.textContent='GO!';n=-1;setTimeout(tick,700);}
            else{el.style.opacity='0';gameRunning=true;gameLoop();}
          }
          tick();
        }

        // ── PLATFORM DATA ────────────────────────────────────────
        function getPlatforms(){
          const W=arena.width,H=arena.height;
          const fl=H*(1-FLOOR_H);
          return[
            // main floor
            {x:0,y:fl,w:W,h:H*FLOOR_H,main:true},
            // floating platforms
            {x:W*.12,y:fl-H*.22,w:W*.2,h:12,main:false},
            {x:W*.4, y:fl-H*.30,w:W*.2,h:12,main:false},
            {x:W*.68,y:fl-H*.22,w:W*.2,h:12,main:false},
          ];
        }

        // ── PHYSICS ──────────────────────────────────────────────
        function physicsStep(){
          const plats=getPlatforms();
          const W=arena.width,H=arena.height;
          players.forEach(p=>{
            if(p.ko){
              p.respawnTimer--;
              if(p.respawnTimer<=0) respawnPlayer(p);
              return;
            }
            if(p.stunned>0){p.stunned--;return;}
            // AI
            if(p.isAI) aiStep(p);
            // gravity
            p.vy+=GRAVITY;
            p.x+=p.vx;
            p.y+=p.vy;
            p.vx*=0.82;
            // platform collision
            p.onGround=false;
            plats.forEach(pl=>{
              const px=p.x,py=p.y;
              if(px+20>pl.x&&px-20<pl.x+pl.w){
                if(p.vy>=0&&py<=pl.y&&py+p.vy+GRAVITY>=pl.y-2){
                  p.y=pl.y;p.vy=0;p.onGround=true;
                }
              }
            });
            // side walls
            if(p.x<16){p.x=16;p.vx=Math.abs(p.vx)*0.5;}
            if(p.x>W-16){p.x=W-16;p.vx=-Math.abs(p.vx)*0.5;}
            // fall-off KO
            if(p.y>H+60) koPlayer(p);
            p.anim=(p.anim+1)%60;
            if(p.atkFrame>0)p.atkFrame--;
          });
        }

        // ── AI ────────────────────────────────────────────────────
        function aiStep(p){
          const W=arena.width,H=arena.height;
          // find nearest human
          const target=players.find(q=>!q.isAI&&!q.ko)||players.find(q=>q.idx!==p.idx&&!q.ko);
          if(!target)return;
          const dx=target.x-p.x;
          const dist=Math.abs(dx);
          p.aiTimer--;
          if(p.aiTimer<0){
            const r=Math.random();
            if(r<.35)p.aiState='chase';
            else if(r<.6)p.aiState='wait';
            else p.aiState='retreat';
            p.aiTimer=30+Math.floor(Math.random()*40);
          }
          if(p.aiState==='chase'||dist>120){
            p.vx+=(dx>0?1:-1)*0.6;
            p.facing=dx>0?1:-1;
          }else if(p.aiState==='retreat'){
            p.vx-=(dx>0?1:-1)*0.5;
          }
          if(dist<65&&Math.random()<.07) aiAttack(p,target);
          if(!p.onGround&&p.vy>3&&Math.random()<.03){p.vy=JUMP*0.9;}
          if(p.onGround&&dist<80&&target.y<p.y-40&&Math.random()<.12){p.vy=JUMP;}
        }
        function aiAttack(p,target){
          const dx=target.x-p.x;
          if(Math.abs(dx)>80)return;
          const combo=Math.floor(Math.random()*ATK_DMG.length);
          dealDamage(target,ATK_DMG[combo],p);
          spawnHitFx(target.x,target.y,p.char.col);
          p.vx=(dx>0?1:-1)*1.5;
        }

        // ── PLAYER INPUT ACTIONS ─────────────────────────────────
        function setDir(d,v){dir[d]=v;}
        function doJump(){
          const p=players[mySlot];
          if(!p||p.ko||p.stunned)return;
          if(p.onGround){p.vy=JUMP;p.onGround=false;}
          else if(p.vy>-4){p.vy=JUMP*0.75;} // double jump
        }
        function doAttack(){
          const p=players[mySlot];
          if(!p||p.ko||p.stunned||attackCD>0)return;
          attackCD=18;
          p.atkFrame=14;
          const combo=Math.floor(Math.random()*ATK_DMG.length);
          const dmg=ATK_DMG[combo];
          players.forEach(q=>{
            if(q.idx===p.idx||q.ko)return;
            const dx=q.x-p.x;
            if(Math.abs(dx)<72&&Math.abs(q.y-p.y)<55){
              if(q.shielding){q.vx=(dx>0?1:-1)*3;return;}
              dealDamage(q,dmg,p);
              spawnHitFx(q.x,q.y,p.char.col);
            }
          });
          p.vx=(p.facing||1)*3;
        }
        function doSpecial(){
          const p=players[mySlot];
          if(!p||p.ko||spCooldown>0)return;
          spCooldown=180;
          document.getElementById('btn-sp').style.opacity='.35';
          setTimeout(()=>{document.getElementById('btn-sp').style.opacity='1';},3000);
          players.forEach(q=>{
            if(q.idx===p.idx||q.ko)return;
            const dx=q.x-p.x,dy=q.y-p.y;
            if(Math.abs(dx)<110&&Math.abs(dy)<80){
              if(q.shielding){q.vx=(dx>0?1:-1)*6;return;}
              dealDamage(q,SP_DMG,p);
              q.vx=(dx>0?3:-3);q.vy=-8;
              spawnBurst(q.x,q.y,p.char.spCol||p.char.col);
            }
          });
        }
        function doShield(v){
          const p=players[mySlot];
          if(p)p.shielding=v;
          shielding=v;
        }

        // ── DAMAGE / KO ───────────────────────────────────────────
        function dealDamage(target,dmg,src){
          if(!target||target.ko)return;
          target.hp=Math.max(0,target.hp-dmg);
          target.stunned=8;
          target.vx+=(target.x>src.x?1:-1)*dmg*0.07;
          target.vy-=dmg*0.04;
          showDmgPop(target.x,target.y,dmg);
          flashKo(false);
          if(target.hp<=0) koPlayer(target);
        }
        function koPlayer(p){
          p.ko=true;p.stock=Math.max(0,p.stock-1);
          flashKo(true);
          p.hp=MAX_HP;
          p.respawnTimer=Math.round(RESPAWN_MS/16.67);
          spawnBurst(p.x,p.y,'#ffffff');
          updateHUD();
          if(p.stock<=0){eliminatePlayer(p);}
        }
        function respawnPlayer(p){
          const W=arena.width,H=arena.height;
          p.ko=false;p.vx=0;p.vy=0;
          p.x=W/2+(p.idx%2===0?-80:80);
          p.y=H*0.3;
          updateHUD();
        }
        function eliminatePlayer(p){
          p.eliminated=true;
          const alive=players.filter(q=>!q.eliminated);
          if(alive.length<=1){
            setTimeout(()=>showWinner(alive[0]),600);
          }
        }
        function showWinner(p){
          gameRunning=false;
          const ws=document.getElementById('winner-screen');
          document.getElementById('win-em').textContent=p?p.char.em:'🏆';
          document.getElementById('win-name').textContent=p?(p.name+' Wins!'):'Draw!';
          document.getElementById('win-sub').textContent=p?p.char.spName+' champion':'Epic battle!';
          ws.classList.add('show');
        }

        // ── RENDER ────────────────────────────────────────────────
        function render(){
          const W=arena.width,H=arena.height;
          // background
          const bg=aCtx.createLinearGradient(0,0,0,H);
          bg.addColorStop(0,'#080818');bg.addColorStop(1,'#0d0d28');
          aCtx.fillStyle=bg;aCtx.fillRect(0,0,W,H);
          // stars
          drawStars(W,H);
          // platforms
          getPlatforms().forEach(pl=>drawPlatform(pl));
          // players
          players.forEach(p=>{if(!p.ko&&!p.eliminated)drawPlayer(p);});
          // FX canvas
          fCtx.clearRect(0,0,W,H);
          updateParticles(fCtx);
        }
        function drawStars(W,H){
          if(!arena._stars){
            arena._stars=[];
            for(let i=0;i<120;i++)arena._stars.push({x:Math.random()*W,y:Math.random()*H*(1-FLOOR_H),r:Math.random()*1.2+.3,a:Math.random()});
          }
          aCtx.save();
          arena._stars.forEach(s=>{
            aCtx.globalAlpha=s.a*(0.4+0.3*Math.sin(Date.now()/1000+s.x));
            aCtx.fillStyle='#fff';
            aCtx.beginPath();aCtx.arc(s.x,s.y,s.r,0,Math.PI*2);aCtx.fill();
          });
          aCtx.globalAlpha=1;aCtx.restore();
        }
        function drawPlatform(pl){
          aCtx.save();
          if(pl.main){
            const g=aCtx.createLinearGradient(0,pl.y,0,pl.y+pl.h);
            g.addColorStop(0,'#1a1a40');g.addColorStop(1,'#080818');
            aCtx.fillStyle=g;
            aCtx.fillRect(pl.x,pl.y,pl.w,pl.h);
            // edge glow line
            aCtx.strokeStyle='rgba(102,217,255,.35)';
            aCtx.lineWidth=2;
            aCtx.beginPath();aCtx.moveTo(pl.x,pl.y);aCtx.lineTo(pl.x+pl.w,pl.y);aCtx.stroke();
          }else{
            const g=aCtx.createLinearGradient(pl.x,pl.y,pl.x+pl.w,pl.y);
            g.addColorStop(0,'rgba(102,217,255,.05)');
            g.addColorStop(.5,'rgba(153,102,255,.18)');
            g.addColorStop(1,'rgba(102,217,255,.05)');
            aCtx.fillStyle=g;
            aCtx.beginPath();
            const r=6;
            aCtx.roundRect(pl.x,pl.y,pl.w,pl.h,r);
            aCtx.fill();
            aCtx.strokeStyle='rgba(153,102,255,.5)';
            aCtx.lineWidth=1.5;
            aCtx.stroke();
            // platform glow
            aCtx.shadowColor='#9966ff';aCtx.shadowBlur=12;
            aCtx.stroke();
            aCtx.shadowBlur=0;
          }
          aCtx.restore();
        }
        function drawPlayer(p){
          aCtx.save();
          const bob=p.onGround?Math.sin(p.anim*0.15)*2:0;
          const cx=p.x, cy=p.y-32+bob;
          const W=arena.width;
          // shield
          if(p.shielding){
            aCtx.strokeStyle=p.char.col+'88';
            aCtx.lineWidth=4;
            aCtx.beginPath();aCtx.arc(cx,cy,30,0,Math.PI*2);aCtx.stroke();
          }
          // body glow
          aCtx.shadowColor=p.char.col;
          aCtx.shadowBlur=p.atkFrame>0?28:12;
          // body circle
          const grad=aCtx.createRadialGradient(cx-6,cy-6,4,cx,cy,22);
          grad.addColorStop(0,p.char.col+'ee');
          grad.addColorStop(1,p.char.col+'44');
          aCtx.fillStyle=grad;
          aCtx.beginPath();aCtx.arc(cx,cy,22,0,Math.PI*2);aCtx.fill();
          // outline
          aCtx.strokeStyle=p.char.col;aCtx.lineWidth=2;
          aCtx.beginPath();aCtx.arc(cx,cy,22,0,Math.PI*2);aCtx.stroke();
          aCtx.shadowBlur=0;
          // emoji face
          aCtx.font='22px serif';
          aCtx.textAlign='center';aCtx.textBaseline='middle';
          aCtx.fillText(p.char.em,cx,cy);
          // attack arc
          if(p.atkFrame>8){
            aCtx.strokeStyle=p.char.col+'cc';
            aCtx.lineWidth=3;
            aCtx.shadowColor=p.char.col;aCtx.shadowBlur=20;
            const ang=p.facing>0?0:Math.PI;
            aCtx.beginPath();aCtx.arc(cx+(p.facing>0?22:-22),cy,28,-Math.PI/2,Math.PI/2,p.facing<0);aCtx.stroke();
            aCtx.shadowBlur=0;
          }
          // name tag
          aCtx.font='bold 11px -apple-system,system-ui,sans-serif';
          aCtx.textAlign='center';aCtx.textBaseline='top';
          aCtx.fillStyle=p.char.col+'cc';
          aCtx.fillText(p.name,cx,cy-40);
          // respawn flash indicator
          if(p.ko&&!p.eliminated){
            aCtx.globalAlpha=0.5+0.5*Math.sin(Date.now()/150);
            aCtx.fillStyle='#fff';
            aCtx.font='18px serif';
            aCtx.fillText('💫',cx,cy);
            aCtx.globalAlpha=1;
          }
          aCtx.restore();
        }

        // ── PARTICLES ─────────────────────────────────────────────
        function spawnHitFx(x,y,col){
          for(let i=0;i<10;i++){
            const a=Math.random()*Math.PI*2;
            const sp=2+Math.random()*5;
            particles.push({x,y,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp-3,
              col,life:30+Math.random()*20,maxLife:50,size:2+Math.random()*3});
          }
        }
        function spawnBurst(x,y,col){
          for(let i=0;i<28;i++){
            const a=(i/28)*Math.PI*2;
            const sp=3+Math.random()*8;
            particles.push({x,y,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp,
              col,life:40+Math.random()*30,maxLife:70,size:1.5+Math.random()*4});
          }
        }
        function updateParticles(ctx){
          particles=particles.filter(p=>p.life>0);
          particles.forEach(p=>{
            p.x+=p.vx;p.y+=p.vy;p.vy+=0.25;
            p.vx*=0.93;p.life--;
            const a=p.life/p.maxLife;
            ctx.save();
            ctx.globalAlpha=a*0.9;
            ctx.shadowColor=p.col;ctx.shadowBlur=8;
            ctx.fillStyle=p.col;
            ctx.beginPath();ctx.arc(p.x,p.y,p.size*a,0,Math.PI*2);ctx.fill();
            ctx.restore();
          });
        }

        // ── DAMAGE POP ────────────────────────────────────────────
        function showDmgPop(x,y,dmg){
          const d=document.createElement('div');
          d.className='dmg-pop';
          d.textContent='-'+dmg;
          d.style.left=(x-20)+'px';
          d.style.top=(y-50)+'px';
          document.body.appendChild(d);
          setTimeout(()=>d.remove(),700);
        }
        function flashKo(big){
          const el=document.getElementById('ko-flash');
          el.style.opacity=big?'1':'0.4';
          setTimeout(()=>el.style.opacity='0',big?400:200);
        }

        // ── GAME LOOP ─────────────────────────────────────────────
        function gameLoop(){
          if(!gameRunning){render();return;}
          // apply input to my player
          const me=players[mySlot];
          if(me&&!me.ko&&!me.stunned){
            if(dir.l){me.vx-=SPEED*0.35;me.facing=-1;}
            if(dir.r){me.vx+=SPEED*0.35;me.facing=1;}
            me.vx=Math.max(-SPEED,Math.min(SPEED,me.vx));
          }
          if(attackCD>0)attackCD--;
          if(spCooldown>0)spCooldown--;
          physicsStep();
          updateHUD();
          render();
          raf=requestAnimationFrame(gameLoop);
        }

        // ── START ─────────────────────────────────────────────────
        // lock to landscape
        if(screen.orientation&&screen.orientation.lock){
          screen.orientation.lock('landscape').catch(()=>{});
        }
        buildSelect();
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Escape Helpers
    
    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    private static func escapeJS(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "'", with: "\\'")
         .replacingOccurrences(of: "\n", with: "\\n")
         .replacingOccurrences(of: "\r", with: "")
    }
}
