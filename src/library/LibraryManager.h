#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QCryptographicHash>
#include <QFile>

class DatabaseManager;

class LibraryManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList folders READ folders NOTIFY foldersChanged)
    Q_PROPERTY(QVariantList currentPapers READ currentPapers NOTIFY currentPapersChanged)
    Q_PROPERTY(int currentFolderId READ currentFolderId WRITE setCurrentFolderId NOTIFY currentFolderIdChanged)

public:
    explicit LibraryManager(DatabaseManager *db, QObject *parent = nullptr);

    QVariantList folders() const { return m_folders; }
    QVariantList currentPapers() const { return m_currentPapers; }
    int currentFolderId() const { return m_currentFolderId; }
    void setCurrentFolderId(int id);

    Q_INVOKABLE void addFolder(const QString &name, const QString &path);
    Q_INVOKABLE void removeFolder(int folderId);
    Q_INVOKABLE void scanFolder(int folderId);
    Q_INVOKABLE void scanAllFolders();
    Q_INVOKABLE QVariantList searchPapers(const QString &keyword);
    Q_INVOKABLE QVariantMap getPaper(int paperId);
    Q_INVOKABLE void updatePaperReadProgress(int paperId, int page, double progress);
    Q_INVOKABLE void refreshFolders();
    Q_INVOKABLE void refreshCurrentFolder();

    static QString computeFileHash(const QString &filePath);

signals:
    void foldersChanged();
    void currentPapersChanged();
    void currentFolderIdChanged();
    void paperAdded(int paperId, const QVariantMap &paper);
    void scanProgress(int folderId, int current, int total);
    void scanFinished(int folderId, int addedCount);

private:
    void loadFolders();
    void loadPapersForFolder(int folderId);
    QString extractTitleFromPath(const QString &filePath);

    DatabaseManager *m_db;
    QVariantList m_folders;
    QVariantList m_currentPapers;
    int m_currentFolderId = -1;
};
