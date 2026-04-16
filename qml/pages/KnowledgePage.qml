import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: theme.bg1

    Component.onCompleted: {
        if (ragflowClient.isConfigured)
            kbManager.loadKnowledgeBases()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── 顶部工具栏 ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: theme.bg1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                Text {
                    text: "知识库"
                    color: theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                // 连接状态
                Rectangle {
                    width: statusRow.width + 16
                    height: 26
                    radius: 13
                    color: ragflowClient.isConfigured
                           ? Qt.rgba(0.19, 0.82, 0.35, 0.12)
                           : Qt.rgba(1, 0.62, 0.04, 0.12)

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6; height: 6
                            radius: 3
                            color: ragflowClient.isConfigured ? theme.success : theme.warning
                        }

                        Text {
                            text: ragflowClient.isConfigured ? "RAGFlow 已连接" : "未配置 API"
                            color: ragflowClient.isConfigured ? theme.success : theme.warning
                            font.pixelSize: 11
                        }
                    }
                }

                // 刷新
                KbToolBtn {
                    icon: "↻"
                    tooltip: "刷新知识库列表"
                    visible: ragflowClient.isConfigured
                    onClicked: kbManager.loadKnowledgeBases()
                }

                // 新建知识库
                Rectangle {
                    width: 110; height: 32
                    radius: theme.radiusMd
                    color: createBtn.containsMouse ? theme.accentHover : theme.accent
                    visible: ragflowClient.isConfigured

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text { text: "+"; color: "white"; font.pixelSize: 16; font.bold: true }
                        Text { text: "新建知识库"; color: "white"; font.pixelSize: 12 }
                    }

                    MouseArea {
                        id: createBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: createKbDialog.open()
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

        // ── 未配置提示 ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !ragflowClient.isConfigured

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🔑"
                    font.pixelSize: 48
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "请先在设置中配置 RAGFlow API Key"
                    color: theme.textMuted
                    font.pixelSize: 14
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140; height: 36
                    radius: theme.radiusMd
                    color: goSettingsBtn.containsMouse ? theme.accentHover : theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "前往设置"
                        color: "white"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: goSettingsBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appState.currentPage = 3
                    }
                }
            }
        }

        // ── 加载中 ─────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: ragflowClient.isConfigured && kbManager.isLoading

            Column {
                anchors.centerIn: parent
                spacing: 12

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "正在加载知识库..."
                    color: theme.textMuted
                    font.pixelSize: 13
                }
            }
        }

        // ── 知识库列表 ─────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: ragflowClient.isConfigured && !kbManager.isLoading
            clip: true

            Flow {
                width: parent.width
                padding: 20
                spacing: 16

                Repeater {
                    model: kbManager.knowledgeBases

                    delegate: KbCard {
                        kbData: modelData
                    }
                }

                // 空状态
                Item {
                    width: parent.width - 40
                    height: 200
                    visible: kbManager.knowledgeBases.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🧠"
                            font.pixelSize: 40
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "还没有知识库\n点击「新建知识库」开始创建"
                            color: theme.textMuted
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    // ── 知识库卡片组件 ─────────────────────────────────────────────
    component KbCard: Rectangle {
        property var kbData: ({})
        width: 260; height: 160
        radius: theme.radiusLg
        color: cardMouse.containsMouse ? theme.bg3 : theme.bg2
        border.color: theme.bg4
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // 图标 + 名称
            RowLayout {
                spacing: 10

                Rectangle {
                    width: 36; height: 36
                    radius: 8
                    color: theme.accentDim

                    Text {
                        anchors.centerIn: parent
                        text: "🧠"
                        font.pixelSize: 18
                    }
                }

                Column {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: kbData.name || "未命名知识库"
                        color: theme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: kbData.embedding_model || "默认模型"
                        color: theme.textMuted
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            // 统计信息
            RowLayout {
                spacing: 0
                Layout.fillWidth: true

                KbStat { label: "文档"; value: kbData.document_count || 0 }
                Rectangle { width: 1; height: 24; color: theme.bg4 }
                KbStat { label: "片段"; value: kbData.chunk_count || 0 }
                Rectangle { width: 1; height: 24; color: theme.bg4 }
                KbStat { label: "词数"; value: formatCount(kbData.token_num || 0) }
            }

            Item { Layout.fillHeight: true }

            // 底部操作
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // 同步文件夹
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: theme.radiusSm
                    color: syncFolderBtn.containsMouse ? theme.bg4 : theme.bg3

                    Text {
                        anchors.centerIn: parent
                        text: "同步文件夹"
                        color: theme.textSecondary
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: syncFolderBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: syncFolderDialog.open(kbData.id)
                    }
                }

                // AI 问答
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: theme.radiusSm
                    color: chatKbBtn.containsMouse ? theme.accentHover : theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "AI 问答"
                        color: "white"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: chatKbBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            chatDialog.kbId = kbData.id
                            chatDialog.kbName = kbData.name
                            chatDialog.open()
                        }
                    }
                }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            z: -1
        }
    }

    // 统计数字组件
    component KbStat: Item {
        property string label: ""
        property var value: 0
        Layout.fillWidth: true
        height: 36

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value.toString()
                color: theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: theme.textMuted
                font.pixelSize: 10
            }
        }
    }

    // 工具按钮组件
    component KbToolBtn: Item {
        property string icon: ""
        property string tooltip: ""
        signal clicked()

        width: 32; height: 32

        Rectangle {
            anchors.fill: parent
            radius: theme.radiusSm
            color: kbBtnMouse.containsMouse ? theme.bg3 : "transparent"
        }

        Text {
            anchors.centerIn: parent
            text: icon
            font.pixelSize: 15
            color: theme.textSecondary
        }

        MouseArea {
            id: kbBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        ToolTip.visible: kbBtnMouse.containsMouse && tooltip !== ""
        ToolTip.text: tooltip
        ToolTip.delay: 600
    }

    // 辅助函数
    function formatCount(n) {
        if (n >= 10000) return (n / 10000).toFixed(1) + "w"
        if (n >= 1000) return (n / 1000).toFixed(1) + "k"
        return n.toString()
    }

    // ── 对话框 ─────────────────────────────────────────────────────
    // 新建知识库对话框
    Dialog {
        id: createKbDialog
        title: "新建知识库"
        modal: true
        anchors.centerIn: parent
        width: 360

        background: Rectangle {
            color: theme.bg2
            radius: theme.radiusLg
            border.color: theme.bg4
            border.width: 1
        }

        header: Rectangle {
            height: 48
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "新建知识库"
                color: theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.Medium
            }
        }

        contentItem: Column {
            spacing: 12
            padding: 20

            Text {
                text: "知识库名称"
                color: theme.textSecondary
                font.pixelSize: 12
            }

            Rectangle {
                width: parent.width - 40
                height: 36
                radius: theme.radiusSm
                color: theme.bg1
                border.color: kbNameInput.activeFocus ? theme.accent : theme.bg4
                border.width: 1

                TextInput {
                    id: kbNameInput
                    anchors.fill: parent
                    anchors.margins: 8
                    color: theme.textPrimary
                    font.pixelSize: 13
                    placeholderText: "例如：机器学习论文集"
                    placeholderTextColor: theme.textMuted
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
                color: cancelKbBtn.containsMouse ? theme.bg3 : theme.bg1
                border.color: theme.bg4
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "取消"
                    color: theme.textSecondary
                    font.pixelSize: 13
                }

                MouseArea {
                    id: cancelKbBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: createKbDialog.close()
                }
            }

            Rectangle {
                width: 80; height: 32
                radius: theme.radiusSm
                color: confirmKbBtn.containsMouse ? theme.accentHover : theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "创建"
                    color: "white"
                    font.pixelSize: 13
                }

                MouseArea {
                    id: confirmKbBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (kbNameInput.text.trim() !== "") {
                            kbManager.createKnowledgeBase(kbNameInput.text.trim())
                            kbNameInput.text = ""
                            createKbDialog.close()
                        }
                    }
                }
            }
        }
    }

    // 同步文件夹对话框
    Dialog {
        id: syncFolderDialog
        property string targetKbId: ""
        modal: true
        anchors.centerIn: parent
        width: 400

        function open(kbId) {
            targetKbId = kbId
            visible = true
        }

        background: Rectangle {
            color: theme.bg2
            radius: theme.radiusLg
            border.color: theme.bg4
            border.width: 1
        }

        contentItem: Column {
            spacing: 12
            padding: 20

            Text {
                text: "选择要同步到此知识库的文件夹"
                color: theme.textSecondary
                font.pixelSize: 13
            }

            Repeater {
                model: libraryManager.folders

                delegate: Rectangle {
                    width: 360
                    height: 44
                    radius: theme.radiusSm
                    color: folderSyncMouse.containsMouse ? theme.bg3 : theme.bg1
                    border.color: theme.bg4
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text { text: "📁"; font.pixelSize: 16 }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name || "未命名"
                                color: theme.textPrimary
                                font.pixelSize: 13
                            }

                            Text {
                                text: (modelData.paperCount || 0) + " 篇文献"
                                color: theme.textMuted
                                font.pixelSize: 10
                            }
                        }

                        Rectangle {
                            width: 60; height: 26
                            radius: theme.radiusSm
                            color: syncNowBtn.containsMouse ? theme.accentHover : theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "同步"
                                color: "white"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: syncNowBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    kbManager.syncFolderToKb(modelData.id, syncFolderDialog.targetKbId)
                                    syncFolderDialog.close()
                                    appState.statusMessage = "正在同步文件夹到知识库..."
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: folderSyncMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        z: -1
                    }
                }
            }
        }

        footer: Item {
            height: 16
        }
    }

    // AI 问答对话框（全屏知识库问答）
    Dialog {
        id: chatDialog
        property string kbId: ""
        property string kbName: ""
        modal: true
        anchors.centerIn: parent
        width: 700
        height: 560

        background: Rectangle {
            color: theme.bg1
            radius: theme.radiusLg
            border.color: theme.bg4
            border.width: 1
        }

        header: Rectangle {
            height: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 12

                Text {
                    text: "知识库问答：" + chatDialog.kbName
                    color: theme.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 28; height: 28
                    radius: 4
                    color: closeChatBtn.containsMouse ? theme.bg3 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: theme.textSecondary
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: closeChatBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chatDialog.close()
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

        contentItem: ColumnLayout {
            spacing: 0

            // 对话区域
            ScrollView {
                id: kbChatScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Column {
                    id: kbChatHistory
                    width: kbChatScroll.width
                    spacing: 12
                    padding: 16

                    Repeater {
                        id: kbChatMessages
                        model: []

                        delegate: Item {
                            width: kbChatHistory.width - 32
                            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                            height: kbBubble.implicitHeight + 8

                            Rectangle {
                                id: kbBubble
                                anchors.right: modelData.isUser ? parent.right : undefined
                                anchors.left: modelData.isUser ? undefined : parent.left
                                width: Math.min(parent.width * 0.82, implicitWidth + 24)
                                implicitHeight: kbBubbleText.implicitHeight + 20
                                radius: theme.radiusMd
                                color: modelData.isUser ? theme.accentDim : theme.bg2
                                border.color: modelData.isUser ? theme.accent : theme.bg4
                                border.width: 1

                                Text {
                                    id: kbBubbleText
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    text: modelData.text
                                    color: theme.textPrimary
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            // 输入区
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: theme.bg0

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: theme.bg4
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: theme.radiusMd
                        color: theme.bg2
                        border.color: kbChatInput.activeFocus ? theme.accent : theme.bg4
                        border.width: 1

                        TextInput {
                            id: kbChatInput
                            anchors.fill: parent
                            anchors.margins: 10
                            color: theme.textPrimary
                            font.pixelSize: 13
                            placeholderText: "向知识库提问... (Enter 发送)"
                            placeholderTextColor: theme.textMuted
                            clip: true

                            Keys.onReturnPressed: sendKbMessage()
                        }
                    }

                    Rectangle {
                        width: 38; height: 38
                        radius: theme.radiusMd
                        color: kbSendBtn.containsMouse ? theme.accentHover : theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: kbSendBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sendKbMessage()
                        }
                    }
                }
            }
        }

        function sendKbMessage() {
            var text = kbChatInput.text.trim()
            if (!text) return

            var messages = kbChatMessages.model.slice()
            messages.push({ isUser: true, text: text })
            kbChatMessages.model = messages
            kbChatInput.text = ""
            appState.statusMessage = "正在查询知识库..."

            // TODO: 调用 RAGFlow 问答 API
        }
    }
}
