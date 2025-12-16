import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase plugins
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.divyanshupatel.vitconnect"
    compileSdk = 36  // Required by mobile_scanner v7.1.3
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.divyanshupatel.vitconnect"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
    minSdk = 24  // Android 7 (API 24) - minimum target requested by developer
        targetSdk = flutter.targetSdkVersion
        
        // Auto-generate versionCode from semantic version to prevent Crashlytics duplicates
        // e.g. 1.0.0 → 10000, 1.0.1 → 10001, 1.2.3 → 10203
        val flutterVersionName = flutter.versionName ?: "1.0.0"
        versionName = flutterVersionName
        
        val parts = flutterVersionName.split(".")
        versionCode = if (parts.size == 3) {
            try {
                val major = parts[0].toInt()
                val minor = parts[1].toInt()
                val patch = parts[2].toInt()
                val autoCode = major * 10000 + minor * 100 + patch
                println("🚀 Auto-versioning: $flutterVersionName → versionCode $autoCode")
                autoCode
            } catch (e: NumberFormatException) {
                println("⚠️ Could not parse versionName, using flutter.versionCode")
                flutter.versionCode
            }
        } else {
            flutter.versionCode
        }
        
        // Vector drawable support for smaller APK
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { fileName ->
                file(fileName)
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Performance optimizations for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Use release signing config
            signingConfig = signingConfigs.getByName("release")
            
            // Additional optimizations
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
                // Keep only device ABIs to reduce APK/AAB size. Exclude x86/x86_64 (emulator-only).
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
            }
            
            // Firebase Crashlytics - make upload non-fatal to allow offline builds
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = true
                nativeSymbolUploadEnabled = true
                unstrippedNativeLibsDir = null
            }
        }
        
        debug {
            // Debug builds should not use minification
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
            
            // Explicitly specify ABIs for debug builds too
            ndk {
                // For local/emulator debugging you can add x86/x86_64 if you need, but keep CI/dev builds smaller.
                abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
            }
            
            // Firebase Crashlytics for debug
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }
        }
    }
    
    // Enable APK splits for smaller download sizes
    splits {
        abi {
            isEnable = true
            reset()
            // Limit ABI splits to device ABIs only to reduce artifacts size
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true  // Enable universal APK for development
        }
        density {
            isEnable = false  // Disable density splits for development
        }
    }
    
    // Optimize packaging
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module",
                "META-INF/*.properties",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "**/*.md",
                "**/*.txt",
                "**/*.pro",
                "DebugProbesKt.bin",
                "kotlin/**",
                "META-INF/com.android.tools/**",
                "META-INF/proguard/**",
                "okhttp3/**",
                "kotlin-tooling-metadata.json"
            )
        }
        jniLibs {
            useLegacyPackaging = false
            excludes += setOf(
                "**/libc++_shared.so"
            )
        }
    }
    
    // Bundle configuration for smaller downloads
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    
    // Firebase dependencies (versions managed by BoM)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-perf")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
}
