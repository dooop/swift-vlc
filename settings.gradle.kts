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

        // Backs the sample app's "maven" flavor, which resolves the published
        // io.github.dooop:vlc-player artifact instead of the local project.
        // Requires a GitHub token with `read:packages` in ~/.gradle/gradle.properties
        // (gpr.user / gpr.key) or the GITHUB_ACTOR / GITHUB_TOKEN environment variables.
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/dooop/vlc-player")
            credentials {
                username =
                    providers.gradleProperty("gpr.user")
                        .orElse(providers.environmentVariable("GITHUB_ACTOR"))
                        .orNull
                password =
                    providers.gradleProperty("gpr.key")
                        .orElse(providers.environmentVariable("GITHUB_TOKEN"))
                        .orNull
            }
        }
    }
}

rootProject.name = "vlc-player"
include(":app")
project(":app").projectDir = file("android/app")
include(":vlc-player")
project(":vlc-player").projectDir = file("android/vlc-player")
