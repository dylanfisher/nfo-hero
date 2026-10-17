/// An `<audio>` of a file's `<streamdetails>`.
public struct AudioStream: Sendable, Equatable {
    /// As written, such as `TrueHD Atmos` or `ac3`.
    public var codec: String?
    /// Including the LFE channel, so 5.1 is 6.
    public var channels: Int?
    /// An ISO 639-2 code, such as `eng`, as written.
    public var language: String?

    public init(codec: String?, channels: Int?, language: String?) {
        self.codec = codec
        self.channels = channels
        self.language = language
    }
}
