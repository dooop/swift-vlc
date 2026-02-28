//
//  PlayerTrack.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 23.12.24.
//

import Foundation

struct PlayerTrack: Identifiable, Hashable {
  let index: Int32
  var id: Int32 { index }
  var name: String

  static var disable: PlayerTrack {
    return PlayerTrack(index: -1, name: "Disable")
  }
}
