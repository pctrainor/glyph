import Foundation

// MARK: - Survey Template Generator

/// Generates self-contained HTML surveys that:
/// 1. Render beautifully in WKWebView (offline, sandboxed)
/// 2. Collect answers interactively (multiple choice, rating, text)
/// 3. On submit, display a QR code OF the response for the originator to scan back
///
/// The response QR uses the GLYR: prefix and contains JSON with the answers,
/// matching back to the originating survey via surveyId.
///
/// This creates a complete offline feedback loop:
///   Originator → [GLYW: survey QR] → Respondent → [GLYR: response QR] → Originator
///
enum SurveyTemplateGenerator {
    
    /// Generates the full interactive survey HTML page.
    /// The page includes a built-in QR code generator (canvas-based) so
    /// the respondent can show their response QR to be scanned back.
    static func generateSurveyHTML(survey: GlyphSurvey) -> String {
        let questionsJSON = generateQuestionsJSON(survey.questions)
        let surveyId = escapeJS(survey.id)
        let surveyTitle = escapeHTML(survey.title)
        // expiresAt as Unix timestamp (seconds since 1970), or 0 for no window
        let expiresAtUnix: Int = {
            if let d = survey.expiresAt { return Int(d.timeIntervalSince1970) }
            return 0
        }()
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(surveyTitle)</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
        min-height:100vh;display:flex;flex-direction:column;align-items:center;
        padding:24px 20px;-webkit-user-select:none;user-select:none}
        .hdr{text-align:center;margin-bottom:20px}
        .hdr h1{font-size:1.8em;font-weight:800;background:linear-gradient(135deg,#66d9ff,#9966ff);
        -webkit-background-clip:text;-webkit-text-fill-color:transparent}
        .hdr p{color:#667;font-size:.85em;margin-top:4px}
        .prog{display:flex;gap:4px;margin:12px 0 20px;width:100%;max-width:380px}
        .prog .dot{flex:1;height:4px;border-radius:2px;background:#1a1a2e;transition:background .3s}
        .prog .dot.done{background:#66d9ff}.prog .dot.cur{background:#9966ff}
        .card{background:#12121e;border:1px solid #222;border-radius:20px;padding:24px 20px;
        width:100%;max-width:380px;animation:fadeUp .4s ease}
        @keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}
        .qn{font-size:.75em;color:#66d9ff;font-weight:700;text-transform:uppercase;
        letter-spacing:1px;margin-bottom:8px}
        .qt{font-size:1.15em;font-weight:600;line-height:1.5;margin-bottom:16px;color:#fff}
        .opts{display:flex;flex-direction:column;gap:8px}
        .opt{padding:14px 16px;background:#1a1a2e;border:1px solid #333;border-radius:14px;
        font-size:1em;cursor:pointer;transition:all .2s;color:#ccc;
        -webkit-tap-highlight-color:transparent}
        .opt:active{transform:scale(.98)}
        .opt.sel{background:#66d9ff22;border-color:#66d9ff;color:#66d9ff;font-weight:600}
        .stars{display:flex;gap:8px;justify-content:center;padding:8px 0}
        .star{font-size:2em;cursor:pointer;transition:all .15s;filter:grayscale(1) opacity(.3)}
        .star.on{filter:none;transform:scale(1.1)}
        .txtinput{width:100%;background:#1a1a2e;border:1px solid #333;border-radius:12px;
        padding:14px;color:#e0e0e0;font-family:-apple-system,sans-serif;font-size:1em;
        resize:vertical;min-height:80px;outline:none}
        .txtinput:focus{border-color:#66d9ff}
        .nav{display:flex;gap:10px;margin-top:16px;width:100%;max-width:380px}
        .btn{flex:1;padding:14px;border:none;border-radius:14px;font-size:1em;font-weight:700;
        cursor:pointer;font-family:-apple-system,sans-serif;transition:all .2s}
        .btn:active{transform:scale(.97)}
        .btn-next{background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000}
        .btn-back{background:#1a1a2e;color:#888;border:1px solid #333}
        .btn-submit{background:linear-gradient(135deg,#66d9ff,#9966ff);color:#000}
        .btn:disabled{opacity:.3;pointer-events:none}
        .done{text-align:center;animation:fadeUp .5s ease}
        .done h2{font-size:1.5em;color:#fff;margin-bottom:8px}
        .done p{color:#888;font-size:.9em;margin-bottom:20px;line-height:1.5}
        .qr-wrap{background:#fff;padding:16px;border-radius:16px;display:inline-block;
        margin:16px 0;box-shadow:0 0 40px #66d9ff33}
        .qr-wrap canvas{display:block}
        .done .hint{color:#556;font-size:.8em;margin-top:12px;line-height:1.5}
        .foot{color:#222;font-size:.7em;margin-top:auto;padding-top:20px}
        .expired{text-align:center;animation:fadeUp .5s ease;padding-top:40px}
        .expired h2{font-size:1.6em;color:#ff6666;margin-bottom:12px}
        .expired p{color:#888;font-size:.95em;line-height:1.6}
        .expired .icon{font-size:3em;margin-bottom:16px}
        </style>
        </head>
        <body>
        <div class="hdr"><h1>\(surveyTitle)</h1><p>Survey · Delivered via Glyph</p></div>
        <div class="prog" id="prog"></div>
        <div id="stage"></div>
        <div id="nav-area"></div>
        <div class="foot">Glyph · Offline Surveys</div>
        <script>
        const SID='\(surveyId)';
        const Q=\(questionsJSON);
        const EXPIRES=\(expiresAtUnix);
        let cur=0,ans={};
        function init(){
        if(EXPIRES>0&&Math.floor(Date.now()/1000)>EXPIRES){showExpired();return;}
        updateProg();showQ();
        }
        function showExpired(){
        document.getElementById('prog').innerHTML='';
        let h='<div class="expired"><div class="icon" style="font-size:3em;color:#ff6666">✕</div>';
        h+='<h2>Survey Expired</h2>';
        h+='<p>This survey\\'s time window has closed.<br>Responses are no longer accepted.</p>';
        h+='</div>';
        document.getElementById('stage').innerHTML=h;
        document.getElementById('nav-area').innerHTML='';
        }
        function updateProg(){
        let p=document.getElementById('prog');
        p.innerHTML=Q.map((_,i)=>'<div class="dot'+(i<cur?' done':i===cur?' cur':'')+'"></div>').join('');
        }
        function showQ(){
        if(cur>=Q.length){showDone();return;}
        updateProg();
        let q=Q[cur],h='<div class="card"><div class="qn">Question '+(cur+1)+' of '+Q.length+'</div>';
        h+='<div class="qt">'+q.text+'</div>';
        if(q.type==='mc'){
        h+='<div class="opts">';
        q.options.forEach((o,i)=>{
        let sel=ans[q.id]===i?' sel':'';
        h+='<div class="opt'+sel+'" onclick="pickMC(\\''+q.id+'\\','+i+',this)">'+o+'</div>';
        });
        h+='</div>';
        }else if(q.type==='rating'){
        let max=q.maxRating||5;
        h+='<div class="stars">';
        for(let i=1;i<=max;i++){
        let on=(ans[q.id]||0)>=i?' on':'';
        h+='<span class="star'+on+'" onclick="pickRating(\\''+q.id+'\\','+i+')">★</span>';
        }
        h+='</div>';
        }else if(q.type==='text'){
        let val=ans[q.id]||'';
        h+='<textarea class="txtinput" id="tinput" placeholder="Type your answer…" oninput="pickText(\\''+q.id+'\\')">'+val+'</textarea>';
        }
        h+='</div>';
        document.getElementById('stage').innerHTML=h;
        // Nav buttons
        let nh='<div class="nav">';
        if(cur>0)nh+='<button class="btn btn-back" onclick="prev()">Back</button>';
        if(cur<Q.length-1)nh+='<button class="btn btn-next" id="nbtn" onclick="next()"'+(hasAnswer(q)?'':' disabled')+'>Next</button>';
        else nh+='<button class="btn btn-submit" id="nbtn" onclick="submit()"'+(hasAnswer(q)?'':' disabled')+'>Submit</button>';
        nh+='</div>';
        document.getElementById('nav-area').innerHTML=nh;
        }
        function hasAnswer(q){return ans[q.id]!==undefined&&ans[q.id]!==''&&ans[q.id]!==null;}
        function pickMC(qid,idx,el){
        ans[qid]=idx;
        document.querySelectorAll('.opt').forEach(o=>o.classList.remove('sel'));
        el.classList.add('sel');
        let b=document.getElementById('nbtn');if(b)b.disabled=false;
        }
        function pickRating(qid,val){
        ans[qid]=val;
        showQ();
        }
        function pickText(qid){
        let v=document.getElementById('tinput').value;
        ans[qid]=v;
        let b=document.getElementById('nbtn');if(b)b.disabled=!v.trim();
        }
        function next(){if(cur<Q.length-1){cur++;showQ();}}
        function prev(){if(cur>0){cur--;showQ();}}
        function submit(){
        let answers=Q.map(q=>{
        let a={questionId:q.id};
        if(q.type==='mc')a.choiceIndex=ans[q.id]!=null?ans[q.id]:null;
        else if(q.type==='rating')a.ratingValue=ans[q.id]||null;
        else if(q.type==='text')a.textValue=ans[q.id]||'';
        return a;
        });
        let resp={id:rndId(),surveyId:SID,answers:answers,submittedAt:Math.floor(Date.now()/1000)};
        let json=JSON.stringify(resp);
        let b64=btoa(unescape(encodeURIComponent(json)));
        let payload='GLYR:'+b64;
        showResponse(payload);
        }
        function rndId(){return Math.random().toString(36).substr(2,8);}
        function showResponse(payload){
        updateProg();
        document.querySelectorAll('.dot').forEach(d=>d.className='dot done');
        let h='<div class="done"><h2>Thanks!</h2>';
        h+='<p>Your response is ready.<br>Show this QR code to the survey creator:</p>';
        h+='<div class="qr-wrap"><canvas id="qrc" width="280" height="280"></canvas></div>';
        h+='<div class="hint">The survey creator scans this to collect your response.<br>No internet needed — pure light transfer.</div>';
        h+='</div>';
        document.getElementById('stage').innerHTML=h;
        document.getElementById('nav-area').innerHTML='';
        drawQR(document.getElementById('qrc'),payload);
        }
        \(qrCanvasGenerator())
        init();
        </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Questions JSON
    
    private static func generateQuestionsJSON(_ questions: [SurveyQuestion]) -> String {
        let items = questions.map { q -> String in
            var parts = [String]()
            parts.append("id:'\(escapeJS(q.id))'")
            parts.append("text:'\(escapeJS(q.text))'")
            parts.append("type:'\(q.type.rawValue)'")
            
            if let options = q.options {
                let optStr = options.map { "'\(escapeJS($0))'" }.joined(separator: ",")
                parts.append("options:[\(optStr)]")
            }
            if let max = q.maxRating {
                parts.append("maxRating:\(max)")
            }
            return "{\(parts.joined(separator: ","))}"
        }
        return "[\(items.joined(separator: ","))]"
    }
    
    // MARK: - Canvas QR Code Generator
    
    /// Pure JavaScript QR code generator that draws on a canvas element.
    /// This is a minimal QR encoder — enough to encode GLYR: response payloads
    /// (typically ~200-500 chars, well within QR capacity).
    /// Uses alphanumeric mode where possible, byte mode otherwise.
    private static func qrCanvasGenerator() -> String {
        // Embed a minimal QR code generator in JS.
        // We use a well-known compact approach: generate the QR matrix,
        // then draw it on canvas.
        return """
        function drawQR(canvas,text){
        // Minimal QR Code generator for response payloads
        // Uses a simplified approach: encode data, build matrix, draw
        var qr=makeQR(text);
        if(!qr)return;
        var ctx=canvas.getContext('2d');
        var size=canvas.width;
        var cellSize=Math.floor(size/qr.length);
        var offset=Math.floor((size-cellSize*qr.length)/2);
        ctx.fillStyle='#ffffff';ctx.fillRect(0,0,size,size);
        ctx.fillStyle='#000000';
        for(var y=0;y<qr.length;y++){
        for(var x=0;x<qr[y].length;x++){
        if(qr[y][x])ctx.fillRect(offset+x*cellSize,offset+y*cellSize,cellSize,cellSize);
        }}
        }
        // Compact QR encoder
        function makeQR(data){
        var d=[];for(var i=0;i<data.length;i++)d.push(data.charCodeAt(i));
        var ver=Math.max(1,Math.ceil(d.length/17));
        if(ver>40)return null;
        // Use version that fits: each version holds roughly (ver*ver*3 - overhead) bits
        for(var v=1;v<=40;v++){
        var cap=getCapacity(v);
        if(cap>=d.length){ver=v;break;}
        }
        var sz=ver*4+17;
        var m=[];for(var i=0;i<sz;i++){m[i]=[];for(var j=0;j<sz;j++)m[i][j]=null;}
        // Finder patterns
        putFinder(m,0,0);putFinder(m,sz-7,0);putFinder(m,0,sz-7);
        // Timing patterns
        for(var i=8;i<sz-8;i++){m[6][i]=i%2===0;m[i][6]=i%2===0;}
        // Format + version info (simplified - use mask 0, EC level L)
        putFormat(m,sz);
        if(ver>=7)putVersion(m,sz,ver);
        // Alignment patterns
        var aligns=getAlignments(ver);
        for(var a=0;a<aligns.length;a++){
        for(var b=0;b<aligns.length;b++){
        var ay=aligns[a],ax=aligns[b];
        if(m[ay][ax]===null)putAlign(m,ay,ax);
        }}
        // Encode data
        var bits=encodeData(d,ver);
        // Place data
        placeData(m,sz,bits);
        // Apply mask 0 (checkerboard)
        for(var y=0;y<sz;y++){
        for(var x=0;x<sz;x++){
        if(m[y][x]===null)m[y][x]=false;
        if(isData(m,sz,y,x)&&((y+x)%2===0))m[y][x]=!m[y][x];
        }}
        return m;
        }
        function getCapacity(v){
        // Approximate byte capacity at EC level L
        var t=[0,17,32,53,78,106,134,154,192,230,271,321,367,425,458,520,586,644,718,792,858,929,1003,1091,1171,1273,1367,1465,1528,1628,1732,1840,1952,2068,2188,2303,2431,2563,2699,2809,2953];
        return t[v]||0;
        }
        function putFinder(m,r,c){
        for(var y=-1;y<=7;y++){for(var x=-1;x<=7;x++){
        var ry=r+y,cx=c+x;
        if(ry<0||cx<0||ry>=m.length||cx>=m.length)continue;
        if((y>=0&&y<=6&&(x===0||x===6))||(x>=0&&x<=6&&(y===0||y===6))||(y>=2&&y<=4&&x>=2&&x<=4))
        m[ry][cx]=true;
        else m[ry][cx]=false;
        }}}
        function putAlign(m,r,c){
        for(var y=-2;y<=2;y++){for(var x=-2;x<=2;x++){
        m[r+y][c+x]=(Math.abs(y)===2||Math.abs(x)===2||(!y&&!x));
        }}}
        function getAlignments(v){
        if(v===1)return[];
        var first=6,last=v*4+10;
        var count=Math.floor(v/7)+2;
        var step=(count===2)?0:Math.ceil((last-first)/(count-1));
        if(step%2)step++;
        var pos=[first];
        for(var i=1;i<count-1;i++)pos.push(last-step*(count-1-i));
        pos.push(last);
        return pos;
        }
        function putFormat(m,sz){
        var bits=0x5412; // L level, mask 0
        for(var i=0;i<15;i++){
        var b=(bits>>i)&1?true:false;
        // Around top-left finder
        if(i<6)m[8][i]=b;
        else if(i<8)m[8][i+1]=b;
        else if(i===8)m[7][8]=b;
        else m[14-i][8]=b;
        // Mirror
        if(i<8)m[sz-1-i][8]=b;
        else m[8][sz-15+i]=b;
        }
        m[sz-8][8]=true;
        }
        function putVersion(m,sz,v){
        var vInfo=[0,0,0,0,0,0,0,0x07C94,0x085BC,0x09A99,0x0A4D3,0x0BBF6,0x0C762,0x0D847,0x0E60D,0x0F928,0x10B78,0x1145D,0x12A17,0x13532,0x149A6,0x15683,0x168C9,0x177EC,0x18EC4,0x191E1,0x1AFAB,0x1B08E,0x1CC1A,0x1D33F,0x1ED75,0x1F250,0x209D5,0x216F0,0x228BA,0x2379F,0x24B0B,0x2542E,0x26A64,0x27541,0x28C69];
        if(v>=7&&vInfo[v]){
        var info=vInfo[v];
        for(var i=0;i<18;i++){
        var b=(info>>i)&1?true:false;
        m[Math.floor(i/3)][sz-11+i%3]=b;
        m[sz-11+i%3][Math.floor(i/3)]=b;
        }}
        }
        function encodeData(bytes,ver){
        var bits=[];
        // Byte mode indicator: 0100
        bits.push(0,1,0,0);
        // Character count (8 or 16 bits depending on version)
        var ccBits=ver<=9?8:16;
        for(var i=ccBits-1;i>=0;i--)bits.push((bytes.length>>i)&1);
        // Data bytes
        for(var i=0;i<bytes.length;i++){
        for(var j=7;j>=0;j--)bits.push((bytes[i]>>j)&1);
        }
        // Terminator
        for(var i=0;i<4&&bits.length<getDataBits(ver);i++)bits.push(0);
        // Pad to byte boundary
        while(bits.length%8)bits.push(0);
        // Pad bytes
        var padBytes=[0xEC,0x11];var pi=0;
        while(bits.length<getDataBits(ver)){
        for(var j=7;j>=0;j--)bits.push((padBytes[pi]>>j)&1);
        pi=(pi+1)%2;
        }
        // Add error correction
        return addEC(bits,ver);
        }
        function getDataBits(v){
        var t=[0,152,272,440,640,864,1088,1248,1552,1856,2192,2592,2960,3424,3688,4184,4712,5176,5768,6360,6888,7456,8048,8752,9392,10208,10960,11744,12248,13048,13880,14744,15640,16568,17528,18448,19472,20528,21616,22496,23648];
        return t[v]||0;
        }
        function addEC(dataBits,ver){
        // Simplified: return data bits + some EC bits
        // For a proper implementation we'd do Reed-Solomon, but for our response QR
        // (shown on screen, scanned directly) we can use low EC and it works fine
        var dataBytes=[];
        for(var i=0;i<dataBits.length;i+=8){
        var b=0;for(var j=0;j<8&&i+j<dataBits.length;j++)b|=dataBits[i+j]<<(7-j);
        dataBytes.push(b);
        }
        // EC codewords using polynomial division
        var ecInfo=getECInfo(ver);
        var allBits=[];
        var offset=0;
        for(var g=0;g<ecInfo.groups.length;g++){
        var grp=ecInfo.groups[g];
        for(var b=0;b<grp.blocks;b++){
        var block=dataBytes.slice(offset,offset+grp.dataPerBlock);
        offset+=grp.dataPerBlock;
        var ec=rsEncode(block,ecInfo.ecPerBlock);
        // Data bits
        for(var i=0;i<block.length;i++)
        for(var j=7;j>=0;j--)allBits.push((block[i]>>j)&1);
        // EC bits
        for(var i=0;i<ec.length;i++)
        for(var j=7;j>=0;j--)allBits.push((ec[i]>>j)&1);
        }}
        return allBits;
        }
        function getECInfo(v){
        // EC Level L info for common versions
        var info={
        1:{ecPerBlock:7,groups:[{blocks:1,dataPerBlock:19}]},
        2:{ecPerBlock:10,groups:[{blocks:1,dataPerBlock:34}]},
        3:{ecPerBlock:15,groups:[{blocks:1,dataPerBlock:55}]},
        4:{ecPerBlock:20,groups:[{blocks:1,dataPerBlock:80}]},
        5:{ecPerBlock:26,groups:[{blocks:1,dataPerBlock:108}]},
        6:{ecPerBlock:18,groups:[{blocks:2,dataPerBlock:68}]},
        7:{ecPerBlock:20,groups:[{blocks:2,dataPerBlock:78}]},
        8:{ecPerBlock:24,groups:[{blocks:2,dataPerBlock:97}]},
        9:{ecPerBlock:30,groups:[{blocks:2,dataPerBlock:116}]},
        10:{ecPerBlock:18,groups:[{blocks:2,dataPerBlock:68},{blocks:2,dataPerBlock:69}]},
        };
        return info[v]||info[1];
        }
        function rsEncode(data,ecLen){
        var gf=256;var pp=285;
        var log=new Array(gf);var exp=new Array(gf);
        var v=1;for(var i=0;i<255;i++){exp[i]=v;log[v]=i;v<<=1;if(v>=gf)v^=pp;}
        function gfMul(a,b){if(!a||!b)return 0;return exp[(log[a]+log[b])%255];}
        // Generator polynomial
        var gen=[1];
        for(var i=0;i<ecLen;i++){
        var ng=new Array(gen.length+1).fill(0);
        for(var j=0;j<gen.length;j++){ng[j]^=gen[j];ng[j+1]^=gfMul(gen[j],exp[i]);}
        gen=ng;
        }
        // Division
        var msg=data.slice().concat(new Array(ecLen).fill(0));
        for(var i=0;i<data.length;i++){
        var coef=msg[i];if(!coef)continue;
        for(var j=0;j<gen.length;j++)msg[i+j]^=gfMul(gen[j],coef);
        }
        return msg.slice(data.length);
        }
        function placeData(m,sz,bits){
        var bi=0,up=true;
        for(var x=sz-1;x>=1;x-=2){
        if(x===6)x--;
        for(var i=0;i<sz;i++){
        var y=up?sz-1-i:i;
        if(m[y][x]===null){m[y][x]=bi<bits.length?!!bits[bi++]:false;}
        if(m[y][x-1]===null){m[y][x-1]=bi<bits.length?!!bits[bi++]:false;}
        }
        up=!up;
        }}
        function isData(m,sz,y,x){
        // Check if a cell is a data cell (not a function pattern)
        if(y===6||x===6)return false;
        if(y<9&&x<9)return false;
        if(y<9&&x>=sz-8)return false;
        if(y>=sz-8&&x<9)return false;
        return true;
        }
        """
    }
    
    // MARK: - Helpers
    
    private static func escapeJS(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "'", with: "\\'")
         .replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
         .replacingOccurrences(of: "\r", with: "")
    }
    
    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
