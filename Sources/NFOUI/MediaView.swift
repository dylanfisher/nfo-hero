import NFOKit
import SwiftUI

/// The info cards for a media-server NFO, one per item, or its raw text when View → Show Raw is
/// on.
struct MediaView: View {
    let items: [MediaItem]
    let text: String
    let fileURL: URL?
    /// Nil where there is no View → Show Raw.
    let showRaw: Binding<Bool>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // State as a plain property rather than `@State`: in the macOS 27 SDK `@State` is a macro
    // whose plugin ships only with Xcode, so it does not build with the Command Line Tools.
    // SwiftUI finds `State` properties by reflection, so this keeps its value across updates.
    private let loaded: State<LoadedArtwork?>
    private var artwork: LoadedArtwork? { loaded.wrappedValue }

    init(items: [MediaItem], text: String, fileURL: URL?, showRaw: Binding<Bool>?) {
        self.items = items
        self.text = text
        self.fileURL = fileURL
        self.showRaw = showRaw
        // Found here rather than in the task below so the first layout already holds the poster's
        // space, and the card does not move when the poster is decoded. SwiftUI keeps the first
        // value and ignores the ones from later inits.
        loaded = State(initialValue: fileURL.map(LoadedArtwork.find(nextTo:)))
    }

    var body: some View {
        Group {
            if showRaw?.wrappedValue == true {
                NFOTextView(text: text)
            } else {
                cards
            }
        }
        .focusedSceneValue(\.showRaw, showRaw.map(ShowRawToggle.init))
        .task(id: fileURL) {
            guard let fileURL else { return }
            var found = artwork
            // The window's file was moved since the view was made.
            if found?.nfoURL != fileURL {
                found = LoadedArtwork.find(nextTo: fileURL)
                loaded.wrappedValue = found
            }
            guard let decoded = await found?.decoded(), !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                loaded.wrappedValue = decoded
            }
        }
    }

    private var cardList: some View {
        ForEach(items.indices, id: \.self) { index in
            if index > 0 { Divider() }
            MediaItemView(
                item: items[index], poster: artwork?.poster ?? .absent,
                hasShowRaw: showRaw != nil)
        }
    }

    /// Up to this many cards are laid out in a plain VStack, which reports their exact height, so
    /// the window opens fitting them. A LazyVStack estimates the cards it has not built, 9 pt
    /// short for two or three episodes and 90 pt short for ten, which left a window that
    /// scrolled. Ten episode cards are taller than most screens, and a window for more opens at
    /// the fallback size, where the estimate does not matter.
    private static let eagerCardLimit = 10

    private var cards: some View {
        ScrollView {
            Group {
                if items.count <= Self.eagerCardLimit {
                    VStack(alignment: .leading, spacing: 32) { cardList }
                } else {
                    // Lazy so a file with many episodes builds only the cards on screen.
                    LazyVStack(alignment: .leading, spacing: 32) { cardList }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(alignment: .top) {
            if case .decoded(let fanart) = artwork?.fanart {
                // Downsampled and faded so it tints the window without competing with the text.
                Image(decorative: fanart, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.12)
                    .mask(
                        LinearGradient(
                            colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
    }
}
