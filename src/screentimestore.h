/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include <QMap>
#include <QObject>
#include <QSet>
#include <QString>
#include <QVariantList>

class ScreenTimeStore : public QObject
{
    Q_OBJECT

public:
    explicit ScreenTimeStore(QObject *parent = nullptr);
    ~ScreenTimeStore() override = default;

    void loadFromDisk(const QString &filePath);
    void saveToDisk(const QString &storageDir, const QString &filePath) const;

    void addUsageSeconds(const QString &dateStr, const QString &appId, int seconds);
    void setAppLimit(const QString &appId, int limitMinutes);
    void clearAll();

    int todayTotalSeconds(const QString &selectedDate) const;
    QString todayTotalFormatted(const QString &selectedDate) const;
    QString vsAverageText(const QString &selectedDate) const;

    QVariantList appUsageList(const QString &selectedDate) const;
    QVariantList weeklyChartData(const QString &selectedDate) const;
    QVariantList categoryBreakdown(const QString &selectedDate) const;

    bool checkLimitExceeded(const QString &dateStr, const QString &appId, int &limitMins, int &currentSecs);

    const QMap<QString, QMap<QString, int>> &dailyUsage() const { return m_dailyUsage; }

Q_SIGNALS:
    void dataChanged();
    void appLimitExceeded(const QString &appId, int limitMinutes, int currentSeconds);

private:
    // dateStr ("YYYY-MM-DD") -> (appId -> seconds)
    QMap<QString, QMap<QString, int>> m_dailyUsage;
    // appId -> limitMinutes
    QMap<QString, int> m_appLimits;
    // Set of "YYYY-MM-DD|appId" already notified in this session
    QSet<QString> m_notifiedLimits;
};
