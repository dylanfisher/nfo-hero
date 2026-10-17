import NFOKit
import Testing

private func video(
    codec: String? = nil, width: Int? = nil, height: Int? = nil, hdrType: String? = nil
) -> VideoStream {
    VideoStream(codec: codec, width: width, height: height, hdrType: hdrType)
}

@Test func summarizesResolutionCodecAndHDR() {
    #expect(
        video(codec: "HEVC", width: 3840, height: 2160, hdrType: "dolbyvision").summary
            == "2160p HEVC Dolby Vision")
    #expect(video(codec: "h264", width: 1920, height: 1080).summary == "1080p h264")
    #expect(video().summary == nil)
}

@Test func classifiesCroppedWidescreenByWidth() {
    #expect(video(width: 3840, height: 1600).resolution == "2160p")
    #expect(video(width: 1920, height: 800).resolution == "1080p")
    #expect(video(width: 1280, height: 534).resolution == "720p")
}

@Test func classifiesPillarboxedVideoByHeight() {
    #expect(video(width: 1440, height: 1080).resolution == "1080p")
    #expect(video(width: 960, height: 720).resolution == "720p")
}

@Test func givesTheHeightBelow720p() {
    #expect(video(width: 720, height: 576).resolution == "576p")
    #expect(video(width: 720, height: 480).resolution == "480p")
    #expect(video(width: 720).resolution == nil)
}

@Test func namesHDRTypes() {
    #expect(video(hdrType: "hdr10").hdrName == "HDR10")
    #expect(video(hdrType: "HDR10plus").hdrName == "HDR10+")
    #expect(video(hdrType: "hlg").hdrName == "HLG")
    #expect(video(hdrType: "pq").hdrName == "pq")
}
