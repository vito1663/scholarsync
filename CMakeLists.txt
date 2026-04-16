cmake_minimum_required(VERSION 3.22)
project(ScholarSync VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
# 注意：不使用 CMAKE_AUTORCC，改用 add_custom_command 显式调用 rcc
# 这样可以确保 rcc 使用与当前 Qt 版本完全匹配的工具生成 qrc_qml.cpp

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
# 用 add_custom_command 在编译前调用平台对应的 rcc 生成 qrc_qml.cpp
# 这是最可靠的跨平台方式，确保符号名称与当前 Qt 版本完全匹配
# ============================================================
set(QRC_OUTPUT "${CMAKE_BINARY_DIR}/qrc_qml.cpp")

# 获取 Qt 的 rcc 工具路径
get_target_property(QT_RCC_EXECUTABLE Qt6::rcc IMPORTED_LOCATION)
if(NOT QT_RCC_EXECUTABLE)
    find_program(QT_RCC_EXECUTABLE rcc HINTS "${Qt6_DIR}/../../../bin" "${Qt6_DIR}/../../../../bin")
endif()
message(STATUS "Qt rcc tool: ${QT_RCC_EXECUTABLE}")

add_custom_command(
    OUTPUT "${QRC_OUTPUT}"
    COMMAND "${QT_RCC_EXECUTABLE}"
            --name qml_resources
            "${CMAKE_SOURCE_DIR}/qml.qrc"
            -o "${QRC_OUTPUT}"
    DEPENDS "${CMAKE_SOURCE_DIR}/qml.qrc"
            "${CMAKE_SOURCE_DIR}/qml/main.qml"
            "${CMAKE_SOURCE_DIR}/qml/components/SideBar.qml"
            "${CMAKE_SOURCE_DIR}/qml/components/SearchBar.qml"
            "${CMAKE_SOURCE_DIR}/qml/components/AddFolderDialog.qml"
            "${CMAKE_SOURCE_DIR}/qml/pages/LibraryPage.qml"
            "${CMAKE_SOURCE_DIR}/qml/pages/PdfReaderPage.qml"
            "${CMAKE_SOURCE_DIR}/qml/pages/KnowledgePage.qml"
            "${CMAKE_SOURCE_DIR}/qml/pages/SettingsPage.qml"
    COMMENT "Generating QML resources with rcc..."
    VERBATIM
)

# 收集源文件
set(SOURCES
    src/main.cpp
    "${QRC_OUTPUT}"                 # 由当前平台 rcc 在编译时生成
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
