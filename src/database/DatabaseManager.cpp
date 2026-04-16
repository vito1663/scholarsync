#include "DatabaseManager.h"
#include <QSqlError>
#include <QSqlRecord>
#include <QDebug>
#include <QDateTime>

DatabaseManager::DatabaseManager(const QString &dbPath, QObject *parent)
    : QObject(parent), m_dbPath(dbPath)
{
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen())
        m_db.close();
}

bool DatabaseManager::initialize()
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(m_dbPath);

    if (!m_db.open()) {
        qCritical() << "Failed to open database:" << m_db.lastError().text();
        return false;
    }

    // 开启 WAL 模式提升并发性能
    QSqlQuery pragma(m_db);
    pragma.exec("PRAGMA journal_mode=WAL");
    pragma.exec("PRAGMA foreign_keys=ON");

    createTables();
    return true;
}

void DatabaseManager::createTables()
{
    QSqlQuery q(m_db);

    // 文件夹表
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            path TEXT NOT NULL UNIQUE,
            sync_to_kb INTEGER DEFAULT 0,
            kb_id TEXT DEFAULT '',
            kb_name TEXT DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    )");

    // 文献表
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS papers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            authors TEXT DEFAULT '',
            journal TEXT DEFAULT '',
            year INTEGER DEFAULT 0,
            doi TEXT DEFAULT '',
            abstract TEXT DEFAULT '',
            file_path TEXT NOT NULL,
            file_hash TEXT DEFAULT '',
            tags TEXT DEFAULT '',
            is_synced INTEGER DEFAULT 0,
            ragflow_doc_id TEXT DEFAULT '',
            last_read_page INTEGER DEFAULT 0,
            read_progress REAL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
        )
    )");

    // 注释表
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS annotations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            paper_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            page INTEGER NOT NULL,
            rect_x REAL, rect_y REAL, rect_w REAL, rect_h REAL,
            color TEXT DEFAULT '#FFEB3B',
            content TEXT DEFAULT '',
            selected_text TEXT DEFAULT '',
            created_at TEXT NOT NULL,
            FOREIGN KEY (paper_id) REFERENCES papers(id) ON DELETE CASCADE
        )
    )");

    // 设置表
    q.exec(R"(
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
    )");

    // 创建索引
    q.exec("CREATE INDEX IF NOT EXISTS idx_papers_folder ON papers(folder_id)");
    q.exec("CREATE INDEX IF NOT EXISTS idx_papers_title ON papers(title)");
    q.exec("CREATE INDEX IF NOT EXISTS idx_annotations_paper ON annotations(paper_id)");
}

int DatabaseManager::addFolder(const QString &name, const QString &path, bool syncToKb, const QString &kbId)
{
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    q.prepare("INSERT INTO folders (name, path, sync_to_kb, kb_id, created_at, updated_at) VALUES (?,?,?,?,?,?)");
    q.addBindValue(name);
    q.addBindValue(path);
    q.addBindValue(syncToKb ? 1 : 0);
    q.addBindValue(kbId);
    q.addBindValue(now);
    q.addBindValue(now);
    if (q.exec()) return q.lastInsertId().toInt();
    qWarning() << "addFolder error:" << q.lastError().text();
    return -1;
}

bool DatabaseManager::removeFolder(int folderId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM folders WHERE id=?");
    q.addBindValue(folderId);
    return q.exec();
}

bool DatabaseManager::updateFolderSyncStatus(int folderId, bool syncToKb, const QString &kbId)
{
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    q.prepare("UPDATE folders SET sync_to_kb=?, kb_id=?, updated_at=? WHERE id=?");
    q.addBindValue(syncToKb ? 1 : 0);
    q.addBindValue(kbId);
    q.addBindValue(now);
    q.addBindValue(folderId);
    return q.exec();
}

QVariantList DatabaseManager::getFolders()
{
    QVariantList result;
    QSqlQuery q("SELECT id, name, path, sync_to_kb, kb_id, kb_name, created_at FROM folders ORDER BY name", m_db);
    while (q.next()) {
        QVariantMap folder;
        folder["id"] = q.value(0).toInt();
        folder["name"] = q.value(1).toString();
        folder["path"] = q.value(2).toString();
        folder["syncToKb"] = q.value(3).toBool();
        folder["kbId"] = q.value(4).toString();
        folder["kbName"] = q.value(5).toString();
        folder["createdAt"] = q.value(6).toString();

        // 统计文献数量
        QSqlQuery countQ(m_db);
        countQ.prepare("SELECT COUNT(*) FROM papers WHERE folder_id=?");
        countQ.addBindValue(folder["id"]);
        countQ.exec();
        folder["paperCount"] = countQ.next() ? countQ.value(0).toInt() : 0;

        result.append(folder);
    }
    return result;
}

int DatabaseManager::addPaper(const QVariantMap &data)
{
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO papers (folder_id, title, authors, journal, year, doi, abstract,
                           file_path, file_hash, tags, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    )");
    q.addBindValue(data.value("folderId").toInt());
    q.addBindValue(data.value("title", "Untitled").toString());
    q.addBindValue(data.value("authors", "").toString());
    q.addBindValue(data.value("journal", "").toString());
    q.addBindValue(data.value("year", 0).toInt());
    q.addBindValue(data.value("doi", "").toString());
    q.addBindValue(data.value("abstract", "").toString());
    q.addBindValue(data.value("filePath").toString());
    q.addBindValue(data.value("fileHash", "").toString());
    q.addBindValue(data.value("tags", "").toString());
    q.addBindValue(now);
    q.addBindValue(now);
    if (q.exec()) return q.lastInsertId().toInt();
    qWarning() << "addPaper error:" << q.lastError().text();
    return -1;
}

bool DatabaseManager::updatePaper(int paperId, const QVariantMap &data)
{
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    q.prepare(R"(
        UPDATE papers SET title=?, authors=?, journal=?, year=?, doi=?, abstract=?,
        tags=?, is_synced=?, ragflow_doc_id=?, last_read_page=?, read_progress=?, updated_at=?
        WHERE id=?
    )");
    q.addBindValue(data.value("title").toString());
    q.addBindValue(data.value("authors").toString());
    q.addBindValue(data.value("journal").toString());
    q.addBindValue(data.value("year").toInt());
    q.addBindValue(data.value("doi").toString());
    q.addBindValue(data.value("abstract").toString());
    q.addBindValue(data.value("tags").toString());
    q.addBindValue(data.value("isSynced", false).toBool() ? 1 : 0);
    q.addBindValue(data.value("ragflowDocId", "").toString());
    q.addBindValue(data.value("lastReadPage", 0).toInt());
    q.addBindValue(data.value("readProgress", 0.0).toReal());
    q.addBindValue(now);
    q.addBindValue(paperId);
    return q.exec();
}

bool DatabaseManager::removePaper(int paperId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM papers WHERE id=?");
    q.addBindValue(paperId);
    return q.exec();
}

QVariantList DatabaseManager::getPapersByFolder(int folderId)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT id, title, authors, journal, year, doi, abstract, file_path,
               tags, is_synced, ragflow_doc_id, last_read_page, read_progress, created_at
        FROM papers WHERE folder_id=? ORDER BY title
    )");
    q.addBindValue(folderId);
    q.exec();
    while (q.next()) {
        QVariantMap paper;
        paper["id"] = q.value(0).toInt();
        paper["title"] = q.value(1).toString();
        paper["authors"] = q.value(2).toString();
        paper["journal"] = q.value(3).toString();
        paper["year"] = q.value(4).toInt();
        paper["doi"] = q.value(5).toString();
        paper["abstract"] = q.value(6).toString();
        paper["filePath"] = q.value(7).toString();
        paper["tags"] = q.value(8).toString();
        paper["isSynced"] = q.value(9).toBool();
        paper["ragflowDocId"] = q.value(10).toString();
        paper["lastReadPage"] = q.value(11).toInt();
        paper["readProgress"] = q.value(12).toReal();
        paper["createdAt"] = q.value(13).toString();
        result.append(paper);
    }
    return result;
}

QVariantList DatabaseManager::searchPapers(const QString &keyword)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare(R"(
        SELECT id, title, authors, journal, year, file_path, is_synced, read_progress
        FROM papers
        WHERE title LIKE ? OR authors LIKE ? OR abstract LIKE ? OR tags LIKE ?
        ORDER BY title LIMIT 100
    )");
    QString kw = "%" + keyword + "%";
    q.addBindValue(kw); q.addBindValue(kw); q.addBindValue(kw); q.addBindValue(kw);
    q.exec();
    while (q.next()) {
        QVariantMap paper;
        paper["id"] = q.value(0).toInt();
        paper["title"] = q.value(1).toString();
        paper["authors"] = q.value(2).toString();
        paper["journal"] = q.value(3).toString();
        paper["year"] = q.value(4).toInt();
        paper["filePath"] = q.value(5).toString();
        paper["isSynced"] = q.value(6).toBool();
        paper["readProgress"] = q.value(7).toReal();
        result.append(paper);
    }
    return result;
}

QVariantMap DatabaseManager::getPaperById(int paperId)
{
    QVariantMap paper;
    QSqlQuery q(m_db);
    q.prepare("SELECT * FROM papers WHERE id=?");
    q.addBindValue(paperId);
    q.exec();
    if (q.next()) {
        QSqlRecord rec = q.record();
        for (int i = 0; i < rec.count(); i++)
            paper[rec.fieldName(i)] = q.value(i);
    }
    return paper;
}

bool DatabaseManager::saveAnnotation(int paperId, const QVariantMap &ann)
{
    QString now = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO annotations (paper_id, type, page, rect_x, rect_y, rect_w, rect_h,
                                color, content, selected_text, created_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    )");
    q.addBindValue(paperId);
    q.addBindValue(ann.value("type", "highlight").toString());
    q.addBindValue(ann.value("page", 0).toInt());
    q.addBindValue(ann.value("rectX", 0.0).toReal());
    q.addBindValue(ann.value("rectY", 0.0).toReal());
    q.addBindValue(ann.value("rectW", 0.0).toReal());
    q.addBindValue(ann.value("rectH", 0.0).toReal());
    q.addBindValue(ann.value("color", "#FFEB3B").toString());
    q.addBindValue(ann.value("content", "").toString());
    q.addBindValue(ann.value("selectedText", "").toString());
    q.addBindValue(now);
    return q.exec();
}

QVariantList DatabaseManager::getAnnotations(int paperId)
{
    QVariantList result;
    QSqlQuery q(m_db);
    q.prepare("SELECT id, type, page, rect_x, rect_y, rect_w, rect_h, color, content, selected_text FROM annotations WHERE paper_id=? ORDER BY page, rect_y");
    q.addBindValue(paperId);
    q.exec();
    while (q.next()) {
        QVariantMap ann;
        ann["id"] = q.value(0).toInt();
        ann["type"] = q.value(1).toString();
        ann["page"] = q.value(2).toInt();
        ann["rectX"] = q.value(3).toReal();
        ann["rectY"] = q.value(4).toReal();
        ann["rectW"] = q.value(5).toReal();
        ann["rectH"] = q.value(6).toReal();
        ann["color"] = q.value(7).toString();
        ann["content"] = q.value(8).toString();
        ann["selectedText"] = q.value(9).toString();
        result.append(ann);
    }
    return result;
}

bool DatabaseManager::removeAnnotation(int annotationId)
{
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM annotations WHERE id=?");
    q.addBindValue(annotationId);
    return q.exec();
}

QString DatabaseManager::getSetting(const QString &key, const QString &defaultValue)
{
    QSqlQuery q(m_db);
    q.prepare("SELECT value FROM settings WHERE key=?");
    q.addBindValue(key);
    q.exec();
    if (q.next()) return q.value(0).toString();
    return defaultValue;
}

bool DatabaseManager::setSetting(const QString &key, const QString &value)
{
    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES (?,?)");
    q.addBindValue(key);
    q.addBindValue(value);
    return q.exec();
}
