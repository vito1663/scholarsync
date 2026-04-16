#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class RagflowClient;
class DatabaseManager;

class KnowledgeBaseManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList knowledgeBases READ knowledgeBases NOTIFY knowledgeBasesChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit KnowledgeBaseManager(RagflowClient *client, DatabaseManager *db, QObject *parent = nullptr);

    QVariantList knowledgeBases() const { return m_knowledgeBases; }
    bool isLoading() const { return m_isLoading; }

    Q_INVOKABLE void loadKnowledgeBases();
    Q_INVOKABLE void createKnowledgeBase(const QString &name);
    Q_INVOKABLE void syncFolderToKb(int folderId, const QString &kbId);
    Q_INVOKABLE void uploadPaperToKb(int paperId, const QString &kbId);

signals:
    void knowledgeBasesChanged();
    void isLoadingChanged();
    void syncProgress(int paperId, const QString &status);
    void kbOperationError(const QString &message);

private:
    RagflowClient *m_client;
    DatabaseManager *m_db;
    QVariantList m_knowledgeBases;
    bool m_isLoading = false;
    void setLoading(bool v);
};
