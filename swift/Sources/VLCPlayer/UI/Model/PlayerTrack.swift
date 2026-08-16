//
//  PlayerTrack.swift
//  vlc-player
//
//  Created by Dominic Opitz on 23.12.24.
//

import Foundation

struct PlayerTrack: Identifiable, Hashable {
  static let disabledId = "vlc-player.disabled"

  let id: String
  var name: String

  static var disable: PlayerTrack {
    PlayerTrack(id: disabledId, name: String(localized: .disable))
  }
}
