import NFOKit
import SwiftUI

/// The info card for one movie, show, episode, music video, album or artist.
struct MediaItemView: View {
    let item: MediaItem
    /// Absent when the folder has no poster; the card then has no image and no placeholder.
    let poster: LoadedArtwork.Slot

    /// Between the facts on one line, such as rating, runtime and genres.
    private static let factSeparator = "  ·  "
    /// Between the names in one fact, such as genres or directors.
    private static let listSeparator = ", "

    private static let posterWidth: CGFloat = 200
    private static let posterShape = RoundedRectangle(cornerRadius: 6)

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            if poster != .absent {
                posterImage
            }
            VStack(alignment: .leading, spacing: 14) {
                header
                if let tagline = item.tagline {
                    Text(tagline).font(.title3).italic().foregroundStyle(.secondary)
                }
                if !facts.isEmpty {
                    Text(facts.joined(separator: Self.factSeparator)).foregroundStyle(.secondary)
                }
                if !otherRatings.isEmpty {
                    Text(otherRatings.joined(separator: Self.factSeparator))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                if let plot = item.plot {
                    Text(plot).frame(maxWidth: 640, alignment: .leading)
                }
                credits
                if !item.cast.isEmpty {
                    cast
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .textSelection(.enabled)
    }

    /// The frame is set from the kind's aspect ratio before the image is decoded, so the card does
    /// not move when it arrives. An image of another shape fits inside the frame, at the top,
    /// rather than being cropped: square album art in a 2:3 frame would lose a third of its width.
    /// A poster that fails to decode keeps its frame, so the text does not jump left after it had
    /// been laid out beside the placeholder.
    private var posterImage: some View {
        ZStack(alignment: .top) {
            switch poster {
            case .absent, .decoding, .failed:
                Self.posterShape
                    .fill(.quaternary)
                    .overlay {
                        Image(
                            systemName: poster == .failed ? "photo.badge.exclamationmark" : "photo"
                        )
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    }
                    .transition(.opacity)
            case .decoded(let image):
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Self.posterShape)
                    .shadow(radius: 4, y: 2)
                    .transition(.opacity)
            }
        }
        .frame(
            width: Self.posterWidth, height: Self.posterWidth / item.posterAspectRatio,
            alignment: .top
        )
        .accessibilityHidden(true)
    }

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if item.kind == .episode {
                let episodeLine = [item.showTitle, item.episodeCode].compactMap { $0 }
                if !episodeLine.isEmpty {
                    Text(episodeLine.joined(separator: Self.factSeparator))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            (Text(item.title ?? "Untitled")
                + Text(item.year.map { "  \(String($0))" } ?? "").foregroundStyle(.secondary))
                .font(.largeTitle.bold())
            if let originalTitle = item.originalTitle, originalTitle != item.title {
                Text(originalTitle).font(.title3).foregroundStyle(.secondary)
            }
            if !item.artists.isEmpty, item.kind != .artist {
                Text(item.artists.joined(separator: Self.listSeparator)).font(.title2)
            }
        }
    }

    /// Primary rating, runtime, certification, air date and genres on one line.
    private var facts: [String] {
        var facts: [String] = []
        if let rating = item.primaryRating {
            facts.append("★ \(rating.formattedValue)\(Self.votes(rating))")
        }
        facts += [item.formattedRuntime, item.mpaa].compactMap { $0 }
        if let aired = item.aired, item.kind == .episode {
            facts.append("Aired \(aired)")
        }
        if !item.genres.isEmpty {
            facts.append(item.genres.joined(separator: Self.listSeparator))
        }
        return facts
    }

    private var otherRatings: [String] {
        let primary = item.primaryRating
        return item.ratings.filter { $0 != primary }.map { rating in
            [rating.name, rating.formattedValue].compactMap { $0 }.joined(separator: " ")
                + Self.votes(rating)
        }
    }

    private static func votes(_ rating: Rating) -> String {
        rating.votes.map { " (\($0.formatted()) votes)" } ?? ""
    }

    private var credits: some View {
        let rows: [(String, [String])] = [
            ("Album", [item.album].compactMap { $0 }),
            (item.directors.count == 1 ? "Director" : "Directors", item.directors),
            (item.studios.count == 1 ? "Studio" : "Studios", item.studios),
        ].filter { !$0.1.isEmpty }
        return Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4)
        {
            ForEach(rows, id: \.0) { label, values in
                GridRow {
                    Text(label).foregroundStyle(.secondary)
                    Text(values.joined(separator: Self.listSeparator))
                }
            }
        }
    }

    private var cast: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cast").font(.headline)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 4) {
                ForEach(item.listedCast.indices, id: \.self) { index in
                    let member = item.cast[index]
                    GridRow {
                        Text(member.name)
                        Text(member.role ?? "").foregroundStyle(.secondary)
                    }
                }
            }
            if item.unlistedCastCount > 0 {
                Text("and \(item.unlistedCastCount.formatted()) more, listed in View → Show Raw")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
