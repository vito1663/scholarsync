import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: searchBar
    property string searchText: ""
    property bool isActive: false
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusSm
        color: theme.bg2
        border.color: searchField.activeFocus ? theme.accent : theme.bg4
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: "⌕"
                color: theme.textMuted
                font.pixelSize: 13
            }

            TextInput {
                id: searchField
                Layout.fillWidth: true
                color: theme.textPrimary
                font.pixelSize: theme.fontSm
                placeholderText: "在文档中搜索..."
                placeholderTextColor: theme.textMuted
                clip: true

                onTextChanged: {
                    searchBar.searchText = text
                    searchBar.isActive = text.length > 0
                }

                Keys.onEscapePressed: {
                    text = ""
                    focus = false
                }
            }

            // 搜索结果计数
            Text {
                text: searchBar.isActive ? "结果" : ""
                color: theme.textMuted
                font.pixelSize: 10
                visible: searchBar.isActive
            }

            // 清除
            Text {
                text: "✕"
                color: theme.textMuted
                font.pixelSize: 10
                visible: searchField.text.length > 0

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: searchField.text = ""
                }
            }
        }
    }
}
