/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#pragma once

#include <QMap>
#include <QObject>
#include <QSet>
#include <QString>
#include <QTimer>
#include <QVariantList>

class ScreenTimeTracker : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.cesar.kscreentime.Tracker")

    Q_PROPERTY(QString selectedDate READ selectedDate WRITE selectDate NOTIFY dataChanged)
    Q_PROPERTY(int todayTotalSeconds READ todayTotalSeconds NOTIFY dataChanged)
    Q_PROPERTY(QString todayTotalFormatted READ todayTotalFormatted NOTIFY dataChanged)
    Q_PROPERTY(QString vsAverageText READ vsAverageText NOTIFY dataChanged)
    Q_PROPERTY(QString currentActiveApp READ currentActiveApp NOTIFY activeAppChanged)
    Q_PROPERTY(QString currentActiveDisplayName READ currentActiveDisplayName NOTIFY activeAppChanged)
    Q_PROPERTY(QString currentActiveCaption READ currentActiveCaption NOTIFY activeAppChanged)
    Q_PROPERTY(QVariantList appUsageList READ appUsageList NOTIFY dataChanged)
    Q_PROPERTY(QVariantList weeklyChartData READ weeklyChartData NOTIFY dataChanged)
    Q_PROPERTY(QVariantList categoryBreakdown READ categoryBreakdown NOTIFY dataChanged)

public:
    explicit ScreenTimeTracker(const QString &storageDir = QString(), QObject *parent = nullptr);
    ~ScreenTimeTracker() override;

    QString storageFilePath() const;
    QString selectedDate() const;
    int todayTotalSeconds() const;
    QString todayTotalFormatted() const;
    QString vsAverageText() const;
    QString currentActiveApp() const;
    QString currentActiveDisplayName() const;
    QString currentActiveCaption() const;

    QVariantList appUsageList() const;
    QVariantList weeklyChartData() const;
    QVariantList categoryBreakdown() const;

    Q_INVOKABLE void recordActiveApp(const QString &appClass, const QString &caption = QString());
    Q_INVOKABLE void addUsageSeconds(const QString &dateStr, const QString &appId, int seconds);
    Q_INVOKABLE void setAppLimit(const QString &appId, int limitMinutes);
    Q_INVOKABLE void selectDate(const QString &dateStr);
    Q_INVOKABLE void tickActiveApp();

    bool startLiveTracking();
    void stopLiveTracking();

    static QString classifyAppCategory(const QString &appId);
    static QString formatDuration(int totalSeconds);
    static QString displayNameForApp(const QString &appId);
    static QString iconNameForApp(const QString &appId);
    static QString iconNameForCategory(const QString &category);
    static QString normalizeAppId(const QString &rawAppClass);

public Q_SLOTS:
    Q_SCRIPTABLE void RecordActiveApp(const QString &appClass, const QString &caption = QString());

Q_SIGNALS:
    void dataChanged();
    void activeAppChanged();
    void appLimitExceeded(const QString &appId, int limitMinutes, int currentSeconds);

private:
    void loadFromDisk();
    void saveToDisk() const;
    void seedInitialDataIfEmpty();
    void checkAndNotifyLimit(const QString &dateStr, const QString &appId);
    void sendDesktopNotification(const QString &title, const QString &body) const;
    QString detectFallbackRunningGuiApp() const;

    QString m_storageDir;
    QString m_selectedDate;
    QString m_currentActiveApp;
    QString m_currentActiveCaption;
    bool m_liveMode = false;
    bool m_kwinHookLoaded = false;
    int m_ticksSinceSave = 0;

    // dateStr ("YYYY-MM-DD") -> (appId -> seconds)
    QMap<QString, QMap<QString, int>> m_dailyUsage;
    // appId -> limitMinutes (<= 0 means no limit)
    QMap<QString, int> m_appLimits;
    // Set of "YYYY-MM-DD|appId" already notified in this session
    QSet<QString> m_notifiedLimits;

    QTimer m_tickTimer;
};
