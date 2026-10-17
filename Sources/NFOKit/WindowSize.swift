import Foundation

/// The size a document window or Quick Look preview opens at: the size its content needs when
/// that fits on the screen, and a portrait size scaled to the screen's height when it does not.
public enum WindowSize {
    /// The share of the visible screen height that content may need and still open at its own
    /// size. The rest leaves room to see the windows behind.
    static let fittingHeightFraction = 0.9
    /// The share of the visible screen height a window takes when its content does not fit.
    static let fallbackHeightFraction = 0.7
    /// Width over height when the content does not fit. At 4:5 a laptop screen with 875 pt of
    /// visible height gives 490 pt of width, about 60 columns of the 13 pt monospaced font.
    static let fallbackAspectRatio = 4.0 / 5.0
    /// The smallest size a window opens at, so a ten-line `.diz` does not open as a sliver with
    /// its title cut off. About 50 columns by 15 lines of the monospaced font.
    static let minimum = CGSize(width: 420, height: 280)

    /// The opening size for content whose ideal size is `ideal`, on a screen whose visible area,
    /// without the menu bar and Dock, is `visible`. Both sizes include any window title bar.
    ///
    /// Content that fits within the screen's width and ``fittingHeightFraction`` of its height
    /// opens at its ideal size, so it needs no scrolling and leaves no empty space, but never
    /// below ``minimum``. Other content opens ``fallbackHeightFraction`` of the screen tall at
    /// ``fallbackAspectRatio``, widened to the ideal width when the content is wider, so a
    /// 160-column NFO scrolls only down. The width never exceeds the screen's.
    public static func opening(ideal: CGSize, visible: CGSize) -> CGSize {
        let fits =
            ideal.width <= visible.width && ideal.height <= visible.height * fittingHeightFraction
        let size: CGSize
        if fits {
            size = CGSize(
                width: max(ideal.width, minimum.width), height: max(ideal.height, minimum.height))
        } else {
            let height = visible.height * fallbackHeightFraction
            size = CGSize(width: max(height * fallbackAspectRatio, ideal.width), height: height)
        }
        return CGSize(
            width: min(size.width, visible.width), height: min(size.height, visible.height))
    }
}
