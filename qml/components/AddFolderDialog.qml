import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog {
    id: addFolderDialog
    modal: true
    anchors.centerIn: Overlay.overlay
    width: 420

    background: Rectangle {
        color: theme.bg2
        radius: theme.radiusLg
        border.color: theme.bg4
        border.width: 1
    }

    header: Rectangle {
        height: 52
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 12

            Text {
                text: "添加文件夹"
                color: theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28; height: 28
                radius: 4
                color: closeDialogBtn.containsMouse ? theme.bg3 : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: theme.textSecondary
                    font.pixelSize: 13
                }

                MouseArea {
                    id: closeDialogBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: addFolderDialog.close()
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.bg4
        }
    }

    contentItem: Column {
        spacing: 16
        padding: 20

        // 文件夹名称
        Column {
            width: parent.width - 40
            spacing: 6

            Text {
                text: "文件夹名称"
                color: theme.textSecondary
                font.pixelSize: 12
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: theme.radiusSm
                color: theme.bg1
                border.color: folderNameInput.activeFocus ? theme.accent : theme.bg4
                border.width: 1

                TextInput {
                    id: folderNameInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: theme.textPrimary
                    font.pixelSize: 13
                    placeholderText: "例如：机器学习论文"
                    placeholderTextColor: theme.textMuted
                    clip: true
                }
            }
        }

        // 文件夹路径
        Column {
            width: parent.width - 40
            spacing: 6

            Text {
                text: "文件夹路径"
                color: theme.textSecondary
                font.pixelSize: 12
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: theme.radiusSm
                    color: theme.bg1
                    border.color: folderPathInput.activeFocus ? theme.accent : theme.bg4
                    border.width: 1

                    TextInput {
                        id: folderPathInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: theme.textPrimary
                        font.pixelSize: 13
                        placeholderText: "/path/to/papers"
                        placeholderTextColor: theme.textMuted
                        clip: true

                        onTextChanged: {
                            // 自动填充文件夹名称
                            if (folderNameInput.text === "" && text !== "") {
                                var parts = text.split("/")
                                var lastName = parts[parts.length - 1]
                                if (lastName) folderNameInput.text = lastName
                            }
                        }
                    }
                }

                Rectangle {
                    width: 80; height: 36
                    radius: theme.radiusSm
                    color: browseBtn.containsMouse ? theme.bg4 : theme.bg3
                    border.color: theme.bg4
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "浏览..."
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: browseBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: folderChooser.open()
                    }
                }
            }
        }

        // 同步到知识库选项
        Rectangle {
            width: parent.width - 40
            height: 48
            radius: theme.radiusSm
            color: theme.bg1
            border.color: theme.bg4
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "同步为知识库"
                        color: theme.textPrimary
                        font.pixelSize: 13
                    }

                    Text {
                        text: "将此文件夹的 PDF 自动上传到 RAGFlow 知识库"
                        color: theme.textMuted
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: 44; height: 24
                    radius: 12
                    color: syncToggle.checked ? theme.accent : theme.bg4

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        width: 18; height: 18
                        radius: 9
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        x: syncToggle.checked ? parent.width - width - 3 : 3

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        id: syncToggle
                        property bool checked: false
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: checked = !checked
                    }
                }
            }
        }
    }

    footer: RowLayout {
        spacing: 8
        padding: 16

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 80; height: 32
            radius: theme.radiusSm
            color: cancelAddBtn.containsMouse ? theme.bg3 : theme.bg1
            border.color: theme.bg4
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "取消"
                color: theme.textSecondary
                font.pixelSize: 13
            }

            MouseArea {
                id: cancelAddBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: addFolderDialog.close()
            }
        }

        Rectangle {
            width: 80; height: 32
            radius: theme.radiusSm
            color: confirmAddBtn.containsMouse ? theme.accentHover : theme.accent
            enabled: folderPathInput.text.trim() !== ""
            opacity: enabled ? 1.0 : 0.5

            Text {
                anchors.centerIn: parent
                text: "添加"
                color: "white"
                font.pixelSize: 13
            }

            MouseArea {
                id: confirmAddBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var name = folderNameInput.text.trim()
                    var path = folderPathInput.text.trim()
                    if (path !== "") {
                        if (name === "") {
                            var parts = path.split("/")
                            name = parts[parts.length - 1] || path
                        }
                        libraryManager.addFolder(name, path)
                        folderNameInput.text = ""
                        folderPathInput.text = ""
                        syncToggle.checked = false
                        addFolderDialog.close()
                    }
                }
            }
        }
    }

    // 文件夹选择器
    FolderDialog {
        id: folderChooser
        title: "选择文件夹"
        onAccepted: {
            var path = selectedFolder.toString().replace("file://", "")
            folderPathInput.text = path
        }
    }
}
