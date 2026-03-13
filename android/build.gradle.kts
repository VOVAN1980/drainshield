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
    afterEvaluate {
        val extension = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        extension?.apply {
            compileSdkVersion(35)
            defaultConfig {
                minSdk = 24
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core") {
                useVersion("1.15.0")
            }
            if (requested.group == "androidx.browser") {
                useVersion("1.8.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
