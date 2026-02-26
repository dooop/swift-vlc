//
//  PlayerControls.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 16.11.24.
//

import SwiftUI

struct PlayerControls: View {
  @ObservedObject var player: PlayerViewModel
  @Binding var editing: Bool
  @State private var position: Float = 0

  let onToggle: () -> Void
  let onRestart: () -> Void

  var body: some View {
    VStack {

      #if os(tvOS)
        Spacer()
      #endif
      Button(
        action: {
          switch player.state {
          case .finished, .error: onRestart()
          default: onToggle()
          }
        },
        label: {
          let icon =
            switch player.state {
            case .playing: "pause.fill"
            case .paused: "play.fill"
            case .finished: "arrow.trianglehead.clockwise"
            case .error: "exclamationmark.triangle.fill"
            default: player.playing ? "pause.fill" : "play.fill"
            }

          if player.state == .loading {
            ProgressView()
              #if !os(tvOS)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              #endif
          } else {
            Image(systemName: icon)
              .font(.largeTitle)
              .foregroundStyle(.white)
              #if !os(tvOS)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              #endif
          }
        }
      )
      #if os(macOS)
        .buttonStyle(PlainButtonStyle())
      #endif
      #if os(tvOS)
        Spacer()
      #endif

      HStack {
        Spacer()

        if !player.audioTracks.isEmpty {
          PlayerTrackButton(
            selection: $player.audio,
            tracks: $player.audioTracks,
            title: "Audio",
            message: "Change Audio Track",
            systemImage: "speaker.fill",
            onEditingChanged: editingChanged
          ) { track in
            player.changeAudio(track: track)
          }
        }

        if !player.subtitleTracks.isEmpty {
          PlayerTrackButton(
            selection: $player.subtitle,
            tracks: $player.subtitleTracks,
            title: "Subtitle",
            message: "Change Subtitle Track",
            systemImage: "text.bubble",
            onEditingChanged: editingChanged
          ) { track in
            player.changeSubtitle(track: track)
          }
        }
      }

      Slider(
        value: $position,
        in: 0...1,
        onEditingChanged: editingChanged
      )
      .frame(maxHeight: 42)

      HStack {
        Text("\(player.currentTime)")
        Spacer()
        Text("\(player.remainingTime)")
      }
      .font(.caption)
      .foregroundColor(.white)
    }
    .onChange(
      of: position,
      { oldValue, newValue in
        if player.position != newValue {
          player.seek(to: newValue)
        }
      }
    )
    .onReceive(player.$position) { newValue in
      if position != newValue {
        position = newValue
      }
    }
    .padding()
    .background(
      .black.opacity(0.6),
      ignoresSafeAreaEdges: .all
    )
  }

  private func editingChanged(_ editing: Bool) {
    self.editing = editing
  }
}

#Preview {
  PlayerControls(
    player: PlayerViewModel(),
    editing: .constant(false),
    onToggle: {},
    onRestart: {})
}
