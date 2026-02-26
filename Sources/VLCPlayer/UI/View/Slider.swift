//
//  Slider.swift
//  swift-vlc
//
//  Created by Dominic Opitz on 02.06.24.
//

import SwiftUI

#if os(tvOS)
  import UIKit

  struct Slider: UIViewRepresentable {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onEditingChanged: ((Bool) -> Void)?

    init(
      value: Binding<Float>,
      in range: ClosedRange<Float> = 0...1,
      onEditingChanged: ((Bool) -> Void)? = nil
    ) {
      self._value = value
      self.range = range
      self.onEditingChanged = onEditingChanged
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UISliderView {
      let sliderView = UISliderView()
      sliderView.value = value
      sliderView.range = range
      sliderView.onEditingChanged = onEditingChanged
      sliderView.onValueChanged = { newValue in
        self.updateSlider(value: newValue)
      }
      return sliderView
    }

    func updateUIView(_ uiView: UISliderView, context: Context) {
      // Update only if the value really changed.
      if uiView.value != value {
        uiView.value = value
      }
    }

    // MARK: - Private

    private func updateSlider(value: Float) {
      if self.value != value {
        self.value = value
      }
    }
  }

  class UISliderView: UIView, UIGestureRecognizerDelegate {

    // MARK: - Public API

    var onValueChanged: ((Float) -> Void)?
    var onEditingChanged: ((Bool) -> Void)?
    var range: ClosedRange<Float> = 0...1

    var value: Float = 0 {
      didSet {
        updateSliderPosition()
        onValueChanged?(value)
      }
    }

    // MARK: - Private UI Elements

    private let thumbView = UIView()
    private let progressView = UIView()
    private let trackView = UIView()

    private let panRecognizer = UIPanGestureRecognizer()
    private var trackHeightConstraint: NSLayoutConstraint!
    private var progressHeightConstraint: NSLayoutConstraint!
    private var progressWidthConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupViews()
      setupAutoLayout()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
      // Track View
      trackView.backgroundColor = .darkGray
      addSubview(trackView)

      // Progress View
      // Replace `.accent` with your own color if needed
      progressView.backgroundColor = UIColor.tintColor
      addSubview(progressView)

      // Thumb View
      thumbView.backgroundColor = .white
      thumbView.layer.cornerRadius = 15
      thumbView.layer.borderWidth = 2
      thumbView.layer.borderColor = UIColor.black.cgColor
      thumbView.layer.shadowColor = UIColor.black.cgColor
      thumbView.layer.shadowOpacity = 0.5
      thumbView.layer.shadowOffset = CGSize(width: 0, height: 2)
      thumbView.layer.shadowRadius = 3
      thumbView.layer.opacity = 0
      addSubview(thumbView)
    }

    private func setupAutoLayout() {
      // Track View Constraints
      trackView.translatesAutoresizingMaskIntoConstraints = false
      trackHeightConstraint = trackView.heightAnchor.constraint(equalToConstant: 5)
      NSLayoutConstraint.activate([
        trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
        trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        trackHeightConstraint,
      ])

      // Progress View Constraints
      progressView.translatesAutoresizingMaskIntoConstraints = false
      progressHeightConstraint = progressView.heightAnchor.constraint(equalToConstant: 5)
      progressWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
      NSLayoutConstraint.activate([
        progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
        progressWidthConstraint,
        progressHeightConstraint,
      ])

      // Thumb View Constraints
      thumbView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
        thumbView.centerXAnchor.constraint(equalTo: progressView.trailingAnchor),
        thumbView.widthAnchor.constraint(equalToConstant: 30),
        thumbView.heightAnchor.constraint(equalToConstant: 30),
      ])
    }

    // MARK: - Focus Handling

    override var canBecomeFocused: Bool {
      return true
    }

    override func didUpdateFocus(
      in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator
    ) {
      super.didUpdateFocus(in: context, with: coordinator)

      if context.nextFocusedView == self {
        // Slider is gaining focus
        coordinator.addCoordinatedAnimations({
          self.thumbView.layer.opacity = 1
          self.trackHeightConstraint.constant = 10
          self.progressHeightConstraint.constant = 10
        })

        // Set up gesture recognizer only when in focus
        panRecognizer.addTarget(self, action: #selector(handlePan(_:)))
        panRecognizer.delegate = self
        addGestureRecognizer(panRecognizer)

      } else if context.previouslyFocusedView == self {
        // Slider is losing focus
        coordinator.addCoordinatedAnimations({
          self.thumbView.layer.opacity = 0
          self.trackHeightConstraint.constant = 5
          self.progressHeightConstraint.constant = 5
        })

        // Remove gesture recognizer
        panRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
        removeGestureRecognizer(panRecognizer)
      }
    }

    // MARK: - Gesture Recognizer Delegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
      let velocity = pan.velocity(in: self)
      // Only start pan if horizontal velocity is dominant over vertical
      return abs(velocity.x) > abs(velocity.y)
    }

    // MARK: - Pan Gesture Handling

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
      let translation = gesture.translation(in: self)

      // Calculate how much the user has moved (in slider coordinate space)
      let deltaValue =
        Float(translation.x / trackView.frame.width) * (range.upperBound - range.lowerBound)

      // Clamp value inside our range
      let newValue = max(range.lowerBound, min(range.upperBound, value + deltaValue))

      switch gesture.state {
      case .began:
        onEditingChanged?(true)
      case .ended, .failed, .cancelled:
        onEditingChanged?(false)
      case .changed:
        value = newValue
        // Reset translation so next call is relative
        gesture.setTranslation(.zero, in: self)
      default:
        break
      }
    }

    // MARK: - Layout

    override func layoutSubviews() {
      super.layoutSubviews()
      updateSliderPosition()
    }

    // MARK: - Slider Update

    private func updateSliderPosition() {
      guard trackView.frame.width > 0 else { return }

      let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
      let newWidth = CGFloat(normalizedValue) * trackView.frame.width

      // Disable implicit animations for performance/smoothness
      CATransaction.setDisableActions(true)
      progressWidthConstraint.constant = newWidth
      layer.layoutIfNeeded()
    }
  }
#endif

#Preview {
  @Previewable @State var value: Float = 0.42
  Slider(value: $value)
}
