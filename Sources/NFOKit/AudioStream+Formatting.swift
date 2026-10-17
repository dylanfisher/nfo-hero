import Foundation

extension AudioStream {
    /// Codec, channel layout and language, such as `TrueHD Atmos 7.1 (English)`. Nil when the
    /// stream has none of them.
    public func summary(locale: Locale = .current) -> String? {
        var parts = [codec, channelLayout].compactMap { $0 }
        if let language {
            parts.append(
                "(\(LanguageNames.names(for: language, locale: locale).joined(separator: ", ")))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// `Mono`, `Stereo`, or the main channels and the LFE channel, such as `5.1` for 6.
    public var channelLayout: String? {
        guard let channels, channels > 0 else { return nil }
        switch channels {
        case 1: return "Mono"
        case 2: return "Stereo"
        default: return "\(channels - 1).1"
        }
    }
}
