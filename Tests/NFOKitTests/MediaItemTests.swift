import Foundation
import NFOKit
import Testing

private func item(_ name: String) throws -> MediaItem {
    try #require(NFO.fixture(name).mediaItems().first)
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
    let album = try #require(NFO.parse(Data(xml.utf8)).mediaItems().first)
    #expect(album.plot == "Short.")
    #expect(album.artists == ["Radiohead"])
}

@Test func picksTheFirstRatingWhenNoneIsTheDefault() throws {
    let xml = """
        <movie><ratings>\
        <rating name="imdb"><value>8.2</value></rating>\
        <rating name="themoviedb" max="10"><value>7.9</value></rating>\
        </ratings></movie>
        """
    let movie = try #require(NFO.parse(Data(xml.utf8)).mediaItems().first)
    #expect(movie.primaryRating?.name == "imdb")
}

@Test func skipsRatingsWithoutANumericValue() throws {
    let xml = """
        <movie><ratings>\
        <rating name="imdb"><value /></rating>\
        <rating name="themoviedb"><value>n/a</value></rating>\
        <rating name="trakt"><value>7.5</value></rating>\
        </ratings></movie>
        """
    let movie = try #require(NFO.parse(Data(xml.utf8)).mediaItems().first)
    #expect(movie.ratings.map(\.name) == ["trakt"])
}

@Test func readsTextInsideCDATA() throws {
    let xml = "<movie><plot><![CDATA[Dinosaurs & <chaos>.]]></plot></movie>"
    let movie = try #require(NFO.parse(Data(xml.utf8)).mediaItems().first)
    #expect(movie.plot == "Dinosaurs & <chaos>.")
}

@Test func removesBidirectionalControlsFromCardText() throws {
    let text = """
        <movie><title>\u{202E}gnp.exe\u{202C}</title><mpaa>PG\u{2067}</mpaa>\
        <genre>Drama \u{202D}x\u{2069}</genre><plot>שלום \u{200F}world</plot></movie>
        """
    let movie = try #require(NFO.parse(Data(text.utf8)).mediaItems().first)
    #expect(movie.title == "gnp.exe")
    #expect(movie.mpaa == "PG")
    #expect(movie.genres == ["Drama x"])
    // Marks only set the direction of neutral characters and cannot carry past a field.
    #expect(movie.plot == "שלום \u{200F}world")
}

@Test func readsStreamDetails() throws {
    let movie = try item("radarr-movie.nfo")
    #expect(
        movie.video
            == VideoStream(codec: "HEVC", width: 3840, height: 2160, hdrType: "dolbyvision"))
    #expect(
        movie.audioStreams
            == [AudioStream(codec: "TrueHD Atmos", channels: 8, language: "engengeng")])
    #expect(movie.subtitleLanguages.count == 49)
    #expect(movie.subtitleLanguages.prefix(4) == ["eng", "eng", "alb", "ara"])
}

@Test func leavesStreamDetailsEmptyWithoutFileInfo() throws {
    let show = try item("sonarr-tvshow.nfo")
    #expect(show.video == nil)
    #expect(show.audioStreams.isEmpty)
    #expect(show.subtitleLanguages.isEmpty)
}
