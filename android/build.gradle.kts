import com.android.build.api.variant.AndroidComponentsExtension
import com.android.build.gradle.LibraryExtension
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val androidSdkDir = localProperties.getProperty("sdk.dir")?.replace("\\", "/")
val unityNdkVersion = "27.0.12077973"

allprojects {
    if (androidSdkDir != null) {
        extensions.extraProperties.apply {
            set("unity.androidSdkPath", androidSdkDir)
            set("unity.androidNdkPath", "$androidSdkDir/ndk/$unityNdkVersion")
            set("unity.androidNdkVersion", unityNdkVersion)
            set("unity.installInBuildFolder", "false")
        }
    }
    repositories {
        flatDir {
            dirs(
                file("${rootProject.projectDir}/unityLibrary/UnityExport/unityLibrary/libs"),
            )
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    if (project.name == "unityLibrary") {
        afterEvaluate {
            tasks.matching { it.name == "buildIl2Cpp" }.configureEach {
                val il2cppCompiler =
                    project.file(
                        "src/main/Il2CppOutputProject/IL2CPP/build/deploy/il2cpp.exe",
                    )
                onlyIf { il2cppCompiler.exists() }
            }
        }
    }

    // Align Flutter plugin modules to Java/Kotlin 17 before AGP locks compileOptions.
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<AndroidComponentsExtension<*, *, *>>("androidComponents") {
            finalizeDsl {
                extensions.configure<LibraryExtension>("android") {
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }
        }
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}
