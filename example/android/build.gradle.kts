// Kotlin and Android Gradle Plugin versions are declared in settings.gradle.kts
// (org.jetbrains.kotlin.android and com.android.application).

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Put Gradle outputs under `<Flutter project>/build/` so Flutter tools find
// `build/app/outputs/flutter-apk/*.apk` (see flutter_tools getApkDirectory).
val newBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    project.layout.buildDirectory.set(newBuildDir.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
