//
//  PlayerTrackButton.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 16.11.24.
//

import SwiftUI

struct PlayerTrackButton: View {
  @State private var showOptions = false
  @Binding var selection: PlayerTrack
  @Binding var tracks: [PlayerTrack]
  let title: LocalizedStringResource
  let message: LocalizedStringResource
  let systemImage: String

  var onEditingChanged: ((Bool) -> Void)?
  var onChange: ((PlayerTrack) -> Void)?

  var body: some View {
    Button(
      action: {
        showOptions = true
        onEditingChanged?(true)
      },
      label: {
        Image(systemName: systemImage)
          .font(.headline)
          .foregroundStyle(.white)
          .accessibilityLabel(title)
      }
    )
    .confirmationDialog(title, isPresented: $showOptions) {
      ForEach($tracks) { track in
        Button(track.name.wrappedValue) {
          let track = track.wrappedValue
          selection = track
          onChange?(track)
          showOptions = false
          onEditingChanged?(false)
        }
      }

      Button(.cancel, role: .cancel) {
        showOptions = false
        onEditingChanged?(false)
      }
    } message: {
      Text(message)
    }
  }
}

#Preview {
  @Previewable @State var selection = PlayerTrack.disable

  PlayerTrackButton(
    selection: $selection,
    tracks: .constant([.disable, PlayerTrack(index: 0, name: "English")]),
    title: .audio,
    message: .changeAudioTrack,
    systemImage: "speaker.fill"
  ).background(.black)
}
