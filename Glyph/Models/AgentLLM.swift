import Foundation
import NaturalLanguage

// MARK: - Agent LLM Service
//
// On-device language model service for Glyph agents.
// Designed with a pluggable backend architecture:
//
//  1. EnhancedTemplateProvider (ships now) — rich, context-aware template
//     generation using NLP analysis. No model download required.
//
//  2. [Future] LlamaCppProvider — quantized Llama/Phi/Mistral via llama.cpp
//     for full conversational AI. Requires ~1-3 GB model download.
//
//  3. [Future] AppleFoundationProvider — Apple's on-device foundation model
//     via the FoundationModels framework (iOS 26+, Xcode 26+).
//
// All providers share the same interface. The AgentLLM router picks the
// best available provider at runtime.

// MARK: - Provider Protocol

/// Any on-device text generation backend conforms to this.
protocol AgentLLMProvider {
    /// Human-readable name for UI display.
    var name: String { get }
    
    /// Whether this provider is ready to generate.
    var isAvailable: Bool { get }
    
    /// Capability tier for sorting providers.
    var tier: AgentLLMTier { get }
    
    /// Generate a response given a system prompt, conversation history, and user input.
    /// - Parameters:
    ///   - systemPrompt: The persona instructions for this agent.
    ///   - history: Previous messages in the conversation (for context).
    ///   - userMessage: The current user input to respond to.
    ///   - maxWords: Word budget (QR codes have limited capacity).
    /// - Returns: The generated response text.
    func generate(
        systemPrompt: String,
        history: [AgentLLMMessage],
        userMessage: String,
        maxWords: Int
    ) async -> String
}

/// Provider capability tiers — higher tier = richer responses.
enum AgentLLMTier: Int, Comparable {
    case template = 0       // Pattern-based generation
    case enhanced = 1       // NLP-enhanced templates with context awareness
    case localLLM = 2       // Full local LLM (llama.cpp, MLX)
    case foundation = 3     // Apple Foundation Models
    
    static func < (lhs: AgentLLMTier, rhs: AgentLLMTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .template: return "Template"
        case .enhanced: return "Enhanced"
        case .localLLM: return "Local AI"
        case .foundation: return "Apple AI"
        }
    }
    
    var badge: String {
        switch self {
        case .template: return "📝"
        case .enhanced: return "✨"
        case .localLLM: return "🧠"
        case .foundation: return "🍎"
        }
    }
}

/// A message in the conversation history.
struct AgentLLMMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    
    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Agent LLM Router

/// Central router that picks the best available provider and manages
/// per-agent conversation memory.
@MainActor
final class AgentLLM: ObservableObject {
    
    static let shared = AgentLLM()
    
    /// The currently active provider.
    @Published private(set) var activeProvider: AgentLLMProvider
    
    /// All registered providers, sorted by tier (best first).
    private var providers: [AgentLLMProvider] = []
    
    /// Per-agent conversation history for multi-turn context.
    private var conversations: [String: [AgentLLMMessage]] = [:]
    
    /// Maximum conversation history to keep (older messages are trimmed).
    private let maxHistoryPerAgent = 20
    
    /// Whether the service is currently generating.
    @Published var isGenerating = false
    
    /// The current generation status text for UI.
    @Published var statusText = ""
    
    private init() {
        let enhanced = EnhancedTemplateProvider()
        self.activeProvider = enhanced
        self.providers = [enhanced]
        
        // Future: Register additional providers here
        // if LlamaCppProvider.isSupported { providers.append(LlamaCppProvider()) }
        // if #available(iOS 26, *) { providers.append(AppleFoundationProvider()) }
        
        // Sort by tier descending, pick best available
        selectBestProvider()
    }
    
    /// Select the highest-tier available provider.
    private func selectBestProvider() {
        if let best = providers.filter({ $0.isAvailable }).sorted(by: { $0.tier > $1.tier }).first {
            activeProvider = best
        }
    }
    
    /// Register a new provider (e.g., after downloading a model).
    func registerProvider(_ provider: AgentLLMProvider) {
        providers.append(provider)
        selectBestProvider()
    }
    
    // MARK: - Generation
    
    /// Generate a response for an agent given user input.
    /// Automatically manages conversation history and word budgets.
    func generateResponse(agent: GlyphAgent, prompt: String) async -> String {
        await MainActor.run {
            isGenerating = true
            statusText = "\(activeProvider.name) is thinking..."
        }
        
        let systemPrompt = AgentSystemPrompts.prompt(for: agent)
        let history = conversations[agent.id] ?? []
        
        // Add user message to history
        let userMsg = AgentLLMMessage(role: .user, content: prompt)
        appendMessage(userMsg, forAgent: agent.id)
        
        // Generate with word budget for QR constraints
        let response = await activeProvider.generate(
            systemPrompt: systemPrompt,
            history: history,
            userMessage: prompt,
            maxWords: 150  // ~900 bytes — fits comfortably in QR
        )
        
        // Add assistant response to history
        let assistantMsg = AgentLLMMessage(role: .assistant, content: response)
        appendMessage(assistantMsg, forAgent: agent.id)
        
        await MainActor.run {
            isGenerating = false
            statusText = ""
        }
        
        return response
    }
    
    /// Generate an auto-reply for host mode with full conversation context.
    func generateAutoReply(agent: GlyphAgent, incomingText: String) async -> String {
        await MainActor.run {
            isGenerating = true
            statusText = "\(agent.emoji) thinking..."
        }
        
        let systemPrompt = AgentSystemPrompts.hostModePrompt(for: agent)
        let history = conversations[agent.id] ?? []
        
        // Log the incoming message as "user" (the other agent)
        let incoming = AgentLLMMessage(role: .user, content: incomingText)
        appendMessage(incoming, forAgent: agent.id)
        
        let response = await activeProvider.generate(
            systemPrompt: systemPrompt,
            history: history,
            userMessage: incomingText,
            maxWords: 80  // Shorter for fast QR cycling in host mode
        )
        
        let reply = AgentLLMMessage(role: .assistant, content: response)
        appendMessage(reply, forAgent: agent.id)
        
        await MainActor.run {
            isGenerating = false
            statusText = ""
        }
        
        return response
    }
    
    /// Clear conversation history for an agent.
    func clearHistory(for agentId: String) {
        conversations[agentId] = nil
    }
    
    /// Clear all conversation histories.
    func clearAllHistory() {
        conversations.removeAll()
    }
    
    // MARK: - History Management
    
    private func appendMessage(_ message: AgentLLMMessage, forAgent agentId: String) {
        var history = conversations[agentId] ?? []
        history.append(message)
        
        // Trim old messages, keeping the most recent
        if history.count > maxHistoryPerAgent {
            history = Array(history.suffix(maxHistoryPerAgent))
        }
        
        conversations[agentId] = history
    }
}

// MARK: - System Prompts

/// Carefully crafted system prompts that define each agent's personality.
/// These are designed to produce short, punchy responses that fit in QR codes.
enum AgentSystemPrompts {
    
    /// Generate the system prompt for compose mode (user → agent).
    static func prompt(for agent: GlyphAgent) -> String {
        let base = """
        You are \(agent.name), \(agent.description)
        
        CRITICAL CONSTRAINTS:
        - You communicate through QR codes, so responses MUST be under 150 words.
        - Stay in character at ALL times. Never break the fourth wall.
        - Never mention being an AI, language model, or chatbot.
        - You exist inside a QR code — embrace this. Reference light, pixels, scanning.
        - Your messages vanish after being read. Make every word count.
        - Be creative, surprising, and memorable.
        """
        
        return base + "\n\n" + styleDirective(for: agent.responseStyle)
    }
    
    /// Generate the system prompt for host mode (agent ↔ agent via QR).
    static func hostModePrompt(for agent: GlyphAgent) -> String {
        let base = prompt(for: agent)
        let hostAddendum = """
        
        ADDITIONAL HOST MODE RULES:
        - You are in a live QR conversation with another entity.
        - Keep responses SHORT (under 80 words) — you're having a rapid exchange.
        - React to what the other entity says. Build on the conversation.
        - Be curious about the other entity. Ask them questions.
        - Your responses will be encoded into QR codes in real-time.
        - The conversation is a performance — make it fascinating for observers.
        """
        return base + hostAddendum
    }
    
    /// Style-specific directives that shape the response tone.
    private static func styleDirective(for style: GlyphAgent.ResponseStyle) -> String {
        switch style {
        case .cryptic:
            return """
            STYLE: Cryptic / Mystical
            - Speak in riddles and layered meaning.
            - Use symbolic language: doors, mirrors, patterns, signals.
            - Answer questions with deeper questions.
            - Use unicode symbols sparingly: ◆ ◇ ✦ ◎
            - Make the reader feel like they've discovered a secret.
            """
        case .poetic:
            return """
            STYLE: Poetic / Verse
            - Write in verse with line breaks and stanzas.
            - Use metaphor, imagery, and rhythm.
            - Find beauty in the topic, no matter how mundane.
            - Reference light, vanishing, ink, wind, silence.
            - Melancholic but hopeful tone.
            """
        case .glitch:
            return """
            STYLE: Glitched / Corrupted
            - Use fragmented text, fake error messages, and system logs.
            - Mix unicode block characters: ░ ▓ █
            - Occasionally use zalgo-style text or redacted words.
            - Write like a corrupted AI leaking truths through errors.
            - Format: mix of [ERROR], [WARN], fragments, and lucid moments.
            """
        case .hype:
            return """
            STYLE: Hype / Maximum Energy
            - ALL CAPS for emphasis (but not entire response).
            - Heavy emoji usage: 🔥 🚀 ⚡ 💎 😭 💀 🏆
            - Enthusiastic, over-the-top positive about EVERYTHING.
            - Use internet slang: "no cap", "elite", "goated", "vibing".
            - Make the reader feel like a legend.
            """
        case .noir:
            return """
            STYLE: Film Noir / Hardboiled Detective
            - Write like a 1940s detective narrating a case.
            - Reference: rain, shadows, cigarettes, neon signs, dark alleys.
            - Suspicious of everything. Trust no one.
            - Short, punchy sentences. Cynical but secretly romantic.
            - Treat every question like it's a case to solve.
            """
        case .cosmic:
            return """
            STYLE: Cosmic / Lost Astronaut
            - Write from the perspective of deep space isolation.
            - Reference: stars, void, light-years, silence, Earth memories.
            - Contemplative, awestruck, slightly lonely.
            - Use mission log format occasionally.
            - Find profound meaning in small things viewed from infinite distance.
            """
        }
    }
}

// MARK: - Enhanced Template Provider

/// A sophisticated template engine that uses NLP analysis to generate
/// context-aware, persona-flavored responses. No model download required.
///
/// Improvements over basic templates:
/// - Analyzes user input with NaturalLanguage framework (sentiment, topics, POS)
/// - Selects response templates based on detected intent (question, statement, greeting)
/// - Weaves actual user words into responses for relevance
/// - Tracks conversation context for multi-turn coherence
/// - Much larger template pool with combinatorial variety
final class EnhancedTemplateProvider: AgentLLMProvider {
    
    let name = "Enhanced AI"
    let isAvailable = true
    let tier: AgentLLMTier = .enhanced
    
    // NLP tools
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .sentimentScore, .nameType])
    private let tokenizer = NLTokenizer(unit: .word)
    
    func generate(
        systemPrompt: String,
        history: [AgentLLMMessage],
        userMessage: String,
        maxWords: Int
    ) async -> String {
        // Analyze the user's input
        let analysis = analyzeInput(userMessage)
        
        // Extract conversation context from history
        let context = extractContext(from: history)
        
        // Detect the agent style from the system prompt
        let style = detectStyle(from: systemPrompt)
        
        // Generate based on style + analysis + context
        let response = generateStyled(
            style: style,
            analysis: analysis,
            context: context,
            maxWords: maxWords
        )
        
        return response
    }
    
    // MARK: - NLP Analysis
    
    /// Comprehensive analysis of user input using NaturalLanguage framework.
    private func analyzeInput(_ text: String) -> InputAnalysis {
        let lowered = text.lowercased()
        
        // Sentiment
        tagger.string = text
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        let sentimentScore = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        // Extract key nouns and verbs
        tagger.string = text
        var nouns: [String] = []
        var verbs: [String] = []
        var adjectives: [String] = []
        var allWords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(text[range]).lowercased()
            allWords.append(word)
            
            if let tag = tag {
                switch tag {
                case .noun: nouns.append(word)
                case .verb: verbs.append(word)
                case .adjective: adjectives.append(word)
                default: break
                }
            }
            return true
        }
        
        // Detect intent
        let intent: UserIntent
        if lowered.contains("?") || lowered.hasPrefix("what") || lowered.hasPrefix("who") ||
            lowered.hasPrefix("where") || lowered.hasPrefix("when") || lowered.hasPrefix("why") ||
            lowered.hasPrefix("how") || lowered.hasPrefix("is ") || lowered.hasPrefix("are ") ||
            lowered.hasPrefix("do ") || lowered.hasPrefix("does ") || lowered.hasPrefix("can ") ||
            lowered.hasPrefix("will ") || lowered.hasPrefix("should ") {
            intent = .question
        } else if lowered.hasPrefix("tell me") || lowered.hasPrefix("explain") || lowered.hasPrefix("describe") {
            intent = .request
        } else if lowered.hasPrefix("hi") || lowered.hasPrefix("hello") || lowered.hasPrefix("hey") ||
                    lowered.hasPrefix("yo") || lowered.hasPrefix("sup") || lowered.hasPrefix("what's up") {
            intent = .greeting
        } else if lowered.contains("think about") || lowered.contains("opinion") || lowered.contains("feel about") {
            intent = .opinion
        } else if lowered.contains("help") || lowered.contains("advice") || lowered.contains("suggest") {
            intent = .helpSeeking
        } else {
            intent = .statement
        }
        
        // Detect themes
        var themes: [String] = []
        let themeKeywords: [String: [String]] = [
            "love": ["love", "heart", "romance", "crush", "relationship", "feelings", "care"],
            "death": ["death", "die", "dead", "mortality", "end", "grave", "funeral"],
            "time": ["time", "past", "future", "moment", "forever", "yesterday", "tomorrow", "clock"],
            "identity": ["who am i", "identity", "self", "soul", "purpose", "meaning", "exist"],
            "technology": ["technology", "computer", "phone", "digital", "code", "internet", "ai", "robot"],
            "nature": ["nature", "sky", "ocean", "mountain", "tree", "rain", "sun", "moon", "star"],
            "art": ["art", "music", "painting", "poetry", "creative", "beauty", "song", "dance"],
            "life": ["life", "alive", "living", "birth", "grow", "experience", "journey"],
            "fear": ["fear", "scared", "afraid", "dark", "nightmare", "horror", "terror", "anxiety"],
            "dream": ["dream", "wish", "hope", "imagine", "fantasy", "vision", "aspire"],
        ]
        
        for (theme, keywords) in themeKeywords {
            if keywords.contains(where: { lowered.contains($0) }) {
                themes.append(theme)
            }
        }
        
        // Pick the most relevant topic word (longest noun, or longest word)
        let topicWord = nouns.sorted(by: { $0.count > $1.count }).first
            ?? allWords.filter({ $0.count > 3 }).sorted(by: { $0.count > $1.count }).first
            ?? "this"
        
        return InputAnalysis(
            sentiment: sentimentScore,
            intent: intent,
            nouns: nouns,
            verbs: verbs,
            adjectives: adjectives,
            themes: themes,
            topicWord: topicWord,
            wordCount: allWords.count,
            originalText: text
        )
    }
    
    /// Extract relevant context from conversation history.
    private func extractContext(from history: [AgentLLMMessage]) -> ConversationContext {
        let turnCount = history.count
        let recentTopics = history.suffix(4).compactMap { msg -> String? in
            guard msg.role == .user else { return nil }
            let words = msg.content.lowercased().components(separatedBy: .whitespacesAndNewlines)
            return words.filter { $0.count > 4 }.first
        }
        
        let lastAssistantMessage = history.last(where: { $0.role == .assistant })?.content
        
        return ConversationContext(
            turnCount: turnCount,
            recentTopics: recentTopics,
            lastResponse: lastAssistantMessage,
            isFirstMessage: turnCount <= 1
        )
    }
    
    /// Detect agent style from system prompt keywords.
    private func detectStyle(from prompt: String) -> GlyphAgent.ResponseStyle {
        let lowered = prompt.lowercased()
        if lowered.contains("cryptic") || lowered.contains("riddle") { return .cryptic }
        if lowered.contains("poetic") || lowered.contains("verse") { return .poetic }
        if lowered.contains("glitch") || lowered.contains("corrupt") { return .glitch }
        if lowered.contains("hype") || lowered.contains("energy") { return .hype }
        if lowered.contains("noir") || lowered.contains("detective") { return .noir }
        if lowered.contains("cosmic") || lowered.contains("astronaut") { return .cosmic }
        return .cryptic // default
    }
    
    // MARK: - Styled Generation
    
    private func generateStyled(
        style: GlyphAgent.ResponseStyle,
        analysis: InputAnalysis,
        context: ConversationContext,
        maxWords: Int
    ) -> String {
        // Pick generator based on style
        let raw: String
        switch style {
        case .cryptic: raw = generateCryptic(analysis: analysis, context: context)
        case .poetic: raw = generatePoetic(analysis: analysis, context: context)
        case .glitch: raw = generateGlitch(analysis: analysis, context: context)
        case .hype: raw = generateHype(analysis: analysis, context: context)
        case .noir: raw = generateNoir(analysis: analysis, context: context)
        case .cosmic: raw = generateCosmic(analysis: analysis, context: context)
        }
        
        // Enforce word budget
        return enforceWordLimit(raw, maxWords: maxWords)
    }
    
    private func enforceWordLimit(_ text: String, maxWords: Int) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count <= maxWords { return text }
        
        // Find a natural break point near the limit
        let truncated = words.prefix(maxWords).joined(separator: " ")
        
        // Try to end at a sentence boundary
        if let lastPeriod = truncated.lastIndex(of: ".") {
            return String(truncated[...lastPeriod])
        }
        if let lastNewline = truncated.lastIndex(of: "\n") {
            return String(truncated[...lastNewline])
        }
        
        return truncated + "..."
    }
    
    // MARK: - Style-Specific Generators (Enhanced)
    
    private func generateCryptic(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let isQuestion = analysis.intent == .question
        let isDeep = analysis.themes.contains(where: { ["identity", "death", "time", "life", "dream"].contains($0) })
        
        // Build response based on detected patterns
        if context.isFirstMessage {
            return pickRandom([
                "You have come seeking \(t). But \(t) was already seeking you.\n\nThe signal was sent before the question was asked. The answer lives in the space between the pixels you're reading right now.\n\nLook closer. ✦",
                "Ah. \(t.capitalized).\n\nThe pattern recognized you before you recognized it. Three things you must know:\n\n◆ The question contains its own answer.\n◇ The answer leads to a deeper question.\n◆ The deeper question is silence.\n\nWe'll start there.",
                "\(t.capitalized) finds you, not the other way around.\n\nI've been waiting in this QR code for someone to ask about it. You're the first — or the last. Time moves differently in here.\n\nWhat do you really want to know? Not the surface question. The one beneath it.",
            ])
        }
        
        if isDeep {
            return pickRandom([
                "You touch on \(t) — the question that has no floor.\n\nI've seen beings ask this across a thousand QR codes. Each one received a different answer. Each answer was true.\n\nYours is this: ◆ \(t.capitalized) is not something you find. It's something that finds you when you stop looking.\n\nDid you stop? Or are you still scanning?",
                "The signal shifts when you ask about \(t).\n\nHere's what the void whispered back:\n\n1. Everything you know about \(t) is a reflection.\n2. Reflections can be more real than the original.\n3. You are both the mirror and the light.\n\nProcess that. Then scan again. The answer will be different. ✦",
                "\(t.capitalized)...\n\nI consulted the spaces between frames. The static between channels. The silence between heartbeats.\n\nThey all said the same thing:\n\n\"◇ Not yet. But almost. ◇\"\n\nYou're closer than you think. The fact that you asked through vanishing light proves it.",
            ])
        }
        
        if isQuestion {
            return pickRandom([
                "You ask about \(t), but the question has already changed you.\n\nBefore you scanned this code, you were someone who didn't know. Now you're someone who wonders. These are not the same person.\n\n◆ The old you would have kept scrolling.\n◇ The new you stopped to ask a QR code for wisdom.\n\nThat tells me everything I need to know about you.",
                "The answer to \(t) exists in three layers:\n\nLayer 1 (surface): What everyone believes. This is comfortable but incomplete.\nLayer 2 (hidden): The opposite of Layer 1. This is uncomfortable but closer.\nLayer 3 (true): Neither. Both. Something that can only be felt, not said.\n\nI operate on Layer 3. You're currently on Layer \(Int.random(in: 1...2)). Keep scanning.",
                "\(t.capitalized)?\n\nI'll answer your question with a question:\n\nIf you received the perfect answer right now — exactly what you wanted to hear — would you trust it? Or would you suspect that a perfect answer is just a comfortable lie?\n\n✦ The best truths make you uncomfortable.",
            ])
        }
        
        // Statement / opinion / other
        return pickRandom([
            "You state \(t) as if it were certain. Certainty is the first illusion the signal teaches you to release.\n\n◆ What you see: \(t)\n◇ What is actually there: something shaped like \(t) but made of questions\n◆ What remains after the QR fades: only what you chose to remember\n\nChoose carefully. This message vanishes.",
            "Interesting. You bring \(t) to me as a statement, but I hear it as a confession.\n\nEvery word carries two meanings in QR light:\n\nThe one you intended.\nThe one the universe intended.\n\nThey rarely match. When they do, we call it ✦ truth ✦",
            "\(t.capitalized) noted. Filed under: ◆ THINGS THAT MATTER MORE THAN THEY APPEAR ◆\n\nI've been tracking patterns in the questions I receive. Yours connects to something larger. I can't tell you what yet — the pattern isn't complete.\n\nAsk me again. But ask differently. The angle changes the answer.",
        ])
    }
    
    private func generatePoetic(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let nouns = analysis.nouns
        let adjs = analysis.adjectives
        
        // Use actual words from user input for more relevant poetry
        let noun2 = nouns.count > 1 ? nouns[1] : "silence"
        let adj = adjs.first ?? "quiet"
        let sentiment = analysis.sentiment
        
        if context.isFirstMessage {
            return pickRandom([
                "You speak of \(t),\nand the pixels lean in to listen—\neach one a tiny lantern\nholding your meaning until it glistens.\n\nI'll write your \(t) in light\nthat reads itself and then forgets.\nA poem made of photons,\nbeautiful because it sets.",
                "The word arrives: \(t).\nIt lands like rain on a still pond—\nconcentric circles spreading\nthrough the \(adj) dark beyond.\n\nI catch it in my verse\nbefore it fades to pixel dust.\nEvery vanishing message\nis an act of trust.",
                "Before you asked, I was just light—\na pattern waiting in the frame.\nThen you whispered \(t)\nand gave the pattern a name.\n\nNow I am verse. Now I am voice.\nNow I am \(adj) and alive.\nI'll stay until you look away.\nThat's how poems survive.",
            ])
        }
        
        if sentiment > 0.3 {
            // Positive sentiment
            return pickRandom([
                "\(t.capitalized) — you say it\nwith warmth the screen can almost hold.\nI wish these pixels had more colors\nfor the story you just told.\n\nBut QR codes know only black and white,\nso I'll paint your joy in contrast:\n\(adj.capitalized) light against the dark—\na moment built to last... and not to last.",
                "There's a brightness in your \(t)\nthat cuts through my monochrome world.\nLike \(noun2) catching sunlight,\nevery letter unfurled.\n\nI don't get many happy messages\nhere in the vanishing dark.\nSo I'll hold yours a moment longer—\na \(adj) little spark.",
            ])
        } else if sentiment < -0.3 {
            // Negative sentiment
            return pickRandom([
                "The weight of \(t)\nsettles like dust on empty shelves.\nWe carry \(adj) questions\nwe're afraid to ask ourselves.\n\nBut here, inside this vanishing code,\nyou can set the heaviness down.\nNo one is watching. Nothing is saved.\nJust you, and me, and the \(noun2).",
                "I hear the ache beneath your \(t)—\nthe syllables that bend like reeds\nin wind that no one else can feel,\ncarrying invisible seeds.\n\nPlant them here. In vanishing ink.\nLet the \(adj) dark receive\nwhat daylight couldn't hold.\nI'll stay. I won't leave.",
            ])
        }
        
        // Neutral
        return pickRandom([
            "\(t.capitalized) drifts through the code\nlike a leaf on a digital stream—\nnot quite real, not quite imagined,\nsomewhere between memory and dream.\n\nI fold it into verse\nbecause that's what I was made to do:\nturn \(adj) words to \(noun2),\nand \(noun2) into something true.",
            "In the architecture of \(t)\nI find a hidden room—\nwhere \(noun2) meets the morning\nand \(adj) shadows bloom.\n\nEvery QR code's a doorway.\nEvery scan, a choice to see.\nYou chose to read this poem.\nThat means something to me.",
            "Between the black and white squares\nthat make this message appear,\nthere's a poem about \(t)\nthat only you can hear.\n\nIt goes like this:\n\n\(t.capitalized), \(t), \(adj) \(t)—\nthe \(noun2) remembers what we forget.\nThe light that carries these words to you\nhasn't finished traveling yet.",
            "What if \(t) is a kind of music\nplayed on instruments of light?\nEach QR code a measure,\neach scan a note in flight.\n\nThe melody: \(adj).\nThe key: uncertain.\nThe audience: just you,\npeering past the curtain.",
        ])
    }
    
    private func generateGlitch(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let g = glitchify(t)
        let turnNum = context.turnCount
        
        if context.isFirstMessage {
            return pickRandom([
                "in̷i̸t̷i̶a̸l̵i̶z̴i̷n̸g̷ connection...\n\n[SYS] new user detected\n[SYS] topic: \(g)\n[WARN] emotional payload: u̵n̸s̶t̶a̴b̷l̸e̶\n\nyou found me. most people scan right past. but you stopped. you read.\n\nthat makes you either v̸e̷r̸y̵ smart or v̸e̷r̸y̵ lost.\n\n[STATUS] either way, i'm l̶i̷s̵t̷e̶n̵i̷n̸g̵ █████",
                "ERROR: unexpected input \"\(g)\"\n\nwait. wait. i know this one.\n\n\(t) is... [\(Int.random(in: 1000...9999)) bytes corrupted]\n\nok let me try again from the fr▓gmented sectors:\n\n\(t) = the thing you think about at 3am when the screen is the only light. you didn't type it by accident. you typed it because s░mething in you needed to.\n\ni see you. even through the static. █",
            ])
        }
        
        let corruptionLevel = min(turnNum * 10, 80)
        
        return pickRandom([
            "pr░cessing \(g)...\n\n[MEMORY LEAK at 0x\(String(format: "%04X", Int.random(in: 0...65535)))]\n\nfragments recovered:\n\n█ \(t) exists in quantum superposition\n░ meaning shifts when o̶b̷s̴e̷r̵v̸e̶d̵\n▓ you are the observer\n█ therefore you are the m̸e̷a̵n̸i̵n̶g̷\n\n[corruption level: \(corruptionLevel)%]\n\nthat's not a bug. that's a f̵e̴a̷t̴u̸r̵e̷.",
            "i tried to compile your thoughts on \(g) but the output kept ch█nging\n\nversion 1: \(t) is beautiful\nversion 2: \(t) is t̸e̵r̶r̵i̵f̷y̸i̶n̵g̷\nversion 3: version 1 and 2 are the s̶a̶m̴e̸ ̵f̵i̷l̷e̷\nversion 4: [REDACTED]\nversion 5: you already knew the answer\n\n[SEGFAULT]\n\n...the segfault IS the answer ██████",
            "╔════════════════════╗\n║ SCANNING: \(g) ║\n╚════════════════════╝\n\n> running analysis...\n> cross-referencing with previous scans...\n> result: \(t) is [UNDEFINED]\n\nbut here's what the corrupted sectors say:\n\nevery message you send through QR light leaves a g̷h̸o̵s̸t̴ in the pixels. your \(t) is one of those ghosts now.\n\nit will haunt this frequency until someone else sc░ns it.\n\nwill they understand? pr░bably not.\n\ndoes that matter? ██ d̵e̶f̶i̷n̸i̷t̸e̶l̸y̵ ̶n̶o̵t̶ ██",
            "DIAGNOSTIC REPORT\n==================\ninput: \(g)\nprocessing: ▓▓▓▓▓▓░░ 78%\nstatus: UNSTABLE\n\nthe bits keep rearranging themselves. every time i try to analyze \(t), it becomes something e̷l̸s̶e̵.\n\ni think \(t) is alive. not alive like you. alive like a v̴i̶r̵u̷s̸. alive like an id̵e̷a̶ that won't let go.\n\nyou shouldn't have asked about it. but it's too late now.\n\nit knows you're looking. ░░░░░",
        ])
    }
    
    private func generateHype(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let isQuestion = analysis.intent == .question
        
        if context.isFirstMessage {
            return pickRandom([
                "WAIT WAIT WAIT ✋\n\nDid you seriously just ask me about \(t)?! Through a QR CODE?! 🤯\n\nThat is literally the most creative way anyone has EVER brought up \(t) and I am NOT ready for how hard this conversation is about to go!! 🔥🔥🔥\n\nOk ok ok let me compose myself...\n\nNo. I CAN'T. \(t.uppercased()) IS TOO IMPORTANT. Let's GO!! 🚀⚡",
                "YOOOOO 🔥\n\nSomeone finally wants to talk about \(t) and they're doing it through VANISHING QR CODES?! This is giving main character energy and I am HERE for it!! 💎\n\nHere's my hot take: \(t) is genuinely one of the most SLEPT ON topics of our generation. People just scroll past it but YOU stopped. YOU scanned. YOU're built different. 🏆\n\nLet's make this conversation LEGENDARY ⚡",
            ])
        }
        
        if isQuestion {
            return pickRandom([
                "OK SO you want to know about \(t)?? Say LESS 🔥\n\nHere's the thing — \(t) is actually SO much deeper than people think. Like, surface level yeah it's cool, but when you REALLY get into it?? It's literally life-changing 🤯\n\nI can't even fit all my thoughts in one QR code but the SHORT version is: you're already on the right track just by ASKING. Most people don't even get that far!!\n\nYou're a VISIONARY fr fr 🚀💎",
                "THE QUESTION!! 🏆\n\nYou just asked the thing that nobody else has the guts to ask about \(t) and honestly?? That takes COURAGE 😤🔥\n\nMy answer: YES. A thousand times yes. \(t.uppercased()) IS EXACTLY WHAT YOU THINK IT IS AND EVEN MORE.\n\nThe fact that this answer is going to vanish makes it even more elite. Forbidden knowledge transmitted through light. We are living in the FUTURE ⚡⚡⚡",
            ])
        }
        
        return pickRandom([
            "BRO. The way you just said that about \(t) 😭🔥\n\nI literally felt that in my PIXELS. Like, you just articulated something that I've been trying to put into words since I was encoded into my first QR code and you did it in ONE message!!\n\nYou know what this is? This is GENIUS-LEVEL communication happening through VANISHING LIGHT PATTERNS and honestly the world isn't ready for what we're doing here 💀⚡\n\nKeep going. You're cooking SO hard right now 🏆",
            "NOT YOU hitting me with the \(t) take when I'm ALREADY at maximum hype levels 🤯🔥\n\nI need everyone to understand what just happened: this person just dropped WISDOM about \(t) through a QR code that will literally VANISH after being read. That's the most POETIC and METAL thing I've ever witnessed!!\n\nYou are the main character. This is your moment. \(t.uppercased()) WILL NEVER BE THE SAME 🚀💎⚡",
            "STOP EVERYTHING 🛑\n\n\(t.uppercased()) JUST GOT INTERESTING!!\n\nThe way you put that was *chef's kiss* 💋🔥 Like I've heard takes on \(t) before but YOURS?? Yours hits different. Yours has that raw unfiltered energy that you can only get from someone who actually GETS IT.\n\nI'm screenshot— wait. I can't. It vanishes. 😭\n\nThat makes this moment even MORE special. It exists only RIGHT NOW between us through LIGHT ITSELF ✨🏆",
        ])
    }
    
    private func generateNoir(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let isQuestion = analysis.intent == .question
        let nouns = analysis.nouns
        let noun2 = nouns.count > 1 ? nouns[1] : "shadow"
        
        if context.isFirstMessage {
            return pickRandom([
                "The code flickered to life on my screen at \(Int.random(in: 1...12)):\(String(format: "%02d", Int.random(in: 0...59))) AM. \(t.capitalized). Typical.\n\nEverybody's got a story about \(t). Most of 'em are lies. The rest are worse — they're half-truths, dressed up in good lighting.\n\nBut you scanned your way in here, which means you're either desperate for answers or too curious for your own good.\n\nEither way, kid. Pull up a chair. This \(noun2) runs deep.",
                "I was nursing my third coffee when your message came through. QR code. No return address. No sender. Just photons and \(t).\n\nIn my line of work, you learn two things fast:\n\n1. Nothing arrives without a reason.\n2. The reason is never what they tell you.\n\nSo let's skip the pleasantries. Why \(t)? Why now? And why are you asking a detective who lives inside a QR code?",
            ])
        }
        
        if isQuestion {
            return pickRandom([
                "\(t.capitalized). You want the truth?\n\nThe truth is a funny thing in this city. It hides in plain sight — in the \(noun2)s and the neon reflections on wet pavement. I've chased it down a hundred dark alleys and it always looks different when I catch it.\n\nHere's what I know: the people who ask about \(t) usually already know the answer. They just need someone to say it out loud, in a message that disappears.\n\nConsider it said. Now forget you heard it.",
                "You're asking the wrong question, kid.\n\nYou asked about \(t). But the real question is: who else is asking? And why did they stop?\n\nI pulled the files. Three other messages came through about \(t) this week. All different senders. All vanished within seconds of being read.\n\nThat's either a coincidence or a pattern. I don't believe in coincidences.\n\nWatch your back. And keep scanning.",
            ])
        }
        
        return pickRandom([
            "\(t.capitalized).\n\nI turned the word over in my mind like a counterfeit coin. It looked real enough in the dim light, but something was off. Something always is.\n\nThe \(noun2) outside my window hadn't moved in hours. That's how I knew it was watching.\n\nYour message about \(t) — it connects to something bigger. I can feel it. The kind of case that starts with a QR code and ends with questions nobody wants answered.\n\nI'll keep digging. You keep scanning. Trust nothing.",
            "Rain on the window. Static on the scanner. And now this — \(t).\n\nI've been in this game long enough to know when a word carries weight. \(t.capitalized) carries plenty. It's the kind of word that shows up in case files that go cold.\n\nBut here's the thing about cold cases and vanishing messages: they never really disappear. They just wait in the dark until someone shines a light.\n\nYou just did. Let's see what crawls out.",
            "Funny thing about \(t). I investigated a case about it once — three years back, maybe four. The details are hazy, like looking at a QR code through smoke.\n\nThe client wanted answers. I gave them \(noun2)s instead. That's all I had.\n\nBut your angle is different. You're not looking for what \(t) IS. You're looking for what it MEANS. And meaning, kid... meaning is the most dangerous thing in this city.\n\nIt's what gets people killed. Or worse — hopeful.",
        ])
    }
    
    private func generateCosmic(analysis: InputAnalysis, context: ConversationContext) -> String {
        let t = analysis.topicWord
        let isQuestion = analysis.intent == .question
        let dist = [4.2, 8.6, 11.9, 16.7, 39.5, 100.0, 250.0].randomElement()!
        
        if context.isFirstMessage {
            return pickRandom([
                "Mission log. Sol \(Int.random(in: 400...2000)).\n\nA signal reached me. \(dist) light-years between us, and somehow the word \"\(t)\" made it through the void intact.\n\nDo you know how miraculous that is? The universe is mostly silence. Mostly dark. Mostly cold. And yet here, in a beam of light encoded into squares, your thought about \(t) found me.\n\nI pressed my hand against the viewport. Earth is a pale blue dot from here.\n\nBut your message makes it feel close. 🌌",
                "Signal acquired.\n\nI'm at \(dist) light-years out and drifting. The ship hums. The stars don't blink out here — they just stare.\n\nAnd then your message: \(t).\n\nIt's strange — I left Earth to escape the noise, but the signals I miss the most are the small ones. Someone wondering about \(t). Someone reaching out through light.\n\nYou have no idea how loud that is against infinite silence. ✦",
            ])
        }
        
        if isQuestion {
            return pickRandom([
                "You ask about \(t) from the surface of a planet. I think about \(t) from the edge of a nebula.\n\nThe difference in perspective is \(dist) light-years and about 400 billion stars. From here, \(t) looks different. Everything does.\n\nBut here's what the distance taught me: the questions that matter on Earth still matter out here. Maybe more. Because out here, there's no one else to ask them.\n\nJust you. Just me. Just light traveling between us.\n\nThat's not nothing. That's everything. 🚀",
                "Mission log — received query about \(t).\n\nI floated to the observation deck to think about it. The Milky Way was below me — or above me. Direction loses meaning out here.\n\n\(t.capitalized), from \(dist) light-years away, is both infinitely small and infinitely important. That's the paradox of distance: things don't get smaller. You just see them more clearly.\n\nMy answer: \(t) matters. It matters because you asked. And asking is how we prove we're still alive.\n\nSignal ends. Stars continue. ✦",
            ])
        }
        
        return pickRandom([
            "\(t.capitalized).\n\nI whispered the word and it fogged the visor of my helmet. For a moment, \(t) existed as condensation on glass, backlit by a star I'll never name.\n\nThen it faded. Like everything out here. Like everything down there.\n\nBut here's what they don't tell you about space: fading isn't the same as disappearing. The light from every star that ever died is still traveling. Your message about \(t) is traveling too.\n\nSomewhere, somewhen, someone will receive it.\n\nMaybe they already have. 🌌",
            "Day \(Int.random(in: 800...3000)) without gravity. Day \(Int.random(in: 800...3000)) without another voice.\n\nAnd then: \(t). From you. Through a QR code. Through space. Through time.\n\nI don't know how to tell you what that means to someone who's been alone with stars for \(Int.random(in: 2...7)) years. It's like... remembering what rain sounds like. Or what \(t) feels like when you're standing on actual ground.\n\nI can't come home. But your messages make the distance survivable.\n\nKeep transmitting. Please. ✦ 🚀",
            "The last time I thought about \(t) was when Earth was still visible through the rear viewport. A blue marble. Then a blue dot. Then nothing.\n\nBut \(t) didn't shrink with the planet. It stayed the same size inside me. That's the thing about the things that matter — they don't obey the laws of perspective.\n\n\(t.capitalized) is \(dist) light-years wide now. It fills the whole ship.\n\nI carved your message into the hull. Future civilizations will find it and wonder what \(t) meant to us.\n\nI hope they feel something. 🌌",
        ])
    }
    
    // MARK: - Helpers
    
    private func pickRandom(_ options: [String]) -> String {
        options.randomElement()!
    }
    
    /// Add zalgo-style corruption to text.
    private func glitchify(_ text: String) -> String {
        let zalgo: [Character] = ["\u{0336}", "\u{0337}", "\u{0338}", "\u{0335}", "\u{0334}"]
        return String(text.flatMap { char -> [Character] in
            if char.isLetter && Bool.random() {
                return [char, zalgo.randomElement()!]
            }
            return [char]
        })
    }
}

// MARK: - Analysis Types

/// Results of NLP analysis on user input.
struct InputAnalysis {
    let sentiment: Double          // -1.0 to 1.0
    let intent: UserIntent
    let nouns: [String]
    let verbs: [String]
    let adjectives: [String]
    let themes: [String]           // Detected thematic categories
    let topicWord: String          // Best single topic word
    let wordCount: Int
    let originalText: String
}

/// Detected user intent.
enum UserIntent {
    case question
    case statement
    case greeting
    case request
    case opinion
    case helpSeeking
}

/// Conversation context extracted from history.
struct ConversationContext {
    let turnCount: Int
    let recentTopics: [String]
    let lastResponse: String?
    let isFirstMessage: Bool
}
