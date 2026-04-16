#include "SyncManager.h"
#include "../library/FolderWatcher.h"
#include "../ragflow/KnowledgeBaseManager.h"
#include "../library/LibraryManager.h"
#include <QDebug>

SyncManager::SyncManager(FolderWatcher *watcher, KnowledgeBaseManager *kbManager,
                         LibraryManager *libraryManager, QObject *parent)
    : QObject(parent)
    , m_watcher(watcher)
    , m_kbManager(kbManager)
    , m_libraryManager(libraryManager)
{
    // 监听文件夹变化，自动扫描新文件
    connect(m_watcher, &FolderWatcher::fileAdded, this, [this](int folderId, const QString &filePath) {
        qDebug() << "New file detected:" << filePath;
        emit newPaperDetected(filePath);
        emit syncStatusChanged("检测到新文件: " + filePath);
        // 重新扫描文件夹
        m_libraryManager->scanFolder(folderId);
    });

    connect(m_watcher, &FolderWatcher::fileRemoved, this, [this](int folderId, const QString &filePath) {
        Q_UNUSED(folderId)
        emit syncStatusChanged("文件已移除: " + filePath);
    });
}

void SyncManager::startWatching()
{
    m_watcher->watchAll(m_libraryManager->folders());
}
