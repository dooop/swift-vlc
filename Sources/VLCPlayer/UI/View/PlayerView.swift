//
//  PlayerView.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 24.02.26.
//

import SwiftUI
import VLC

#if os(macOS)
  struct PlayerView: NSViewControllerRepresentable {
    let vlc: VLCMediaPlayer

    init(vlc: VLCMediaPlayer) {
      self.vlc = vlc
    }

    func makeNSViewController(context: Context) -> NSViewController {
      let viewController = NSViewController()
      vlc.drawable = viewController.view
      return viewController
    }

    func updateNSViewController(_ viewController: NSViewController, context: Context) {
      vlc.drawable = viewController.view
    }
  }
#else
  struct PlayerView: UIViewControllerRepresentable {
    let vlc: VLCMediaPlayer

    init(vlc: VLCMediaPlayer) {
      self.vlc = vlc
    }

    func makeUIViewController(context: Context) -> UIViewController {
      let viewController = UIViewController()
      vlc.drawable = viewController.view
      return viewController
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
      vlc.drawable = viewController.view
    }
  }
#endif

#Preview {
  let vlc = VLCMediaPlayer()
  PlayerView(vlc: vlc)
    .onAppear {
      vlc.media = VLCMedia(
        url: URL(
          string:
            "https://test-videos.co.uk/vids/bigbuckbunny/mkv/1080/Big_Buck_Bunny_1080_10s_1MB.mkv")!
      )
      vlc.play()
    }.onDisappear {
      vlc.stop()
    }
}
