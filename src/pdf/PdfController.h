#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class DatabaseManager;

class PdfController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentFilePath READ currentFilePath NOTIFY currentFilePathChanged)
    Q_PROPERTY(int currentPaperId READ currentPaperId NOTIFY currentPaperIdChanged)
    Q_PROPERTY(QVariantList annotations READ annotations NOTIFY annotationsChanged)

public:
    explicit PdfController(QObject *parent = nullptr);

    QString currentFilePath() const { return m_currentFilePath; }
    int currentPaperId() const { return m_currentPaperId; }
    QVariantList annotations() const { return m_annotations; }

    Q_INVOKABLE void openPaper(int paperId, const QString &filePath, DatabaseManager *db);
    Q_INVOKABLE void closePaper();
    Q_INVOKABLE void addAnnotation(const QVariantMap &annotation, DatabaseManager *db);
    Q_INVOKABLE void removeAnnotation(int annotationId, DatabaseManager *db);
    Q_INVOKABLE void loadAnnotations(int paperId, DatabaseManager *db);

signals:
    void currentFilePathChanged();
    void currentPaperIdChanged();
    void annotationsChanged();
    void paperOpened(int paperId, const QString &filePath);

private:
    QString m_currentFilePath;
    int m_currentPaperId = -1;
    QVariantList m_annotations;
};
