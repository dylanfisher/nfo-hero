extension MediaItem {
    /// The poster's width over its height, so a card can reserve the poster's space before the
    /// image is decoded. Movie, show and season posters are 2:3, the size TMDB and Kodi use.
    /// Album covers are square, and so are the artist images Lidarr and Kodi save.
    public var posterAspectRatio: Double {
        switch kind {
        case .movie, .tvShow, .episode, .musicVideo: 2.0 / 3.0
        case .album, .artist: 1
        }
    }
}
