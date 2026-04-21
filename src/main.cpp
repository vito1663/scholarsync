#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QDebug>
#include <QMessageLogContext>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

#include "database/DatabaseManager.h"
#include "library/LibraryManager.h"
#include "library/FolderWatcher.h"
#include "pdf/PdfController.h"
#include "ragflow/RagflowClient.h"
#include "ragflow/KnowledgeBaseManager.h"
#include "sync/SyncManager.h"

// 全局日志文件
static QFile *g_logFile = nullptr;

// 日志处理器：同时写文件和 Windows OutputDebugString
static void messageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    QString level;
    switch (type) {
    case QtDebugMsg:    level = "DEBUG"; break;
    case QtInfoMsg:     level = "INFO "; break;
    case QtWarningMsg:  level = "WARN "; break;
    case QtCriticalMsg: level = "ERROR"; break;
    case QtFatalMsg:    level = "FATAL"; break;
    }
    QString line = QString("[%1] %2: %3")
        .arg(QDateTime::currentDateTime().toString("hh:mm:ss.zzz"))
        .arg(level)
        .arg(msg);

    if (g_logFile && g_logFile->isOpen()) {
        QTextStream stream(g_logFile);
        stream << line << "\n";
        stream.flush();
    }

#ifdef Q_OS_WIN
    OutputDebugStringW((const wchar_t*)line.utf16());
    OutputDebugStringW(L"\n");
#endif

    if (type == QtFatalMsg) {
#ifdef Q_OS_WIN
        MessageBoxW(nullptr,
                    (const wchar_t*)line.utf16(),
                    L"ScholarSync Fatal Error",
                    MB_OK | MB_ICONERROR);
#endif
        abort();
    }
}

// 显示 Windows 错误弹窗（用于启动失败时）
static void showError(const QString &msg)
{
    qCritical() << msg;
#ifdef Q_OS_WIN
    MessageBoxW(nullptr,
                (const wchar_t*)msg.utf16(),
                L"ScholarSync Error",
                MB_OK | MB_ICONERROR);
#endif
}

int main(int argc, char *argv[])
{
    // 显式初始化 QML 资源（防止 MSVC Release 模式链接器 /OPT:REF 优化删除资源数据）
    Q_INIT_RESOURCE(qml_resources);

    // 初始化日志文件（在 QApplication 之前，确保所有日志都能被捕获）
    QString logDir = QDir::homePath() + "/AppData/Roaming/ScholarSync/ScholarSync";
#ifdef Q_OS_WIN
    // Windows 下使用 %APPDATA%
    QDir().mkpath(logDir);
    g_logFile = new QFile(logDir + "/scholarsync.log");
    if (!g_logFile->open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        // 如果无法写入 AppData，写到 exe 同目录
        delete g_logFile;
        g_logFile = new QFile("scholarsync.log");
        g_logFile->open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text);
    }
#endif
    qInstallMessageHandler(messageHandler);

    qInfo() << "=== ScholarSync starting ===";
    qInfo() << "Qt version:" << QT_VERSION_STR;
    qInfo() << "Build type: Release";

    QGuiApplication app(argc, argv);
    app.setApplicationName("ScholarSync");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("ScholarSync");

    qInfo() << "QGuiApplication created";

    // 使用 Basic 样式，配合自定义 QML 主题
    QQuickStyle::setStyle("Basic");

    // 初始化数据目录
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    qInfo() << "Data dir:" << dataDir;
    if (!QDir().mkpath(dataDir)) {
        showError(QString("Cannot create data directory: %1").arg(dataDir));
        return -1;
    }

    // 初始化核心服务
    qInfo() << "Initializing DatabaseManager...";
    DatabaseManager dbManager(dataDir + "/scholarsync.db");
    if (!dbManager.initialize()) {
        showError(QString("Failed to initialize database at: %1/scholarsync.db").arg(dataDir));
        return -1;
    }
    qInfo() << "Database initialized OK";

    LibraryManager libraryManager(&dbManager);
    FolderWatcher folderWatcher;
    PdfController pdfController;
    RagflowClient ragflowClient;
    KnowledgeBaseManager kbManager(&ragflowClient, &dbManager);
    SyncManager syncManager(&folderWatcher, &kbManager, &libraryManager);

    qInfo() << "All managers created";

    // 从数据库加载 API 配置
    QString apiKey = dbManager.getSetting("ragflow_api_key", "");
    QString baseUrl = dbManager.getSetting("ragflow_base_url", "https://cloud.ragflow.io");
    if (!apiKey.isEmpty()) {
        ragflowClient.setApiKey(apiKey);
        ragflowClient.setBaseUrl(baseUrl);
        qInfo() << "RAGFlow API configured, base URL:" << baseUrl;
    } else {
        qInfo() << "No RAGFlow API key configured yet";
    }

    // QML 引擎
    qInfo() << "Creating QML engine...";
    QQmlApplicationEngine engine;

    // 注册 C++ 对象到 QML 上下文
    engine.rootContext()->setContextProperty("libraryManager", &libraryManager);
    engine.rootContext()->setContextProperty("pdfController", &pdfController);
    engine.rootContext()->setContextProperty("ragflowClient", &ragflowClient);
    engine.rootContext()->setContextProperty("kbManager", &kbManager);
    engine.rootContext()->setContextProperty("syncManager", &syncManager);
    engine.rootContext()->setContextProperty("dbManager", &dbManager);
    engine.rootContext()->setContextProperty("appDataDir", dataDir);

    qInfo() << "Context properties set";

    // 加载主 QML（资源嵌入路径为 qrc:/qml/main.qml）
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

    bool loadFailed = false;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &loadFailed](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "QML root object creation FAILED for URL:" << url.toString();
            loadFailed = true;
            QCoreApplication::exit(-1);
        } else if (obj && url == objUrl) {
            qInfo() << "QML root object created successfully";
        }
    }, Qt::QueuedConnection);

    // 监听 QML 警告
    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        for (const QQmlError &w : warnings) {
            qWarning() << "QML Warning:" << w.toString();
        }
    });

    qInfo() << "Loading QML from:" << url.toString();
    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        showError(
            "Failed to load QML interface!\n\n"
            "Possible causes:\n"
            "1. Missing Qt QML modules (QtQuick.Controls, QtQuick.Pdf, etc.)\n"
            "2. QML syntax error\n"
            "3. Missing resource file\n\n"
            "Check log file for details:\n"
            + logDir + "/scholarsync.log"
        );
        return -1;
    }

    qInfo() << "QML loaded successfully, entering event loop";

    int ret = app.exec();
    qInfo() << "Application exiting with code:" << ret;

    if (g_logFile) {
        g_logFile->close();
        delete g_logFile;
    }
    return ret;
}
