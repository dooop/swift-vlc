//
//  PlayerViewModelTests.swift
//  vlc-player
//

import Testing

@testable import VLCPlayer

@MainActor
@Suite("PlayerViewModel track mapping")
struct PlayerViewModelTests {
  @Test("maps parallel name/index arrays into tracks")
  func mapsNamesAndIndexes() {
    let viewModel = PlayerViewModel()
    let tracks = viewModel.tracksBy(names: ["English", "Deutsch"], indexes: [Int32(0), Int32(1)])
    #expect(tracks == [PlayerTrack(index: 0, name: "English"), PlayerTrack(index: 1, name: "Deutsch")])
  }

  @Test("returns no tracks when names and indexes disagree in count")
  func mismatchedCountsYieldNoTracks() {
    let viewModel = PlayerViewModel()
    let tracks = viewModel.tracksBy(names: ["English"], indexes: [Int32(0), Int32(1)])
    #expect(tracks.isEmpty)
  }

  @Test("drops entries whose types don't match the expected Int32/String pair")
  func mismatchedTypesAreSkipped() {
    let viewModel = PlayerViewModel()
    let tracks = viewModel.tracksBy(names: ["English", 42], indexes: [Int32(0), Int32(1)])
    #expect(tracks == [PlayerTrack(index: 0, name: "English")])
  }

  @Test("returns an empty list for empty input")
  func emptyInputYieldsNoTracks() {
    let viewModel = PlayerViewModel()
    let tracks = viewModel.tracksBy(names: [], indexes: [])
    #expect(tracks.isEmpty)
  }
}
