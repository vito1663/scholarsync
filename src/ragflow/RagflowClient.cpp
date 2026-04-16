#include "RagflowClient.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QHttpMultiPart>
#include <QHttpPart>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QUrl>

RagflowClient::RagflowClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_baseUrl("https://cloud.ragflow.io")
{
}

void RagflowClient::setApiKey(const QString &key)
{
    if (m_apiKey != key) {
        m_apiKey = key;
        emit apiKeyChanged();
    }
}

void RagflowClient::setBaseUrl(const QString &url)
{
    if (m_baseUrl != url) {
        m_baseUrl = url.endsWith('/') ? url.chopped(1) : url;
        emit baseUrlChanged();
    }
}

QNetworkRequest RagflowClient::buildRequest(const QString &path)
{
    QNetworkRequest req;
    req.setUrl(QUrl(m_baseUrl + path));
    req.setRawHeader("Authorization", ("Bearer " + m_apiKey).toUtf8());
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return req;
}

void RagflowClient::handleNetworkError(QNetworkReply *reply, const QString &operation)
{
    QString msg = reply->errorString();
    QByteArray body = reply->readAll();
    if (!body.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(body);
        if (doc.isObject() && doc.object().contains("message"))
            msg = doc.object()["message"].toString();
    }
    emit error(operation, msg);
}

void RagflowClient::listDatasets()
{
    auto *reply = m_nam->get(buildRequest("/api/v1/datasets?page=1&page_size=100"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "listDatasets");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QVariantList datasets;
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            QJsonArray arr = doc.object()["data"].toArray();
            for (const QJsonValue &v : arr)
                datasets.append(v.toObject().toVariantMap());
        }
        emit datasetsLoaded(datasets);
    });
}

void RagflowClient::createDataset(const QString &name)
{
    QJsonObject body;
    body["name"] = name;
    body["chunk_method"] = "naive";
    body["language"] = "Chinese";

    QNetworkRequest req = buildRequest("/api/v1/datasets");
    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "createDataset");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            emit datasetCreated(doc.object()["data"].toObject().toVariantMap());
        }
    });
}

void RagflowClient::deleteDataset(const QString &datasetId)
{
    QJsonObject body;
    QJsonArray ids;
    ids.append(datasetId);
    body["ids"] = ids;

    QNetworkRequest req = buildRequest("/api/v1/datasets");
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    auto *reply = m_nam->sendCustomRequest(req, "DELETE", QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, datasetId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "deleteDataset");
            return;
        }
        emit datasetDeleted(datasetId);
    });
}

void RagflowClient::uploadDocument(const QString &datasetId, const QString &filePath)
{
    QFile *file = new QFile(filePath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        emit error("uploadDocument", "Cannot open file: " + filePath);
        return;
    }

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QHttpPart filePart;
    QFileInfo fi(filePath);
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QString("form-data; name=\"file\"; filename=\"%1\"").arg(fi.fileName()));
    filePart.setHeader(QNetworkRequest::ContentTypeHeader, "application/pdf");
    filePart.setBodyDevice(file);
    file->setParent(multiPart);
    multiPart->append(filePart);

    QNetworkRequest req;
    req.setUrl(QUrl(m_baseUrl + "/api/v1/datasets/" + datasetId + "/documents"));
    req.setRawHeader("Authorization", ("Bearer " + m_apiKey).toUtf8());

    auto *reply = m_nam->post(req, multiPart);
    multiPart->setParent(reply);

    connect(reply, &QNetworkReply::finished, this, [this, reply, datasetId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "uploadDocument");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            QJsonArray arr = doc.object()["data"].toArray();
            if (!arr.isEmpty())
                emit documentUploaded(datasetId, arr[0].toObject().toVariantMap());
        }
    });
}

void RagflowClient::deleteDocument(const QString &datasetId, const QString &docId)
{
    QJsonObject body;
    QJsonArray ids;
    ids.append(docId);
    body["ids"] = ids;

    QNetworkRequest req = buildRequest("/api/v1/datasets/" + datasetId + "/documents");
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    auto *reply = m_nam->sendCustomRequest(req, "DELETE", QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, datasetId, docId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "deleteDocument");
            return;
        }
        emit documentDeleted(datasetId, docId);
    });
}

void RagflowClient::parseDocuments(const QString &datasetId, const QStringList &docIds)
{
    QJsonObject body;
    QJsonArray ids;
    for (const QString &id : docIds) ids.append(id);
    body["document_ids"] = ids;

    QNetworkRequest req = buildRequest("/api/v1/datasets/" + datasetId + "/documents/run");
    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply, datasetId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "parseDocuments");
            return;
        }
        emit parseStarted(datasetId);
    });
}

void RagflowClient::listDocuments(const QString &datasetId)
{
    auto *reply = m_nam->get(buildRequest("/api/v1/datasets/" + datasetId + "/documents?page=1&page_size=100"));
    connect(reply, &QNetworkReply::finished, this, [this, reply, datasetId]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "listDocuments");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QVariantList docs;
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            QJsonObject data = doc.object()["data"].toObject();
            QJsonArray arr = data["docs"].toArray();
            for (const QJsonValue &v : arr)
                docs.append(v.toObject().toVariantMap());
        }
        emit documentsListed(datasetId, docs);
    });
}

void RagflowClient::chat(const QString &chatId, const QString &message, const QString &sessionId)
{
    QJsonObject body;
    body["question"] = message;
    body["stream"] = true;
    if (!sessionId.isEmpty())
        body["session_id"] = sessionId;

    QNetworkRequest req;
    req.setUrl(QUrl(m_baseUrl + "/api/v1/chats/" + chatId + "/completions"));
    req.setRawHeader("Authorization", ("Bearer " + m_apiKey).toUtf8());
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    QString fullResponse;

    connect(reply, &QNetworkReply::readyRead, this, [this, reply, &fullResponse]() {
        QByteArray data = reply->readAll();
        QList<QByteArray> lines = data.split('\n');
        for (const QByteArray &line : lines) {
            if (line.startsWith("data: ")) {
                QByteArray jsonData = line.mid(6).trimmed();
                if (jsonData == "[DONE]") continue;
                QJsonDocument doc = QJsonDocument::fromJson(jsonData);
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    if (obj.contains("answer")) {
                        QString chunk = obj["answer"].toString();
                        fullResponse += chunk;
                        emit chatChunkReceived(chunk);
                    }
                }
            }
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, fullResponse]() mutable {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "chat");
            return;
        }
        emit chatFinished(fullResponse);
    });
}

void RagflowClient::retrieval(const QString &datasetId, const QString &query)
{
    QJsonObject body;
    body["question"] = query;
    QJsonArray ids;
    ids.append(datasetId);
    body["dataset_ids"] = ids;
    body["top_k"] = 10;

    QNetworkRequest req = buildRequest("/api/v1/retrieval");
    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "retrieval");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QVariantList chunks;
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            QJsonObject data = doc.object()["data"].toObject();
            QJsonArray arr = data["chunks"].toArray();
            for (const QJsonValue &v : arr)
                chunks.append(v.toObject().toVariantMap());
        }
        emit retrievalResult(chunks);
    });
}

void RagflowClient::createChatApp(const QString &name, const QStringList &datasetIds)
{
    QJsonObject body;
    body["name"] = name;
    QJsonArray ids;
    for (const QString &id : datasetIds) ids.append(id);
    body["dataset_ids"] = ids;
    body["llm"] = QJsonObject{{"model_name", "deepseek-chat"}, {"temperature", 0.1}};

    QNetworkRequest req = buildRequest("/api/v1/chats");
    auto *reply = m_nam->post(req, QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "createChatApp");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            emit chatAppCreated(doc.object()["data"].toObject().toVariantMap());
        }
    });
}

void RagflowClient::listChatApps()
{
    auto *reply = m_nam->get(buildRequest("/api/v1/chats?page=1&page_size=100"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            handleNetworkError(reply, "listChatApps");
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QVariantList apps;
        if (doc.isObject() && doc.object()["code"].toInt() == 0) {
            QJsonArray arr = doc.object()["data"].toArray();
            for (const QJsonValue &v : arr)
                apps.append(v.toObject().toVariantMap());
        }
        emit chatAppsLoaded(apps);
    });
}
