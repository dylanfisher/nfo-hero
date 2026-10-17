import Foundation
import NFOKit
import Testing

private struct NotMediaError: Error {
    let kind: NFO.Kind
}

private func item(_ name: String) throws -> MediaItem {
    let url = try #require(Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: nil))
    let kind = try NFO.parse(Data(contentsOf: url)).kind
    guard case .media(let items) = kind else { throw NotMediaError(kind: kind) }
    return try #require(items.first)
}

@Test func readsARadarrMovie() throws {
    let movie = try item("radarr-movie.nfo")
    #expect(movie.kind == .movie)
    #expect(movie.title == "Jurassic Park")
    #expect(movie.originalTitle == "Jurassic Park")
    #expect(movie.year == 1993)
    #expect(movie.runtime == 127)
    #expect(movie.mpaa == "PG-13")
    #expect(movie.genres == ["Adventure", "Science Fiction"])
    #expect(movie.studios == ["Universal Pictures"])
    #expect(movie.directors == ["Steven Spielberg"])
    #expect(movie.plot?.hasPrefix("A wealthy entrepreneur") == true)
    #expect(movie.cast.count == 22)
    #expect(movie.cast.first == CastMember(name: "Sam Neill", role: "Grant"))
}

@Test func treatsEmptyElementsAsMissing() throws {
    let movie = try item("radarr-movie.nfo")
    #expect(movie.tagline == nil)
}

@Test func readsDetailedRatingsAndPicksTheDefault() throws {
    let movie = try item("radarr-movie.nfo")
    #expect(movie.ratings.map(\.name) == ["imdb", "themoviedb", "tomatometerallcritics"])
    #expect(
        movie.primaryRating
            == Rating(name: "imdb", value: 8.2, max: 10, votes: 1_202_505, isDefault: true)
    )
    #expect(movie.ratings.last?.max == 100)
}

@Test func fallsBackToAPlainRating() throws {
    let show = try item("sonarr-tvshow.nfo")
    #expect(show.ratings == [Rating(name: nil, value: 8.5, max: nil, votes: nil, isDefault: false)])
    #expect(show.primaryRating?.value == 8.5)
}

@Test func readsATVShowAndTakesTheYearFromPremiered() throws {
    let show = try item("sonarr-tvshow.nfo")
    #expect(show.kind == .tvShow)
    #expect(show.title == "The Expanse")
    #expect(show.year == 2015)
    #expect(show.studios == ["Syfy", "Amazon"])
    #expect(show.cast.last == CastMember(name: "Dominique Tipper", role: nil))
}

@Test func readsAnEpisodeAndTakesTheYearFromAired() throws {
    let episode = try item("multi-episode.nfo")
    #expect(episode.kind == .episode)
    #expect(episode.showTitle == "Lost")
    #expect(episode.season == 1)
    #expect(episode.episode == 1)
    #expect(episode.aired == "2004-09-22")
    #expect(episode.year == 2004)
    #expect(episode.directors == ["J.J. Abrams"])
}

@Test func readsAnAlbumWithItsReviewAsThePlot() throws {
    let album = try item("lidarr-album.nfo")
    #expect(album.kind == .album)
    #expect(album.title == "OK Computer")
    #expect(album.artists == ["Radiohead"])
    #expect(album.year == 1997)
    #expect(album.plot == "The third studio album by Radiohead.")
}

@Test func readsAnArtistNameAsTheTitleAndBiographyAsThePlot() throws {
    let artist = try item("lidarr-artist.nfo")
    #expect(artist.kind == .artist)
    #expect(artist.title == "Radiohead")
    #expect(artist.plot == "English rock band formed in Abingdon in 1985.")
    #expect(artist.genres == ["Alternative Rock"])
}

@Test func readsAMusicVideoAndARuntimeWithAUnit() throws {
    let video = try item("musicvideo.nfo")
    #expect(video.kind == .musicVideo)
    #expect(video.artists == ["Radiohead"])
    #expect(video.album == "OK Computer")
    #expect(video.runtime == 4)
}

@Test func fallsBackToTheOutlineAndAlbumArtistCredits() throws {
    let xml = """
        <album><outline>Short.</outline>\
        <albumArtistCredits><artist>Radiohead</artist></albumArtistCredits></album>
        """
    guard case .media(let items) = try NFO.parse(Data(xml.utf8)).kind else {
        Issue.record("expected media")
        return
    }
    #expect(items.first?.plot == "Short.")
    #expect(items.first?.artists == ["Radiohead"])
}
