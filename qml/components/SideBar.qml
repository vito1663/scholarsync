import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: sidebar
    color: theme.bg0

    // 右侧细分割线
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: theme.bg4
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Logo 区域 ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: appState.sidebarCollapsed ? 0 : 16
                anchors.rightMargin: 8
                spacing: 10

                // Logo 图标
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: theme.accent
                    Layout.alignment: Qt.AlignVCenter
                    anchors.leftMargin: appState.sidebarCollapsed ? 14 : 0

                    Text {
                        anchors.centerIn: parent
                        text: "S"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                Text {
                    text: "ScholarSync"
                    color: theme.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    visible: !appState.sidebarCollapsed
                    Layout.fillWidth: true
                }

                // 折叠按钮
                Item {
                    width: 28; height: 28
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: collapseBtn.containsMouse ? theme.bg3 : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: appState.sidebarCollapsed ? "›" : "‹"
                        color: theme.textSecondary
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: collapseBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.sidebarCollapsed = !appState.sidebarCollapsed
                    }
                }
            }
        }

        // 分割线
        Rectangle { Layout.fillWidth: true; height: 1; color: theme.bg4 }

        // ── 搜索框 ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 8
            height: 32
            radius: theme.radiusSm
            color: theme.bg2
            border.color: searchInput.activeFocus ? theme.accent : theme.bg4
            border.width: 1
            visible: !appState.sidebarCollapsed

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "⌕"
                    color: theme.textMuted
                    font.pixelSize: 14
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: theme.textPrimary
                    font.pixelSize: theme.fontMd
                    placeholderText: "搜索文献..."
                    placeholderTextColor: theme.textMuted
                    clip: true

                    onTextChanged: {
                        appState.searchQuery = text
                        appState.isSearchMode = text.length > 0
                    }

                    Keys.onEscapePressed: {
                        text = ""
                        focus = false
                    }
                }

                Text {
                    text: "✕"
                    color: theme.textMuted
                    font.pixelSize: 11
                    visible: searchInput.text.length > 0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }

        // ── 主导航 ────────────────────────────────────────────────
        NavItem {
            icon: "📚"; label: "文献库"
            pageIndex: 0
            shortcut: "L"
        }
        NavItem {
            icon: "📖"; label: "PDF 阅读"
            pageIndex: 1
            shortcut: "R"
            enabled: appState.selectedPaperPath !== ""
        }
        NavItem {
            icon: "🧠"; label: "知识库"
            pageIndex: 2
            shortcut: "K"
        }

        // ── 文件夹列表 ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            height: 28
            color: "transparent"
            visible: !appState.sidebarCollapsed

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                spacing: 0

                Text {
                    text: "文件夹"
                    color: theme.textMuted
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    font.capitalization: Font.AllUppercase
                    Layout.fillWidth: true
                }

                // 添加文件夹按钮
                Item {
                    width: 24; height: 24

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: addFolderBtn.containsMouse ? theme.bg3 : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: theme.textSecondary
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: addFolderBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addFolderDialog.open()
                    }
                }
            }
        }

        // 文件夹列表
        ListView {
            id: folderList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 280)
            clip: true
            model: libraryManager.folders
            visible: !appState.sidebarCollapsed

            delegate: FolderItem {
                width: folderList.width
                folderData: modelData
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        // 弹性空间
        Item { Layout.fillHeight: true }

        // ── 底部：设置 ────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: theme.bg4 }

        NavItem {
            icon: "⚙"; label: "设置"
            pageIndex: 3
            shortcut: "S"
        }
    }

    // ── 添加文件夹对话框 ──────────────────────────────────────────
    AddFolderDialog {
        id: addFolderDialog
    }

    // ── 内部组件：导航项 ──────────────────────────────────────────
    component NavItem: Item {
        property string icon: ""
        property string label: ""
        property int pageIndex: 0
        property string shortcut: ""
        property bool enabled: true

        width: parent.width
        height: 40

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            radius: theme.radiusSm
            color: appState.currentPage === pageIndex
                   ? theme.accentDim
                   : (navMouse.containsMouse ? theme.bg3 : "transparent")
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: appState.sidebarCollapsed ? 0 : 12
            spacing: 10

            Text {
                text: icon
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
                anchors.leftMargin: appState.sidebarCollapsed ? 20 : 0
                opacity: enabled ? 1.0 : 0.4
                horizontalAlignment: appState.sidebarCollapsed ? Text.AlignHCenter : Text.AlignLeft
                Layout.preferredWidth: appState.sidebarCollapsed ? parent.width : -1
            }

            Text {
                text: label
                color: appState.currentPage === pageIndex ? theme.accent : theme.textSecondary
                font.pixelSize: theme.fontMd
                font.weight: appState.currentPage === pageIndex ? Font.Medium : Font.Normal
                visible: !appState.sidebarCollapsed
                opacity: enabled ? 1.0 : 0.4
                Layout.fillWidth: true
            }
        }

        // 左侧选中指示条
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 20
            radius: 2
            color: theme.accent
            visible: appState.currentPage === pageIndex
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: parent.enabled
            onClicked: {
                appState.currentPage = pageIndex
            }
        }

        ToolTip.visible: appState.sidebarCollapsed && navMouse.containsMouse
        ToolTip.text: label
        ToolTip.delay: 500
    }

    // ── 内部组件：文件夹项 ────────────────────────────────────────
    component FolderItem: Item {
        property var folderData: ({})
        height: 36

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            radius: theme.radiusSm
            color: appState.selectedFolderId === folderData.id
                   ? theme.accentDim
                   : (folderMouse.containsMouse ? theme.bg3 : "transparent")
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: folderData.syncToKb ? "🔵" : "📁"
                font.pixelSize: 13
            }

            Text {
                text: folderData.name || "未命名"
                color: appState.selectedFolderId === folderData.id
                       ? theme.accent : theme.textSecondary
                font.pixelSize: theme.fontMd
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: folderData.paperCount || "0"
                color: theme.textMuted
                font.pixelSize: theme.fontSm
            }
        }

        MouseArea {
            id: folderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                appState.selectedFolderId = folderData.id
                libraryManager.currentFolderId = folderData.id
                appState.currentPage = 0
                appState.isSearchMode = false
            }
        }
    }
}
