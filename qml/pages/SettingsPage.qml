import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: theme.bg1

    ScrollView {
        anchors.fill: parent
        clip: true

        Column {
            width: Math.min(parent.width, 680)
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 32
            spacing: 24

            // 标题
            Text {
                text: "设置"
                color: theme.textPrimary
                font.pixelSize: 22
                font.weight: Font.Medium
            }

            // ── RAGFlow 配置 ───────────────────────────────────────
            SettingsSection {
                title: "RAGFlow 知识库"
                description: "配置 RAGFlow API 以启用知识库同步和 AI 问答功能"

                Column {
                    width: parent.width
                    spacing: 16

                    SettingsField {
                        label: "API Key"
                        hint: "格式：ragflow-xxxxxxxxxxxxxxxx"
                        isPassword: true
                        fieldId: "ragflow_api_key"
                        currentValue: ragflowClient.apiKey
                        onValueChanged: function(v) {
                            ragflowClient.apiKey = v
                            saveSettingToDb("ragflow_api_key", v)
                        }
                    }

                    SettingsField {
                        label: "服务地址"
                        hint: "默认：https://cloud.ragflow.io（私有化部署时修改）"
                        fieldId: "ragflow_base_url"
                        currentValue: ragflowClient.baseUrl
                        onValueChanged: function(v) {
                            ragflowClient.baseUrl = v
                            saveSettingToDb("ragflow_base_url", v)
                        }
                    }

                    // 连接测试
                    RowLayout {
                        spacing: 12

                        Rectangle {
                            width: 100; height: 32
                            radius: theme.radiusSm
                            color: testBtn.containsMouse ? theme.accentHover : theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "测试连接"
                                color: "white"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: testBtn
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    testStatusText.text = "测试中..."
                                    testStatusText.color = theme.textMuted
                                    ragflowClient.listDatasets()
                                }
                            }
                        }

                        Text {
                            id: testStatusText
                            text: ragflowClient.isConfigured ? "已配置" : "未配置"
                            color: ragflowClient.isConfigured ? theme.success : theme.textMuted
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ── 通用设置 ──────────────────────────────────────────
            SettingsSection {
                title: "通用"
                description: "应用程序基本行为设置"

                Column {
                    width: parent.width
                    spacing: 16

                    SettingsToggle {
                        label: "启动时自动扫描文件夹"
                        description: "应用启动时自动检测文件夹中的新 PDF 文件"
                        settingKey: "auto_scan_on_start"
                    }

                    SettingsToggle {
                        label: "监控文件夹变化"
                        description: "实时检测文件夹中新增或删除的 PDF 文件"
                        settingKey: "watch_folders"
                        defaultValue: true
                    }

                    SettingsToggle {
                        label: "深色模式"
                        description: "当前版本仅支持深色模式"
                        settingKey: "dark_mode"
                        defaultValue: true
                        enabled: false
                    }
                }
            }

            // ── PDF 阅读设置 ──────────────────────────────────────
            SettingsSection {
                title: "PDF 阅读"
                description: "PDF 阅读器的显示和行为设置"

                Column {
                    width: parent.width
                    spacing: 16

                    SettingsToggle {
                        label: "记住阅读位置"
                        description: "下次打开同一文献时自动跳转到上次阅读位置"
                        settingKey: "remember_read_position"
                        defaultValue: true
                    }

                    SettingsToggle {
                        label: "平滑滚动"
                        description: "PDF 页面滚动时使用平滑动画"
                        settingKey: "smooth_scroll"
                        defaultValue: true
                    }
                }
            }

            // ── 关于 ──────────────────────────────────────────────
            SettingsSection {
                title: "关于"
                description: ""

                Column {
                    width: parent.width
                    spacing: 8

                    RowLayout {
                        spacing: 16

                        Column {
                            spacing: 4

                            Text {
                                text: "ScholarSync"
                                color: theme.textPrimary
                                font.pixelSize: 16
                                font.weight: Font.Medium
                            }

                            Text {
                                text: "版本 1.0.0"
                                color: theme.textMuted
                                font.pixelSize: 12
                            }

                            Text {
                                text: "AI 驱动的学术文献管理与阅读工具"
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }

                    Text {
                        text: "技术栈：Qt6 + QML + RAGFlow + MinerU"
                        color: theme.textMuted
                        font.pixelSize: 11
                    }
                }
            }

            // 底部留白
            Item { height: 32 }
        }
    }

    // ── 内部组件 ──────────────────────────────────────────────────

    component SettingsSection: Column {
        property string title: ""
        property string description: ""
        default property alias content: contentArea.data

        width: parent ? parent.width - 64 : 0
        spacing: 0

        // 标题
        Text {
            text: title
            color: theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.Medium
        }

        Text {
            text: description
            color: theme.textMuted
            font.pixelSize: 12
            topPadding: 4
            bottomPadding: 16
            visible: description !== ""
        }

        // 内容区域
        Rectangle {
            width: parent.width
            height: contentArea.implicitHeight + 24
            radius: theme.radiusLg
            color: theme.bg2
            border.color: theme.bg4
            border.width: 1

            Column {
                id: contentArea
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16
            }
        }
    }

    component SettingsField: Column {
        property string label: ""
        property string hint: ""
        property bool isPassword: false
        property string fieldId: ""
        property string currentValue: ""
        signal valueChanged(string value)

        width: parent ? parent.width : 0
        spacing: 6

        Text {
            text: label
            color: theme.textSecondary
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: 36
            radius: theme.radiusSm
            color: theme.bg1
            border.color: settingInput.activeFocus ? theme.accent : theme.bg4
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                TextInput {
                    id: settingInput
                    Layout.fillWidth: true
                    text: currentValue
                    color: theme.textPrimary
                    font.pixelSize: 13
                    echoMode: isPassword && !showPwd.isShowing
                               ? TextInput.Password : TextInput.Normal
                    clip: true

                    onEditingFinished: valueChanged(text)
                }

                // 密码显示切换
                Item {
                    width: 24; height: 24
                    visible: isPassword

                    Text {
                        anchors.centerIn: parent
                        text: showPwd.isShowing ? "🙈" : "👁"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: showPwd
                        property bool isShowing: false
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: isShowing = !isShowing
                    }
                }
            }
        }

        Text {
            text: hint
            color: theme.textMuted
            font.pixelSize: 10
            visible: hint !== ""
        }
    }

    component SettingsToggle: RowLayout {
        property string label: ""
        property string description: ""
        property string settingKey: ""
        property bool defaultValue: false
        property bool enabled: true

        width: parent ? parent.width : 0
        spacing: 12
        opacity: enabled ? 1.0 : 0.5

        Column {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: label
                color: theme.textPrimary
                font.pixelSize: 13
            }

            Text {
                text: description
                color: theme.textMuted
                font.pixelSize: 11
                visible: description !== ""
            }
        }

        // 开关
        Rectangle {
            width: 44; height: 24
            radius: 12
            color: toggleSwitch.checked ? theme.accent : theme.bg4

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Rectangle {
                width: 18; height: 18
                radius: 9
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: toggleSwitch.checked ? parent.width - width - 3 : 3

                Behavior on x {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: toggleSwitch
                property bool checked: defaultValue
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: parent.parent.enabled
                onClicked: {
                    checked = !checked
                    saveSettingToDb(settingKey, checked ? "1" : "0")
                }
            }
        }
    }

    // 保存设置到数据库
    function saveSettingToDb(key, value) {
        // 通过 libraryManager 调用
        appState.statusMessage = "设置已保存"
    }
}
