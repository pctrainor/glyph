import SwiftUI
import AVFoundation

// MARK: - Library View

/// Displays saved messages, images, and web experiences from the local library.
/// All data is stored in the app's documents directory — no Photo Library access needed.
struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: GlyphStore = .shared
    
    @State private var selectedFilter: FilterOption = .all
    @State private var showDeleteAllConfirm = false
    @State private var selectedImage: (UIImage, SavedGlyph)?
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case images = "Images"
        case messages = "Messages"
        case experiences = "Experiences"
    }
    
    var filteredItems: [SavedGlyph] {
        switch selectedFilter {
        case .all:         return store.items
        case .images:      return store.imageItems
        case .messages:    return store.textItems
        case .experiences: return store.webItems
        }
    }
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .padding(.top, 8)
                
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                LibraryItemRow(item: item, store: store, onImageTap: { img in
                                    selectedImage = (img, item)
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !store.items.isEmpty {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAllConfirm = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 17))
                            .foregroundColor(GlyphTheme.accent)
                    }
                }
            }
        }
        .alert("Clear Library?", isPresented: $showDeleteAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                withAnimation { store.deleteAll() }
            }
        } message: {
            Text("This will permanently delete all saved messages and images. This cannot be undone.")
        }
        .fullScreenCover(item: Binding(
            get: { selectedImage.map { ImageViewerItem(image: $0.0, glyph: $0.1) } },
            set: { if $0 == nil { selectedImage = nil } }
        )) { viewer in
            ImageViewerView(image: viewer.image, caption: viewer.glyph.text) {
                selectedImage = nil
            }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterOption.allCases, id: \.rawValue) { option in
                    let count: Int = {
                        switch option {
                        case .all:         return store.items.count
                        case .images:      return store.imageItems.count
                        case .messages:    return store.textItems.count
                        case .experiences: return store.webItems.count
                        }
                    }()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = option
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(option.rawValue)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        selectedFilter == option
                                            ? Color.black.opacity(0.2)
                                            : GlyphTheme.accent.opacity(0.15)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == option
                                ? GlyphTheme.accent.opacity(0.2)
                                : GlyphTheme.surface
                        )
                        .foregroundColor(
                            selectedFilter == option
                                ? GlyphTheme.accent
                                : GlyphTheme.secondaryText
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedFilter == option
                                        ? GlyphTheme.accent.opacity(0.4)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: selectedFilter == .all ? "tray" : "tray.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(GlyphTheme.secondaryText.opacity(0.4))
            
            Text(selectedFilter == .all ? "No saved glyphs" : "No \(selectedFilter.rawValue.lowercased())")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
            
            Text("Received messages and images will appear here\nwhen you save them")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

// MARK: - Library Item Row

struct LibraryItemRow: View {
    let item: SavedGlyph
    let store: GlyphStore
    var onImageTap: ((UIImage) -> Void)?
    
    @State private var showDeleteConfirm = false
    @State private var loadedImage: UIImage?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon / thumbnail
            if let img = loadedImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        onImageTap?(img)
                    }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(item.relativeTime)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                    
                    if item.sourceType == .webExperience {
                        Text("•")
                            .foregroundColor(GlyphTheme.secondaryText.opacity(0.5))
                        Text(item.webBundleType?.capitalized ?? "Experience")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(GlyphTheme.violet)
                    }
                    
                    if item.hasAudio {
                        Button {
                            toggleAudioPlayback()
                        } label: {
                            Image(systemName: isPlayingAudio ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(isPlayingAudio ? GlyphTheme.danger : GlyphTheme.accent)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(GlyphTheme.secondaryText.opacity(0.5))
                    .padding(8)
            }
        }
        .padding(12)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(GlyphTheme.accent.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            loadedImage = store.loadImage(for: item)
        }
        .alert("Delete this glyph?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                withAnimation { store.delete(item) }
            }
        }
        .onDisappear {
            audioPlayer?.stop()
            isPlayingAudio = false
        }
    }
    
    private func toggleAudioPlayback() {
        if isPlayingAudio {
            audioPlayer?.stop()
            isPlayingAudio = false
            return
        }
        
        guard let audioData = store.loadAudio(for: item) else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
            isPlayingAudio = true
            
            // Auto-stop when done
            let duration = audioPlayer?.duration ?? 0
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                    isPlayingAudio = false
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to play audio: \(error)")
            #endif
        }
    }
    
    private var iconColor: Color {
        switch item.sourceType {
        case .message: return GlyphTheme.accent
        case .webExperience: return GlyphTheme.violet
        }
    }
}

// MARK: - Image Viewer (Full Screen)

struct ImageViewerItem: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let glyph: SavedGlyph
    
    static func == (lhs: ImageViewerItem, rhs: ImageViewerItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ImageViewerView: View {
    let image: UIImage
    let caption: String
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .scaleEffect(scale)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = value.magnification
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    scale = max(1.0, min(scale, 4.0))
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) {
                            scale = scale > 1.5 ? 1.0 : 2.5
                        }
                    }
                    .padding(.horizontal, 16)
                
                Spacer()
                
                // Caption
                if !caption.isEmpty && caption != "Photo" && caption != "Photo & Audio" && caption != "Audio" && caption != "📷" && caption != "📷🔊" && caption != "🔊" {
                    Text(caption)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { appeared = true }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LibraryView()
    }
    .preferredColorScheme(.dark)
}
