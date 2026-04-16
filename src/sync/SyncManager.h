#pragma once
#include <QObject>

class FolderWatcher;
class KnowledgeBaseManager;
class LibraryManager;

class SyncManager : public QObject
{
    Q_OBJECT

public:
    explicit SyncManager(FolderWatcher *watcher, KnowledgeBaseManager *kbManager,
                         LibraryManager *libraryManager, QObject *parent = nullptr);

    Q_INVOKABLE void startWatching();

signals:
    void newPaperDetected(const QString &filePath);
    void syncStatusChanged(const QString &message);

private:
    FolderWatcher *m_watcher;
    KnowledgeBaseManager *m_kbManager;
    LibraryManager *m_libraryManager;
};
