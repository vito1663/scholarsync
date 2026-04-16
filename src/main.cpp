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

#include "database/DatabaseManager.h"
#include "library/LibraryManager.h"
#include "library/FolderWatcher.h"
#include "pdf/PdfController.h"
#include "ragflow/RagflowClient.h"
#include "ragflow/KnowledgeBaseManager.h"
#include "sync/SyncManager.h"

// 日志输出到文件（Windows 下无控制台时用于调试）
void setupFileLogging()
{
    QString logPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
                      + "/ScholarSync/scholarsync.log";
    QDir().mkpath(QFileInfo(logPath).absolutePath());
    // 将 qDebug 输出重定向到文件
    static QFile logFile(logPath);
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        qInstallMessageHandler([](QtMsgType, const QMessageLogContext &, const QString &msg) {
            static QTextStream stream(&logFile);
            stream << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss") << " " << msg << "\n";
            stream.flush();
        });
    }
}

int main(int argc, char *argv[])
{
    // 显式初始化 QML 资源（防止 MSVC Release 模式链接器 /OPT:REF 优化删除资源数据）
    // 资源名称来自 rcc --name qml_resources qml.qrc
    Q_INIT_RESOURCE(qml_resources);

    // Windows 下开启文件日志（无控制台时用于调试）
#ifdef Q_OS_WIN
    setupFileLogging();
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("ScholarSync");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("ScholarSync");

    // 使用 Basic 样式，配合自定义 QML 主题
    QQuickStyle::setStyle("Basic");

    // 初始化数据目录
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);

    // 初始化核心服务
    DatabaseManager dbManager(dataDir + "/scholarsync.db");
    if (!dbManager.initialize()) {
        qCritical() << "Failed to initialize database";
        return -1;
    }

    LibraryManager libraryManager(&dbManager);
    FolderWatcher folderWatcher;
    PdfController pdfController;
    RagflowClient ragflowClient;
    KnowledgeBaseManager kbManager(&ragflowClient, &dbManager);
    SyncManager syncManager(&folderWatcher, &kbManager, &libraryManager);

    // 从数据库加载 API 配置
    QString apiKey = dbManager.getSetting("ragflow_api_key", "");
    QString baseUrl = dbManager.getSetting("ragflow_base_url", "https://cloud.ragflow.io");
    if (!apiKey.isEmpty()) {
        ragflowClient.setApiKey(apiKey);
        ragflowClient.setBaseUrl(baseUrl);
    }

    // QML 引擎
    QQmlApplicationEngine engine;

    // 注册 C++ 对象到 QML 上下文
    engine.rootContext()->setContextProperty("libraryManager", &libraryManager);
    engine.rootContext()->setContextProperty("pdfController", &pdfController);
    engine.rootContext()->setContextProperty("ragflowClient", &ragflowClient);
    engine.rootContext()->setContextProperty("kbManager", &kbManager);
    engine.rootContext()->setContextProperty("syncManager", &syncManager);
    engine.rootContext()->setContextProperty("dbManager", &dbManager);
    engine.rootContext()->setContextProperty("appDataDir", dataDir);

    // 加载主 QML（资源嵌入路径为 qrc:/qml/main.qml）
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
