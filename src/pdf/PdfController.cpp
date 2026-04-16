#include "PdfController.h"
#include "../database/DatabaseManager.h"
#include <QDebug>

PdfController::PdfController(QObject *parent)
    : QObject(parent)
{
}

void PdfController::openPaper(int paperId, const QString &filePath, DatabaseManager *db)
{
    m_currentPaperId = paperId;
    m_currentFilePath = filePath;
    emit currentPaperIdChanged();
    emit currentFilePathChanged();
    emit paperOpened(paperId, filePath);

    if (db) loadAnnotations(paperId, db);
}

void PdfController::closePaper()
{
    m_currentPaperId = -1;
    m_currentFilePath.clear();
    m_annotations.clear();
    emit currentPaperIdChanged();
    emit currentFilePathChanged();
    emit annotationsChanged();
}

void PdfController::addAnnotation(const QVariantMap &annotation, DatabaseManager *db)
{
    if (!db || m_currentPaperId < 0) return;
    if (db->saveAnnotation(m_currentPaperId, annotation)) {
        loadAnnotations(m_currentPaperId, db);
    }
}

void PdfController::removeAnnotation(int annotationId, DatabaseManager *db)
{
    if (!db) return;
    if (db->removeAnnotation(annotationId)) {
        m_annotations.removeIf([annotationId](const QVariant &v) {
            return v.toMap()["id"].toInt() == annotationId;
        });
        emit annotationsChanged();
    }
}

void PdfController::loadAnnotations(int paperId, DatabaseManager *db)
{
    if (!db) return;
    m_annotations = db->getAnnotations(paperId);
    emit annotationsChanged();
}
