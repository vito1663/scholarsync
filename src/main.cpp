#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDir>
#include <QStandardPaths>

#include "database/DatabaseManager.h"
#include "library/LibraryManager.h"
#include "library/FolderWatcher.h"
#include "pdf/PdfController.h"
#include "ragflow/RagflowClient.h"
#include "ragflow/KnowledgeBaseManager.h"
#include "sync/SyncManager.h"

int main(int argc, char *argv[])
{
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

    // 加载主 QML（使用 qt_add_qml_module 生成的 URI）
    const QUrl url(u"qrc:/ScholarSync/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
