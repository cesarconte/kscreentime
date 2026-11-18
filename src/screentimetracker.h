/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include "appclassifier.h"
#include "kwinwindowlistener.h"
#include "screentimestore.h"

#include <QObject>
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
    Q_PROPERTY(bool windowVisible READ windowVisible WRITE setWindowVisible NOTIFY windowVisibleChanged)

public:
    explicit ScreenTimeTracker(const QString &storageDir = QString(), QObject *parent = nullptr);
    ~ScreenTimeTracker() override;

    QString storageFilePath() const;
    QString selectedDate() const { return m_selectedDate; }
    int todayTotalSeconds() const { return m_store.todayTotalSeconds(m_selectedDate); }
    QString todayTotalFormatted() const { return m_store.todayTotalFormatted(m_selectedDate); }
    QString vsAverageText() const { return m_store.vsAverageText(m_selectedDate); }
    QString currentActiveApp() const { return m_currentActiveApp; }
    QString currentActiveDisplayName() const;
    QString currentActiveCaption() const { return m_currentActiveCaption; }
    bool windowVisible() const { return m_windowVisible; }
    void setWindowVisible(bool visible);

    QVariantList appUsageList() const { return m_store.appUsageList(m_selectedDate); }
    QVariantList weeklyChartData() const { return m_store.weeklyChartData(m_selectedDate); }
    QVariantList categoryBreakdown() const { return m_store.categoryBreakdown(m_selectedDate); }

    Q_INVOKABLE void recordActiveApp(const QString &appClass, const QString &caption = QString());
    Q_INVOKABLE void addUsageSeconds(const QString &dateStr, const QString &appId, int seconds);
    Q_INVOKABLE void setAppLimit(const QString &appId, int limitMinutes);
    Q_INVOKABLE void selectDate(const QString &dateStr);
    Q_INVOKABLE void tickActiveApp();
    Q_INVOKABLE void clearAllData();

    bool startLiveTracking();
    void stopLiveTracking();

    // Static forwarders for unit tests and backwards compatibility
    static QString classifyAppCategory(const QString &appId)
    {
        return AppClassifier::classifyAppCategory(appId);
    }
    static QString formatDuration(int totalSeconds)
    {
        return AppClassifier::formatDuration(totalSeconds);
    }
    static QString displayNameForApp(const QString &appId)
    {
        return AppClassifier::displayNameForApp(appId);
    }
    static QString iconNameForApp(const QString &appId)
    {
        return AppClassifier::iconNameForApp(appId);
    }
    static QString iconNameForCategory(const QString &category)
    {
        return AppClassifier::iconNameForCategory(category);
    }
    static QString normalizeAppId(const QString &rawAppClass)
    {
        return AppClassifier::normalizeAppId(rawAppClass);
    }

public Q_SLOTS:
    Q_SCRIPTABLE void RecordActiveApp(const QString &appClass, const QString &caption = QString());
    Q_SCRIPTABLE void ShowWindow();
    Q_SCRIPTABLE void ClearAllData();

Q_SIGNALS:
    void dataChanged();
    void activeAppChanged();
    void windowVisibleChanged();
    void showWindowRequested();
    void appLimitExceeded(const QString &appId, int limitMinutes, int currentSeconds);

private:
    QString m_storageDir;
    QString m_selectedDate;
    QString m_currentActiveApp;
    QString m_currentActiveCaption;
    bool m_windowVisible = true;
    int m_ticksSinceSave = 0;

    ScreenTimeStore m_store;
    KWinWindowListener m_listener;
    QTimer m_tickTimer;
};
