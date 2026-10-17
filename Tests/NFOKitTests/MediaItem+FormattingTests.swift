import NFOKit
import Testing

private func item(runtime: Int?) -> MediaItem {
    var item = MediaItem(kind: .movie)
    item.runtime = runtime
    return item
}

private func item(season: Int?, episode: Int?) -> MediaItem {
    var item = MediaItem(kind: .episode)
    item.season = season
    item.episode = episode
    return item
}

@Test func formatsRuntimeAsHoursAndMinutes() {
    #expect(item(runtime: 127).formattedRuntime == "2 h 7 min")
    #expect(item(runtime: 42).formattedRuntime == "42 min")
    #expect(item(runtime: 120).formattedRuntime == "2 h")
}

@Test func leavesOutAMissingOrZeroRuntime() {
    #expect(item(runtime: nil).formattedRuntime == nil)
    #expect(item(runtime: 0).formattedRuntime == nil)
}

@Test func formatsSeasonAndEpisodeAsACode() {
    #expect(item(season: 1, episode: 2).episodeCode == "S01E02")
    #expect(item(season: 0, episode: 1).episodeCode == "S00E01")
    #expect(item(season: 12, episode: 104).episodeCode == "S12E104")
}

@Test func needsBothSeasonAndEpisodeForACode() {
    #expect(item(season: 1, episode: nil).episodeCode == nil)
    #expect(item(season: nil, episode: 2).episodeCode == nil)
}

private func item(castCount: Int) -> MediaItem {
    var item = MediaItem(kind: .movie)
    item.cast = (0..<castCount).map { CastMember(name: "Actor \($0)", role: nil) }
    return item
}

@Test func listsTheWholeCastUpToTheLimit() {
    let movie = item(castCount: MediaItem.castLimit)
    #expect(movie.listedCast == movie.cast[...])
    #expect(movie.unlistedCastCount == 0)
}

@Test func countsTheCastPastTheLimit() {
    let movie = item(castCount: 25_000)
    #expect(movie.listedCast == movie.cast.prefix(MediaItem.castLimit))
    #expect(movie.unlistedCastCount == 25_000 - MediaItem.castLimit)
}
