allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure build directory redirection using canonicalized absolute paths to avoid Windows path bugs.
val newBuildDir: File = file("${rootProject.projectDir}/../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: File = file("${newBuildDir}/${project.name}")
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
