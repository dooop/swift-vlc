//
//  PlayerViewModel.swift
//  vlc-player
//
//  Created by Dominic Opitz on 01.06.24.
//

import SwiftUI
import VLC

private struct PlayerProgress {
  var position: Float = 0
  var duration: Int32 = 0
  var currentTime = ""
  var remainingTime = ""
}

@MainActor
class PlayerViewModel: NSObject, ObservableObject {
  private var url: URL?
  private var positions: [String: Float] = [:]

  @AppStorage("vlcPlayerPositions") private var positionsData: Data = Data()
  @AppStorage("vlcPlayerSubTitleScale") private var subTitleScale: Int = 100

  @Published private(set) var vlcPlayer: VLCMediaPlayer? = nil
  @Published private(set) var state = PlayerState.loading
  @Published private(set) var playing = false
  @Published private var progress = PlayerProgress()
  @Published var audio: PlayerTrack = .disable
  @Published var audioTracks: [PlayerTrack] = []
  @Published var subtitle: PlayerTrack = .disable
  @Published var subtitleTracks: [PlayerTrack] = []

  var currentTime: String { progress.currentTime }
  var remainingTime: String { progress.remainingTime }
  var duration: Int32 { progress.duration }
  var position: Float { progress.position }

  func load(media url: URL) {
    self.url = url
    vlcPlayer = VLCMediaPlayer(options: ["--sub-text-scale=\(subTitleScale)"])
    vlcPlayer?.delegate = self
    vlcPlayer?.media = VLCMedia(url: url)
    if let positions = try? JSONDecoder().decode([String: Float].self, from: positionsData) {
      self.positions = positions
      progress.position = positions[url.path()] ?? 0
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
    vlcPlayer?.position = position
    var updatedProgress = progress
    updatedProgress.position = position
    updatedProgress.currentTime = VLCTime(int: Int32(position * Float(duration))).stringValue
    progress = updatedProgress
  }

  func changeAudio(track: PlayerTrack) {
    vlcPlayer?.currentAudioTrackIndex = track.index
  }

  func changeSubtitle(track: PlayerTrack) {
    vlcPlayer?.currentVideoSubTitleIndex = track.index
  }

  private func updatePlayer(state: VLCMediaPlayerState, playing: Bool) {
    self.playing = playing

    switch state {
    case .playing:
      self.state = .playing
    case .paused:
      self.state = .paused
    case .stopped:
      self.state = .finished
    case .ended:
      self.state = .finished
    case .opening:
      self.state = .loading
    case .buffering:
      self.state = playing ? .playing : .loading
    case .esAdded:
      updateAudioTracks()
      updateSubtitleTracks()
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
    progress = PlayerProgress(
      position: position,
      duration: duration,
      currentTime: currentTime,
      remainingTime: remainingTime
    )
  }

  private func updateAudioTracks() {
    let tracks = tracksBy(
      names: vlcPlayer?.audioTrackNames ?? [],
      indexes: vlcPlayer?.audioTrackIndexes ?? [])
    audio = tracks.first(where: { $0.index == vlcPlayer?.currentAudioTrackIndex }) ?? .disable
    audioTracks = tracks
  }

  private func updateSubtitleTracks() {
    let tracks = tracksBy(
      names: vlcPlayer?.videoSubTitlesNames ?? [],
      indexes: vlcPlayer?.videoSubTitlesIndexes ?? [])
    subtitle =
      tracks.first(where: { $0.index == vlcPlayer?.currentVideoSubTitleIndex }) ?? .disable
    subtitleTracks = tracks
  }

  func tracksBy(names: [Any], indexes: [Any]) -> [PlayerTrack] {
    guard names.count == indexes.count else {
      return []
    }

    var tracks: [PlayerTrack] = []
    for (index, track) in indexes.enumerated() {
      if let trackIndex = track as? Int32,
        let trackName = names[index] as? String
      {
        tracks.append(PlayerTrack(index: trackIndex, name: trackName))
      }
    }
    return tracks
  }
}

extension PlayerViewModel: VLCMediaPlayerDelegate {
  nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
    guard let player = aNotification.object as? VLCMediaPlayer else {
      return
    }

    let state = player.state
    let playing = player.isPlaying

    Task { @MainActor in
      self.updatePlayer(state: state, playing: playing)
    }
  }

  nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
    guard let player = aNotification.object as? VLCMediaPlayer else {
      return
    }

    let position = player.position
    let duration = player.media?.length.intValue ?? 0
    let time = player.time.stringValue
    let remaining = (player.remainingTime ?? VLCTime()).stringValue

    Task { @MainActor in
      self.updatePlayer(
        position: position, duration: duration, currentTime: time, remainingTime: remaining)
    }
  }
}
