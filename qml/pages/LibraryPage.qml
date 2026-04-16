import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: theme.bg1

    // 搜索结果或当前文件夹文献
    property var displayPapers: appState.isSearchMode
        ? libraryManager.searchPapers(appState.searchQuery)
        : libraryManager.currentPapers

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── 顶部工具栏 ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: theme.bg1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                // 标题
                Text {
                    text: appState.isSearchMode
                          ? "搜索: \"" + appState.searchQuery + "\""
                          : (appState.selectedFolderId < 0 ? "全部文献" : getFolderName())
                    color: theme.textPrimary
                    font.pixelSize: theme.fontXl
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                // 文献数量
                Text {
                    text: displayPapers.length + " 篇"
                    color: theme.textMuted
                    font.pixelSize: theme.fontMd
                }

                // 刷新按钮
                ToolButton2 {
                    icon: "↻"
                    tooltip: "刷新"
                    onClicked: libraryManager.refreshCurrentFolder()
                }

                // 扫描文件夹
                ToolButton2 {
                    icon: "⟳"
                    tooltip: "重新扫描文件夹"
                    visible: appState.selectedFolderId >= 0
                    onClicked: libraryManager.scanFolder(appState.selectedFolderId)
                }

                // 视图切换
                ToolButton2 {
                    id: viewToggle
                    icon: isGridView ? "☰" : "⊞"
                    tooltip: isGridView ? "列表视图" : "网格视图"
                    property bool isGridView: false
                    onClicked: isGridView = !isGridView
                }
            }

            // 底部分割线
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: theme.bg4
            }
        }

        // ── 空状态提示 ────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: displayPapers.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: appState.selectedFolderId < 0 ? "📂" : "📄"
                    font.pixelSize: 48
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: appState.isSearchMode
                          ? "未找到相关文献"
                          : (appState.selectedFolderId < 0
                             ? "请在左侧选择或添加文件夹"
                             : "此文件夹暂无文献\n将 PDF 文件放入文件夹后点击扫描")
                    color: theme.textMuted
                    font.pixelSize: theme.fontMd
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140; height: 36
                    radius: theme.radiusMd
                    color: theme.accent
                    visible: appState.selectedFolderId >= 0 && !appState.isSearchMode

                    Text {
                        anchors.centerIn: parent
                        text: "扫描文件夹"
                        color: "white"
                        font.pixelSize: theme.fontMd
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: libraryManager.scanFolder(appState.selectedFolderId)
                    }
                }
            }
        }

        // ── 文献列表 ──────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: displayPapers.length > 0
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: paperList
                width: parent.width
                model: displayPapers
                spacing: 1
                clip: true

                delegate: PaperListItem {
                    width: paperList.width
                    paperData: modelData
                }
            }
        }
    }

    // 辅助函数
    function getFolderName() {
        var folders = libraryManager.folders
        for (var i = 0; i < folders.length; i++) {
            if (folders[i].id === appState.selectedFolderId)
                return folders[i].name
        }
        return "文献库"
    }

    // ── 内部组件：文献列表项 ──────────────────────────────────────
    component PaperListItem: Item {
        property var paperData: ({})
        height: 72

        Rectangle {
            anchors.fill: parent
            color: itemMouse.containsMouse ? theme.bg3 : theme.bg1

            // 选中高亮
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                color: theme.accent
                visible: appState.selectedPaperId === paperData.id
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                spacing: 14

                // PDF 图标
                Rectangle {
                    width: 40; height: 52
                    radius: 4
                    color: theme.bg2
                    border.color: theme.bg4
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "PDF"
                            color: theme.accent
                            font.pixelSize: 9
                            font.bold: true
                        }

                        // 阅读进度条
                        Rectangle {
                            width: 28; height: 3
                            radius: 2
                            color: theme.bg4

                            Rectangle {
                                width: parent.width * (paperData.readProgress || 0)
                                height: parent.height
                                radius: 2
                                color: theme.accent
                            }
                        }
                    }
                }

                // 文献信息
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    Text {
                        text: paperData.title || "未知标题"
                        color: theme.textPrimary
                        font.pixelSize: theme.fontMd
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: 1
                    }

                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true

                        Text {
                            text: paperData.authors || "未知作者"
                            color: theme.textSecondary
                            font.pixelSize: theme.fontSm
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: paperData.year > 0 ? paperData.year : ""
                            color: theme.textMuted
                            font.pixelSize: theme.fontSm
                            visible: paperData.year > 0
                        }
                    }

                    RowLayout {
                        spacing: 6

                        Text {
                            text: paperData.journal || ""
                            color: theme.textMuted
                            font.pixelSize: theme.fontSm
                            font.italic: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: paperData.journal !== ""
                        }

                        // 同步状态标签
                        Rectangle {
                            width: syncLabel.width + 10
                            height: 16
                            radius: 8
                            color: paperData.isSynced ? Qt.rgba(0.19, 0.82, 0.35, 0.15) : Qt.rgba(1,1,1,0.05)
                            visible: true

                            Text {
                                id: syncLabel
                                anchors.centerIn: parent
                                text: paperData.isSynced ? "已同步" : "未同步"
                                color: paperData.isSynced ? theme.synced : theme.textMuted
                                font.pixelSize: 9
                            }
                        }
                    }
                }

                // 操作按钮（悬停显示）
                RowLayout {
                    spacing: 4
                    visible: itemMouse.containsMouse

                    ToolButton2 {
                        icon: "📖"
                        tooltip: "打开阅读"
                        onClicked: openPaper(paperData)
                    }
                }
            }

            // 底部分割线
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                height: 1
                color: theme.bg4
            }
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                appState.selectedPaperId = paperData.id
            }
            onDoubleClicked: {
                openPaper(paperData)
            }
        }
    }

    function openPaper(paper) {
        appState.selectedPaperId = paper.id
        appState.selectedPaperPath = paper.filePath || paper.file_path || ""
        appState.selectedPaperTitle = paper.title || "未知标题"
        appState.currentPage = 1
    }

    // ── 内部组件：工具按钮 ────────────────────────────────────────
    component ToolButton2: Item {
        property string icon: ""
        property string tooltip: ""
        signal clicked()

        width: 32; height: 32

        Rectangle {
            anchors.fill: parent
            radius: theme.radiusSm
            color: btnMouse.containsMouse ? theme.bg3 : "transparent"
        }

        Text {
            anchors.centerIn: parent
            text: icon
            font.pixelSize: 15
            color: theme.textSecondary
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        ToolTip.visible: btnMouse.containsMouse && tooltip !== ""
        ToolTip.text: tooltip
        ToolTip.delay: 600
    }
}
