//
//  PlayerTrackTests.swift
//  swift-vlc
//

import Testing

@testable import VLCPlayer

@Suite("PlayerTrack")
struct PlayerTrackTests {
  @Test("disable uses the sentinel index -1")
  func disableUsesSentinelIndex() {
    #expect(PlayerTrack.disable.index == -1)
  }

  @Test("id mirrors the track index")
  func idMirrorsIndex() {
    let track = PlayerTrack(index: 3, name: "English")
    #expect(track.id == track.index)
  }

  @Test("tracks with the same index and name are equal")
  func equalityIsValueBased() {
    let a = PlayerTrack(index: 1, name: "Deutsch")
    let b = PlayerTrack(index: 1, name: "Deutsch")
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
  }

  @Test("tracks are distinguished by index")
  func differentIndexesAreNotEqual() {
    #expect(PlayerTrack(index: 1, name: "x") != PlayerTrack(index: 2, name: "x"))
  }

  @Test("disable carries a localized, non-empty name")
  func disableIsLocalized() {
    #expect(!PlayerTrack.disable.name.isEmpty)
  }
}
