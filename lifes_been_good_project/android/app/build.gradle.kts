plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.androidfreeman.lifesbeengood"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.androidfreeman.lifesbeengood"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        externalNativeBuild {
            cmake {
                targets.addAll(
                    listOf(
                        "campus_cli",
                        "system_init",
                        "profiles_list",
                        "students_list",
                        "students_insert",
                        "students_delete",
                        "students_get",
                        "courses_list",
                        "courses_insert",
                        "timetable_list",
                        "timetable_insert",
                        "contacts_list",
                        "todos_list",
                        "todos_add",
                        "todos_toggle",
                        "attendance_session_start",
                        "attendance_record_mark",
                        "csv_op",
                        "json_op",
                    )
                )
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}

flutter {
    source = "../.."
}

val nativeBinNames = listOf(
    "campus_cli",
    "system_init",
    "profiles_list",
    "students_list",
    "students_insert",
    "students_delete",
    "students_get",
    "courses_list",
    "courses_insert",
    "timetable_list",
    "timetable_insert",
    "contacts_list",
    "todos_list",
    "todos_add",
    "todos_toggle",
    "attendance_session_start",
    "attendance_record_mark",
    "csv_op",
    "json_op",
)

fun registerSyncNativeBinsTask(variant: String) {
    val taskName = "syncNativeBins$variant"
    tasks.register(taskName) {
        val intermediatesDir = file("$buildDir/intermediates")
        val outDir = file("src/main/jniLibs")

        doLast {
            if (!intermediatesDir.exists()) return@doLast
            val v = variant.lowercase()
            val objDir = intermediatesDir.walkTopDown().firstOrNull {
                it.isDirectory && it.name == "obj" && it.path.lowercase().contains("${File.separator}$v${File.separator}")
            } ?: return@doLast

            val abiDirs = objDir.listFiles()?.filter { it.isDirectory } ?: emptyList()
            for (abiDir in abiDirs) {
                val abiOutDir = file("${outDir.path}/${abiDir.name}")
                abiOutDir.mkdirs()
                for (name in nativeBinNames) {
                    val src = File(abiDir, name)
                    if (!src.exists()) continue
                    val dest = File(abiOutDir, "lib${name}.so")
                    src.copyTo(dest, overwrite = true)
                }
            }
        }
    }

    tasks.matching { it.name == "merge${variant}Assets" }.configureEach {
        dependsOn(taskName)
    }
    tasks.matching { it.name == "externalNativeBuild$variant" }.configureEach {
        tasks.named(taskName).configure { dependsOn(this@configureEach) }
    }
}

afterEvaluate {
    registerSyncNativeBinsTask("Debug")
    registerSyncNativeBinsTask("Release")
}
