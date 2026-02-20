import SwiftUI

// MARK: - Survey Question Input

struct SurveyQuestionInput: Identifiable {
    let id = UUID()
    var text = ""
    var type: SurveyQuestion.QuestionType = .multipleChoice
    var options: [String] = ["", ""]
    var maxRating: Int = 5
}

// MARK: - Survey Compose View

/// Create and publish a survey via cycling QR codes.
/// The survey is wrapped as a GLYW: web bundle — respondents interact with
/// the HTML survey and generate a GLYR: response QR for scanning back.
struct SurveyComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SurveyStore.shared
    
    @State private var surveyTitle = ""
    @State private var questions: [SurveyQuestionInput] = [SurveyQuestionInput()]
    @State private var qrImages: [UIImage] = []
    @State private var showQR = false
    @State private var isGenerating = false
    @State private var selectedWindow: TimeWindow = .none
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    titleField
                    questionsList
                    addQuestionButton
                    timeWindowSection
                    sizeEstimate
                    generateButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Create Survey")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showQR) {
            QRDisplayView(
                qrImages: qrImages,
                expiration: .forever,
                messagePreview: "Survey: \(surveyTitle)",
                timeWindow: selectedWindow
            )
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(GlyphTheme.accentGradient)
            Text("Build a Survey")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
            Text("Create questions, generate QR codes.\nRespondents answer and show you a response QR.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Title
    
    private var titleField: some View {
        GlyphTextField(
            label: "Survey Title",
            placeholder: "e.g., Transit Feedback",
            text: $surveyTitle
        )
    }
    
    // MARK: - Questions List
    
    private var questionsList: some View {
        ForEach(questions.indices, id: \.self) { i in
            SurveyQuestionEditor(
                index: i,
                input: $questions[i],
                onDelete: questions.count > 1 ? { withAnimation { _ = questions.remove(at: i) } } : nil
            )
        }
    }
    
    // MARK: - Add Question
    
    private var addQuestionButton: some View {
        AddItemButton(label: "Add Question") {
            withAnimation { questions.append(SurveyQuestionInput()) }
        }
    }
    
    // MARK: - Size Estimate
    
    private var sizeEstimate: some View {
        SizeEstimateView(estimatedBytes: estimateSize())
    }
    
    // MARK: - Time Window
    
    private var timeWindowSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Survey valid for")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TimeWindow.allCases) { window in
                        TimeWindowChip(
                            window: window,
                            isSelected: selectedWindow == window
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedWindow = window
                            }
                        }
                    }
                }
            }
            
            if selectedWindow != .none {
                Text(selectedWindow.subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(GlyphTheme.violet.opacity(0.7))
            }
        }
    }
    
    private func estimateSize() -> Int {
        // Survey HTML is ~4-6 KB base + ~200 bytes/question + QR generator JS ~3 KB
        let base = 7000
        let qContent = questions.reduce(0) { total, q in
            total + q.text.count + q.options.reduce(0) { $0 + $1.count } + 100
        }
        return (base + qContent) / 4  // Gzip typically 3-4x compression
    }
    
    // MARK: - Generate
    
    private var generateButton: some View {
        Button {
            generate()
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                }
                Text("Generate Survey")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: GlyphTheme.buttonHeight)
            .background(GlyphTheme.accentGradient)
            .foregroundStyle(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
        }
        .disabled(isGenerating || surveyTitle.isEmpty || !hasValidQuestions)
        .padding(.bottom, 24)
    }
    
    private var hasValidQuestions: Bool {
        questions.contains { q in
            !q.text.isEmpty && {
                switch q.type {
                case .multipleChoice:
                    return q.options.filter { !$0.isEmpty }.count >= 2
                case .rating:
                    return true
                case .text:
                    return true
                }
            }()
        }
    }
    
    private func generate() {
        isGenerating = true
        Task {
            // Build SurveyQuestion models
            let surveyQuestions = questions.compactMap { input -> SurveyQuestion? in
                guard !input.text.isEmpty else { return nil }
                switch input.type {
                case .multipleChoice:
                    let validOptions = input.options.filter { !$0.isEmpty }
                    guard validOptions.count >= 2 else { return nil }
                    return SurveyQuestion(
                        text: input.text,
                        type: .multipleChoice,
                        options: validOptions
                    )
                case .rating:
                    return SurveyQuestion(
                        text: input.text,
                        type: .rating,
                        maxRating: input.maxRating
                    )
                case .text:
                    return SurveyQuestion(
                        text: input.text,
                        type: .text
                    )
                }
            }
            
            guard !surveyQuestions.isEmpty else {
                await MainActor.run { isGenerating = false }
                return
            }
            
            // Create and save survey
            let survey = GlyphSurvey(title: surveyTitle, questions: surveyQuestions, expiresAt: selectedWindow.expiresAt())
            store.save(survey: survey)
            
            // Generate HTML
            let html = SurveyTemplateGenerator.generateSurveyHTML(survey: survey)
            
            // Wrap as GLYW: web bundle → chunk → QR images
            let bundle = GlyphWebBundle(
                title: surveyTitle,
                html: html,
                templateType: "survey",
                createdAt: Date()
            )
            let images = GlyphWebChunkSplitter.split(bundle: bundle)
            
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty {
                    qrImages = images
                    showQR = true
                }
            }
        }
    }
}

// MARK: - Survey Question Editor

struct SurveyQuestionEditor: View {
    let index: Int
    @Binding var input: SurveyQuestionInput
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
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
            
            // Question type picker
            HStack(spacing: 8) {
                questionTypePill(.multipleChoice, label: "Choice", icon: "list.bullet")
                questionTypePill(.rating, label: "Rating", icon: "star.fill")
                questionTypePill(.text, label: "Text", icon: "text.cursor")
            }
            
            // Question text
            TextField("Question", text: $input.text)
                .textFieldStyle(.plain)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
                .padding(12)
                .background(GlyphTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Type-specific editor
            switch input.type {
            case .multipleChoice:
                multipleChoiceEditor
            case .rating:
                ratingEditor
            case .text:
                Text("Respondent will type a free-form answer")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
            }
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Type Pill
    
    private func questionTypePill(
        _ type: SurveyQuestion.QuestionType,
        label: String,
        icon: String
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.2)) { input.type = type }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(input.type == type ? GlyphTheme.accent.opacity(0.2) : GlyphTheme.background)
            .foregroundStyle(input.type == type ? GlyphTheme.accent : GlyphTheme.secondaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(input.type == type ? GlyphTheme.accent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Multiple Choice Editor
    
    private var multipleChoiceEditor: some View {
        VStack(spacing: 8) {
            ForEach(input.options.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    Circle()
                        .stroke(GlyphTheme.secondaryText.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    
                    TextField("Option \(i + 1)", text: $input.options[i])
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                        .padding(10)
                        .background(GlyphTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if input.options.count > 2 {
                        Button {
                            withAnimation { _ = input.options.remove(at: i) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(GlyphTheme.danger.opacity(0.5))
                        }
                    }
                }
            }
            
            if input.options.count < 6 {
                Button {
                    withAnimation { input.options.append("") }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Option")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(GlyphTheme.violet)
                }
            }
        }
    }
    
    // MARK: - Rating Editor
    
    private var ratingEditor: some View {
        HStack(spacing: 12) {
            Text("Max stars:")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
            
            ForEach([3, 5, 7, 10], id: \.self) { val in
                Button {
                    input.maxRating = val
                } label: {
                    Text("\(val)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(width: 36, height: 32)
                        .background(input.maxRating == val ? GlyphTheme.accent.opacity(0.2) : GlyphTheme.background)
                        .foregroundStyle(input.maxRating == val ? GlyphTheme.accent : GlyphTheme.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SurveyComposeView()
    }
    .preferredColorScheme(.dark)
}
