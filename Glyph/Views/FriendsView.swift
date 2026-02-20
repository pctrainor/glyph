import SwiftUI

// MARK: - Friends View

/// Shows the locally-stored friends list — people whose signed Glyph messages you've scanned.
/// Tap a friend to open their conversation. Swipe to delete.
struct FriendsView: View {
    @ObservedObject private var store = FriendStore.shared
    @ObservedObject private var convoStore = ConversationStore.shared
    @State private var searchText = ""
    @State private var selectedFriend: GlyphFriend?
    
    private var filteredFriends: [GlyphFriend] {
        if searchText.isEmpty { return store.friends }
        let query = searchText.lowercased()
        return store.friends.filter {
            $0.handle.lowercased().contains(query) ||
            ($0.nickname?.lowercased().contains(query) ?? false) ||
            $0.platform.displayName.lowercased().contains(query)
        }
    }
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            if store.friends.isEmpty {
                emptyState
            } else {
                friendsList
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedFriend) { friend in
            ConversationView(friend: friend)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)
            
            Text("No friends yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("Scan a signed Glyph message to\nadd someone as a friend")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Friends List
    
    private var friendsList: some View {
        List {
            ForEach(filteredFriends) { friend in
                Button {
                    guard selectedFriend == nil else { return }
                    selectedFriend = friend
                } label: {
                    FriendRow(friend: friend, convoStore: convoStore)
                }
                .listRowBackground(GlyphTheme.surface)
                .listRowSeparatorTint(GlyphTheme.accent.opacity(0.1))
                .contextMenu {
                    if let url = friend.profileURL {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Open \(friend.platform.displayName)", systemImage: "arrow.up.right.square")
                        }
                    }
                    Button(role: .destructive) {
                        store.remove(friend)
                    } label: {
                        Label("Remove Friend", systemImage: "person.badge.minus")
                    }
                }
            }
            .onDelete { offsets in
                let friendsToRemove = offsets.map { filteredFriends[$0] }
                for friend in friendsToRemove {
                    store.remove(friend)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search friends")
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: GlyphFriend
    let convoStore: ConversationStore
    
    private var conversation: Conversation {
        convoStore.conversation(for: friend.id)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Platform icon circle
            ZStack {
                Circle()
                    .fill(GlyphTheme.accentGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: friend.platform.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            // Handle + conversation preview
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(friend.nickname ?? friend.displayHandle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(GlyphTheme.primaryText)
                    
                    if friend.nickname != nil {
                        Text(friend.displayHandle)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                    }
                }
                
                HStack(spacing: 8) {
                    // Conversation preview or platform
                    Text(conversation.previewText)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Locked count badge
                    if conversation.lockedCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 9))
                            Text("\(conversation.lockedCount)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(GlyphTheme.violet)
                    }
                    
                    // Message count
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 10))
                        Text("\(conversation.messages.count)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(GlyphTheme.secondaryText.opacity(0.6))
                    
                    // Time
                    Text(timeAgo(friend.lastSeen))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        FriendsView()
            .preferredColorScheme(.dark)
    }
}
