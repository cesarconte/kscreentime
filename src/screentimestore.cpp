/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "screentimestore.h"
#include "appclassifier.h"

#include <QDate>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>

#include <algorithm>
#include <cmath>

ScreenTimeStore::ScreenTimeStore(QObject *parent)
    : QObject(parent)
{
}

void ScreenTimeStore::loadFromDisk(const QString &filePath)
{
    m_dailyUsage.clear();
    m_appLimits.clear();

    QFile file(filePath);
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isObject()) {
        return;
    }

    const QJsonObject root = doc.object();
    const QJsonObject daysObj = root.value(QStringLiteral("days")).toObject();
    for (auto dayIt = daysObj.begin(); dayIt != daysObj.end(); ++dayIt) {
        const QString dateStr = dayIt.key();
        const QJsonObject appsObj = dayIt.value().toObject();
        QMap<QString, int> appMap;
        for (auto appIt = appsObj.begin(); appIt != appsObj.end(); ++appIt) {
            const int secs = appIt.value().toInt(0);
            if (secs > 0) {
                appMap.insert(AppClassifier::normalizeAppId(appIt.key()), secs);
            }
        }
        if (!appMap.isEmpty()) {
            m_dailyUsage.insert(dateStr, appMap);
        }
    }

    const QJsonObject limitsObj = root.value(QStringLiteral("appLimits")).toObject();
    for (auto limIt = limitsObj.begin(); limIt != limitsObj.end(); ++limIt) {
        const int mins = limIt.value().toInt(0);
        if (mins > 0) {
            m_appLimits.insert(AppClassifier::normalizeAppId(limIt.key()), mins);
        }
    }
}

void ScreenTimeStore::saveToDisk(const QString &storageDir, const QString &filePath) const
{
    QDir().mkpath(storageDir);

    QJsonObject daysObj;
    for (auto dayIt = m_dailyUsage.cbegin(); dayIt != m_dailyUsage.cend(); ++dayIt) {
        QJsonObject appsObj;
        for (auto appIt = dayIt.value().cbegin(); appIt != dayIt.value().cend(); ++appIt) {
            if (appIt.value() > 0) {
                appsObj.insert(appIt.key(), appIt.value());
            }
        }
        if (!appsObj.isEmpty()) {
            daysObj.insert(dayIt.key(), appsObj);
        }
    }

    QJsonObject limitsObj;
    for (auto limIt = m_appLimits.cbegin(); limIt != m_appLimits.cend(); ++limIt) {
        if (limIt.value() > 0) {
            limitsObj.insert(limIt.key(), limIt.value());
        }
    }

    QJsonObject root;
    root.insert(QStringLiteral("days"), daysObj);
    root.insert(QStringLiteral("appLimits"), limitsObj);

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        file.close();
    }
}

void ScreenTimeStore::addUsageSeconds(const QString &dateStr, const QString &appId, int seconds)
{
    if (seconds <= 0) {
        return;
    }
    const QString cleanDate = dateStr.trimmed().isEmpty()
        ? QDate::currentDate().toString(Qt::ISODate)
        : dateStr.trimmed();
    const QString normalizedApp = AppClassifier::normalizeAppId(appId);
    if (normalizedApp.isEmpty()) {
        return;
    }

    m_dailyUsage[cleanDate][normalizedApp] += seconds;

    int limitMins = 0;
    int currentSecs = 0;
    if (checkLimitExceeded(cleanDate, normalizedApp, limitMins, currentSecs)) {
        Q_EMIT appLimitExceeded(normalizedApp, limitMins, currentSecs);
    }
}

void ScreenTimeStore::setAppLimit(const QString &appId, int limitMinutes)
{
    const QString normalizedApp = AppClassifier::normalizeAppId(appId);
    if (normalizedApp.isEmpty()) {
        return;
    }

    if (limitMinutes <= 0) {
        m_appLimits.remove(normalizedApp);
    } else {
        m_appLimits[normalizedApp] = limitMinutes;
        const QString today = QDate::currentDate().toString(Qt::ISODate);
        int limM = 0;
        int curS = 0;
        if (checkLimitExceeded(today, normalizedApp, limM, curS)) {
            Q_EMIT appLimitExceeded(normalizedApp, limM, curS);
        }
    }
}

void ScreenTimeStore::clearAll()
{
    m_dailyUsage.clear();
    m_notifiedLimits.clear();
}

bool ScreenTimeStore::checkLimitExceeded(const QString &dateStr, const QString &appId, int &limitMins, int &currentSecs)
{
    limitMins = m_appLimits.value(appId, 0);
    if (limitMins <= 0) {
        return false;
    }

    currentSecs = m_dailyUsage.value(dateStr).value(appId, 0);
    if (currentSecs < limitMins * 60) {
        return false;
    }

    const QString key = dateStr + QLatin1Char('|') + appId;
    if (m_notifiedLimits.contains(key)) {
        return false;
    }
    m_notifiedLimits.insert(key);
    return true;
}

int ScreenTimeStore::todayTotalSeconds(const QString &selectedDate) const
{
    const auto dayMap = m_dailyUsage.value(selectedDate);
    int total = 0;
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        total += std::max(0, it.value());
    }
    return total;
}

QString ScreenTimeStore::todayTotalFormatted(const QString &selectedDate) const
{
    return AppClassifier::formatDuration(todayTotalSeconds(selectedDate));
}

QString ScreenTimeStore::vsAverageText(const QString &selectedDate) const
{
    const QDate refDate = QDate::fromString(selectedDate, Qt::ISODate).isValid()
        ? QDate::fromString(selectedDate, Qt::ISODate)
        : QDate::currentDate();

    int sum7 = 0;
    int activeDays = 0;
    for (int i = 0; i < 7; ++i) {
        const QString dStr = refDate.addDays(-i).toString(Qt::ISODate);
        const auto dayMap = m_dailyUsage.value(dStr);
        int daySum = 0;
        for (int secs : dayMap) {
            daySum += std::max(0, secs);
        }
        sum7 += daySum;
        if (daySum > 0) {
            ++activeDays;
        }
    }

    const int avgSeconds = activeDays > 0 ? (sum7 / activeDays) : 0;
    const int currentSeconds = todayTotalSeconds(selectedDate);
    if (avgSeconds <= 0) {
        return QStringLiteral("Registrando actividad real en esta sesión");
    }

    const int diffPct = static_cast<int>(std::round(((currentSeconds - avgSeconds) * 100.0) / avgSeconds));
    const QString avgFormatted = AppClassifier::formatDuration(avgSeconds);
    if (std::abs(diffPct) <= 2) {
        return QStringLiteral("En la media de %1 día(s) (%2)").arg(activeDays).arg(avgFormatted);
    }
    if (diffPct > 0) {
        return QStringLiteral("+%1% frente a la media (%2)").arg(diffPct).arg(avgFormatted);
    }
    return QStringLiteral("%1% frente a la media (%2)").arg(diffPct).arg(avgFormatted);
}

QVariantList ScreenTimeStore::appUsageList(const QString &selectedDate) const
{
    const auto dayMap = m_dailyUsage.value(selectedDate);
    int totalSecs = 0;
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        totalSecs += std::max(0, it.value());
    }

    struct Entry {
        QString appId;
        int seconds;
    };
    QList<Entry> entries;
    entries.reserve(dayMap.size());
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        if (it.value() > 0) {
            entries.push_back({it.key(), it.value()});
        }
    }

    std::sort(entries.begin(), entries.end(), [](const Entry &a, const Entry &b) {
        if (a.seconds != b.seconds) {
            return a.seconds > b.seconds;
        }
        return a.appId < b.appId;
    });

    QVariantList result;
    result.reserve(entries.size());
    for (const Entry &entry : entries) {
        const int limitMins = m_appLimits.value(entry.appId, 0);
        const bool exceeded = (limitMins > 0) && (entry.seconds >= limitMins * 60);
        const double ratio = totalSecs > 0
            ? static_cast<double>(entry.seconds) / static_cast<double>(totalSecs)
            : 0.0;

        QVariantMap item;
        item.insert(QStringLiteral("appId"), entry.appId);
        item.insert(QStringLiteral("displayName"), AppClassifier::displayNameForApp(entry.appId));
        item.insert(QStringLiteral("category"), AppClassifier::classifyAppCategory(entry.appId));
        item.insert(QStringLiteral("iconName"), AppClassifier::iconNameForApp(entry.appId));
        item.insert(QStringLiteral("seconds"), entry.seconds);
        item.insert(QStringLiteral("formattedDuration"), AppClassifier::formatDuration(entry.seconds));
        item.insert(QStringLiteral("ratio"), ratio);
        item.insert(QStringLiteral("limitMinutes"), limitMins);
        item.insert(QStringLiteral("limitExceeded"), exceeded);
        result.push_back(item);
    }
    return result;
}

QVariantList ScreenTimeStore::weeklyChartData(const QString &selectedDate) const
{
    const QDate today = QDate::currentDate();
    static const QStringList kDayNames = {
        QStringLiteral("Lun"),
        QStringLiteral("Mar"),
        QStringLiteral("Mié"),
        QStringLiteral("Jue"),
        QStringLiteral("Vie"),
        QStringLiteral("Sáb"),
        QStringLiteral("Dom")
    };

    struct DayEntry {
        QString dateStr;
        QString dayLabel;
        int totalSeconds;
    };

    QList<DayEntry> days;
    days.reserve(7);
    int maxDaySeconds = 0;

    for (int offset = 6; offset >= 0; --offset) {
        const QDate d = today.addDays(-offset);
        const QString dStr = d.toString(Qt::ISODate);
        const auto dayMap = m_dailyUsage.value(dStr);
        int total = 0;
        for (int secs : dayMap) {
            total += std::max(0, secs);
        }
        maxDaySeconds = std::max(maxDaySeconds, total);
        const int dow = d.dayOfWeek();
        const QString label = (dow >= 1 && dow <= 7) ? kDayNames.at(dow - 1) : dStr.right(2);
        days.push_back({dStr, label, total});
    }

    QVariantList result;
    result.reserve(days.size());
    for (const DayEntry &de : days) {
        const double ratio = maxDaySeconds > 0
            ? static_cast<double>(de.totalSeconds) / static_cast<double>(maxDaySeconds)
            : 0.0;
        QVariantMap item;
        item.insert(QStringLiteral("date"), de.dateStr);
        item.insert(QStringLiteral("dayLabel"), de.dayLabel);
        item.insert(QStringLiteral("totalSeconds"), de.totalSeconds);
        item.insert(QStringLiteral("formattedDuration"), AppClassifier::formatDuration(de.totalSeconds));
        item.insert(QStringLiteral("ratio"), ratio);
        item.insert(QStringLiteral("isSelected"), de.dateStr == selectedDate);
        result.push_back(item);
    }
    return result;
}

QVariantList ScreenTimeStore::categoryBreakdown(const QString &selectedDate) const
{
    const auto dayMap = m_dailyUsage.value(selectedDate);
    QMap<QString, int> catSums;
    int totalSecs = 0;

    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        const int secs = std::max(0, it.value());
        if (secs <= 0) {
            continue;
        }
        const QString cat = AppClassifier::classifyAppCategory(it.key());
        catSums[cat] += secs;
        totalSecs += secs;
    }

    struct CatEntry {
        QString category;
        int seconds;
    };
    QList<CatEntry> list;
    for (auto it = catSums.cbegin(); it != catSums.cend(); ++it) {
        list.push_back({it.key(), it.value()});
    }
    std::sort(list.begin(), list.end(), [](const CatEntry &a, const CatEntry &b) {
        if (a.seconds != b.seconds) {
            return a.seconds > b.seconds;
        }
        return a.category < b.category;
    });

    QVariantList result;
    result.reserve(list.size());
    for (const CatEntry &ce : list) {
        const double ratio = totalSecs > 0
            ? static_cast<double>(ce.seconds) / static_cast<double>(totalSecs)
            : 0.0;
        QVariantMap item;
        item.insert(QStringLiteral("category"), ce.category);
        item.insert(QStringLiteral("iconName"), AppClassifier::iconNameForCategory(ce.category));
        item.insert(QStringLiteral("seconds"), ce.seconds);
        item.insert(QStringLiteral("formattedDuration"), AppClassifier::formatDuration(ce.seconds));
        item.insert(QStringLiteral("ratio"), ratio);
        result.push_back(item);
    }
    return result;
}
