cmake_minimum_required(VERSION 3.22)
project(ScholarSync VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

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

# 收集源文件
set(SOURCES
    src/main.cpp
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

qt_add_qml_module(ScholarSync
    URI ScholarSync
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/components/SideBar.qml
        qml/components/SearchBar.qml
        qml/components/AddFolderDialog.qml
        qml/pages/LibraryPage.qml
        qml/pages/PdfReaderPage.qml
        qml/pages/KnowledgePage.qml
        qml/pages/SettingsPage.qml
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

# 设置应用信息
set_target_properties(ScholarSync PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.scholarsync.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)
