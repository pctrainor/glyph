import SwiftUI
import Translation

// MARK: - Translation View

/// Full-screen two-person translation conversation UI.
/// Uses Apple's Translation framework for on-device translation.
struct TranslationView: View {
    @State private var service = TranslationService()
    @State private var inputText = ""
    @State private var translationConfig: TranslationSession.Configuration?
    @FocusState private var inputFocused: Bool
    @State private var showLanguagePickerA = false
    @State private var showLanguagePickerB = false
    @State private var languageSearch = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────
            header
            
            // ── Language Bar ─────────────────────────
            languageBar
            
            // ── Quick Phrases ────────────────────────
            quickPhraseBar
            
            // ── Messages ─────────────────────────────
            messageList
            
            // ── Input Bar ────────────────────────────
            inputBar
        }
        .background(GlyphTheme.background)
        .translationTask(translationConfig) { session in
            await handleTranslation(session)
        }
        .sheet(isPresented: $showLanguagePickerA) {
            LanguagePickerSheet(
                title: "Person A Language",
                selectedLanguage: $service.languageA,
                languages: service.availableLanguages
            )
        }
        .sheet(isPresented: $showLanguagePickerB) {
            LanguagePickerSheet(
                title: "Person B Language",
                selectedLanguage: $service.languageB,
                languages: service.availableLanguages
            )
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("🌐 Glyph Translate")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GlyphTheme.accent, Color(red: 0.27, green: 0.87, blue: 0.53)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("On-device · Offline · Private")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button("Clear Conversation", systemImage: "trash") {
                    service.clearConversation()
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Language Bar
    
    private var languageBar: some View {
        HStack(spacing: 8) {
            languageButton(
                label: "Person A",
                language: service.languageA,
                color: GlyphTheme.accent
            ) {
                showLanguagePickerA = true
            }
            
            Button(action: { 
                withAnimation(.spring(response: 0.3)) {
                    service.swapLanguages()
                }
            }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GlyphTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(GlyphTheme.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1)))
            }
            
            languageButton(
                label: "Person B",
                language: service.languageB,
                color: GlyphTheme.violet
            ) {
                showLanguagePickerB = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(GlyphTheme.surface.opacity(0.5))
    }
    
    private func languageButton(label: String, language: Locale.Language, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                HStack(spacing: 4) {
                    Text(service.displayName(for: language))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(color.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(GlyphTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2))
            )
        }
    }
    
    // MARK: - Quick Phrases
    
    private var quickPhraseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(quickPhrases, id: \.self) { phrase in
                    Button(action: {
                        inputText = phrase
                        sendMessage()
                    }) {
                        Text(phrase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(GlyphTheme.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.08)))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 6)
    }
    
    private var quickPhrases: [String] {
        ["Hello", "Thank you", "How are you?", "Yes", "No", "Please",
         "Sorry", "Where is...?", "How much?", "Help", "Water", "Food"]
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if service.messages.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(service.messages) { msg in
                            MessageBubble(message: msg, service: service)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .onChange(of: service.messages.count) { _, _ in
                if let last = service.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🌐")
                .font(.system(size: 60))
            Text("Pick two languages above,\nthen type or tap a phrase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("100% on-device · No internet needed")
                .font(.caption2)
                .foregroundStyle(.quaternary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.05))
            
            HStack(spacing: 8) {
                // Speaker toggle
                HStack(spacing: 0) {
                    speakerButton(.personA, color: GlyphTheme.accent)
                    speakerButton(.personB, color: GlyphTheme.violet)
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1)))
                
                // Text input
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(GlyphTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08))
                    )
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .background(
                            service.activeSpeaker == .personA
                                ? AnyShapeStyle(LinearGradient(colors: [GlyphTheme.accent, Color(red: 0.27, green: 0.87, blue: 0.53)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(LinearGradient(colors: [GlyphTheme.violet, Color(red: 1, green: 0.4, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .clipShape(Circle())
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(GlyphTheme.surface.opacity(0.3))
    }
    
    private func speakerButton(_ speaker: TranslationService.Speaker, color: Color) -> some View {
        Button(action: { service.activeSpeaker = speaker }) {
            Text(speaker == .personA ? "A" : "B")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(service.activeSpeaker == speaker ? .black : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(service.activeSpeaker == speaker ? color : Color.clear)
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let message = service.sendMessage(text: text)
        inputText = ""
        
        // Trigger translation via Apple's framework
        translationConfig = .init(
            source: message.sourceLanguage,
            target: message.targetLanguage
        )
    }
    
    private func handleTranslation(_ session: TranslationSession) async {
        guard let lastMessage = service.messages.last,
              lastMessage.translatedText == nil else { return }
        
        do {
            let response = try await session.translate(lastMessage.originalText)
            service.updateTranslation(for: lastMessage.id, with: response.targetText)
        } catch {
            service.updateTranslation(for: lastMessage.id, with: "⚠️ \(error.localizedDescription)")
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: TranslationService.Message
    let service: TranslationService
    
    var body: some View {
        HStack {
            if message.speaker == .personB { Spacer(minLength: 40) }
            
            VStack(alignment: message.speaker == .personA ? .leading : .trailing, spacing: 4) {
                // Original text
                Text(message.originalText)
                    .font(.body)
                    .foregroundStyle(.white)
                
                // Translation
                if let translated = message.translatedText {
                    Text(translated)
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.27, green: 0.87, blue: 0.53))
                        .italic()
                        .padding(.top, 2)
                }
                
                // Language tags
                HStack(spacing: 4) {
                    Text(message.sourceLanguage.minimalIdentifier.uppercased())
                    Text("→")
                    Text(message.targetLanguage.minimalIdentifier.uppercased())
                }
                .font(.caption2)
                .foregroundStyle(.quaternary)
            }
            .padding(12)
            .background(
                message.speaker == .personA
                    ? Color(red: 0.1, green: 0.17, blue: 0.24)
                    : Color(red: 0.17, green: 0.1, blue: 0.24)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        message.speaker == .personA
                            ? Color(red: 0.17, green: 0.23, blue: 0.3)
                            : Color(red: 0.23, green: 0.17, blue: 0.3),
                        lineWidth: 1
                    )
            )
            
            if message.speaker == .personA { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Language Picker Sheet

private struct LanguagePickerSheet: View {
    let title: String
    @Binding var selectedLanguage: Locale.Language
    let languages: [TranslationService.SupportedLanguage]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredLanguages: [TranslationService.SupportedLanguage] {
        guard !searchText.isEmpty else { return languages }
        let q = searchText.lowercased()
        return languages.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.nativeName.lowercased().contains(q) ||
            $0.region.lowercased().contains(q)
        }
    }
    
    private var groupedLanguages: [(String, [TranslationService.SupportedLanguage])] {
        Dictionary(grouping: filteredLanguages, by: \.region)
            .sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedLanguages, id: \.0) { region, langs in
                    Section(header: Text(region)) {
                        ForEach(langs) { lang in
                            Button(action: {
                                selectedLanguage = lang.language
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(lang.displayName)
                                                .foregroundStyle(.primary)
                                            if lang.isEndangered {
                                                Text("endangered")
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.orange.opacity(0.15))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        Text(lang.nativeName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if lang.language.minimalIdentifier == selectedLanguage.minimalIdentifier {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(GlyphTheme.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search languages...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    TranslationView()
}
