/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "screentimetracker.h"

#include <QDate>
#include <QDir>
#include <QStandardPaths>

ScreenTimeTracker::ScreenTimeTracker(const QString &storageDir, QObject *parent)
    : QObject(parent)
    , m_selectedDate(QDate::currentDate().toString(Qt::ISODate))
    , m_store(this)
    , m_listener(this)
{
    const bool isDefaultStorage = storageDir.trimmed().isEmpty();
    if (isDefaultStorage) {
        m_storageDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
            + QStringLiteral("/kscreentime");
    } else {
        m_storageDir = storageDir.trimmed();
    }

    QDir().mkpath(m_storageDir);
    m_store.loadFromDisk(storageFilePath());

    connect(&m_store, &ScreenTimeStore::dataChanged,
            this, &ScreenTimeTracker::dataChanged);
    connect(&m_store, &ScreenTimeStore::appLimitExceeded,
            this, [this](const QString &appId, int limitMinutes, int currentSeconds) {
                Q_EMIT appLimitExceeded(appId, limitMinutes, currentSeconds);
                if (m_listener.isLiveMode()) {
                    KWinWindowListener::sendDesktopNotification(
                        QStringLiteral("Tiempo de Uso — Límite alcanzado"),
                        QStringLiteral("Has superado el límite diario de %1 min en %2 (%3).")
                            .arg(limitMinutes)
                            .arg(displayNameForApp(appId))
                            .arg(formatDuration(currentSeconds)));
                }
            });

    m_tickTimer.setInterval(1000);
    connect(&m_tickTimer, &QTimer::timeout, this, &ScreenTimeTracker::tickActiveApp);

    if (isDefaultStorage) {
        QTimer::singleShot(0, this, &ScreenTimeTracker::startLiveTracking);
    }
}

ScreenTimeTracker::~ScreenTimeTracker()
{
    stopLiveTracking();
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

QString ScreenTimeTracker::storageFilePath() const
{
    return m_storageDir + QStringLiteral("/usage.json");
}

QString ScreenTimeTracker::currentActiveDisplayName() const
{
    if (m_currentActiveApp.isEmpty()) {
        return QStringLiteral("Escritorio Wayland (sin ventana activa)");
    }
    return displayNameForApp(m_currentActiveApp);
}

void ScreenTimeTracker::setWindowVisible(bool visible)
{
    if (m_windowVisible == visible) {
        return;
    }
    m_windowVisible = visible;
    Q_EMIT windowVisibleChanged();
}

void ScreenTimeTracker::recordActiveApp(const QString &appClass, const QString &caption)
{
    const QString normalized = normalizeAppId(appClass);
    const QString cleanCaption = caption.trimmed();

    const bool changed = (m_currentActiveApp != normalized) || (m_currentActiveCaption != cleanCaption);
    m_currentActiveApp = normalized;
    m_currentActiveCaption = cleanCaption;

    if (changed) {
        Q_EMIT activeAppChanged();
    }
}

void ScreenTimeTracker::addUsageSeconds(const QString &dateStr, const QString &appId, int seconds)
{
    m_store.addUsageSeconds(dateStr, appId, seconds);
    m_store.saveToDisk(m_storageDir, storageFilePath());
    Q_EMIT dataChanged();
}

void ScreenTimeTracker::setAppLimit(const QString &appId, int limitMinutes)
{
    m_store.setAppLimit(appId, limitMinutes);
    m_store.saveToDisk(m_storageDir, storageFilePath());
    Q_EMIT dataChanged();
}

void ScreenTimeTracker::selectDate(const QString &dateStr)
{
    const QString trimmed = dateStr.trimmed();
    if (trimmed.isEmpty() || trimmed == m_selectedDate) {
        return;
    }
    m_selectedDate = trimmed;
    Q_EMIT dataChanged();
}

void ScreenTimeTracker::tickActiveApp()
{
    if (m_currentActiveApp.isEmpty()) {
        return;
    }
    if (m_listener.isLiveMode() && KWinWindowListener::isScreenLocked()) {
        return;
    }

    const QString todayStr = QDate::currentDate().toString(Qt::ISODate);
    if (m_selectedDate != todayStr && m_store.dailyUsage().value(m_selectedDate).isEmpty()) {
        m_selectedDate = todayStr;
    }

    m_store.addUsageSeconds(todayStr, m_currentActiveApp, 1);

    ++m_ticksSinceSave;
    if (m_ticksSinceSave >= 5) {
        m_ticksSinceSave = 0;
        m_store.saveToDisk(m_storageDir, storageFilePath());
    }

    Q_EMIT dataChanged();
}

void ScreenTimeTracker::clearAllData()
{
    m_store.clearAll();
    m_store.saveToDisk(m_storageDir, storageFilePath());
    Q_EMIT dataChanged();
}

bool ScreenTimeTracker::startLiveTracking()
{
    const bool ok = m_listener.startLiveTracking(this);
    m_tickTimer.start();
    return ok;
}

void ScreenTimeTracker::stopLiveTracking()
{
    m_tickTimer.stop();
    m_listener.stopLiveTracking();
}

void ScreenTimeTracker::RecordActiveApp(const QString &appClass, const QString &caption)
{
    recordActiveApp(appClass, caption);
}

void ScreenTimeTracker::ShowWindow()
{
    setWindowVisible(true);
    Q_EMIT showWindowRequested();
}

void ScreenTimeTracker::ClearAllData()
{
    clearAllData();
}

void ScreenTimeTracker::setDowntimeEnabled(bool enabled)
{
    m_store.setDowntimeEnabled(enabled);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::setDowntimeStart(const QString &start)
{
    m_store.setDowntimeStart(start);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::setDowntimeEnd(const QString &end)
{
    m_store.setDowntimeEnd(end);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::setDowntimeBlockAtLimit(bool block)
{
    m_store.setDowntimeBlockAtLimit(block);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::addAlwaysAllowedApp(const QString &appId)
{
    m_store.addAlwaysAllowedApp(appId);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::removeAlwaysAllowedApp(const QString &appId)
{
    m_store.removeAlwaysAllowedApp(appId);
    m_store.saveToDisk(m_storageDir, storageFilePath());
}

void ScreenTimeTracker::setChartViewMode(const QString &mode)
{
    if (m_chartViewMode != mode) {
        m_chartViewMode = mode;
        Q_EMIT chartViewModeChanged();
    }
}
