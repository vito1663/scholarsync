#pragma once
#include <QObject>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QMap>

class FolderWatcher : public QObject
{
    Q_OBJECT

public:
    explicit FolderWatcher(QObject *parent = nullptr);

    Q_INVOKABLE void watchFolder(int folderId, const QString &path);
    Q_INVOKABLE void unwatchFolder(int folderId);
    Q_INVOKABLE void watchAll(const QVariantList &folders);

signals:
    void folderChanged(int folderId, const QString &path);
    void fileAdded(int folderId, const QString &filePath);
    void fileRemoved(int folderId, const QString &filePath);

private slots:
    void onDirectoryChanged(const QString &path);
    void onDebounceTimeout();

private:
    QFileSystemWatcher m_watcher;
    QTimer m_debounceTimer;
    QMap<QString, int> m_pathToFolderId;  // path -> folderId
    QMap<int, QString> m_folderIdToPath;  // folderId -> path
    QMap<int, QStringList> m_folderFiles; // folderId -> known files
    QString m_pendingChangePath;
};
