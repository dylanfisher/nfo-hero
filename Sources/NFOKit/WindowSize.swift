import Foundation

/// The size a document window or Quick Look preview opens at: portrait, scaled to the screen's
/// height so it grows on larger displays.
public enum WindowSize {
    /// Width over height. At 4:5, a 900 pt laptop screen still gives about 630 pt of width, enough
    /// for an 80-column scene NFO in the 13 pt monospaced font.
    static let aspectRatio = 4.0 / 5.0
    /// The share of the visible screen height a new window takes.
    static let heightFraction = 0.9

    /// The opening size for a screen whose visible area, without the menu bar and Dock, is
    /// `visible`. The width never exceeds the screen's.
    public static func portrait(fitting visible: CGSize) -> CGSize {
        let height = visible.height * heightFraction
        return CGSize(width: min(height * aspectRatio, visible.width), height: height)
    }
}
