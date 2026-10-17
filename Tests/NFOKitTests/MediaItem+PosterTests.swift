import NFOKit
import Testing

@Test func reservesATwoByThreePosterForVideo() {
    for kind in [MediaItem.Kind.movie, .tvShow, .episode, .musicVideo] {
        #expect(MediaItem(kind: kind).posterAspectRatio == 2.0 / 3.0)
    }
}

@Test func reservesASquareCoverForMusic() {
    #expect(MediaItem(kind: .album).posterAspectRatio == 1)
    #expect(MediaItem(kind: .artist).posterAspectRatio == 1)
}
