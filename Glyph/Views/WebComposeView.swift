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
        .navigationTitle(selectedTemplate?.displayName ?? "Apps")
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
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 48))
                        .foregroundStyle(GlyphTheme.accentGradient)
                    Text("Glyph Apps")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.primaryText)
                    Text("Interactive apps delivered via QR code.\nNo internet needed — ever.")
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
            // Agent is temporarily disabled — placeholder UI
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "person.crop.rectangle.stack")
                    .font(.system(size: 64))
                    .foregroundStyle(GlyphTheme.accentGradient)
                Text("Host an Agent")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.primaryText)
                Text("AI agents are coming soon.\nStay tuned for creative persona-driven QR messages.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        case .translation:
            TranslationView()
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
                Text("Generate QR")
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

// MARK: - Quiz Editor View

/// Quiz categories with pre-built question banks.
enum QuizCategory: String, CaseIterable, Identifiable {
    case custom = "custom"
    case movies = "movies"
    case geography = "geography"
    case history = "history"
    case science = "science"
    case sports = "sports"
    case music = "music"
    case popCulture = "pop_culture"
    case foodDrink = "food_drink"
    case animals = "animals"
    case technology = "technology"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .custom:     return "Custom"
        case .movies:     return "Movies"
        case .geography:  return "Geography"
        case .history:    return "History"
        case .science:    return "Science"
        case .sports:     return "Sports"
        case .music:      return "Music"
        case .popCulture: return "Pop Culture"
        case .foodDrink:  return "Food & Drink"
        case .animals:    return "Animals"
        case .technology: return "Technology"
        }
    }

    var icon: String {
        switch self {
        case .custom:     return "pencil.and.list.clipboard"
        case .movies:     return "film"
        case .geography:  return "globe.americas"
        case .history:    return "clock.arrow.circlepath"
        case .science:    return "atom"
        case .sports:     return "sportscourt"
        case .music:      return "music.note"
        case .popCulture: return "star.fill"
        case .foodDrink:  return "fork.knife"
        case .animals:    return "pawprint.fill"
        case .technology: return "desktopcomputer"
        }
    }

    var color: Color {
        switch self {
        case .custom:     return GlyphTheme.accent
        case .movies:     return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .geography:  return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .history:    return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .science:    return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .sports:     return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .music:      return Color(red: 0.8, green: 0.3, blue: 0.9)
        case .popCulture: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .foodDrink:  return Color(red: 0.9, green: 0.4, blue: 0.5)
        case .animals:    return Color(red: 0.5, green: 0.8, blue: 0.3)
        case .technology: return Color(red: 0.3, green: 0.8, blue: 0.9)
        }
    }

    /// Pre-built questions for each category.
    var presetQuestions: [TriviaQuestionInput] {
        switch self {
        case .custom:
            return [TriviaQuestionInput()]

        case .movies:
            return [
                TriviaQuestionInput.preset("What film won Best Picture at the 2024 Oscars?", ["Oppenheimer", "Barbie", "Killers of the Flower Moon", "Poor Things"], 0),
                TriviaQuestionInput.preset("Who directed Jurassic Park?", ["James Cameron", "Steven Spielberg", "Ridley Scott", "George Lucas"], 1),
                TriviaQuestionInput.preset("Which movie features the quote 'Here's looking at you, kid'?", ["Gone with the Wind", "The Maltese Falcon", "Casablanca", "Citizen Kane"], 2),
                TriviaQuestionInput.preset("What is the highest-grossing film of all time?", ["Avengers: Endgame", "Avatar", "Titanic", "Star Wars: The Force Awakens"], 1),
                TriviaQuestionInput.preset("Who played the Joker in The Dark Knight?", ["Jack Nicholson", "Jared Leto", "Joaquin Phoenix", "Heath Ledger"], 3),
                TriviaQuestionInput.preset("Which Studio Ghibli film features a bathhouse for spirits?", ["My Neighbor Totoro", "Spirited Away", "Princess Mononoke", "Howl's Moving Castle"], 1),
                TriviaQuestionInput.preset("What year was the original Star Wars released?", ["1975", "1977", "1979", "1980"], 1),
                TriviaQuestionInput.preset("Which actor has won the most Academy Awards?", ["Meryl Streep", "Daniel Day-Lewis", "Katharine Hepburn", "Jack Nicholson"], 2),
                TriviaQuestionInput.preset("What is the name of the fictional country in Black Panther?", ["Genosha", "Wakanda", "Latveria", "Zamunda"], 1),
                TriviaQuestionInput.preset("Who composed the score for Inception?", ["John Williams", "Hans Zimmer", "Howard Shore", "Danny Elfman"], 1),
            ]

        case .geography:
            return [
                TriviaQuestionInput.preset("What is the smallest country in the world?", ["Monaco", "Liechtenstein", "Vatican City", "San Marino"], 2),
                TriviaQuestionInput.preset("Which river is the longest in the world?", ["Amazon", "Nile", "Mississippi", "Yangtze"], 1),
                TriviaQuestionInput.preset("What is the capital of Australia?", ["Sydney", "Melbourne", "Canberra", "Brisbane"], 2),
                TriviaQuestionInput.preset("Which desert is the largest in the world?", ["Sahara", "Arabian", "Gobi", "Antarctic"], 3),
                TriviaQuestionInput.preset("Mount Everest is located on the border of which two countries?", ["India & China", "Nepal & China", "Nepal & India", "Pakistan & China"], 1),
                TriviaQuestionInput.preset("What is the most populated city in the world?", ["Shanghai", "Delhi", "Tokyo", "São Paulo"], 2),
                TriviaQuestionInput.preset("Which country has the most time zones?", ["Russia", "USA", "France", "China"], 2),
                TriviaQuestionInput.preset("What is the deepest ocean trench?", ["Tonga Trench", "Philippine Trench", "Mariana Trench", "Java Trench"], 2),
                TriviaQuestionInput.preset("Which African country was never colonized?", ["Nigeria", "Kenya", "Ethiopia", "Ghana"], 2),
                TriviaQuestionInput.preset("What is the largest island in the world?", ["Madagascar", "Borneo", "Greenland", "New Guinea"], 2),
            ]

        case .history:
            return [
                TriviaQuestionInput.preset("In what year did World War II end?", ["1943", "1944", "1945", "1946"], 2),
                TriviaQuestionInput.preset("Who was the first person to walk on the Moon?", ["Buzz Aldrin", "Neil Armstrong", "John Glenn", "Yuri Gagarin"], 1),
                TriviaQuestionInput.preset("The Berlin Wall fell in which year?", ["1987", "1989", "1991", "1993"], 1),
                TriviaQuestionInput.preset("Who painted the Mona Lisa?", ["Michelangelo", "Raphael", "Leonardo da Vinci", "Donatello"], 2),
                TriviaQuestionInput.preset("Which empire built Machu Picchu?", ["Aztec", "Maya", "Inca", "Olmec"], 2),
                TriviaQuestionInput.preset("What ancient wonder was located in Alexandria?", ["Colossus", "Hanging Gardens", "Lighthouse", "Temple of Artemis"], 2),
                TriviaQuestionInput.preset("Who was the first woman to fly solo across the Atlantic?", ["Bessie Coleman", "Amelia Earhart", "Harriet Quimby", "Jacqueline Cochran"], 1),
                TriviaQuestionInput.preset("The French Revolution began in which year?", ["1776", "1789", "1799", "1804"], 1),
                TriviaQuestionInput.preset("Which civilization invented paper?", ["Egyptian", "Greek", "Chinese", "Roman"], 2),
                TriviaQuestionInput.preset("Who wrote the Declaration of Independence?", ["Benjamin Franklin", "John Adams", "Thomas Jefferson", "George Washington"], 2),
            ]

        case .science:
            return [
                TriviaQuestionInput.preset("What is the chemical symbol for gold?", ["Go", "Gd", "Au", "Ag"], 2),
                TriviaQuestionInput.preset("How many bones are in the adult human body?", ["186", "206", "226", "256"], 1),
                TriviaQuestionInput.preset("What planet is known as the Red Planet?", ["Venus", "Jupiter", "Mars", "Saturn"], 2),
                TriviaQuestionInput.preset("What is the speed of light (approx)?", ["186,000 mi/s", "670,000 mi/s", "1 million mi/s", "93,000 mi/s"], 0),
                TriviaQuestionInput.preset("What gas do plants absorb from the atmosphere?", ["Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen"], 2),
                TriviaQuestionInput.preset("What is the hardest natural substance?", ["Quartz", "Topaz", "Diamond", "Corundum"], 2),
                TriviaQuestionInput.preset("Who developed the theory of general relativity?", ["Isaac Newton", "Albert Einstein", "Niels Bohr", "Max Planck"], 1),
                TriviaQuestionInput.preset("What is the powerhouse of the cell?", ["Nucleus", "Ribosome", "Mitochondria", "Golgi Body"], 2),
                TriviaQuestionInput.preset("What element has the atomic number 1?", ["Helium", "Hydrogen", "Lithium", "Carbon"], 1),
                TriviaQuestionInput.preset("How many planets are in our solar system?", ["7", "8", "9", "10"], 1),
            ]

        case .sports:
            return [
                TriviaQuestionInput.preset("How many players are on a soccer team?", ["9", "10", "11", "12"], 2),
                TriviaQuestionInput.preset("Which country has won the most FIFA World Cups?", ["Germany", "Argentina", "Italy", "Brazil"], 3),
                TriviaQuestionInput.preset("What sport is played at Wimbledon?", ["Cricket", "Tennis", "Golf", "Rugby"], 1),
                TriviaQuestionInput.preset("How many rings are on the Olympic flag?", ["4", "5", "6", "7"], 1),
                TriviaQuestionInput.preset("Who holds the record for most NBA points?", ["Michael Jordan", "Kobe Bryant", "LeBron James", "Kareem Abdul-Jabbar"], 2),
                TriviaQuestionInput.preset("In which sport would you perform a slam dunk?", ["Volleyball", "Tennis", "Basketball", "Handball"], 2),
                TriviaQuestionInput.preset("What is the national sport of Japan?", ["Karate", "Sumo", "Judo", "Kendo"], 1),
                TriviaQuestionInput.preset("How long is a marathon (approx)?", ["20 miles", "24 miles", "26.2 miles", "30 miles"], 2),
                TriviaQuestionInput.preset("Which country invented cricket?", ["Australia", "India", "South Africa", "England"], 3),
                TriviaQuestionInput.preset("What sport uses a shuttlecock?", ["Table Tennis", "Badminton", "Squash", "Racquetball"], 1),
            ]

        case .music:
            return [
                TriviaQuestionInput.preset("Who is known as the 'King of Pop'?", ["Prince", "Elvis Presley", "Michael Jackson", "Stevie Wonder"], 2),
                TriviaQuestionInput.preset("Which band released 'Bohemian Rhapsody'?", ["The Beatles", "Led Zeppelin", "Queen", "Pink Floyd"], 2),
                TriviaQuestionInput.preset("What instrument has 88 keys?", ["Guitar", "Violin", "Piano", "Harp"], 2),
                TriviaQuestionInput.preset("Which country is K-pop from?", ["Japan", "China", "South Korea", "Thailand"], 2),
                TriviaQuestionInput.preset("Who sang 'Rolling in the Deep'?", ["Beyoncé", "Adele", "Rihanna", "Taylor Swift"], 1),
                TriviaQuestionInput.preset("What was Elvis Presley's first #1 hit?", ["Jailhouse Rock", "Heartbreak Hotel", "Hound Dog", "Love Me Tender"], 1),
                TriviaQuestionInput.preset("Which instrument does a DJ typically use?", ["Drums", "Turntables", "Saxophone", "Bass Guitar"], 1),
                TriviaQuestionInput.preset("What genre originated in the Bronx in the 1970s?", ["Jazz", "Disco", "Hip-Hop", "Punk"], 2),
                TriviaQuestionInput.preset("How many strings does a standard guitar have?", ["4", "5", "6", "8"], 2),
                TriviaQuestionInput.preset("Who composed 'Moonlight Sonata'?", ["Mozart", "Bach", "Beethoven", "Chopin"], 2),
            ]

        case .popCulture:
            return [
                TriviaQuestionInput.preset("What is the name of the fictional school in Harry Potter?", ["Durmstrang", "Beauxbatons", "Hogwarts", "Ilvermorny"], 2),
                TriviaQuestionInput.preset("Which social media app uses disappearing 'Stories'?", ["Twitter", "LinkedIn", "Snapchat", "Pinterest"], 2),
                TriviaQuestionInput.preset("Who created the character Mickey Mouse?", ["Walt Disney", "Jim Henson", "Chuck Jones", "Hayao Miyazaki"], 0),
                TriviaQuestionInput.preset("What is Baby Yoda's real name?", ["Yoda Jr.", "Grogu", "Din", "Yaddle"], 1),
                TriviaQuestionInput.preset("Which show features the phrase 'Winter is Coming'?", ["The Witcher", "Lord of the Rings", "Game of Thrones", "Vikings"], 2),
                TriviaQuestionInput.preset("What game features characters like Mario and Luigi?", ["Sonic", "Zelda", "Super Mario Bros.", "Donkey Kong"], 2),
                TriviaQuestionInput.preset("Who played Iron Man in the MCU?", ["Chris Evans", "Chris Hemsworth", "Robert Downey Jr.", "Mark Ruffalo"], 2),
                TriviaQuestionInput.preset("What does 'GOAT' stand for in slang?", ["Get Out And Try", "Greatest Of All Time", "Going On A Trip", "Good Or Average Today"], 1),
                TriviaQuestionInput.preset("Which platform is known for short-form video?", ["YouTube", "Facebook", "TikTok", "Reddit"], 2),
                TriviaQuestionInput.preset("What year was the first iPhone released?", ["2005", "2006", "2007", "2008"], 2),
            ]

        case .foodDrink:
            return [
                TriviaQuestionInput.preset("What country is sushi originally from?", ["China", "Korea", "Japan", "Thailand"], 2),
                TriviaQuestionInput.preset("What is the main ingredient in guacamole?", ["Tomato", "Pepper", "Avocado", "Lime"], 2),
                TriviaQuestionInput.preset("Which spice is the most expensive by weight?", ["Vanilla", "Saffron", "Cardamom", "Cinnamon"], 1),
                TriviaQuestionInput.preset("What type of pasta is shaped like a bow tie?", ["Penne", "Rigatoni", "Farfalle", "Fusilli"], 2),
                TriviaQuestionInput.preset("Which fruit is known as the 'king of fruits'?", ["Mango", "Durian", "Jackfruit", "Pineapple"], 1),
                TriviaQuestionInput.preset("What is the most consumed beverage in the world (after water)?", ["Coffee", "Tea", "Beer", "Milk"], 1),
                TriviaQuestionInput.preset("Where did the croissant originate?", ["France", "Austria", "Italy", "Belgium"], 1),
                TriviaQuestionInput.preset("What nut is used to make marzipan?", ["Walnut", "Cashew", "Almond", "Pistachio"], 2),
                TriviaQuestionInput.preset("Which country produces the most coffee?", ["Colombia", "Ethiopia", "Vietnam", "Brazil"], 3),
                TriviaQuestionInput.preset("What is tofu made from?", ["Rice", "Wheat", "Soybeans", "Corn"], 2),
            ]

        case .animals:
            return [
                TriviaQuestionInput.preset("What is the fastest land animal?", ["Lion", "Cheetah", "Gazelle", "Pronghorn"], 1),
                TriviaQuestionInput.preset("How many hearts does an octopus have?", ["1", "2", "3", "4"], 2),
                TriviaQuestionInput.preset("What is a group of lions called?", ["Pack", "Herd", "Pride", "Flock"], 2),
                TriviaQuestionInput.preset("Which bird can fly backwards?", ["Eagle", "Penguin", "Hummingbird", "Owl"], 2),
                TriviaQuestionInput.preset("What is the largest mammal?", ["African Elephant", "Blue Whale", "Giraffe", "Hippopotamus"], 1),
                TriviaQuestionInput.preset("How many legs does a spider have?", ["6", "8", "10", "12"], 1),
                TriviaQuestionInput.preset("What animal has the longest lifespan?", ["Elephant", "Galápagos Tortoise", "Bowhead Whale", "Parrot"], 2),
                TriviaQuestionInput.preset("Which animal can change its color?", ["Gecko", "Chameleon", "Iguana", "Tree Frog"], 1),
                TriviaQuestionInput.preset("What is the only mammal that can fly?", ["Flying Squirrel", "Sugar Glider", "Bat", "Colugo"], 2),
                TriviaQuestionInput.preset("How long can a cockroach live without its head?", ["1 hour", "1 day", "1 week", "1 month"], 2),
            ]

        case .technology:
            return [
                TriviaQuestionInput.preset("What does 'HTTP' stand for?", ["HyperText Transfer Protocol", "High Tech Transfer Program", "Home Tool Transfer Process", "HyperText Technical Protocol"], 0),
                TriviaQuestionInput.preset("Who co-founded Apple with Steve Jobs?", ["Bill Gates", "Steve Wozniak", "Tim Cook", "Larry Page"], 1),
                TriviaQuestionInput.preset("What programming language has a coffee cup logo?", ["Python", "C++", "Java", "Ruby"], 2),
                TriviaQuestionInput.preset("What year was the World Wide Web invented?", ["1985", "1989", "1993", "1995"], 1),
                TriviaQuestionInput.preset("What does 'AI' stand for?", ["Automated Intelligence", "Artificial Intelligence", "Advanced Integration", "Algorithmic Inference"], 1),
                TriviaQuestionInput.preset("Which company created the Android OS?", ["Apple", "Google", "Microsoft", "Samsung"], 1),
                TriviaQuestionInput.preset("What does 'GPU' stand for?", ["General Processing Unit", "Graphics Processing Unit", "Global Power Unit", "Graphical Program Utility"], 1),
                TriviaQuestionInput.preset("Who is known as the father of the computer?", ["Alan Turing", "Charles Babbage", "John von Neumann", "Ada Lovelace"], 1),
                TriviaQuestionInput.preset("What was the first programmable computer called?", ["ENIAC", "Z3", "Colossus", "UNIVAC"], 1),
                TriviaQuestionInput.preset("What does 'URL' stand for?", ["Universal Resource Locator", "Uniform Resource Locator", "United Reference Link", "Universal Reference Locator"], 1),
            ]
        }
    }
}

extension TriviaQuestionInput {
    /// Convenience factory for preset questions.
    static func preset(_ question: String, _ answers: [String], _ correct: Int) -> TriviaQuestionInput {
        var q = TriviaQuestionInput()
        q.question = question
        q.answers = answers
        q.correctIndex = correct
        return q
    }
}

struct TriviaEditorView: View {
    @Binding var title: String
    @Binding var questions: [TriviaQuestionInput]
    @Binding var isGenerating: Bool
    @Binding var qrImages: [UIImage]
    @Binding var showQR: Bool

    @State private var selectedCategory: QuizCategory = .custom
    @State private var questionCount: Int = 5
    @State private var showCategoryPicker = true

    var body: some View {
        ScrollView {
            if showCategoryPicker {
                categoryPickerContent
            } else {
                quizEditorContent
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPickerContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(GlyphTheme.accentGradient)
                Text("Choose a Category")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.primaryText)
                Text("Pick a preset category or create your own quiz.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
            }
            .padding(.top, 16)

            // Category grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(QuizCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = category
                            if category == .custom {
                                title = ""
                                questions = [TriviaQuestionInput()]
                                showCategoryPicker = false
                            } else {
                                title = category.displayName + " Quiz"
                                let preset = category.presetQuestions.shuffled()
                                questions = Array(preset.prefix(questionCount))
                                showCategoryPicker = false
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(category.color)
                            Text(category.displayName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(GlyphTheme.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 90)
                        .background(GlyphTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(category.color.opacity(0.25), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            // Question count picker (for presets)
            VStack(spacing: 8) {
                Text("Questions per quiz")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(GlyphTheme.secondaryText)
                HStack(spacing: 8) {
                    ForEach([5, 7, 10], id: \.self) { count in
                        Button {
                            questionCount = count
                        } label: {
                            Text("\(count)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(questionCount == count ? .black : GlyphTheme.secondaryText)
                                .frame(width: 48, height: 36)
                                .background(questionCount == count ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Quiz Editor

    private var quizEditorContent: some View {
        VStack(spacing: 20) {
            // Back to categories
            HStack {
                Button {
                    withAnimation { showCategoryPicker = true }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Categories")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(GlyphTheme.accent)
                }
                Spacer()
                if selectedCategory != .custom {
                    // Shuffle button for presets
                    Button {
                        let preset = selectedCategory.presetQuestions.shuffled()
                        withAnimation { questions = Array(preset.prefix(questionCount)) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Shuffle")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(GlyphTheme.violet)
                    }
                }
            }
            .padding(.horizontal, 24)

            GlyphTextField(label: "Quiz Title", placeholder: "e.g., Movie Night Quiz", text: $title)
                .padding(.horizontal, 24)

            ForEach(questions.indices, id: \.self) { i in
                triviaRow(at: i)
                    .padding(.horizontal, 24)
            }

            AddItemButton(label: "Add Question") {
                withAnimation { questions.append(TriviaQuestionInput()) }
            }
            .padding(.horizontal, 24)

            SizeEstimateView(estimatedBytes: estimateSize())
                .padding(.horizontal, 24)

            GenerateButtonView(isGenerating: isGenerating) { generate() }
                .disabled(title.isEmpty || questions.isEmpty)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
    }

    private func triviaRow(at i: Int) -> some View {
        let deleteAction: (() -> Void)? = questions.count > 1 ? { withAnimation { _ = questions.remove(at: i) } } : nil
        return TriviaQuestionEditor(index: i, input: $questions[i], onDelete: deleteAction)
    }

    private func estimateSize() -> Int {
        let rawSize = 2800 + questions.count * 120
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
                title: title.isEmpty ? "Quiz" : title,
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
