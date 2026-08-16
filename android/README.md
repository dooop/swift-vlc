# VLC Player for Android

The Android implementation is a Jetpack Compose library backed by LibVLC. It supports Android 6.0
(API 23) and newer and includes a runnable sample application.

## Modules

- `vlc-player/` — reusable Android library that produces an AAR
- `app/` — sample Compose app consuming `:vlc-player`
- Root `build.gradle.kts`, `settings.gradle.kts`, `gradle/`, and wrapper files — shared Gradle setup

Open the repository root in Android Studio so both modules and the version catalog resolve.

## Source-checkout dependency

```kotlin
dependencies {
    implementation(project(":vlc-player"))
}
```

## Compose usage

```kotlin
import android.net.Uri
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import org.videolan.vlcplayer.VLCPlayer

@Composable
fun PlayerScreen() {
    VLCPlayer(
        url = Uri.parse("https://example.com/video.mp4"),
        modifier = Modifier.fillMaxSize(),
    )
}
```

`VLCPlayer` owns and releases LibVLC internally. It includes playback, restart, seek, audio/subtitle
selection, five-second control auto-hide, per-URI playback-position persistence, screen-on handling,
and lifecycle behavior. Pass `subtitleScale` to change subtitle size from its default `100` percent.

## Maven dependency

Releases are published to GitHub Packages with Gradle module metadata and a POM, so transitive
Compose, lifecycle, and LibVLC dependencies are resolved automatically:

```kotlin
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("https://maven.pkg.github.com/dooop/vlc-player")
        credentials {
            username = providers.gradleProperty("gpr.user").orNull
            password = providers.gradleProperty("gpr.key").orNull
        }
    }
}

dependencies {
    implementation("io.github.dooop:vlc-player:0.4.0")
}
```

GitHub Packages requires authentication when resolving Maven packages. Put your GitHub username and
a classic personal access token with `read:packages` in the user-level `~/.gradle/gradle.properties`
(never commit them):

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_GITHUB_TOKEN
```

Every GitHub release also contains `vlc-player-maven-<version>.zip`, a self-contained Maven
repository for consumers that do not want to authenticate with GitHub Packages. Extract it and add
its directory with `maven { url = uri("path/to/repository") }`.

## Using the release AAR directly

GitHub releases contain `vlc-player-android-<version>.aar`. It is a thin AAR, so a consumer using
the file directly must also declare its runtime dependencies:

```kotlin
dependencies {
    implementation(files("libs/vlc-player-android-0.4.0.aar"))
    implementation(platform("androidx.compose:compose-bom:2026.08.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("org.videolan.android:libvlc-all:3.7.5")
}
```

Keep this example aligned with `gradle/libs.versions.toml` when dependencies change.

## Development and checks

Requirements are JDK 17 and Android SDK 37. Use the checked-in Gradle wrapper from the repository
root:

```bash
# Fast library test loop
./gradlew :vlc-player:testDebugUnitTest

# Library compilation and lint
./gradlew :vlc-player:assembleDebug :vlc-player:lintDebug

# Kotlin style check (ktlint)
./gradlew ktlintCheck

# Full local Android verification, including the sample and release AAR
./gradlew :app:assembleDebug :vlc-player:assembleRelease \
  :vlc-player:lintDebug :vlc-player:testDebugUnitTest ktlintCheck
```

Kotlin formatting is enforced by [ktlint](https://github.com/JLLeitschuh/ktlint-gradle) via
`ktlintCheck` in CI. Run `./gradlew ktlintFormat` locally to apply fixes.

The release AAR is written to `android/vlc-player/build/outputs/aar/vlc-player-release.aar`; the
sample APK is under `android/app/build/outputs/apk/debug/`.

To create the same Maven repository that is attached to a release, run:

```bash
./gradlew -PreleaseVersion=0.4.0 \
  :vlc-player:publishReleasePublicationToReleaseBundleRepository
```

The repository is written to `android/vlc-player/build/maven-repository/`.

## Localization

Library strings live in `vlc-player/src/main/res/values/strings.xml`, with translations in locale
directories such as `values-de/strings.xml`. Sample-only strings belong under `app/src/main/res/`.
Never hard-code user-facing text in Kotlin/Compose. Add every library key to the default resource
file first, translate it in each supported locale, reference it through `stringResource`, and run
lint plus unit tests.
