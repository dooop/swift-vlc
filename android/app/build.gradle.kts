import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ktlint)
}

android {
    namespace = "org.videolan.vlcplayer.sample"
    compileSdk = 37

    defaultConfig {
        applicationId = "org.videolan.vlcplayer.sample"
        minSdk = 23
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }

    // Lets the sample app be built and installed against either the local
    // :vlc-player project or the published GitHub Packages artifact, to test
    // that Maven publishing produces a working, self-contained dependency.
    flavorDimensions += "source"
    productFlavors {
        create("local") {
            dimension = "source"
            buildConfigField("String", "DEPENDENCY_SOURCE", "\"project(:vlc-player)\"")
        }
        create("maven") {
            dimension = "source"
            applicationIdSuffix = ".maven"
            buildConfigField(
                "String",
                "DEPENDENCY_SOURCE",
                "\"io.github.dooop:vlc-player:${libs.versions.vlc.player.maven.get()}\"",
            )
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
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
    "localImplementation"(project(":vlc-player"))
    "mavenImplementation"(libs.vlc.player.maven)
    implementation(libs.activity.compose)
}
