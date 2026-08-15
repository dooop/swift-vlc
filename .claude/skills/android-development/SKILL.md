---
name: android-development
description: Implement or review VLC Player Android library and sample-app changes using Kotlin, Jetpack Compose, and LibVLC. Use for files under android/, root Gradle configuration, Compose UI/state/lifecycle work, LibVLC controller changes, Android resources, dependencies, API levels, or AAR behavior.
---

# Develop the Android player

Read `android/README.md`, then identify whether the change belongs to the reusable
`android/vlc-player` library or the `android/app` sample. Keep reusable behavior out of the sample.

## Architecture

- Preserve `org.videolan.vlcplayer.VLCPlayer` as the public Compose entry point.
- Keep LibVLC/media-player ownership and callbacks in `VLCPlayerController`; expose Compose-friendly
  state rather than native objects.
- Construct and dispose native resources through Compose lifecycle-aware effects. Ensure each
  player/controller is released exactly once when its URL or composition lifetime changes.
- Keep activity lifecycle, saved playback position, screen-on state, track selection, control
  auto-hide, and subtitle scale consistent when changing player behavior.
- Avoid storing Activity, Context, View, or Composable references in long-lived objects. Use an
  application context where LibVLC requires a context.
- Keep expensive/native work out of recomposition and avoid launching duplicate collectors or
  timers when the composable recomposes.

## Project conventions

- JDK/JVM target: 17. Minimum SDK: 23. Compile and target SDK: 37.
- Keep versions and aliases in `gradle/libs.versions.toml`.
- Use `api` only for dependencies whose types or Compose constraints are part of the library's
  consumer surface; otherwise use `implementation`.
- Keep library resources in `android/vlc-player/src/main/res` and sample resources in
  `android/app/src/main/res`.
- Never hard-code user-facing text. Use `add-android-localized-string`.
- Add local JVM tests under `android/vlc-player/src/test`. Use instrumentation tests only when the
  behavior truly requires Android runtime/device integration.
- Maintain min-SDK compatibility; guard newer platform APIs or use AndroidX compatibility APIs.

## Workflow

1. Inspect the public composable, controller, relevant resources, Gradle module, and existing tests.
2. Make the smallest library/sample-scoped change that preserves lifecycle ownership.
3. Add or update deterministic tests for pure state/time/conversion behavior.
4. Run `verify-android`; also run `verify-build` if root/shared release or CI configuration changed.
5. Update `android/README.md` when public API, setup, dependency, artifact, or command behavior changes.

Do not publish an AAR, change release tags, or widen the public API unless the request includes it.
