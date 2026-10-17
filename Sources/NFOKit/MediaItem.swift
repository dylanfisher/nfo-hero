/// The fields of one Kodi NFO root element that an info card shows. Empty elements read as nil
/// or are left out of arrays.
public struct MediaItem: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable, CaseIterable {
        case movie
        case tvShow = "tvshow"
        case episode = "episodedetails"
        case musicVideo = "musicvideo"
        case album
        case artist
    }

    public var kind: Kind
    /// `<title>`, or `<name>` for an artist.
    public var title: String?
    public var originalTitle: String?
    /// `<year>`, falling back to the year of `<premiered>` or `<aired>`.
    public var year: Int?
    public var tagline: String?
    /// `<plot>`, falling back to `<outline>`, an album's `<review>` or an artist's `<biography>`.
    public var plot: String?
    /// Minutes.
    public var runtime: Int?
    public var mpaa: String?
    public var genres: [String] = []
    public var studios: [String] = []
    public var directors: [String] = []
    public var ratings: [Rating] = []
    public var cast: [CastMember] = []
    /// Album and music video artists.
    public var artists: [String] = []
    /// The album a music video is from.
    public var album: String?
    public var showTitle: String?
    public var season: Int?
    public var episode: Int?
    /// The episode's air date as written, usually `YYYY-MM-DD`.
    public var aired: String?

    public init(kind: Kind) {
        self.kind = kind
    }

    /// The rating marked `default="true"`, or the first one.
    public var primaryRating: Rating? {
        ratings.first(where: \.isDefault) ?? ratings.first
    }
}

extension MediaItem {
    /// Nil when `element` is not a Kodi root.
    init?(element: XMLTreeElement) {
        guard let kind = Kind(rawValue: element.name) else { return nil }
        self.init(kind: kind)

        title = element.string(kind == .artist ? "name" : "title")
        originalTitle = element.string("originaltitle")
        aired = element.string("aired")
        year =
            element.string("year").flatMap(Self.leadingInteger)
            ?? (element.string("premiered") ?? aired).flatMap(Self.leadingInteger)
        tagline = element.string("tagline")
        plot =
            element.string("plot") ?? element.string("outline") ?? element.string("review")
            ?? element.string("biography")
        // Some writers add a unit, as in "127 min".
        runtime = element.string("runtime").flatMap(Self.leadingInteger)
        mpaa = element.string("mpaa")
        genres = element.strings("genre")
        studios = element.strings("studio")
        directors = element.strings("director")
        ratings = Self.ratings(in: element)
        cast = element.children(named: "actor").compactMap { actor in
            actor.string("name").map { CastMember(name: $0, role: actor.string("role")) }
        }
        artists = element.strings("artist")
        if artists.isEmpty, let credits = element.child(named: "albumArtistCredits") {
            artists = credits.strings("artist")
        }
        album = element.string("album")
        showTitle = element.string("showtitle")
        season = element.string("season").flatMap { Int($0) }
        episode = element.string("episode").flatMap { Int($0) }
    }

    private static func ratings(in element: XMLTreeElement) -> [Rating] {
        let detailed =
            element.child(named: "ratings")?.children(named: "rating").compactMap {
                rating -> Rating? in
                guard let value = rating.string("value").flatMap({ Double($0) }) else {
                    return nil
                }
                return Rating(
                    name: rating.attributes["name"],
                    value: value,
                    max: rating.attributes["max"].flatMap { Double($0) },
                    votes: rating.string("votes").flatMap { Int($0) },
                    isDefault: rating.attributes["default"] == "true"
                )
            } ?? []
        if !detailed.isEmpty { return detailed }

        guard let value = element.string("rating").flatMap({ Double($0) }) else { return [] }
        return [Rating(name: nil, value: value, max: nil, votes: nil, isDefault: false)]
    }

    private static func leadingInteger(_ string: String) -> Int? {
        Int(string.prefix { $0.isASCII && $0.isNumber })
    }
}
