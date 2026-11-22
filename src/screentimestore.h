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
    QVariantList allLimitsList() const;

    bool checkLimitExceeded(const QString &dateStr, const QString &appId, int &limitMins, int &currentSecs);

    const QMap<QString, QMap<QString, int>> &dailyUsage() const { return m_dailyUsage; }

    // Downtime settings
    bool downtimeEnabled() const { return m_downtimeEnabled; }
    void setDowntimeEnabled(bool enabled);
    QString downtimeStart() const { return m_downtimeStart; }
    void setDowntimeStart(const QString &start);
    QString downtimeEnd() const { return m_downtimeEnd; }
    void setDowntimeEnd(const QString &end);
    bool downtimeBlockAtLimit() const { return m_downtimeBlockAtLimit; }
    void setDowntimeBlockAtLimit(bool block);
    bool isDowntimeActive() const;

    // Always allowed apps
    QStringList alwaysAllowedApps() const { return m_alwaysAllowedApps; }
    void setAlwaysAllowedApps(const QStringList &apps);
    void addAlwaysAllowedApp(const QString &appId);
    void removeAlwaysAllowedApp(const QString &appId);
    bool isAlwaysAllowed(const QString &appId) const;

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

    // Golden Gate Settings
    bool m_downtimeEnabled = false;
    QString m_downtimeStart = QStringLiteral("22:00");
    QString m_downtimeEnd = QStringLiteral("07:00");
    bool m_downtimeBlockAtLimit = true;
    QStringList m_alwaysAllowedApps = {
        QStringLiteral("kdialer"),
        QStringLiteral("messages"),
        QStringLiteral("kclock"),
        QStringLiteral("ksettings"),
        QStringLiteral("kreminders")
    };
};
