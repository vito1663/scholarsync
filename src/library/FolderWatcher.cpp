#include "FolderWatcher.h"
#include <QDir>
#include <QDebug>

FolderWatcher::FolderWatcher(QObject *parent)
    : QObject(parent)
{
    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(1500); // 1.5秒防抖

    connect(&m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &FolderWatcher::onDirectoryChanged);
    connect(&m_debounceTimer, &QTimer::timeout,
            this, &FolderWatcher::onDebounceTimeout);
}

void FolderWatcher::watchFolder(int folderId, const QString &path)
{
    if (m_watcher.directories().contains(path)) return;

    m_watcher.addPath(path);
    m_pathToFolderId[path] = folderId;
    m_folderIdToPath[folderId] = path;

    // 记录当前文件列表
    QDir dir(path);
    m_folderFiles[folderId] = dir.entryList({"*.pdf"}, QDir::Files);
}

void FolderWatcher::unwatchFolder(int folderId)
{
    if (m_folderIdToPath.contains(folderId)) {
        QString path = m_folderIdToPath[folderId];
        m_watcher.removePath(path);
        m_pathToFolderId.remove(path);
        m_folderIdToPath.remove(folderId);
        m_folderFiles.remove(folderId);
    }
}

void FolderWatcher::watchAll(const QVariantList &folders)
{
    for (const QVariant &v : folders) {
        QVariantMap f = v.toMap();
        watchFolder(f["id"].toInt(), f["path"].toString());
    }
}

void FolderWatcher::onDirectoryChanged(const QString &path)
{
    m_pendingChangePath = path;
    m_debounceTimer.start();
}

void FolderWatcher::onDebounceTimeout()
{
    if (m_pendingChangePath.isEmpty()) return;

    QString path = m_pendingChangePath;
    m_pendingChangePath.clear();

    if (!m_pathToFolderId.contains(path)) return;
    int folderId = m_pathToFolderId[path];

    QDir dir(path);
    QStringList currentFiles = dir.entryList({"*.pdf"}, QDir::Files);
    QStringList &knownFiles = m_folderFiles[folderId];

    // 检测新增文件
    for (const QString &f : currentFiles) {
        if (!knownFiles.contains(f)) {
            emit fileAdded(folderId, path + "/" + f);
        }
    }

    // 检测删除文件
    for (const QString &f : knownFiles) {
        if (!currentFiles.contains(f)) {
            emit fileRemoved(folderId, path + "/" + f);
        }
    }

    knownFiles = currentFiles;
    emit folderChanged(folderId, path);
}
