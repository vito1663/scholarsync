import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "ScholarSync"

    // ── 全局颜色主题 ──────────────────────────────────────────────
    QtObject {
        id: theme
        readonly property color bg0:       "#0F1117"
        readonly property color bg1:       "#161B27"
        readonly property color bg2:       "#1E2435"
        readonly property color bg3:       "#252D42"
        readonly property color bg4:       "#2E3850"

        readonly property color textPrimary:   "#E8EAF0"
        readonly property color textSecondary: "#8B92A8"
        readonly property color textMuted:     "#555E75"

        readonly property color accent:        "#4F8EF7"
        readonly property color accentHover:   "#6BA3FF"
        readonly property color accentDim:     "#1E3A6E"

        readonly property color success:  "#34C759"
        readonly property color warning:  "#FF9F0A"
        readonly property color danger:   "#FF453A"
        readonly property color synced:   "#30D158"

        readonly property int fontSm:  11
        readonly property int fontMd:  13
        readonly property int fontLg:  15
        readonly property int fontXl:  18

        readonly property int radiusSm: 4
        readonly property int radiusMd: 8
        readonly property int radiusLg: 12
    }

    // ── 全局状态 ──────────────────────────────────────────────────
    QtObject {
        id: appState
        property int currentPage: 0
        property int selectedFolderId: -1
        property int selectedPaperId: -1
        property string selectedPaperPath: ""
        property string selectedPaperTitle: ""
        property bool sidebarCollapsed: false
        property string searchQuery: ""
        property string statusMessage: ""
        property bool isSearchMode: false
    }

    // 背景
    color: theme.bg1

    // ── 主布局 ────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: 24
        spacing: 0

        SideBar {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: appState.sidebarCollapsed ? 56 : 220
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: theme.bg1

            StackLayout {
                anchors.fill: parent
                currentIndex: appState.currentPage

                LibraryPage  { id: libraryPage }
                PdfReaderPage { id: pdfPage }
                KnowledgePage { id: knowledgePage }
                SettingsPage  { id: settingsPage }
            }
        }
    }

    // ── 状态栏 ────────────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 24
        color: theme.bg0
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 16

            Text {
                text: appState.statusMessage || "就绪"
                color: theme.textMuted
                font.pixelSize: theme.fontSm
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: "ScholarSync v1.0"
                color: theme.textMuted
                font.pixelSize: theme.fontSm
            }
        }
    }

    // ── 全局工具函数（供 QML 子页面调用）────────────────────────
    function saveSettingToDb(key, value) {
        dbManager.setSetting(key, value)
        appState.statusMessage = "设置已保存"
    }

    function getSettingFromDb(key, defaultVal) {
        return dbManager.getSetting(key, defaultVal)
    }

    // ── 初始化 ────────────────────────────────────────────────────
    Component.onCompleted: {
        syncManager.startWatching()
        syncManager.syncStatusChanged.connect(function(msg) {
            appState.statusMessage = msg
        })
        appState.statusMessage = "ScholarSync 已就绪"
    }
}
