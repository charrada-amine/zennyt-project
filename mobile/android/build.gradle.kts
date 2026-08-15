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

// ─────────────────────────────────────────────────────────────────────────
// ⚠️ FIX bug connu agora_rtc_engine (6.5.x) : son propre android/build.gradle
// fige compileSdkVersion=31, ce qui casse checkDebugAarMetadata avec les
// dépendances AndroidX modernes (androidx.fragment, androidx.activity, etc.
// qui exigent compileSdk >= 34). Voir :
// https://github.com/AgoraIO-Extensions/Agora-Flutter-SDK/issues/2498
//
// On force donc le compileSdk sur TOUS les sous-projets Android du build,
// quel que soit ce que leur propre build.gradle déclare. Ce callback DOIT
// être enregistré AVANT la ligne evaluationDependsOn(":app") ci-dessous,
// sinon Gradle force l'évaluation de ":app" en premier et refuse ensuite
// d'y attacher un afterEvaluate ("project already evaluated").
// ─────────────────────────────────────────────────────────────────────────
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            when (ext) {
                is com.android.build.gradle.LibraryExtension -> {
                    ext.compileSdkVersion(36)
                    ext.compileOptions {
                        sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17
                        targetCompatibility = org.gradle.api.JavaVersion.VERSION_17
                    }
                }
                is com.android.build.gradle.AppExtension -> {
                    ext.compileSdkVersion(36)
                    ext.compileOptions {
                        sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17
                        targetCompatibility = org.gradle.api.JavaVersion.VERSION_17
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ─────────────────────────────────────────────────────────────────────────
// ⚠️ FIX : "Inconsistent JVM Target Compatibility Between Java and Kotlin
// Tasks" (ex: photo_manager compile son Kotlin en JVM 21 alors que l'app
// force Java 17). Certains plugins tiers n'héritent pas de la config JVM
// de l'app hôte et se rabattent sur le JDK par défaut détecté sur la
// machine (souvent 21 si tu as un JDK récent installé).
//
// On force donc TOUTES les tâches Kotlin ET Java de TOUS les sous-projets
// à cibler JVM 17, pour que ça matche exactement compileOptions/kotlin{}
// définis dans app/build.gradle.kts. tasks.withType(...).configureEach{}
// est "lazy" (n'exige pas que le projet soit déjà évalué), donc pas de
// souci d'ordre comme avec afterEvaluate.
// ─────────────────────────────────────────────────────────────────────────
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}