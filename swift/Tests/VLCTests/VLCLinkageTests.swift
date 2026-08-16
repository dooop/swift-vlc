//
//  VLCLinkageTests.swift
//  vlc-player
//
//  Smoke test for the VLCKit binary target: if the universal xcframework is
//  missing, mis-linked or fails to load at runtime, these tests fail before
//  anything else does.
//

import Foundation
import Testing
import VLC

@Suite("VLC linkage")
struct VLCLinkageTests {
  @Test("the VLCKit framework loads and exposes its core classes")
  func coreClassesAreAvailable() {
    #expect(NSStringFromClass(VLCMediaPlayer.self).hasSuffix("VLCMediaPlayer"))
    #expect(NSStringFromClass(VLCMedia.self).hasSuffix("VLCMedia"))
  }

  @Test("VLCTime formats a millisecond value")
  func timeFormatsValue() {
    #expect(VLCTime(int: 65_000).stringValue == "01:05")
  }

  @Test("VLCMedia can be created from a URL without starting playback")
  func mediaCanBeCreatedFromURL() throws {
    let media = try #require(VLCMedia(url: URL(string: "https://example.com/video.mp4")!))
    #expect(media.url?.absoluteString == "https://example.com/video.mp4")
  }
}
