import Foundation
import NFOKit
import Testing

@Test func opensPortraitAtNinetyPercentOfTheScreenHeight() {
    let size = WindowSize.portrait(fitting: CGSize(width: 1440, height: 875))
    #expect(size.height == 787.5)
    #expect(size.width == 630)
}

@Test func growsWithTheScreenHeight() {
    let laptop = WindowSize.portrait(fitting: CGSize(width: 1440, height: 875))
    let desktop = WindowSize.portrait(fitting: CGSize(width: 2560, height: 1415))
    #expect(desktop.height > laptop.height)
    #expect(desktop.width > laptop.width)
}

@Test func neverExceedsTheScreenWidth() {
    let size = WindowSize.portrait(fitting: CGSize(width: 500, height: 1400))
    #expect(size.width == 500)
}
