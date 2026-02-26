//
//  VLCPlayer.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 01.06.24.
//

import SwiftUI

public struct VLCPlayer: View {
  private let url: URL

  @StateObject private var viewModel = PlayerViewModel()
  @State private var toolbarVisibility = Visibility.automatic
  @State private var timer = Timer.publish(
    every: 5,
    on: .main,
    in: .common
  ).autoconnect()
  @State private var editing: Bool = false
  @State private var showControls = true
  @Environment(\.scenePhase) private var phase

  public init(url: URL) {
    self.url = url
  }

  public var body: some View {
    ZStack {
      if let vlcPlayer = viewModel.vlcPlayer {
        PlayerView(vlc: vlcPlayer)
          .ignoresSafeArea(.all)
          .background(ignoresSafeAreaEdges: .all)
          .toolbarVisibility(toolbarVisibility, for: .automatic)
      }
      if showControls {
        PlayerControls(
          player: viewModel,
          editing: $editing,
          onToggle: togglePlaying,
          onRestart: restartPlayer)
      } else {
        toggle
      }
    }
    #if os(iOS)
      .statusBarHidden()
    #endif
    .onAppear {
      startPlayer()
      disableSleepTimerOrCursor(true)
    }
    .onDisappear {
      stopPlayer()
      disableSleepTimerOrCursor(false)
    }
    .onChange(of: phase) {
      switch phase {
      case .inactive: stopPlayer()
      case .active: startPlayer()
      default: break
      }
    }
    .onReceive(timer) { _ in
      animateControls(false)
    }
    .onChange(of: editing) {
      editing ? viewModel.pause() : viewModel.play()
    }
    .onChange(of: viewModel.state) {
      switch viewModel.state {
      case .playing:
        restartTimer()
      case .paused, .error, .finished:
        animateControls(true)
        cancelTimer()
      default: break
      }
    }
    #if os(tvOS)
      .onPlayPauseCommand {
        togglePlaying()
      }
      .onMoveCommand { move in
        animateControls(true)
        if viewModel.playing {
          restartTimer()
        } else {
          cancelTimer()
        }
      }
    #elseif os(macOS)
      .onTapGesture {
        togglePlaying()
      }
      .onKeyPress(.space) {
        togglePlaying()
        return .handled
      }
    #endif
  }

  private func startPlayer(position: Float? = nil) {
    animateControls(true)
    viewModel.load(media: url)
    viewModel.play()
    viewModel.seek(to: position ?? viewModel.position)
  }

  private func restartPlayer() {
    startPlayer(position: 0.0)
  }

  private func stopPlayer() {
    viewModel.stop()
    viewModel.reset()
  }

  private func togglePlaying() {
    animateControls(true)
    switch viewModel.state {
    case .finished:
      restartPlayer()
      restartTimer()
    case .playing:
      viewModel.pause()
      cancelTimer()
    default:
      viewModel.play()
      restartTimer()
    }
  }

  private func cancelTimer() {
    timer.upstream.connect().cancel()
  }

  private func restartTimer() {
    cancelTimer()
    timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
  }

  private func animateControls(_ visible: Bool) {
    disableSleepTimerOrCursor(!visible)
    withAnimation {
      showControls = visible
      toolbarVisibility = visible ? .automatic : .hidden
    }
  }

  private func disableSleepTimerOrCursor(_ disabled: Bool = true) {
    #if canImport(UIKit)
      UIApplication.shared.isIdleTimerDisabled = disabled
    #elseif os(macOS)
      NSCursor.setHiddenUntilMouseMoves(disabled)
    #endif
  }

  private var toggle: some View {
    return Button(
      action: {
        togglePlaying()
      },
      label: {
        Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    )
    #if os(tvOS)
      .opacity(0)
    #elseif os(macOS)
      .buttonStyle(PlainButtonStyle())
    #endif
  }
}

#Preview {
  VLCPlayer(
    url: URL(
      string:
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    )!
  )
}
