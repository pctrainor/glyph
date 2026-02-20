import SwiftUI

// MARK: - Survey List View

/// Browse created surveys, see response counts, tap for detailed results.
struct SurveyListView: View {
    @StateObject private var store = SurveyStore.shared
    @State private var selectedSurvey: GlyphSurvey?
    @State private var showResults = false
    @State private var showCompose = false
    @State private var deleteTarget: GlyphSurvey?
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            if store.surveys.isEmpty {
                emptyState
            } else {
                surveyList
            }
        }
        .navigationTitle("Surveys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(GlyphTheme.accent)
                }
            }
        }
        .navigationDestination(isPresented: $showCompose) {
            SurveyComposeView()
        }
        .sheet(isPresented: $showResults) {
            if let survey = selectedSurvey {
                SurveyResultsView(survey: survey)
            }
        }
        .alert("Delete Survey?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    withAnimation { store.delete(survey: target) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the survey and all \(store.responseCount(for: deleteTarget?.id ?? "")) collected responses.")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(GlyphTheme.accentGradient)
            Text("No Surveys Yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
            Text("Create a survey, display the QR codes,\nand scan back response QR codes from\nrespondents' devices.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button {
                showCompose = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Survey")
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
    
    // MARK: - Survey List
    
    private var surveyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.surveys) { survey in
                    SurveyRow(
                        survey: survey,
                        responseCount: store.responseCount(for: survey.id),
                        onTap: {
                            selectedSurvey = survey
                            showResults = true
                        },
                        onDelete: {
                            deleteTarget = survey
                            showDeleteConfirm = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Survey Row

struct SurveyRow: View {
    let survey: GlyphSurvey
    let responseCount: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GlyphTheme.accent.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 24))
                        .foregroundStyle(GlyphTheme.accent)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(survey.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(survey.questions.count) Q", systemImage: "questionmark.circle")
                        Label("\(responseCount)", systemImage: "person.2.fill")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                }
                
                Spacer()
                
                // Response badge
                if responseCount > 0 {
                    Text("\(responseCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(width: 30, height: 30)
                        .background(GlyphTheme.accent)
                        .clipShape(Circle())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GlyphTheme.secondaryText)
            }
            .padding(14)
            .background(GlyphTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GlyphTheme.accent.opacity(0.1), lineWidth: 1)
            )
        }
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete Survey", systemImage: "trash")
            }
        }
    }
}

// MARK: - Survey Results View

/// Modal showing detailed results for a specific survey.
struct SurveyResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SurveyStore.shared
    let survey: GlyphSurvey
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlyphTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text(survey.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(GlyphTheme.primaryText)
                            
                            let count = store.responseCount(for: survey.id)
                            Text("\(count) response\(count == 1 ? "" : "s")")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(GlyphTheme.accent)
                            
                            Text("Scan a respondent's QR to add results")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(GlyphTheme.secondaryText)
                        }
                        .padding(.top, 8)
                        
                        // Question results
                        ForEach(Array(survey.questions.enumerated()), id: \.element.id) { index, question in
                            questionResultCard(index: index, question: question)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GlyphTheme.accent)
                }
            }
        }
    }
    
    // MARK: - Question Result Card
    
    @ViewBuilder
    private func questionResultCard(index: Int, question: SurveyQuestion) -> some View {
        let results = store.results(for: question, surveyId: survey.id)
        
        VStack(alignment: .leading, spacing: 12) {
            // Question header
            HStack {
                Text("Q\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(GlyphTheme.accent.opacity(0.15))
                    .clipShape(Capsule())
                
                Text(typeBadge(question.type))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                
                Spacer()
            }
            
            Text(question.text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(GlyphTheme.primaryText)
            
            // Results visualization
            switch results {
            case .multipleChoice(let optionCounts, let total):
                multipleChoiceResults(
                    options: question.options ?? [],
                    counts: optionCounts,
                    total: total
                )
            case .rating(let average, let distribution, let total):
                ratingResults(
                    average: average,
                    distribution: distribution,
                    maxRating: question.maxRating ?? 5,
                    total: total
                )
            case .text(let responses):
                textResults(responses: responses)
            }
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func typeBadge(_ type: SurveyQuestion.QuestionType) -> String {
        switch type {
        case .multipleChoice: return "Multiple Choice"
        case .rating: return "Rating"
        case .text: return "Free Text"
        }
    }
    
    // MARK: - Multiple Choice Results
    
    private func multipleChoiceResults(options: [String], counts: [Int: Int], total: Int) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let count = counts[index] ?? 0
                let pct = total > 0 ? Double(count) / Double(total) : 0
                
                HStack(spacing: 10) {
                    Text(option)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(count)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(GlyphTheme.accent)
                        .frame(width: 30)
                }
                
                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(GlyphTheme.background)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(GlyphTheme.accentGradient)
                            .frame(width: geo.size.width * pct, height: 6)
                            .animation(.spring(response: 0.4), value: pct)
                    }
                }
                .frame(height: 6)
            }
            
            if total == 0 {
                Text("No responses yet")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Rating Results
    
    private func ratingResults(average: Double, distribution: [Int: Int], maxRating: Int, total: Int) -> some View {
        VStack(spacing: 12) {
            if total > 0 {
                // Average display
                HStack(spacing: 8) {
                    Text(String(format: "%.1f", average))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GlyphTheme.accent, GlyphTheme.violet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(1...maxRating, id: \.self) { i in
                                Image(systemName: Double(i) <= average ? "star.fill" : (Double(i) - 0.5 <= average ? "star.leadinghalf.filled" : "star"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(GlyphTheme.accent)
                            }
                        }
                        Text("avg of \(total) response\(total == 1 ? "" : "s")")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(GlyphTheme.secondaryText)
                    }
                }
                
                // Distribution bars
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(1...maxRating, id: \.self) { rating in
                        let count = distribution[rating] ?? 0
                        let maxCount = distribution.values.max() ?? 1
                        let height = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 40 : 0
                        
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(GlyphTheme.accent.opacity(0.6))
                                .frame(width: 24, height: max(4, height))
                                .animation(.spring(response: 0.4), value: height)
                            Text("\(rating)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(GlyphTheme.secondaryText)
                        }
                    }
                }
            } else {
                Text("No responses yet")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
            }
        }
    }
    
    // MARK: - Text Results
    
    private func textResults(responses: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if responses.isEmpty {
                Text("No responses yet")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
            } else {
                ForEach(Array(responses.prefix(10).enumerated()), id: \.offset) { _, response in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 10))
                            .foregroundStyle(GlyphTheme.accent.opacity(0.5))
                            .padding(.top, 3)
                        Text(response)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(GlyphTheme.primaryText)
                            .lineLimit(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GlyphTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if responses.count > 10 {
                    Text("+ \(responses.count - 10) more responses")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(GlyphTheme.secondaryText)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SurveyListView()
    }
    .preferredColorScheme(.dark)
}
