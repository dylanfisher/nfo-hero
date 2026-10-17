extension VideoStream {
    /// Resolution, codec and HDR type, such as `2160p HEVC Dolby Vision`. Nil when the stream has
    /// none of them.
    public var summary: String? {
        let parts = [resolution, codec, hdrName].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// The video's resolution class, such as `1080p`. Widescreen films are cropped in height, as
    /// in 1920 × 800, and 4:3 video in width, as in 1440 × 1080, so a stream is in the first class
    /// whose width or height it nearly reaches. Below 720p, the height.
    public var resolution: String? {
        let classes = [(7680, 4320), (3840, 2160), (2560, 1440), (1920, 1080), (1280, 720)]
        for (classWidth, classHeight) in classes {
            if let width, width * 10 >= classWidth * 9 {
                return "\(classHeight)p"
            }
            if let height, height * 10 >= classHeight * 9 {
                return "\(classHeight)p"
            }
        }
        return height.map { "\($0)p" }
    }

    /// The HDR type's usual name, such as `Dolby Vision` for `dolbyvision`. An unknown type as
    /// written.
    public var hdrName: String? {
        guard let hdrType else { return nil }
        switch hdrType.lowercased() {
        case "dolbyvision": return "Dolby Vision"
        case "hdr10": return "HDR10"
        case "hdr10plus": return "HDR10+"
        case "hlg": return "HLG"
        default: return hdrType
        }
    }
}
