/// The `<video>` of a file's `<streamdetails>`, which Kodi and the media managers read from the
/// media file.
public struct VideoStream: Sendable, Equatable {
    /// As written, such as `HEVC` or `h264`.
    public var codec: String?
    /// Pixels.
    public var width: Int?
    /// Pixels.
    public var height: Int?
    /// As written, such as `dolbyvision` or `hdr10`.
    public var hdrType: String?

    public init(codec: String?, width: Int?, height: Int?, hdrType: String?) {
        self.codec = codec
        self.width = width
        self.height = height
        self.hdrType = hdrType
    }
}
