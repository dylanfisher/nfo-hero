import Foundation
import NFOKit
import Testing

private let english = Locale(identifier: "en_US")

@Test func summarizesCodecChannelsAndLanguage() {
    let audio = AudioStream(codec: "TrueHD Atmos", channels: 8, language: "eng")
    #expect(audio.summary(locale: english) == "TrueHD Atmos 7.1 (English)")
    #expect(AudioStream(codec: nil, channels: nil, language: nil).summary(locale: english) == nil)
}

@Test func namesChannelLayouts() {
    #expect(AudioStream(codec: nil, channels: 1, language: nil).channelLayout == "Mono")
    #expect(AudioStream(codec: nil, channels: 2, language: nil).channelLayout == "Stereo")
    #expect(AudioStream(codec: nil, channels: 6, language: nil).channelLayout == "5.1")
    #expect(AudioStream(codec: nil, channels: 0, language: nil).channelLayout == nil)
}

@Test func splitsRadarrsRunTogetherLanguageCodes() {
    let audio = AudioStream(codec: "AC3", channels: nil, language: "engengfre")
    #expect(audio.summary(locale: english) == "AC3 (English, French)")
}

@Test func keepsALanguageCodeWithNoNameAsWritten() {
    let audio = AudioStream(codec: nil, channels: nil, language: "xxxyyy")
    #expect(audio.summary(locale: english) == "(xxxyyy)")
}

@Test func namesEachSubtitleLanguageOnce() throws {
    let movie = try #require(NFO.fixture("radarr-movie.nfo").mediaItems().first)
    let names = movie.subtitleNames(locale: english)
    #expect(names.prefix(4) == ["English", "Albanian", "Arabic", "Bosnian"])
    #expect(names.count == Set(names).count)
}
