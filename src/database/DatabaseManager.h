#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVariantList>
#include <QVariantMap>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(const QString &dbPath, QObject *parent = nullptr);
    ~DatabaseManager();

    bool initialize();

    // 文件夹操作
    int addFolder(const QString &name, const QString &path, bool syncToKb = false, const QString &kbId = "");
    bool removeFolder(int folderId);
    bool updateFolderSyncStatus(int folderId, bool syncToKb, const QString &kbId = "");
    QVariantList getFolders();

    // 文献操作
    int addPaper(const QVariantMap &paperData);
    bool updatePaper(int paperId, const QVariantMap &paperData);
    bool removePaper(int paperId);
    QVariantList getPapersByFolder(int folderId);
    QVariantList searchPapers(const QString &keyword);
    QVariantMap getPaperById(int paperId);

    // 注释操作
    bool saveAnnotation(int paperId, const QVariantMap &annotation);
    QVariantList getAnnotations(int paperId);
    bool removeAnnotation(int annotationId);

    // 设置操作
    QString getSetting(const QString &key, const QString &defaultValue = "");
    bool setSetting(const QString &key, const QString &value);

    QSqlDatabase &database() { return m_db; }

private:
    void createTables();
    QSqlDatabase m_db;
    QString m_dbPath;
};
