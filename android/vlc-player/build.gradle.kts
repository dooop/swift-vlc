import org.gradle.api.publish.maven.MavenPublication
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ktlint)
    `maven-publish`
}

group = "io.github.dooop"
version = providers.gradleProperty("releaseVersion").getOrElse("0.0.0-SNAPSHOT")

android {
    namespace = "org.videolan.vlcplayer"
    compileSdk = 37

    defaultConfig {
        minSdk = 23
        consumerProguardFiles("consumer-rules.pro")
    }

    buildFeatures {
        compose = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    testOptions {
        unitTests.all {
            it.useJUnit()
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

ktlint {
    android.set(true)
}

dependencies {
    api(platform(libs.compose.bom))
    api(libs.compose.ui)
    api(libs.compose.foundation)
    api(libs.compose.material3)

    implementation(libs.compose.icons)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.libvlc)

    debugImplementation(libs.compose.tooling)
    testImplementation(libs.junit)
}

publishing {
    publications {
        register<MavenPublication>("release") {
            groupId = project.group.toString()
            artifactId = "vlc-player"
            version = project.version.toString()

            afterEvaluate {
                from(components["release"])
            }

            pom {
                name.set("VLC Player for Android")
                description.set("Jetpack Compose video player backed by LibVLC.")
                url.set("https://github.com/dooop/vlc-player")
                licenses {
                    license {
                        name.set("GNU Lesser General Public License v2.1")
                        url.set("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                        distribution.set("repo")
                    }
                }
                scm {
                    connection.set("scm:git:https://github.com/dooop/vlc-player.git")
                    developerConnection.set("scm:git:ssh://git@github.com/dooop/vlc-player.git")
                    url.set("https://github.com/dooop/vlc-player")
                }
            }
        }
    }

    repositories {
        maven {
            name = "ReleaseBundle"
            url = uri(layout.buildDirectory.dir("maven-repository"))
        }

        providers.environmentVariable("GITHUB_REPOSITORY").orNull?.let { repository ->
            maven {
                name = "GitHubPackages"
                url = uri("https://maven.pkg.github.com/$repository")
                credentials {
                    username = providers.environmentVariable("GITHUB_ACTOR").orNull
                    password = providers.environmentVariable("GITHUB_TOKEN").orNull
                }
            }
        }
    }
}
