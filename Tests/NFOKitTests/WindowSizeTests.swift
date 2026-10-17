import Foundation
import NFOKit
import Testing

private let laptop = CGSize(width: 1440, height: 875)

/// Width and height, because Foundation alone does not make CGSize Equatable.
private func sides(_ size: CGSize) -> [Double] { [size.width, size.height] }

@Test func opensContentThatFitsAtItsIdealSize() {
    let ideal = CGSize(width: 1207, height: 760)
    #expect(sides(WindowSize.opening(ideal: ideal, visible: laptop)) == sides(ideal))
}

@Test func opensContentUpToNinetyPercentOfTheScreenHeightAtItsIdealSize() {
    let ideal = CGSize(width: 600, height: 787.5)
    #expect(sides(WindowSize.opening(ideal: ideal, visible: laptop)) == sides(ideal))
}

@Test func neverOpensSmallerThanTheMinimum() {
    let size = WindowSize.opening(ideal: CGSize(width: 372, height: 188), visible: laptop)
    #expect(sides(size) == [420, 280])
}

@Test func keepsTheIdealSideThatIsLargerThanTheMinimum() {
    let size = WindowSize.opening(ideal: CGSize(width: 900, height: 120), visible: laptop)
    #expect(sides(size) == [900, 280])
}

@Test func opensTallContentPortraitAtSeventyPercentOfTheScreenHeight() {
    let size = WindowSize.opening(ideal: CGSize(width: 300, height: 4000), visible: laptop)
    #expect(size.height == 612.5)
    #expect(abs(size.width - 490) < 0.001)
}

@Test func widensTheFallbackToContentWiderThanItsAspectRatio() {
    let size = WindowSize.opening(ideal: CGSize(width: 1130, height: 4000), visible: laptop)
    #expect(sides(size) == [1130, 612.5])
}

@Test func fallsBackForContentWiderThanTheScreen() {
    let size = WindowSize.opening(ideal: CGSize(width: 3000, height: 300), visible: laptop)
    #expect(sides(size) == [1440, 612.5])
}

@Test func growsTheFallbackWithTheScreenHeight() {
    let ideal = CGSize(width: 500, height: 4000)
    let laptopSize = WindowSize.opening(ideal: ideal, visible: laptop)
    let desktopSize = WindowSize.opening(ideal: ideal, visible: CGSize(width: 2560, height: 1409))
    #expect(desktopSize.height > laptopSize.height)
    #expect(desktopSize.width > laptopSize.width)
}

@Test func neverExceedsTheScreen() {
    let narrow = CGSize(width: 400, height: 260)
    #expect(
        sides(WindowSize.opening(ideal: CGSize(width: 100, height: 100), visible: narrow))
            == sides(narrow))
    #expect(
        WindowSize.opening(ideal: CGSize(width: 500, height: 4000), visible: narrow).width == 400)
}
