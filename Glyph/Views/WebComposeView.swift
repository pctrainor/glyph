import SwiftUI
import AVFoundation

// MARK: - Input Models

struct TriviaQuestionInput: Identifiable {
    let id = UUID()
    var question = ""
    var answers = ["", "", "", ""]
    var correctIndex = 0
}

struct ArticleSectionInput: Identifiable {
    let id = UUID()
    var heading = ""
    var body = ""
}

struct AdventureNodeInput: Identifiable {
    var id: String
    var text: String
    var choices: [AdventureChoiceInput]

    struct AdventureChoiceInput: Identifiable {
        let id = UUID()
        var label: String
        var targetId: String
    }

    static func starterStory() -> [AdventureNodeInput] {
        [
            AdventureNodeInput(
                id: "start",
                text: "You find a glowing QR code on the subway wall. It pulses with a faint cyan light.",
                choices: [
                    .init(label: "Scan it", targetId: "scan"),
                    .init(label: "Walk away", targetId: "walk"),
                ]
            ),
            AdventureNodeInput(
                id: "scan",
                text: "Your phone lights up with a cryptic message: 'The underground remembers.'",
                choices: [
                    .init(label: "Reply to the message", targetId: "reply"),
                    .init(label: "Look around the station", targetId: "look"),
                ]
            ),
            AdventureNodeInput(
                id: "walk",
                text: "You walk away, but the glow follows you. Another QR code appears at the next station.",
                choices: [
                    .init(label: "This time, scan it", targetId: "scan"),
                ]
            ),
            AdventureNodeInput(
                id: "reply",
                text: "You type a response into the void. Seconds later, a new glyph appears nearby. You're part of the network now.",
                choices: []
            ),
            AdventureNodeInput(
                id: "look",
                text: "You spot three more codes hidden along the platform. Each one pulses in a different color. The subway is alive with secrets.",
                choices: []
            ),
        ]
    }
}

// MARK: - Web Compose View

/// Compose screen for creating web experiences.
/// User picks a template type, fills in content, and generates a cycling QR burst.
struct WebComposeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTemplate: WebTemplate?
    @State private var qrImages: [UIImage] = []
    @State private var showQR = false
    @State private var isGenerating = false

    // Trivia state
    @State private var triviaTitle = ""
    @State private var triviaQuestions: [TriviaQuestionInput] = [TriviaQuestionInput()]

    // Article state
    @State private var articleTitle = ""
    @State private var articleSubtitle = ""
    @State private var articleAuthor = ""
    @State private var articleSections: [ArticleSectionInput] = [ArticleSectionInput()]

    // Art state
    @State private var artTitle = "Glyph Art"

    // Adventure state
    @State private var adventureTitle = ""
    @State private var adventureNodes: [AdventureNodeInput] = AdventureNodeInput.starterStory()

    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()

            if selectedTemplate == nil {
                templatePicker
            } else {
                templateEditor
            }
        }
        .navigationTitle(selectedTemplate?.displayName ?? "Create Experience")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showQR) {
            QRDisplayView(
                qrImages: qrImages,
                expiration: .forever,
                messagePreview: "Web Experience",
                timeWindow: .none
            )
        }
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(GlyphTheme.accentGradient)
                    Text("Create an Experience")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    Text("Build interactive content that lives inside QR codes.\nNo internet needed — ever.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.bottom, 8)

                ForEach(WebTemplate.composable) { template in
                    TemplateCard(template: template)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTemplate = template
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Template Editor

    @ViewBuilder
    private var templateEditor: some View {
        switch selectedTemplate {
        case .trivia:
            TriviaEditorView(
                title: $triviaTitle,
                questions: $triviaQuestions,
                isGenerating: $isGenerating,
                qrImages: $qrImages,
                showQR: $showQR
            )
        case .article:
            ArticleEditorView(
                title: $articleTitle,
                subtitle: $articleSubtitle,
                author: $articleAuthor,
                sections: $articleSections,
                isGenerating: $isGenerating,
                qrImages: $qrImages,
                showQR: $showQR
            )
        case .art:
            ArtEditorView(
                title: $artTitle,
                isGenerating: $isGenerating,
                qrImages: $qrImages,
                showQR: $showQR
            )
        case .adventure:
            AdventureEditorView(
                title: $adventureTitle,
                nodes: $adventureNodes,
                isGenerating: $isGenerating,
                qrImages: $qrImages,
                showQR: $showQR
            )
        case .soundboard:
            SoundboardPlaceholderView()
        case .survey:
            SurveyEditorRedirectView()
        case .agent:
            AgentComposeView()
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: WebTemplate

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(GlyphTheme.accent.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: template.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(GlyphTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    Spacer()
                    Text(template.estimatedFrames)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GlyphTheme.secondaryText)
                }
                Text(template.description)
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
                .stroke(GlyphTheme.accent.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Shared Helpers

struct SizeEstimateView: View {
    let estimatedBytes: Int

    var body: some View {
        let frames = max(1, estimatedBytes / GlyphChunk.maxChunkBytes + 1)
        let scanTime = Double(frames) * 0.4

        HStack(spacing: 16) {
            statColumn(value: "~\(frames)", label: "frames")
            statColumn(value: "~\(Int(scanTime))s", label: "scan time")
            statColumn(value: "~\(estimatedBytes / 1024)KB", label: "compressed")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(GlyphTheme.accent)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
        }
    }
}

struct GenerateButtonView: View {
    let isGenerating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                }
                Text("Generate Experience")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: GlyphTheme.buttonHeight)
            .background(GlyphTheme.accentGradient)
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
        }
        .disabled(isGenerating)
        .padding(.bottom, 24)
    }
}

struct AddItemButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(GlyphTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(GlyphTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct GlyphTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(14)
                .background(GlyphTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Trivia Editor View

struct TriviaEditorView: View {
    @Binding var title: String
    @Binding var questions: [TriviaQuestionInput]
    @Binding var isGenerating: Bool
    @Binding var qrImages: [UIImage]
    @Binding var showQR: Bool

    var body: some View {
        ScrollView {
            triviaContent
        }
    }

    private var triviaContent: some View {
        VStack(spacing: 20) {
            GlyphTextField(label: "Quiz Title", placeholder: "e.g., NYC Subway Trivia", text: $title)

            ForEach(questions.indices, id: \.self) { i in
                triviaRow(at: i)
            }

            AddItemButton(label: "Add Question") {
                withAnimation { questions.append(TriviaQuestionInput()) }
            }

            SizeEstimateView(estimatedBytes: estimateSize())

            GenerateButtonView(isGenerating: isGenerating) { generate() }
                .disabled(title.isEmpty || questions.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func triviaRow(at i: Int) -> some View {
        let deleteAction: (() -> Void)? = questions.count > 1 ? { withAnimation { _ = questions.remove(at: i) } } : nil
        return TriviaQuestionEditor(index: i, input: $questions[i], onDelete: deleteAction)
    }

    private func estimateSize() -> Int {
        let rawSize = 2000 + questions.count * 100
        return rawSize / 4
    }

    private func generate() {
        isGenerating = true
        Task {
            let qs = questions.compactMap { input -> WebTemplateGenerator.TriviaQuestion? in
                guard !input.question.isEmpty,
                      input.answers.allSatisfy({ !$0.isEmpty }),
                      input.correctIndex < input.answers.count else { return nil }
                return WebTemplateGenerator.TriviaQuestion(
                    question: input.question,
                    answers: input.answers,
                    correctIndex: input.correctIndex
                )
            }
            guard !qs.isEmpty else {
                await MainActor.run { isGenerating = false }
                return
            }
            let html = WebTemplateGenerator.generateTrivia(
                title: title.isEmpty ? "Glyph Trivia" : title,
                questions: qs
            )
            let bundle = GlyphWebBundle(title: title, html: html, templateType: "trivia", createdAt: Date())
            let images = GlyphWebChunkSplitter.split(bundle: bundle)
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty { qrImages = images; showQR = true }
            }
        }
    }
}

// MARK: - Article Editor View

struct ArticleEditorView: View {
    @Binding var title: String
    @Binding var subtitle: String
    @Binding var author: String
    @Binding var sections: [ArticleSectionInput]
    @Binding var isGenerating: Bool
    @Binding var qrImages: [UIImage]
    @Binding var showQR: Bool

    var body: some View {
        ScrollView {
            articleContent
        }
    }

    private var articleContent: some View {
        VStack(spacing: 20) {
            GlyphTextField(label: "Title", placeholder: "Article title", text: $title)
            GlyphTextField(label: "Subtitle (optional)", placeholder: "A brief tagline", text: $subtitle)
            GlyphTextField(label: "Author (optional)", placeholder: "Your name or alias", text: $author)

            ForEach(sections.indices, id: \.self) { i in
                sectionRow(at: i)
            }

            AddItemButton(label: "Add Section") {
                withAnimation { sections.append(ArticleSectionInput()) }
            }

            SizeEstimateView(estimatedBytes: estimateSize())

            GenerateButtonView(isGenerating: isGenerating) { generate() }
                .disabled(title.isEmpty || sections.first?.body.isEmpty ?? true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func sectionRow(at i: Int) -> some View {
        let deleteAction: (() -> Void)? = sections.count > 1 ? { withAnimation { _ = sections.remove(at: i) } } : nil
        return ArticleSectionEditor(index: i, input: $sections[i], onDelete: deleteAction)
    }

    private func estimateSize() -> Int {
        let textLen = sections.reduce(0) { $0 + $1.body.count + $1.heading.count }
        return (1500 + textLen) / 4
    }

    private func generate() {
        isGenerating = true
        Task {
            let secs = sections.compactMap { input -> WebTemplateGenerator.ArticleSection? in
                guard !input.body.isEmpty else { return nil }
                return WebTemplateGenerator.ArticleSection(
                    heading: input.heading.isEmpty ? nil : input.heading,
                    body: input.body
                )
            }
            guard !secs.isEmpty else {
                await MainActor.run { isGenerating = false }
                return
            }
            let html = WebTemplateGenerator.generateArticle(
                title: title,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                author: author.isEmpty ? nil : author,
                sections: secs
            )
            let bundle = GlyphWebBundle(title: title, html: html, templateType: "article", createdAt: Date())
            let images = GlyphWebChunkSplitter.split(bundle: bundle)
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty { qrImages = images; showQR = true }
            }
        }
    }
}

// MARK: - Art Editor View

struct ArtEditorView: View {
    @Binding var title: String
    @Binding var isGenerating: Bool
    @Binding var qrImages: [UIImage]
    @Binding var showQR: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 64))
                    .foregroundStyle(GlyphTheme.accentGradient)
                Text("Interactive Art")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.primaryText)
                Text("Generate a touch-interactive particle art canvas.\nReceivers can draw and create with your Glyph palette.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            GlyphTextField(label: "Title", placeholder: "e.g., Subway Canvas", text: $title)
                .padding(.horizontal, 24)

            SizeEstimateView(estimatedBytes: 2800)
                .padding(.horizontal, 24)

            GenerateButtonView(isGenerating: isGenerating) { generate() }
                .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    private func generate() {
        isGenerating = true
        Task {
            let html = WebTemplateGenerator.generateArt(title: title.isEmpty ? "Glyph Art" : title)
            let bundle = GlyphWebBundle(title: title, html: html, templateType: "art", createdAt: Date())
            let images = GlyphWebChunkSplitter.split(bundle: bundle)
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty { qrImages = images; showQR = true }
            }
        }
    }
}

// MARK: - Adventure Editor View

struct AdventureEditorView: View {
    @Binding var title: String
    @Binding var nodes: [AdventureNodeInput]
    @Binding var isGenerating: Bool
    @Binding var qrImages: [UIImage]
    @Binding var showQR: Bool

    var body: some View {
        ScrollView {
            adventureContent
        }
    }

    private var adventureContent: some View {
        VStack(spacing: 20) {
            GlyphTextField(label: "Story Title", placeholder: "e.g., The Subway Ghost", text: $title)

            ForEach(nodes.indices, id: \.self) { i in
                nodeRow(at: i)
            }

            AddItemButton(label: "Add Story Node") {
                withAnimation {
                    nodes.append(
                        AdventureNodeInput(id: "node\(nodes.count + 1)", text: "", choices: [])
                    )
                }
            }

            SizeEstimateView(estimatedBytes: estimateSize())

            GenerateButtonView(isGenerating: isGenerating) { generate() }
                .disabled(title.isEmpty || nodes.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func nodeRow(at i: Int) -> some View {
        let deleteAction: (() -> Void)? = nodes.count > 1 ? { withAnimation { _ = nodes.remove(at: i) } } : nil
        return AdventureNodeEditor(index: i, input: $nodes[i], allNodeIds: nodes.map(\.id), onDelete: deleteAction)
    }

    private func estimateSize() -> Int {
        let textLen = nodes.reduce(0) { total, node in
            total + node.text.count + node.choices.reduce(0) { $0 + $1.label.count }
        }
        return (1800 + textLen) / 4
    }

    private func generate() {
        isGenerating = true
        Task {
            let storyNodes = nodes.compactMap { input -> WebTemplateGenerator.StoryNode? in
                guard !input.text.isEmpty else { return nil }
                let choices = input.choices.compactMap { choice -> (label: String, targetId: String)? in
                    guard !choice.label.isEmpty, !choice.targetId.isEmpty else { return nil }
                    return (label: choice.label, targetId: choice.targetId)
                }
                return WebTemplateGenerator.StoryNode(id: input.id, text: input.text, choices: choices)
            }
            guard !storyNodes.isEmpty else {
                await MainActor.run { isGenerating = false }
                return
            }
            let html = WebTemplateGenerator.generateAdventure(
                title: title.isEmpty ? "A Glyph Story" : title,
                nodes: storyNodes
            )
            let bundle = GlyphWebBundle(title: title, html: html, templateType: "adventure", createdAt: Date())
            let images = GlyphWebChunkSplitter.split(bundle: bundle)
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty { qrImages = images; showQR = true }
            }
        }
    }
}

// MARK: - Soundboard Placeholder

struct SoundboardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🎵")
                .font(.system(size: 64))
            Text("Sound Collection")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
            Text("Coming soon! Record or attach sound clips\nand build a mini-mixtape in a QR code.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Trivia Question Editor

struct TriviaQuestionEditor: View {
    let index: Int
    @Binding var input: TriviaQuestionInput
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            questionField
            answerFields
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var headerRow: some View {
        HStack {
            Text("Question \(index + 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(GlyphTheme.accent)
            Spacer()
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(GlyphTheme.danger.opacity(0.6))
                }
            }
        }
    }

    private var questionField: some View {
        TextField("Question", text: $input.question)
            .textFieldStyle(.plain)
            .font(.system(size: 16, design: .rounded))
            .foregroundStyle(GlyphTheme.primaryText)
            .padding(12)
            .background(GlyphTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var answerFields: some View {
        ForEach(0..<4, id: \.self) { i in
            HStack(spacing: 8) {
                Button {
                    input.correctIndex = i
                } label: {
                    Image(systemName: input.correctIndex == i ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(input.correctIndex == i ? GlyphTheme.accent : GlyphTheme.secondaryText)
                        .font(.system(size: 20))
                }
                TextField("Answer \(i + 1)", text: $input.answers[i])
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(GlyphTheme.primaryText)
                    .padding(10)
                    .background(GlyphTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Article Section Editor

struct ArticleSectionEditor: View {
    let index: Int
    @Binding var input: ArticleSectionInput
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Section \(index + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.accent)
                Spacer()
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(GlyphTheme.danger.opacity(0.6))
                    }
                }
            }

            TextField("Section heading (optional)", text: $input.heading)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(12)
                .background(GlyphTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            ZStack(alignment: .topLeading) {
                if input.body.isEmpty {
                    Text("Write your content here...")
                        .foregroundStyle(GlyphTheme.secondaryText.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $input.body)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(GlyphTheme.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(minHeight: 100)
            }
            .background(GlyphTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Adventure Node Editor

struct AdventureNodeEditor: View {
    let index: Int
    @Binding var input: AdventureNodeInput
    let allNodeIds: [String]
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            nodeHeader
            nodeIdField
            storyTextField
            choicesList
            addChoiceButton
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(GlyphTheme.accent.opacity(0.1), lineWidth: 1)
        )
    }

    private var nodeHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(GlyphTheme.accent)
                    .frame(width: 8, height: 8)
                Text("Node: \(input.id)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(GlyphTheme.accent)
            }
            Spacer()
            if input.choices.isEmpty {
                Text("ENDING")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(GlyphTheme.warning.opacity(0.15))
                    .clipShape(Capsule())
            }
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(GlyphTheme.danger.opacity(0.6))
                }
            }
        }
    }

    private var nodeIdField: some View {
        HStack(spacing: 6) {
            Text("ID:")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
            TextField("node_id", text: $input.id)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(8)
                .background(GlyphTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var storyTextField: some View {
        ZStack(alignment: .topLeading) {
            if input.text.isEmpty {
                Text("What happens at this point in the story...")
                    .foregroundStyle(GlyphTheme.secondaryText.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
            }
            TextEditor(text: $input.text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(minHeight: 80)
        }
        .background(GlyphTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var choicesList: some View {
        VStack(spacing: 8) {
            ForEach(input.choices.indices, id: \.self) { i in
                choiceRow(at: i)
            }
        }
    }

    private func choiceRow(at i: Int) -> some View {
        AdventureChoiceRow(
            choice: $input.choices[i],
            onDelete: { withAnimation { _ = input.choices.remove(at: i) } }
        )
    }

    private var addChoiceButton: some View {
        Button {
            withAnimation {
                input.choices.append(
                    AdventureNodeInput.AdventureChoiceInput(label: "", targetId: "")
                )
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add Choice")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(GlyphTheme.violet)
        }
    }
}

// MARK: - Adventure Choice Row

struct AdventureChoiceRow: View {
    @Binding var choice: AdventureNodeInput.AdventureChoiceInput
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 12))
                .foregroundStyle(GlyphTheme.violet)

            TextField("Choice text", text: $choice.label)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(8)
                .background(GlyphTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("→")
                .foregroundStyle(GlyphTheme.secondaryText)

            TextField("target_id", text: $choice.targetId)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(GlyphTheme.accent)
                .padding(8)
                .frame(width: 90)
                .background(GlyphTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(GlyphTheme.danger.opacity(0.5))
            }
        }
    }
}

// MARK: - Survey Editor Redirect

/// When survey is picked from Experience templates, redirect to the dedicated compose view.
struct SurveyEditorRedirectView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundStyle(GlyphTheme.accentGradient)
            Text("Survey Builder")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
            Text("Surveys have their own dedicated builder.\nUse the Surveys section from the home screen.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                SurveyComposeView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Go to Survey Builder")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(GlyphTheme.accentGradient)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WebComposeView()
    }
    .preferredColorScheme(.dark)
}
