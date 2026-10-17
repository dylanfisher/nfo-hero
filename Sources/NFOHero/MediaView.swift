import NFOKit
import SwiftUI

/// The info cards for a media-server NFO, one per item, or its raw text when View → Show Raw is
/// on.
struct MediaView: View {
    let items: [MediaItem]
    let text: String
    let fileURL: URL?

    @SceneStorage("showRaw") private var showRaw = false
    // State as a plain property rather than `@State`: in the macOS 27 SDK `@State` is a macro
    // whose plugin ships only with Xcode, so it does not build with the Command Line Tools.
    private let loaded = State(initialValue: LoadedArtwork.none)
    private var artwork: LoadedArtwork { loaded.wrappedValue }

    var body: some View {
        Group {
            if showRaw {
                NFOTextView(text: text)
            } else {
                cards
            }
        }
        .focusedSceneValue(\.showRaw, ShowRawToggle($showRaw))
        .task(id: fileURL) {
            guard let fileURL else { return }
            loaded.wrappedValue = await LoadedArtwork.load(nextTo: fileURL)
        }
    }

    private var cards: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(items.indices, id: \.self) { index in
                    if index > 0 { Divider() }
                    MediaItemView(item: items[index], poster: artwork.poster)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(alignment: .top) {
            if let fanart = artwork.fanart {
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
            }
        }
    }
}
