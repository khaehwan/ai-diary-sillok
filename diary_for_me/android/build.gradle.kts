allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        // 문제가 되는 isar_flutter_libs 모듈을 찾습니다.
        if (name == "isar_flutter_libs") {
            // 안드로이드 설정을 가져옵니다.
            val android = extensions.findByName("android")
            if (android != null) {
                // namespace 속성이 비어있으면 강제로 주입합니다.
                // (Reflection을 사용하여 타입 참조 오류를 방지합니다)
                try {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "dev.isar.isar_flutter_libs")
                    println("✅ [Fix] isar_flutter_libs namespace forced successfully.")
                } catch (e: Exception) {
                    println("⚠️ [Fix] Failed to set namespace for isar_flutter_libs: ${e.message}")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
