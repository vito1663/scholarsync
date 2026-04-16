#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantMap>
#include <QVariantList>

class RagflowClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
    Q_PROPERTY(bool isConfigured READ isConfigured NOTIFY apiKeyChanged)

public:
    explicit RagflowClient(QObject *parent = nullptr);

    QString apiKey() const { return m_apiKey; }
    void setApiKey(const QString &key);
    QString baseUrl() const { return m_baseUrl; }
    void setBaseUrl(const QString &url);
    bool isConfigured() const { return !m_apiKey.isEmpty(); }

    // 知识库管理
    Q_INVOKABLE void listDatasets();
    Q_INVOKABLE void createDataset(const QString &name);
    Q_INVOKABLE void deleteDataset(const QString &datasetId);

    // 文档管理
    Q_INVOKABLE void uploadDocument(const QString &datasetId, const QString &filePath);
    Q_INVOKABLE void deleteDocument(const QString &datasetId, const QString &docId);
    Q_INVOKABLE void parseDocuments(const QString &datasetId, const QStringList &docIds);
    Q_INVOKABLE void listDocuments(const QString &datasetId);

    // AI 问答（流式）
    Q_INVOKABLE void chat(const QString &chatId, const QString &message, const QString &sessionId = "");
    Q_INVOKABLE void retrieval(const QString &datasetId, const QString &query);

    // 创建 Chat 应用
    Q_INVOKABLE void createChatApp(const QString &name, const QStringList &datasetIds);
    Q_INVOKABLE void listChatApps();

signals:
    void apiKeyChanged();
    void baseUrlChanged();

    // 知识库信号
    void datasetsLoaded(const QVariantList &datasets);
    void datasetCreated(const QVariantMap &dataset);
    void datasetDeleted(const QString &datasetId);

    // 文档信号
    void documentUploaded(const QString &datasetId, const QVariantMap &doc);
    void documentDeleted(const QString &datasetId, const QString &docId);
    void documentsListed(const QString &datasetId, const QVariantList &docs);
    void parseStarted(const QString &datasetId);

    // 问答信号
    void chatChunkReceived(const QString &chunk);
    void chatFinished(const QString &fullResponse);
    void retrievalResult(const QVariantList &chunks);

    // Chat 应用信号
    void chatAppsLoaded(const QVariantList &apps);
    void chatAppCreated(const QVariantMap &app);

    // 错误信号
    void error(const QString &operation, const QString &message);

private:
    QNetworkRequest buildRequest(const QString &path);
    void handleNetworkError(QNetworkReply *reply, const QString &operation);

    QNetworkAccessManager *m_nam;
    QString m_apiKey;
    QString m_baseUrl;
};
