import Foundation

extension MediaItem {
    /// The runtime as hours and minutes, such as `2 h 7 min`. Nil when there is no runtime or it
    /// is zero, which some writers use for unknown.
    public var formattedRuntime: String? {
        guard let runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes) min"
        case (_, 0): return "\(hours) h"
        default: return "\(hours) h \(minutes) min"
        }
    }

    /// Season and episode as `S01E02`. Nil unless both are present.
    public var episodeCode: String? {
        guard let season, let episode else { return nil }
        return String(format: "S%02dE%02d", season, episode)
    }

    /// How many cast members a card lists. Each one is a grid row, and laying out the rows blocks
    /// the main thread: 2,000 took over a second and 25,000 over a minute. Show Raw still has
    /// every one.
    public static let castLimit = 100

    /// The first ``castLimit`` members of ``cast``.
    public var listedCast: ArraySlice<CastMember> { cast.prefix(Self.castLimit) }

    /// How many members of ``cast`` are past ``castLimit``.
    public var unlistedCastCount: Int { cast.count - listedCast.count }

    /// The names of ``subtitleLanguages``, each once, such as `English, French`.
    public func subtitleNames(locale: Locale = .current) -> [String] {
        var names: [String] = []
        for language in subtitleLanguages {
            for name in LanguageNames.names(for: language, locale: locale)
            where !names.contains(name) {
                names.append(name)
            }
        }
        return names
    }
}
