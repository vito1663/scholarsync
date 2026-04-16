cmake_minimum_required(VERSION 3.22)
project(ScholarSync VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Qt6 模块
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    QuickControls2
    Qml
    Network
    Sql
    Pdf
    PdfQuick
)

qt_standard_project_setup(REQUIRES 6.5)

# ============================================================
# src/qrc_qml.cpp 由构建前步骤（rcc 工具）生成
# - Linux/macOS: 开发者在本地运行 rcc 生成后提交（或 CI 生成）
# - Windows: GitHub Actions workflow 在 cmake 之前调用 rcc.exe 生成
# 这样确保每个平台使用自己的 Qt rcc 工具，符号名称完全匹配
# ============================================================
set(SOURCES
    src/main.cpp
    src/qrc_qml.cpp
    src/database/DatabaseManager.cpp
    src/library/LibraryManager.cpp
    src/library/FolderWatcher.cpp
    src/pdf/PdfController.cpp
    src/ragflow/RagflowClient.cpp
    src/ragflow/KnowledgeBaseManager.cpp
    src/sync/SyncManager.cpp
)

set(HEADERS
    src/database/DatabaseManager.h
    src/library/LibraryManager.h
    src/library/FolderWatcher.h
    src/pdf/PdfController.h
    src/ragflow/RagflowClient.h
    src/ragflow/KnowledgeBaseManager.h
    src/sync/SyncManager.h
)

qt_add_executable(ScholarSync
    ${SOURCES}
    ${HEADERS}
)

target_link_libraries(ScholarSync PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
    Qt6::Network
    Qt6::Sql
    Qt6::Pdf
    Qt6::PdfQuick
)

# Windows 隐藏控制台窗口（Release 版本）
if(WIN32)
    set_target_properties(ScholarSync PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

# macOS bundle
set_target_properties(ScholarSync PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.scholarsync.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
)

# 输出目录
set_target_properties(ScholarSync PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)
