//
//  PlayerViewModel.swift
//  vlc-player
//
//  Created by Dominic Opitz on 01.06.24.
//

import SwiftUI
import VLC

@MainActor
class PlayerViewModel: NSObject, ObservableObject {
  private var url: URL?
  private var positions: [String: Float] = [:]

  @AppStorage("vlcPlayerPositions") private var positionsData: Data = Data()
  @AppStorage("vlcPlayerSubTitleScale") private var subTitleScale: Int = 100

  @Published private(set) var vlcPlayer: VLCMediaPlayer? = nil
  @Published private(set) var state = PlayerState.loading
  @Published private(set) var playing = false
  @Published private(set) var currentTime = ""
  @Published private(set) var remainingTime = ""
  @Published private(set) var duration: Int32 = 0
  @Published private(set) var position: Float = 0
  @Published var audio: PlayerTrack = .disable
  @Published var audioTracks: [PlayerTrack] = []
  @Published var subtitle: PlayerTrack = .disable
  @Published var subtitleTracks: [PlayerTrack] = []

  func load(media url: URL) {
    self.url = url
    vlcPlayer = VLCMediaPlayer(options: ["--sub-text-scale=\(subTitleScale)"])
    vlcPlayer?.delegate = self
    vlcPlayer?.media = VLCMedia(url: url)
    if let positions = try? JSONDecoder().decode([String: Float].self, from: positionsData) {
      self.positions = positions
      self.position = positions[url.path()] ?? 0
    }
  }

  func reset() {
    if let url {
      positions[url.path()] = position
      positionsData = (try? JSONEncoder().encode(positions)) ?? Data()
    }
    vlcPlayer = nil
  }

  func play() {
    vlcPlayer?.play()
  }

  func pause() {
    vlcPlayer?.pause()
  }

  func stop() {
    vlcPlayer?.stop()
  }

  func seek(to position: Float) {
    vlcPlayer?.position = Double(position)
    currentTime = VLCTime(int: Int32(position * Float(self.duration))).stringValue
  }

  func changeAudio(track: PlayerTrack) {
    guard track.id != PlayerTrack.disabledId else {
      vlcPlayer?.deselectAllAudioTracks()
      return
    }
    vlcPlayer?.audioTracks.first(where: { $0.trackId == track.id })?.selectedExclusively = true
  }

  func changeSubtitle(track: PlayerTrack) {
    guard track.id != PlayerTrack.disabledId else {
      vlcPlayer?.deselectAllTextTracks()
      return
    }
    vlcPlayer?.textTracks.first(where: { $0.trackId == track.id })?.selectedExclusively = true
  }

  private func updatePlayer(state: VLCMediaPlayerState, playing: Bool) {
    self.playing = playing

    switch state {
    case .playing:
      self.state = .playing
    case .paused:
      self.state = .paused
    case .stopped, .stopping:
      self.state = .finished
    case .opening, .nothingSpecial:
      self.state = .loading
    case .error:
      self.state = .error
    @unknown default: break
    }
  }

  private func updatePlayer(
    position: Float,
    duration: Int32,
    currentTime: String,
    remainingTime: String
  ) {
    self.position = position
    self.duration = duration
    self.currentTime = currentTime
    self.remainingTime = remainingTime
  }

  private func updateAudioTracks() {
    let tracks = vlcPlayer?.audioTracks ?? []
    audioTracks = tracks.map { PlayerTrack(id: $0.trackId, name: $0.trackName) }
    audio =
      tracks.first(where: { $0.isSelected })
      .map { PlayerTrack(id: $0.trackId, name: $0.trackName) } ?? .disable
  }

  private func updateSubtitleTracks() {
    let tracks = vlcPlayer?.textTracks ?? []
    subtitleTracks = tracks.map { PlayerTrack(id: $0.trackId, name: $0.trackName) }
    subtitle =
      tracks.first(where: { $0.isSelected })
      .map { PlayerTrack(id: $0.trackId, name: $0.trackName) } ?? .disable
  }
}

extension PlayerViewModel: VLCMediaPlayerDelegate {
  nonisolated func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
    Task { @MainActor in
      self.updatePlayer(state: newState, playing: self.vlcPlayer?.isPlaying ?? false)
    }
  }

  nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
    guard let player = aNotification.object as? VLCMediaPlayer else {
      return
    }

    let position = Float(player.position)
    let duration = player.media?.length.intValue ?? 0
    let time = player.time.stringValue
    let remaining = (player.remainingTime ?? VLCTime()).stringValue

    Task { @MainActor in
      self.updatePlayer(
        position: position, duration: duration, currentTime: time, remainingTime: remaining)
    }
  }

  nonisolated func mediaPlayerTrackAdded(
    _ trackId: String, withType trackType: VLCMedia.TrackType
  ) {
    refreshTracks()
  }

  nonisolated func mediaPlayerTrackRemoved(
    _ trackId: String, withType trackType: VLCMedia.TrackType
  ) {
    refreshTracks()
  }

  nonisolated func mediaPlayerTrackSelected(
    _ trackType: VLCMedia.TrackType, selectedId: String, unselectedId: String
  ) {
    refreshTracks()
  }

  private nonisolated func refreshTracks() {
    Task { @MainActor in
      self.updateAudioTracks()
      self.updateSubtitleTracks()
    }
  }
}
