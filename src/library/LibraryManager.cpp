#include "LibraryManager.h"
#include "../database/DatabaseManager.h"
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QRegularExpression>

LibraryManager::LibraryManager(DatabaseManager *db, QObject *parent)
    : QObject(parent), m_db(db)
{
    loadFolders();
}

void LibraryManager::loadFolders()
{
    m_folders = m_db->getFolders();
    emit foldersChanged();
}

void LibraryManager::refreshFolders()
{
    loadFolders();
}

void LibraryManager::refreshCurrentFolder()
{
    if (m_currentFolderId >= 0)
        loadPapersForFolder(m_currentFolderId);
}

void LibraryManager::setCurrentFolderId(int id)
{
    if (m_currentFolderId != id) {
        m_currentFolderId = id;
        emit currentFolderIdChanged();
        if (id >= 0)
            loadPapersForFolder(id);
        else {
            m_currentPapers.clear();
            emit currentPapersChanged();
        }
    }
}

void LibraryManager::loadPapersForFolder(int folderId)
{
    m_currentPapers = m_db->getPapersByFolder(folderId);
    emit currentPapersChanged();
}

void LibraryManager::addFolder(const QString &name, const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) {
        qWarning() << "Folder does not exist:" << path;
        return;
    }
    int id = m_db->addFolder(name, path);
    if (id > 0) {
        loadFolders();
        scanFolder(id);
    }
}

void LibraryManager::removeFolder(int folderId)
{
    m_db->removeFolder(folderId);
    if (m_currentFolderId == folderId) {
        m_currentFolderId = -1;
        m_currentPapers.clear();
        emit currentFolderIdChanged();
        emit currentPapersChanged();
    }
    loadFolders();
}

void LibraryManager::scanFolder(int folderId)
{
    // 找到文件夹路径
    QString folderPath;
    for (const QVariant &v : m_folders) {
        QVariantMap f = v.toMap();
        if (f["id"].toInt() == folderId) {
            folderPath = f["path"].toString();
            break;
        }
    }
    if (folderPath.isEmpty()) return;

    QDir dir(folderPath);
    QStringList filters = {"*.pdf"};
    QFileInfoList files = dir.entryInfoList(filters, QDir::Files | QDir::Readable);

    int addedCount = 0;
    int total = files.size();

    for (int i = 0; i < files.size(); i++) {
        const QFileInfo &fi = files[i];
        emit scanProgress(folderId, i + 1, total);

        // 检查是否已存在（通过文件路径）
        QVariantList existing = m_db->getPapersByFolder(folderId);
        bool found = false;
        for (const QVariant &v : existing) {
            if (v.toMap()["filePath"].toString() == fi.absoluteFilePath()) {
                found = true;
                break;
            }
        }
        if (found) continue;

        // 添加新文献
        QVariantMap paperData;
        paperData["folderId"] = folderId;
        paperData["title"] = extractTitleFromPath(fi.absoluteFilePath());
        paperData["filePath"] = fi.absoluteFilePath();
        paperData["fileHash"] = computeFileHash(fi.absoluteFilePath());

        int paperId = m_db->addPaper(paperData);
        if (paperId > 0) {
            addedCount++;
            emit paperAdded(paperId, paperData);
        }
    }

    emit scanFinished(folderId, addedCount);
    loadFolders();
    if (m_currentFolderId == folderId)
        loadPapersForFolder(folderId);
}

void LibraryManager::scanAllFolders()
{
    for (const QVariant &v : m_folders) {
        scanFolder(v.toMap()["id"].toInt());
    }
}

QVariantList LibraryManager::searchPapers(const QString &keyword)
{
    return m_db->searchPapers(keyword);
}

QVariantMap LibraryManager::getPaper(int paperId)
{
    return m_db->getPaperById(paperId);
}

void LibraryManager::updatePaperReadProgress(int paperId, int page, double progress)
{
    QVariantMap data = m_db->getPaperById(paperId);
    data["lastReadPage"] = page;
    data["readProgress"] = progress;
    m_db->updatePaper(paperId, data);
}

QString LibraryManager::computeFileHash(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) return "";
    QCryptographicHash hash(QCryptographicHash::Md5);
    // 只读取前 64KB 用于快速哈希
    QByteArray data = file.read(65536);
    hash.addData(data);
    return hash.result().toHex();
}

QString LibraryManager::extractTitleFromPath(const QString &filePath)
{
    QFileInfo fi(filePath);
    QString name = fi.baseName();
    // 清理常见的文件名模式
    name.replace(QRegularExpression("[_\\-]+"), " ");
    name = name.trimmed();
    return name.isEmpty() ? fi.fileName() : name;
}
