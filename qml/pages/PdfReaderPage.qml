import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Pdf

Rectangle {
    id: pdfReaderPage
    color: theme.bg1

    // PDF 文档对象
    PdfDocument {
        id: pdfDoc
        source: appState.selectedPaperPath !== "" ? "file://" + appState.selectedPaperPath : ""
        onStatusChanged: {
            if (status === PdfDocument.Ready) {
                appState.statusMessage = "已加载: " + appState.selectedPaperTitle
                    + "  共 " + pageCount + " 页"
                // 恢复上次阅读位置
                if (appState.selectedPaperId > 0) {
                    var paper = libraryManager.getPaper(appState.selectedPaperId)
                    if (paper.lastReadPage > 0)
                        pdfView.goToPage(paper.lastReadPage)
                }
            } else if (status === PdfDocument.Error) {
                appState.statusMessage = "PDF 加载失败"
            }
        }
    }

    // 搜索模型
    PdfSearchModel {
        id: searchModel
        document: pdfDoc
        searchString: searchBar.searchText
    }

    // 书签模型
    PdfBookmarkModel {
        id: bookmarkModel
        document: pdfDoc
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── 左侧面板（目录/缩略图/注释）────────────────────────────
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: leftPanelVisible ? 220 : 0
            visible: leftPanelVisible
            color: theme.bg0
            clip: true

            property bool leftPanelVisible: true

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // 右侧分割线
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: theme.bg4
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.rightMargin: 1
                spacing: 0

                // 标签切换
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: theme.bg0

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: ["目录", "缩略图", "注释"]
                            delegate: Item {
                                Layout.fillWidth: true
                                height: 40

                                Rectangle {
                                    anchors.fill: parent
                                    color: leftTabs.currentIndex === index
                                           ? theme.bg1 : "transparent"
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 2
                                    color: theme.accent
                                    visible: leftTabs.currentIndex === index
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: leftTabs.currentIndex === index
                                           ? theme.textPrimary : theme.textMuted
                                    font.pixelSize: theme.fontSm
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftTabs.currentIndex = index
                                }
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

                QtObject { id: leftTabs; property int currentIndex: 0 }

                // 目录
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: leftTabs.currentIndex === 0
                    clip: true

                    TreeView {
                        id: tocView
                        model: bookmarkModel
                        anchors.fill: parent

                        delegate: Item {
                            implicitWidth: tocView.width
                            implicitHeight: 32

                            Rectangle {
                                anchors.fill: parent
                                color: tocMouse.containsMouse ? theme.bg3 : "transparent"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 12 + depth * 12
                                text: model.title || ""
                                color: theme.textSecondary
                                font.pixelSize: theme.fontSm
                                elide: Text.ElideRight
                                width: parent.width - anchors.leftMargin - 8
                            }

                            MouseArea {
                                id: tocMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (model.page !== undefined)
                                        pdfView.goToPage(model.page)
                                }
                            }
                        }
                    }
                }

                // 缩略图
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: leftTabs.currentIndex === 1
                    clip: true

                    ListView {
                        id: thumbnailList
                        model: pdfDoc.pageCount
                        spacing: 8

                        delegate: Item {
                            width: thumbnailList.width
                            height: 160

                            Rectangle {
                                anchors.centerIn: parent
                                width: 120; height: 150
                                color: theme.bg2
                                border.color: pdfView.currentPage === index
                                              ? theme.accent : theme.bg4
                                border.width: pdfView.currentPage === index ? 2 : 1
                                radius: 4

                                PdfPageImage {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    document: pdfDoc
                                    currentPage: index
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 4
                                    text: index + 1
                                    color: theme.textMuted
                                    font.pixelSize: theme.fontSm
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pdfView.goToPage(index)
                                }
                            }
                        }
                    }
                }

                // 注释列表
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: leftTabs.currentIndex === 2
                    clip: true

                    ListView {
                        model: pdfController.annotations
                        spacing: 4

                        delegate: Rectangle {
                            width: parent ? parent.width - 16 : 0
                            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                            height: annContent.implicitHeight + 16
                            radius: theme.radiusSm
                            color: theme.bg2
                            border.color: theme.bg4
                            border.width: 1

                            Column {
                                id: annContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                Text {
                                    text: "第 " + (modelData.page + 1) + " 页"
                                    color: theme.textMuted
                                    font.pixelSize: theme.fontSm
                                }

                                Text {
                                    text: modelData.selectedText || modelData.content || ""
                                    color: theme.textSecondary
                                    font.pixelSize: theme.fontSm
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pdfView.goToPage(modelData.page)
                            }
                        }
                    }
                }
            }
        }

        // ── 中间：PDF 阅读区 ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 顶部工具栏
            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: theme.bg0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4

                    // 返回文献库
                    ReaderToolBtn {
                        icon: "←"
                        tooltip: "返回文献库"
                        onClicked: appState.currentPage = 0
                    }

                    // 左侧面板切换
                    ReaderToolBtn {
                        icon: "☰"
                        tooltip: "目录/缩略图"
                        onClicked: leftPanel.leftPanelVisible = !leftPanel.leftPanelVisible
                    }

                    Rectangle { width: 1; height: 24; color: theme.bg4 }

                    // 翻页控制
                    ReaderToolBtn {
                        icon: "‹"
                        tooltip: "上一页"
                        enabled: pdfDoc.status === PdfDocument.Ready && pdfView.currentPage > 0
                        onClicked: pdfView.goToPage(pdfView.currentPage - 1)
                    }

                    // 页码输入
                    Rectangle {
                        width: 80; height: 28
                        radius: theme.radiusSm
                        color: theme.bg2
                        border.color: pageInput.activeFocus ? theme.accent : theme.bg4
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 2

                            TextInput {
                                id: pageInput
                                Layout.fillWidth: true
                                text: pdfDoc.status === PdfDocument.Ready
                                      ? (pdfView.currentPage + 1).toString() : "0"
                                color: theme.textPrimary
                                font.pixelSize: theme.fontSm
                                horizontalAlignment: Text.AlignRight
                                validator: IntValidator { bottom: 1; top: pdfDoc.pageCount }
                                onAccepted: {
                                    var p = parseInt(text) - 1
                                    if (p >= 0 && p < pdfDoc.pageCount)
                                        pdfView.goToPage(p)
                                }
                            }

                            Text {
                                text: "/ " + (pdfDoc.pageCount || 0)
                                color: theme.textMuted
                                font.pixelSize: theme.fontSm
                            }
                        }
                    }

                    ReaderToolBtn {
                        icon: "›"
                        tooltip: "下一页"
                        enabled: pdfDoc.status === PdfDocument.Ready
                                 && pdfView.currentPage < pdfDoc.pageCount - 1
                        onClicked: pdfView.goToPage(pdfView.currentPage + 1)
                    }

                    Rectangle { width: 1; height: 24; color: theme.bg4 }

                    // 缩放控制
                    ReaderToolBtn {
                        icon: "−"
                        tooltip: "缩小"
                        onClicked: pdfView.renderScale = Math.max(0.25, pdfView.renderScale - 0.1)
                    }

                    Text {
                        text: Math.round(pdfView.renderScale * 100) + "%"
                        color: theme.textSecondary
                        font.pixelSize: theme.fontSm
                        width: 44
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ReaderToolBtn {
                        icon: "+"
                        tooltip: "放大"
                        onClicked: pdfView.renderScale = Math.min(4.0, pdfView.renderScale + 0.1)
                    }

                    ReaderToolBtn {
                        icon: "⊡"
                        tooltip: "适合页面"
                        onClicked: pdfView.scaleToPage()
                    }

                    Rectangle { width: 1; height: 24; color: theme.bg4 }

                    // 搜索
                    SearchBar {
                        id: searchBar
                        Layout.preferredWidth: 200
                    }

                    Item { Layout.fillWidth: true }

                    // 标题
                    Text {
                        text: appState.selectedPaperTitle
                        color: theme.textSecondary
                        font.pixelSize: theme.fontSm
                        elide: Text.ElideRight
                        Layout.maximumWidth: 240
                    }

                    Rectangle { width: 1; height: 24; color: theme.bg4 }

                    // AI 问答面板切换
                    ReaderToolBtn {
                        icon: "🤖"
                        tooltip: "AI 问答"
                        onClicked: aiPanel.visible = !aiPanel.visible
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

            // PDF 视图 + AI 面板
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // PDF 多页视图
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#3A3A3A"

                    PdfMultiPageView {
                        id: pdfView
                        anchors.fill: parent
                        document: pdfDoc
                        searchString: searchBar.searchText

                        onCurrentPageChanged: {
                            pageInput.text = (currentPage + 1).toString()
                            // 保存阅读进度
                            if (appState.selectedPaperId > 0 && pdfDoc.pageCount > 0) {
                                libraryManager.updatePaperReadProgress(
                                    appState.selectedPaperId,
                                    currentPage,
                                    currentPage / Math.max(1, pdfDoc.pageCount - 1)
                                )
                            }
                        }
                    }

                    // 空状态
                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: pdfDoc.status !== PdfDocument.Ready

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📄"
                            font.pixelSize: 48
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: appState.selectedPaperPath === ""
                                  ? "请从文献库选择一篇文献"
                                  : "正在加载..."
                            color: theme.textMuted
                            font.pixelSize: theme.fontMd
                        }
                    }
                }

                // AI 问答面板
                Rectangle {
                    id: aiPanel
                    Layout.fillHeight: true
                    Layout.preferredWidth: visible ? 320 : 0
                    visible: false
                    color: theme.bg0

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: theme.bg4
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 1
                        spacing: 0

                        // 面板标题
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: theme.bg0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8

                                Text {
                                    text: "AI 问答"
                                    color: theme.textPrimary
                                    font.pixelSize: theme.fontMd
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: ragflowClient.isConfigured ? "● 已连接" : "○ 未配置"
                                    color: ragflowClient.isConfigured ? theme.success : theme.warning
                                    font.pixelSize: theme.fontSm
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

                        // 对话历史
                        ScrollView {
                            id: chatScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            Column {
                                id: chatHistory
                                width: chatScroll.width
                                spacing: 12
                                padding: 12

                                // 欢迎提示
                                Rectangle {
                                    width: parent.width - 24
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: welcomeText.implicitHeight + 16
                                    radius: theme.radiusMd
                                    color: theme.bg2
                                    visible: chatMessages.count === 0

                                    Text {
                                        id: welcomeText
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        text: "你好！我可以帮你分析这篇文献。\n\n你可以问我：\n• 这篇文章的主要贡献是什么？\n• 解释一下研究方法\n• 总结实验结果"
                                        color: theme.textSecondary
                                        font.pixelSize: theme.fontSm
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Repeater {
                                    id: chatMessages
                                    model: []

                                    delegate: ChatBubble {
                                        width: chatHistory.width - 24
                                        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
                                        isUser: modelData.isUser
                                        messageText: modelData.text
                                    }
                                }
                            }
                        }

                        // 输入区
                        Rectangle {
                            Layout.fillWidth: true
                            height: chatInputArea.implicitHeight + 16
                            color: theme.bg0

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: theme.bg4
                            }

                            RowLayout {
                                id: chatInputArea
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: Math.max(36, chatInput.implicitHeight + 12)
                                    radius: theme.radiusMd
                                    color: theme.bg2
                                    border.color: chatInput.activeFocus ? theme.accent : theme.bg4
                                    border.width: 1

                                    TextArea {
                                        id: chatInput
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        placeholderText: "问关于这篇文献的问题..."
                                        placeholderTextColor: theme.textMuted
                                        color: theme.textPrimary
                                        font.pixelSize: theme.fontSm
                                        wrapMode: TextArea.Wrap
                                        background: null

                                        Keys.onReturnPressed: function(event) {
                                            if (event.modifiers & Qt.ShiftModifier) {
                                                event.accepted = false
                                            } else {
                                                sendMessage()
                                                event.accepted = true
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 36; height: 36
                                    radius: theme.radiusMd
                                    color: sendBtn.containsMouse ? theme.accentHover : theme.accent
                                    enabled: chatInput.text.trim() !== "" && ragflowClient.isConfigured

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↑"
                                        color: "white"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: sendBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sendMessage()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 发送消息函数
    function sendMessage() {
        var text = chatInput.text.trim()
        if (!text) return

        // 添加用户消息
        var messages = chatMessages.model.slice()
        messages.push({ isUser: true, text: text })
        chatMessages.model = messages
        chatInput.text = ""

        // TODO: 调用 RAGFlow API
        appState.statusMessage = "正在查询知识库..."
    }

    // ── 内部组件：工具按钮 ────────────────────────────────────────
    component ReaderToolBtn: Item {
        property string icon: ""
        property string tooltip: ""
        property bool enabled: true
        signal clicked()

        width: 32; height: 32

        Rectangle {
            anchors.fill: parent
            radius: theme.radiusSm
            color: rBtnMouse.containsMouse ? theme.bg3 : "transparent"
            opacity: parent.enabled ? 1.0 : 0.4
        }

        Text {
            anchors.centerIn: parent
            text: icon
            font.pixelSize: 15
            color: theme.textSecondary
        }

        MouseArea {
            id: rBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: parent.enabled
            onClicked: parent.clicked()
        }

        ToolTip.visible: rBtnMouse.containsMouse && tooltip !== ""
        ToolTip.text: tooltip
        ToolTip.delay: 600
    }

    // ── 内部组件：聊天气泡 ────────────────────────────────────────
    component ChatBubble: Item {
        property bool isUser: false
        property string messageText: ""

        height: bubble.implicitHeight + 8

        Rectangle {
            id: bubble
            anchors.right: isUser ? parent.right : undefined
            anchors.left: isUser ? undefined : parent.left
            width: Math.min(parent.width * 0.85, implicitWidth)
            implicitWidth: bubbleText.implicitWidth + 20
            implicitHeight: bubbleText.implicitHeight + 16
            radius: theme.radiusMd
            color: isUser ? theme.accentDim : theme.bg2
            border.color: isUser ? theme.accent : theme.bg4
            border.width: 1

            Text {
                id: bubbleText
                anchors.fill: parent
                anchors.margins: 10
                text: messageText
                color: theme.textPrimary
                font.pixelSize: theme.fontSm
                wrapMode: Text.WordWrap
            }
        }
    }
}
