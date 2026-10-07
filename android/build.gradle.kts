// android/build.gradle.kts  (project level)

import com.android.build.gradle.LibraryExtension
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// (optional) your custom buildDir relocation – keep if you use it
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

/* =======================================================================
   FIX for isar_flutter_libs on AGP 8+
   - Provide a namespace for the library
   - Strip deprecated package="..." from its AndroidManifest.xml
   ======================================================================= */
subprojects {
    if (name.contains("isar_flutter_libs")) {
        pluginManager.withPlugin("com.android.library") {
            // 1) Ensure namespace exists
            extensions.configure(LibraryExtension::class.java) {
                namespace = "dev.isar.isar_flutter_libs.patched"
            }

            // 2) Patch manifest: remove package="..."
            val originalManifest = file("src/main/AndroidManifest.xml")
            val patchedDir = layout.buildDirectory.dir("patchedManifest")
            val patchedManifest = patchedDir.map { it.file("AndroidManifest.xml") }

            val patchIsarManifest = tasks.register("patchIsarManifest") {
                inputs.file(originalManifest)
                outputs.file(patchedManifest)
                doLast {
                    patchedDir.get().asFile.mkdirs()
                    val cleaned = originalManifest.readText()
                        .replace(Regex("""\s+package\s*=\s*["'][^"']+["']"""), "")
                    patchedManifest.get().asFile.writeText(cleaned)
                }
            }

            // 3) Use the patched manifest
            extensions.configure(LibraryExtension::class.java) {
                sourceSets.getByName("main").manifest.srcFile(patchedManifest.get().asFile)
            }

            // 4) Only preBuild depends on the patch (avoids circular dependency)
            tasks.named("preBuild").configure {
                dependsOn(patchIsarManifest)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
