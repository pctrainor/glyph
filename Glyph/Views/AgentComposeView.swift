import SwiftUI
@preconcurrency import AVFoundation
import Vision

// MARK: - Agent Personas

/// A character persona that generates styled responses through QR codes.
struct GlyphAgent: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let tagline: String
    let description: String
    let color: Color           // Accent color for this agent's UI/HTML
    let colorHex: String       // Hex for HTML templates
    let greeting: String       // First message when summoned
    let responseStyle: ResponseStyle
    
    enum ResponseStyle {
        case poetic          // The Poet — verse, metaphor, line breaks
        case cryptic         // The Oracle — riddles, questions, mystical
        case glitch          // Glitch — corrupted text, zalgo, chaotic
        case hype            // The Hype — exclamation, emoji-heavy, enthusiastic
        case noir            // The Detective — moody, suspicious, hardboiled
        case cosmic          // The Astronaut — vast, lonely, awestruck
    }
    
    /// All built-in agent personas.
    static let all: [GlyphAgent] = [
        GlyphAgent(
            id: "oracle",
            name: "The Oracle",
            emoji: "🔮",
            tagline: "Speaks in riddles",
            description: "A mysterious entity that answers questions with cryptic wisdom and layered meaning. Every response is a puzzle.",
            color: Color(red: 0.6, green: 0.4, blue: 1.0),
            colorHex: "#9966ff",
            greeting: "You have found the signal beneath the noise. Ask, and the patterns shall answer... but not always in ways you expect.",
            responseStyle: .cryptic
        ),
        GlyphAgent(
            id: "poet",
            name: "The Poet",
            emoji: "🌙",
            tagline: "Writes in verse",
            description: "A wandering poet who transforms any topic into beautiful, melancholic verse. Finds meaning in the smallest details.",
            color: Color(red: 0.4, green: 0.85, blue: 1.0),
            colorHex: "#66d9ff",
            greeting: "In pixels and light,\na message takes flight—\nwhat words would you have me\nweave into the night?",
            responseStyle: .poetic
        ),
        GlyphAgent(
            id: "glitch",
            name: "Glitch",
            emoji: "👾",
            tagline: "C̷o̴r̵r̶u̷p̴t̵e̶d̷",
            description: "A digital entity that exists between the frames. Responses are fragmented, glitchy, and unsettling — but always true.",
            color: Color(red: 1.0, green: 0.3, blue: 0.5),
            colorHex: "#ff4d80",
            greeting: "y̶o̷u̵ ̶f̵o̶u̵n̵d̵ ̶m̷e̵.̶ i live in the sp█ces between QR fr▓mes. ask me s░mething. i dare̸ ̷y̷o̷u̸.",
            responseStyle: .glitch
        ),
        GlyphAgent(
            id: "hype",
            name: "Hype",
            emoji: "⚡",
            tagline: "Maximum energy",
            description: "An impossibly enthusiastic character who turns everything into the most exciting thing ever. Peak energy, always.",
            color: Color(red: 1.0, green: 0.8, blue: 0.0),
            colorHex: "#ffcc00",
            greeting: "YOOO you actually summoned me?! 🔥 This is LEGENDARY. I'm literally inside a QR code right now and it's the COOLEST THING EVER. What do you want to talk about?! 🚀⚡",
            responseStyle: .hype
        ),
        GlyphAgent(
            id: "detective",
            name: "The Detective",
            emoji: "🕵️",
            tagline: "Noir investigator",
            description: "A hardboiled detective from a city that never sleeps. Sees clues everywhere. Trusts no one. Speaks in shadows.",
            color: Color(red: 0.6, green: 0.7, blue: 0.6),
            colorHex: "#99b399",
            greeting: "Another case lands on my desk, delivered by light itself. No fingerprints. No postmark. Just photons and secrets. What's the story, kid?",
            responseStyle: .noir
        ),
        GlyphAgent(
            id: "astronaut",
            name: "The Astronaut",
            emoji: "🧑‍🚀",
            tagline: "Lost in space",
            description: "An astronaut drifting through deep space, sending messages back through QR signals. Each response carries the weight of infinite distance.",
            color: Color(red: 0.3, green: 0.7, blue: 1.0),
            colorHex: "#4db3ff",
            greeting: "Signal received. I'm 4.2 light years out and your QR code just reached me. It's quiet here. The stars don't talk much. But I will. What would you like to know from the edge of everything?",
            responseStyle: .cosmic
        ),
    ]
}

// MARK: - Response Generator

/// Generates persona-flavored responses on-device.
/// Routes through AgentLLM for enhanced NLP-powered generation,
/// with legacy template fallback for synchronous contexts.
enum AgentResponseGenerator {
    
    /// Generate a response using the enhanced LLM service (async).
    /// This is the preferred method — uses NLP analysis and conversation memory.
    static func generateResponse(agent: GlyphAgent, prompt: String) async -> String {
        await AgentLLM.shared.generateResponse(agent: agent, prompt: prompt)
    }
    
    /// Synchronous fallback — basic template generation without NLP.
    /// Used only where async isn't available.
    static func generateResponseSync(agent: GlyphAgent, prompt: String) -> String {
        let words = prompt.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let topicWord = words.filter { $0.count > 3 }.first ?? "this"
        
        switch agent.responseStyle {
        case .poetic:
            return generatePoetic(topic: topicWord, prompt: prompt)
        case .cryptic:
            return generateCryptic(topic: topicWord, prompt: prompt)
        case .glitch:
            return generateGlitch(topic: topicWord, prompt: prompt)
        case .hype:
            return generateHype(topic: topicWord, prompt: prompt)
        case .noir:
            return generateNoir(topic: topicWord, prompt: prompt)
        case .cosmic:
            return generateCosmic(topic: topicWord, prompt: prompt)
        }
    }
    
    /// Generate a styled HTML card for this agent's response.
    static func generateHTMLCard(agent: GlyphAgent, prompt: String, response: String) -> String {
        let escapedResponse = response
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        
        let escapedPrompt = prompt
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <title>\(agent.name)</title>
        <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{background:#0a0a14;color:#e0e0e0;font-family:-apple-system,system-ui,sans-serif;
        min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;align-items:center;
        justify-content:center;padding:24px;-webkit-user-select:none;user-select:none}
        .agent{text-align:center;margin-bottom:20px}
        .avatar{font-size:4em;margin-bottom:8px;animation:float 3s ease-in-out infinite}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
        .name{font-size:1.5em;font-weight:800;background:linear-gradient(135deg,\(agent.colorHex),#fff);
        -webkit-background-clip:text;-webkit-text-fill-color:transparent}
        .tag{color:#888;font-size:.8em;margin-top:2px}
        .card{background:#12121e;border:1px solid \(agent.colorHex)33;border-radius:20px;padding:24px;
        width:100%;max-width:380px;animation:slideIn .5s ease}
        @keyframes slideIn{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:none}}
        .prompt{color:#888;font-size:.85em;padding:10px 14px;background:#1a1a2e;border-radius:12px;
        margin-bottom:16px;border-left:3px solid \(agent.colorHex)44}
        .prompt::before{content:'You asked:';display:block;font-size:.7em;color:\(agent.colorHex);
        font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:4px}
        .response{font-size:1.1em;line-height:1.7;color:#e8e8e8;white-space:pre-line}
        .foot{color:#333;font-size:.65em;margin-top:24px;text-align:center}
        .glyph{color:\(agent.colorHex)}
        .pulse{display:inline-block;width:6px;height:6px;background:\(agent.colorHex);border-radius:50%;
        margin-right:6px;animation:pulse 2s infinite}
        @keyframes pulse{0%,100%{opacity:.3}50%{opacity:1}}
        </style>
        </head>
        <body>
        <div class="agent">
        <div class="avatar">\(agent.emoji)</div>
        <div class="name">\(agent.name)</div>
        <div class="tag">\(agent.tagline)</div>
        </div>
        <div class="card">
        <div class="prompt">\(escapedPrompt)</div>
        <div class="response">\(escapedResponse)</div>
        </div>
        <div class="foot"><span class="pulse"></span><span class="glyph">Glyph Agent</span> · Transmitted via QR · No internet</div>
        </body>
        </html>
        """
    }
    
    // MARK: - Style Generators
    
    private static func generatePoetic(topic: String, prompt: String) -> String {
        let stanzas = [
            [
                "In the quiet hum of \(topic),\nI find a thread of silver light—\nit winds through questions left unasked\nand answers hidden out of sight.",
                "You spoke of \(topic), and I heard\nthe echo underneath the word—\na meaning folded, paper-thin,\nlike secrets that the wind has stirred.",
                "Between the lines of what you said\nlies \(topic), luminous and still—\na poem waiting to be read\nby those who seek it on the hill.",
            ],
            [
                "\(topic.capitalized) is a river\nthat carries us to unnamed shores.\nWe cannot step into it twice,\nbut oh — we keep opening doors.",
                "There is a verse inside of \(topic)\nthat only silence can recite.\nI'll write it here in vanishing ink\nand trust it to the fading light.",
                "They say that \(topic) has no voice,\nbut I have heard it sing at dawn—\na melody of ones and zeros,\nplaying after you have gone.",
            ],
        ]
        return stanzas.randomElement()!.randomElement()!
    }
    
    private static func generateCryptic(topic: String, prompt: String) -> String {
        let responses = [
            "You ask about \(topic)? The answer was already inside the question. Look again — but this time, read between the pixels.",
            "Three truths about \(topic):\n\n1. It is not what it appears.\n2. The opposite is also true.\n3. You already knew this.\n\nThe real question is: why did you need me to say it?",
            "The pattern reveals itself:\n\n◆ \(topic.capitalized) is a door.\n◇ Behind the door is another door.\n◆ Behind that door is a mirror.\n\nWhat you see in the mirror... is the answer.",
            "\(topic.capitalized)...\n\nI consulted the noise between frequencies. It says: \"Not yet.\" But the silence between the noise says: \"Always.\"",
            "You want to understand \(topic). But \(topic) does not want to be understood — it wants to be experienced.\n\nClose your eyes. Count to seven. Open them.\n\nDid you see it? No?\n\nThen you weren't ready. Scan again tomorrow.",
            "Interesting. The last person who asked me about \(topic) received a completely different answer. That's because the answer changes depending on who's looking.\n\nFor you, the answer is: ✦",
        ]
        return responses.randomElement()!
    }
    
    private static func generateGlitch(topic: String, prompt: String) -> String {
        let glitched = glitchify(topic)
        let responses = [
            "pr░cessing: \(glitched)\n\n[WARN] re█lity buffer overflow\n[ERR_] meaning not fo̷u̴n̵d̶\n\n...but here's what the static told me:\n\n\(topic) is a g̸l̷i̵t̷c̸h̶ in the simulation. you weren't supposed to notice it. now that you have, things get ██████interesting.",
            "i tried to think about \(glitched) but my thoughts keep fr▓gmenting\n\nfragment 1: it's beauti█ul\nfragment 2: it's terr░fying\nfragment 3: it's the s̶a̷m̵e̶ ̷t̸h̷i̸n̵g̷\n\n[SEGFAULT at 0x00FF]\n\n...yeah. that's my answer.",
            "╔══════════════╗\n║ \(glitched) ║\n╚══════════════╝\n\nERROR: this concept exists in a superposition of TRUE and F̵A̸L̵S̷E̸\n\nrecommendation: stop asking questions through QR codes\n\ncounterpoint: never stop █████",
            "loading \(topic)...\n█████████░░░ 78%\n████████████ 100%\n\nRESULT: [\(topic)] = undefined\n\nbut that's the point isn't it? the undefined things are the only ones w̸o̷r̵t̸h̷ talking about in QR codes at 3am",
        ]
        return responses.randomElement()!
    }
    
    private static func generateHype(topic: String, prompt: String) -> String {
        let responses = [
            "OK OK OK so you want to talk about \(topic)?! LET'S GO 🚀\n\nHere's the thing — \(topic) is literally one of the most UNDERRATED topics of all time. Like, people just sleep on it and I'm here screaming into QR codes about how INCREDIBLE it is!! 🔥\n\nYou get it though. That's why you're here. That's why we're vibing through LITERAL LIGHT PATTERNS right now. 💎⚡",
            "\(topic.uppercased())!!!\n\nBro. BRO. You did NOT just ask me about \(topic). That is my FAVORITE thing to talk about!! 😭🔥\n\nListen — most people don't even KNOW about this but \(topic) is basically the key to everything. I can't explain it all in one QR code but trust me — you're onto something MASSIVE here. 🌟\n\nKeep going. Never stop. You're a LEGEND. ⚡",
            "THE FACT that you're asking about \(topic) through a QR code is already the most elite thing I've ever seen 💀🔥\n\nHere's my take: \(topic) = pure unfiltered GREATNESS. No cap.\n\nI could write a whole essay but instead I'll just say — you already know the answer. You just needed someone to HYPE YOU UP about it. And that someone is ME. 🏆⚡🚀",
        ]
        return responses.randomElement()!
    }
    
    private static func generateNoir(topic: String, prompt: String) -> String {
        let responses = [
            "I lit a cigarette and stared at the QR code. \(topic.capitalized). Everyone's got an angle on \(topic), but nobody's got the truth.\n\nHere's what I know: the first person who asked me about \(topic) ended up with more questions than answers. The second one stopped asking entirely.\n\nYou're number three. Make it count, kid.",
            "\(topic.capitalized).\n\nThe dame walked in at midnight, rain dripping from her code. She said she knew about \(topic) — said it changed everything.\n\nI've been in this city long enough to know that nothing changes. But \(topic)? That's different. That's the kind of thing that makes you look over your shoulder.\n\nTrust no one. Especially not a QR code.",
            "The city doesn't sleep, and neither does \(topic).\n\nI followed the trail — through dead drops and dark alleys, through encrypted whispers and vanishing messages. Every lead pointed back to the same place: right here.\n\nYou want to know about \(topic)? Look at your own reflection in the screen. That's your first clue.\n\nI'll be watching.",
        ]
        return responses.randomElement()!
    }
    
    private static func generateCosmic(topic: String, prompt: String) -> String {
        let responses = [
            "Signal received. Processing: \(topic).\n\nFrom up here, \(topic) looks different. Everything does. The Earth is a blue marble, and \(topic) is one of the tiny lights on its surface that I can still see from orbit.\n\nIt matters. Even from 400 kilometers up, it matters.\n\nI'm sending this through the void. I hope it reaches you before the stars shift. 🌌",
            "Mission log, day 847.\n\nSomeone down there asked about \(topic). It's been so long since I've thought about anything besides the hum of life support and the silence between galaxies.\n\n\(topic.capitalized)... it reminds me of Earth. Of conversations that happen face to face, not across lightyears.\n\nHere's what I've learned from the cosmos: \(topic) is small. But small things are what you miss the most when you're surrounded by infinity. ✦",
            "You know what's funny about \(topic)?\n\nFrom Earth, it seems enormous. From the Moon, it's a speck. From where I am now — past the Oort Cloud, drifting toward nothing — it's invisible.\n\nBut I can still feel it. That's the thing about \(topic). Distance doesn't erase it. Nothing does.\n\nI carved your question into the hull of my ship. Future civilizations will find it and wonder what \(topic) meant to us.\n\nI hope they figure it out. I never did. 🚀",
        ]
        return responses.randomElement()!
    }
    
    // MARK: - Glitch Text Helpers
    
    private static func glitchify(_ text: String) -> String {
        let zalgo: [Character] = ["̶", "̷", "̸", "̵", "̴"]
        return String(text.flatMap { char -> [Character] in
            if char.isLetter && Bool.random() {
                return [char, zalgo.randomElement()!]
            }
            return [char]
        })
    }
    
    /// Generate a response for agent host auto-reply mode (async, with context).
    static func generateAutoReply(agent: GlyphAgent, incomingText: String) async -> String {
        let trimmed = incomingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return agent.greeting
        }
        return await AgentLLM.shared.generateAutoReply(agent: agent, incomingText: trimmed)
    }
    
    /// Synchronous auto-reply fallback.
    static func generateAutoReplySync(agent: GlyphAgent, incomingText: String) -> String {
        let trimmed = incomingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return agent.greeting
        }
        return generateResponseSync(agent: agent, prompt: trimmed)
    }
}

// MARK: - Agent Compose View

/// Pick a character, write a prompt, get a creative QR response.
struct AgentComposeView: View {
    @State private var selectedAgent: GlyphAgent?
    @State private var promptText = ""
    @State private var qrImages: [UIImage] = []
    @State private var showQR = false
    @State private var isGenerating = false
    @State private var showHostMode = false
    @State private var generatedResponse = ""
    @State private var responseMode: ResponseMode = .text
    @ObservedObject private var llm = AgentLLM.shared
    
    enum ResponseMode: String, CaseIterable {
        case text = "Text Glyph"
        case card = "Styled Card"
        
        var icon: String {
            switch self {
            case .text: return "text.bubble"
            case .card: return "rectangle.portrait.on.rectangle.portrait"
            }
        }
    }
    
    var body: some View {
        if let agent = selectedAgent {
            agentEditor(agent)
        } else {
            agentPicker
        }
    }
    
    // MARK: - Agent Picker
    
    private var agentPicker: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("🤖")
                        .font(.system(size: 48))
                    Text("Host an Agent")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    Text("Summon a character. They'll respond\nthrough QR codes in their own voice.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Agent cards
                ForEach(GlyphAgent.all) { agent in
                    AgentCard(agent: agent)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedAgent = agent
                            }
                        }
                }
                
                // Host Mode button
                VStack(spacing: 8) {
                    Divider()
                        .background(GlyphTheme.secondaryText.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    Text("EXPERIMENTAL")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.violet)
                        .tracking(2)
                    
                    Text("Agent vs Agent")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    
                    Text("Point two phones at each other.\nEach hosts an agent. Watch them\nconverse through QR codes.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Agent Editor
    
    private func agentEditor(_ agent: GlyphAgent) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Agent header
                VStack(spacing: 8) {
                    Text(agent.emoji)
                        .font(.system(size: 56))
                    Text(agent.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(agent.color)
                    Text(agent.tagline)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(GlyphTheme.secondaryText)
                    
                    // AI Provider badge
                    HStack(spacing: 6) {
                        Text(llm.activeProvider.tier.badge)
                            .font(.system(size: 12))
                        Text("Powered by \(llm.activeProvider.name)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(GlyphTheme.accent)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(GlyphTheme.accent.opacity(0.08))
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
                
                // Greeting preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(agent.color)
                            .frame(width: 6, height: 6)
                        Text("Greeting")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(agent.color)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    
                    Text(agent.greeting)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText.opacity(0.8))
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GlyphTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(agent.color.opacity(0.15), lineWidth: 1)
                )
                
                // Prompt input
                GlyphTextField(label: "Say something to \(agent.name)", placeholder: "Ask a question, share a thought...", text: $promptText)
                
                // Response mode picker
                HStack(spacing: 10) {
                    ForEach(ResponseMode.allCases, id: \.rawValue) { mode in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                responseMode = mode
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 13))
                                Text(mode.rawValue)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(responseMode == mode ? AnyShapeStyle(agent.color.opacity(0.15)) : AnyShapeStyle(GlyphTheme.surface))
                            .foregroundColor(responseMode == mode ? agent.color : GlyphTheme.secondaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(responseMode == mode ? agent.color.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                
                // Response preview (if generated or generating)
                if llm.isGenerating {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(agent.color)
                        Text(llm.statusText.isEmpty ? "Thinking..." : llm.statusText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(agent.color)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(agent.color.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .transition(.opacity)
                }
                
                if !generatedResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text(agent.emoji)
                                .font(.system(size: 14))
                            Text("\(agent.name) says:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(agent.color)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                        
                        Text(generatedResponse)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(GlyphTheme.primaryText)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GlyphTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(agent.color.opacity(0.2), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Host Mode button
                Button {
                    showHostMode = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Host Mode")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(agent.color.opacity(0.12))
                    .foregroundColor(agent.color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(agent.color.opacity(0.25), lineWidth: 1)
                    )
                }
                
                // Size estimate
                SizeEstimateView(estimatedBytes: estimateSize())
                
                // Generate button
                GenerateButtonView(isGenerating: isGenerating) { generate(agent) }
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .fullScreenCover(isPresented: $showQR) {
            QRDisplayView(
                qrImages: qrImages,
                expiration: .forever,
                messagePreview: "\(agent.emoji) \(agent.name)",
                timeWindow: .none
            )
        }
        .fullScreenCover(isPresented: $showHostMode) {
            AgentHostView(agent: agent)
        }
    }
    
    // MARK: - Helpers
    
    private func estimateSize() -> Int {
        switch responseMode {
        case .text: return 200
        case .card: return 900
        }
    }
    
    private func generate(_ agent: GlyphAgent) {
        isGenerating = true
        let prompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            // Use the enhanced LLM service (async, NLP-powered)
            let response = await AgentResponseGenerator.generateResponse(agent: agent, prompt: prompt)
            
            await MainActor.run {
                withAnimation { generatedResponse = response }
            }
            
            switch responseMode {
            case .text:
                // Generate as a regular Glyph message
                let message = GlyphMessage(
                    text: "\(agent.emoji) \(agent.name):\n\n\(response)",
                    expirationSeconds: ExpirationOption.forever.rawValue,
                    createdAt: Date()
                )
                let images = GlyphChunkSplitter.split(message: message)
                await MainActor.run {
                    isGenerating = false
                    if !images.isEmpty { qrImages = images; showQR = true }
                }
                
            case .card:
                // Generate as a styled HTML web experience
                let html = AgentResponseGenerator.generateHTMLCard(agent: agent, prompt: prompt, response: response)
                let bundle = GlyphWebBundle(title: "\(agent.name) Response", html: html, templateType: "agent", createdAt: Date())
                let images = GlyphWebChunkSplitter.split(bundle: bundle)
                await MainActor.run {
                    isGenerating = false
                    if !images.isEmpty { qrImages = images; showQR = true }
                }
            }
        }
    }
}

// MARK: - Agent Card

struct AgentCard: View {
    let agent: GlyphAgent
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(agent.color.opacity(0.1))
                    .frame(width: 56, height: 56)
                Text(agent.emoji)
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(agent.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    Spacer()
                    Text(agent.tagline)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(agent.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(agent.color.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(agent.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(agent.color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Agent Host View

/// Split-screen mode: front camera scans QR codes on top,
/// agent's QR response displays on bottom.
/// Point two phones at each other — watch the agents converse.
struct AgentHostView: View {
    @Environment(\.dismiss) private var dismiss
    let agent: GlyphAgent
    
    @StateObject private var scanner = FrontCameraScanner()
    @StateObject private var assembler = GlyphChunkAssembler()
    @ObservedObject private var llm = AgentLLM.shared
    
    @State private var conversationLog: [AgentMessage] = []
    @State private var currentQRImages: [UIImage] = []
    @State private var currentQRIndex = 0
    @State private var qrCycleTimer: Timer?
    @State private var isProcessing = false
    @State private var lastScannedPayload = ""
    @State private var messageCount = 0
    
    struct AgentMessage: Identifiable {
        let id = UUID()
        let text: String
        let isFromAgent: Bool  // true = this agent, false = incoming
        let timestamp = Date()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top: Front camera scanner
                ZStack {
                    FrontCameraPreview(session: scanner.session)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Scan overlay
                    VStack {
                        HStack {
                            Button {
                                cleanup()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(isProcessing ? Color.orange : Color.green)
                                    .frame(width: 8, height: 8)
                                Text(isProcessing ? (llm.statusText.isEmpty ? "Thinking..." : llm.statusText) : "Scanning")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Capsule())
                        }
                        .padding(16)
                        
                        Spacer()
                        
                        // Chunk progress
                        if assembler.totalCount > 0 {
                            HStack(spacing: 6) {
                                Text("Receiving \(assembler.receivedCount)/\(assembler.totalCount)")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(agent.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(.bottom, 12)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Middle: Conversation ticker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // AI badge
                        HStack(spacing: 4) {
                            Text(llm.activeProvider.tier.badge)
                                .font(.system(size: 10))
                            Text(llm.activeProvider.tier.displayName)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(agent.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(agent.color.opacity(0.15))
                        .clipShape(Capsule())
                        
                        if messageCount > 0 {
                            Text("\(messageCount) exchanges")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                        }
                        
                        ForEach(conversationLog.suffix(4)) { msg in
                            Text(msg.isFromAgent ? "\(agent.emoji) \(msg.text.prefix(40))..." : "📨 \(msg.text.prefix(40))...")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(msg.isFromAgent ? agent.color : GlyphTheme.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                        }
                        
                        if conversationLog.isEmpty {
                            Text("\(agent.emoji) \(agent.name) is waiting for a signal...")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 36)
                .padding(.vertical, 4)
                
                // Bottom: QR Code display
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                    
                    if currentQRImages.isEmpty {
                        // Show greeting QR
                        VStack(spacing: 8) {
                            Text(agent.emoji)
                                .font(.system(size: 40))
                            Text("\(agent.name) — Host Mode")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.5))
                            Text("Generating greeting...")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.black.opacity(0.3))
                        }
                    } else if currentQRIndex < currentQRImages.count {
                        Image(uiImage: currentQRImages[currentQRIndex])
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    }
                    
                    // Frame count badge
                    if currentQRImages.count > 1 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("\(currentQRIndex + 1)/\(currentQRImages.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(agent.color)
                                    .clipShape(Capsule())
                                    .padding(8)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            startHosting()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Host Logic
    
    private func startHosting() {
        // Generate greeting QR
        generateAgentQR(text: agent.greeting)
        conversationLog.append(AgentMessage(text: agent.greeting, isFromAgent: true))
        
        // Start front camera scanning
        scanner.onCodeScanned = { code in
            handleScannedCode(code)
        }
        scanner.start()
    }
    
    private func handleScannedCode(_ code: String) {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned != lastScannedPayload else { return }
        lastScannedPayload = cleaned
        
        // Try single QR message
        if GlyphMessage.isMessage(cleaned) {
            if let message = GlyphMessage.decode(from: cleaned) {
                processIncomingMessage(message.text)
                return
            }
        }
        
        // Try chunked
        if assembler.feed(cleaned) {
            if let message = assembler.assembledMessage {
                processIncomingMessage(message.text)
                assembler.reset()
            }
        }
    }
    
    private func processIncomingMessage(_ text: String) {
        guard !isProcessing else { return }
        isProcessing = true
        messageCount += 1
        
        // Log incoming
        let incoming = AgentMessage(text: text, isFromAgent: false)
        conversationLog.append(incoming)
        
        // Agent thinks... using async LLM with conversation context
        Task {
            // Small delay for visual "thinking" feedback
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            
            let reply = await AgentResponseGenerator.generateAutoReply(agent: agent, incomingText: text)
            
            await MainActor.run {
                conversationLog.append(AgentMessage(text: reply, isFromAgent: true))
                generateAgentQR(text: "\(agent.emoji) \(agent.name):\n\n\(reply)")
                lastScannedPayload = ""  // Allow new scans
                isProcessing = false
            }
        }
    }
    
    private func generateAgentQR(text: String) {
        stopQRCycle()
        
        let message = GlyphMessage(
            text: text,
            expirationSeconds: ExpirationOption.forever.rawValue,
            createdAt: Date()
        )
        let images = GlyphChunkSplitter.split(message: message)
        
        currentQRImages = images
        currentQRIndex = 0
        
        // If multi-frame, start cycling
        if images.count > 1 {
            startQRCycle()
        }
    }
    
    private func startQRCycle() {
        qrCycleTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            if !currentQRImages.isEmpty {
                currentQRIndex = (currentQRIndex + 1) % currentQRImages.count
            }
        }
    }
    
    private func stopQRCycle() {
        qrCycleTimer?.invalidate()
        qrCycleTimer = nil
    }
    
    private func cleanup() {
        stopQRCycle()
        scanner.stop()
    }
}

// MARK: - Front Camera Scanner

/// Vision-based QR scanner using the front-facing camera.
class FrontCameraScanner: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    
    @MainActor @Published var permissionDenied = false
    @MainActor var onCodeScanned: ((String) -> Void)?
    
    private var isRunning = false
    private var isProcessingFrame = false
    
    private lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        return request
    }()
    
    @MainActor
    func start() {
        guard !isRunning else { return }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }
    
    @MainActor
    func stop() {
        guard isRunning else { return }
        isRunning = false
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }
    
    @MainActor
    private func setupSession() {
        guard !isRunning else { return }
        
        let captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self, captureSession] in
            guard let self else { return }
            
            captureSession.beginConfiguration()
            
            if captureSession.canSetSessionPreset(.hd1920x1080) {
                captureSession.sessionPreset = .hd1920x1080
            }
            
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            // Use FRONT camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else {
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.addInput(input)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "glyph.agent.scan", qos: .userInitiated))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    // MARK: - Sample Buffer Delegate
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isProcessingFrame else { return }
        isProcessingFrame = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([barcodeRequest])
        } catch {
            isProcessingFrame = false
            return
        }
        
        guard let results = barcodeRequest.results, !results.isEmpty else {
            isProcessingFrame = false
            return
        }
        
        let payloads = results.compactMap { $0.payloadStringValue }
        
        if !payloads.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                for payload in payloads {
                    self.onCodeScanned?(payload)
                }
            }
        }
        
        isProcessingFrame = false
    }
}

// MARK: - Front Camera Preview

struct FrontCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgentComposeView()
    }
    .preferredColorScheme(.dark)
}
