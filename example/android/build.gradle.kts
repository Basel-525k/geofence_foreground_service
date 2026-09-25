buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set the root project build directory.
val newBuildDir = file("../build")
rootProject.layout.buildDirectory.set(newBuildDir)

// Set each subproject's build directory inside the shared build folder.
subprojects {
    val subBuildDir = File(newBuildDir, project.name)
    project.layout.buildDirectory.set(subBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
