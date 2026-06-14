// android/build.gradle.kts
// ─────────────────────────────────────────────────────────────────────────────
// ROOT GRADLE KOTLIN DSL — HIGH COMPATIBILITY NOVA BUILD PROFILE
// ─────────────────────────────────────────────────────────────────────────────

plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral() // ✅ Fixed unresolved reference syntax error
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Fix missing namespaces in older plugins during build evaluation
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null && android is com.android.build.gradle.BaseExtension) {
            if (android.namespace == null) {
                android.namespace = project.group.toString().replace("-", ".")
            }
        }
    }

    // ✅ FIX: Force JVM 17 on ALL subprojects including on_audio_query_android
    plugins.withId("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }

    // ✅ FIX: Force Java 17 toolchain on all subprojects
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}