/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include <QObject>
#include <QString>

class KWinWindowListener : public QObject
{
    Q_OBJECT

public:
    explicit KWinWindowListener(QObject *parent = nullptr);
    ~KWinWindowListener() override;

    bool startLiveTracking(QObject *dbusExportObject);
    void stopLiveTracking();
    bool isLiveMode() const { return m_liveMode; }

    static bool isScreenLocked();
    static void sendDesktopNotification(const QString &title, const QString &body);

private:
    bool m_liveMode = false;
    int m_kwinScriptId = -1;
};
