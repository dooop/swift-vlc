//
//  VLC.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 24.02.26.
//

#if os(tvOS)
  @_exported import TVVLCKit
#elseif os(iOS) && !targetEnvironment(macCatalyst)
  @_exported import MobileVLCKit
#elseif os(macOS)
  @_exported import VLCKit
#endif
