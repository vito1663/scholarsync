#include "KnowledgeBaseManager.h"
#include "RagflowClient.h"
#include "../database/DatabaseManager.h"
#include <QDebug>

KnowledgeBaseManager::KnowledgeBaseManager(RagflowClient *client, DatabaseManager *db, QObject *parent)
    : QObject(parent), m_client(client), m_db(db)
{
    connect(m_client, &RagflowClient::datasetsLoaded, this, [this](const QVariantList &datasets) {
        m_knowledgeBases = datasets;
        setLoading(false);
        emit knowledgeBasesChanged();
    });

    connect(m_client, &RagflowClient::datasetCreated, this, [this](const QVariantMap &dataset) {
        m_knowledgeBases.append(dataset);
        emit knowledgeBasesChanged();
    });

    connect(m_client, &RagflowClient::documentUploaded, this, [this](const QString &datasetId, const QVariantMap &doc) {
        QString docId = doc.value("id").toString();
        // 触发解析
        m_client->parseDocuments(datasetId, {docId});
        emit syncProgress(-1, "uploaded");
    });

    connect(m_client, &RagflowClient::error, this, [this](const QString &op, const QString &msg) {
        setLoading(false);
        emit kbOperationError(op + ": " + msg);
    });
}

void KnowledgeBaseManager::setLoading(bool v)
{
    if (m_isLoading != v) {
        m_isLoading = v;
        emit isLoadingChanged();
    }
}

void KnowledgeBaseManager::loadKnowledgeBases()
{
    if (!m_client->isConfigured()) return;
    setLoading(true);
    m_client->listDatasets();
}

void KnowledgeBaseManager::createKnowledgeBase(const QString &name)
{
    if (!m_client->isConfigured()) return;
    m_client->createDataset(name);
}

void KnowledgeBaseManager::syncFolderToKb(int folderId, const QString &kbId)
{
    QVariantList papers = m_db->getPapersByFolder(folderId);
    for (const QVariant &v : papers) {
        QVariantMap paper = v.toMap();
        if (!paper["isSynced"].toBool()) {
            uploadPaperToKb(paper["id"].toInt(), kbId);
        }
    }
}

void KnowledgeBaseManager::uploadPaperToKb(int paperId, const QString &kbId)
{
    QVariantMap paper = m_db->getPaperById(paperId);
    if (paper.isEmpty()) return;

    QString filePath = paper["file_path"].toString();
    if (filePath.isEmpty()) filePath = paper["filePath"].toString();

    emit syncProgress(paperId, "uploading");
    m_client->uploadDocument(kbId, filePath);
}
