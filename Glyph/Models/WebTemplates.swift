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
    
    var id: String { rawValue }
    
    /// Apps shown in the Apps picker.
    /// Translation, Quiz, and Survey are the core social apps.
    /// Agent is commented out pending future updates.
    static let composable: [WebTemplate] = [.translation, .trivia, .survey /*, .agent */]
    
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
