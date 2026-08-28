allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Forces every plugin module up to compileSdk 36.
//
// Pinning the app alone is not enough: the failure is `:file_picker` itself
// being compiled against android-34 while `flutter_plugin_android_lifecycle`
// demands 36, and a plugin module takes its compileSdk from the Flutter
// toolchain rather than from the app. The job seeker app carries the identical
// block for the identical reason — remove it and the release build fails on the
// AAR metadata check.
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
