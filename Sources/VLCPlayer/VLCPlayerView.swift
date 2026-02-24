//
//  VLCPlayerView.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 24.02.26.
//

import SwiftUI

#if os(iOS)
  import MobileVLCKit
#elseif os(tvOS)
  import TVVLCKit
#elseif os(macOS)
  import VLCKit
#endif

#if os(macOS)
  public struct VLCPlayerView: NSViewControllerRepresentable {
    public let player: VLCMediaPlayer

    public init(player: VLCMediaPlayer) {
      self.player = player
    }

    public func makeNSViewController(context: Context) -> NSViewController {
      let viewController = NSViewController()
      player.drawable = viewController.view
      return viewController
    }

    public func updateNSViewController(_ viewController: NSViewController, context: Context) {
      player.drawable = viewController.view
    }
  }
#else
  public struct VLCPlayerView: UIViewControllerRepresentable {
    public let player: VLCMediaPlayer

    public init(player: VLCMediaPlayer) {
      self.player = player
    }

    public func makeUIViewController(context: Context) -> UIViewController {
      let viewController = UIViewController()
      player.drawable = viewController.view
      return viewController
    }

    public func updateUIViewController(_ viewController: UIViewController, context: Context) {
      player.drawable = viewController.view
    }
  }
#endif

#Preview {
  VLCPlayerView(player: VLCMediaPlayer())
}
