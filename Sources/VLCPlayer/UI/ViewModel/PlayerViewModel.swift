//
//  PlayerViewModel.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 01.06.24.
//

import Foundation
import SwiftUI

#if os(iOS)
  import MobileVLCKit
#elseif os(tvOS)
  import TVVLCKit
#elseif os(macOS)
  import VLCKit
#endif

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
    vlcPlayer?.position = position
    currentTime = VLCTime(int: Int32(position * Float(self.duration))).stringValue
  }

  func changeAudio(track: PlayerTrack) {
    vlcPlayer?.currentAudioTrackIndex = track.index
  }

  func changeSubtitle(track: PlayerTrack) {
    //Log.player.debug("change subtitle to \(track.name)")
    vlcPlayer?.currentVideoSubTitleIndex = track.index
  }

  private func updatePlayer(state: VLCMediaPlayerState, playing: Bool) {
    self.playing = playing

    switch state {
    case .playing:
      //Log.player.debug("vlc state: playing")
      self.state = .playing
    case .paused:
      //Log.player.debug("vlc state: paused")
      self.state = .paused
    case .stopped:
      //Log.player.debug("vlc state: stopped")
      self.state = .finished
    case .ended:
      //Log.player.debug("vlc state: ended")
      self.state = .finished
    case .opening:
      //Log.player.debug("vlc state: opening")
      self.state = .loading
    case .buffering:
      //Log.player.debug("vlc state: buffering")
      self.state = playing ? .playing : .loading
    case .esAdded:
      //Log.player.debug("vlc state: esAdded")
      updateAudioTracks()
      updateSubtitleTracks()
    case .error:
      //Log.player.debug("vlc state: error")
      self.state = .error
    @unknown default: break
    //Log.player.debug("vlc state: unknown")
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

  private func tracksBy(names: [Any], indexes: [Any]) -> [PlayerTrack] {
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
