pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "vlc-player"
include(":app")
project(":app").projectDir = file("android/app")
include(":vlc-player")
project(":vlc-player").projectDir = file("android/vlc-player")
