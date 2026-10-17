/// View → Dark Text Background, which draws the text view light on dark in either system
/// appearance, the way DOS showed the art. One setting for every window, kept in user defaults.
public enum DarkTextBackground {
    /// The user defaults key, a Bool. The Quick Look extension has its own defaults, where it is
    /// never set.
    public static let defaultsKey = "darkTextBackground"
}
