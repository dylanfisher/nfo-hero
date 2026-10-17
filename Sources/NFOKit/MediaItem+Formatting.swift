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
}
