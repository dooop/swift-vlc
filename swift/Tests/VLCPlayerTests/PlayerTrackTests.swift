//
//  PlayerTrackTests.swift
//  vlc-player
//

import Testing

@testable import VLCPlayer

@Suite("PlayerTrack")
struct PlayerTrackTests {
  @Test("disable uses the sentinel id")
  func disableUsesSentinelId() {
    #expect(PlayerTrack.disable.id == PlayerTrack.disabledId)
  }

  @Test("tracks with the same id and name are equal")
  func equalityIsValueBased() {
    let a = PlayerTrack(id: "1", name: "Deutsch")
    let b = PlayerTrack(id: "1", name: "Deutsch")
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
  }

  @Test("tracks are distinguished by id")
  func differentIdsAreNotEqual() {
    #expect(PlayerTrack(id: "1", name: "x") != PlayerTrack(id: "2", name: "x"))
  }

  @Test("disable carries a localized, non-empty name")
  func disableIsLocalized() {
    #expect(!PlayerTrack.disable.name.isEmpty)
  }
}
