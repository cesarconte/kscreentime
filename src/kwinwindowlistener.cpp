/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "kwinwindowlistener.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QStringList>
#include <QVariantMap>

KWinWindowListener::KWinWindowListener(QObject *parent)
    : QObject(parent)
{
}

KWinWindowListener::~KWinWindowListener()
{
    stopLiveTracking();
}

bool KWinWindowListener::startLiveTracking(QObject *dbusExportObject)
{
    if (m_liveMode) {
        return true;
    }
    m_liveMode = true;

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected() && dbusExportObject) {
        bus.registerService(QStringLiteral("org.cesar.kscreentime"));
        bus.registerObject(QStringLiteral("/Tracker"),
                           dbusExportObject,
                           QDBusConnection::ExportAllSlots | QDBusConnection::ExportScriptableSlots | QDBusConnection::ExportAllProperties);

        const QString scriptPath = QDir::tempPath() + QStringLiteral("/kscreentime_kwin_hook.js");
        QFile f(scriptPath);
        if (f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
            const QString js = QStringLiteral(
                "const ignored = [\n"
                "    \"plasmashell\", \"org.kde.plasmashell\",\n"
                "    \"kscreenlocker_greet\", \"org.kde.kscreenlocker_greet\",\n"
                "    \"krunner\", \"org.kde.krunner\",\n"
                "    \"klivecaptions\", \"org.cesar.klivecaptions\",\n"
                "    \"kdictation\", \"org.cesar.kdictation\",\n"
                "    \"kdropover\", \"org.cesar.kdropover\"\n"
                "];\n"
                "function isTrackable(w) {\n"
                "    if (!w || !w.normalWindow || w.minimized || w.deleted) return false;\n"
                "    if (w.specialWindow || w.desktopWindow || w.dock || w.splash || w.notification || w.onScreenDisplay || w.criticalNotification || w.appletPopup) return false;\n"
                "    const cls = (w.desktopFileName || w.resourceClass || w.resourceName || \"\").toString().toLowerCase();\n"
                "    if (cls.length === 0) return false;\n"
                "    for (let i = 0; i < ignored.length; ++i) {\n"
                "        if (cls === ignored[i] || cls.indexOf(ignored[i]) !== -1) return false;\n"
                "    }\n"
                "    return true;\n"
                "}\n"
                "function findTopWindow() {\n"
                "    if (workspace.activeWindow && isTrackable(workspace.activeWindow)) {\n"
                "        return workspace.activeWindow;\n"
                "    }\n"
                "    const stack = workspace.stackingOrder;\n"
                "    if (stack && stack.length) {\n"
                "        for (let i = stack.length - 1; i >= 0; --i) {\n"
                "            if (isTrackable(stack[i])) {\n"
                "                return stack[i];\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "    return null;\n"
                "}\n"
                "function report() {\n"
                "    const target = findTopWindow();\n"
                "    if (target) {\n"
                "        const cls = (target.desktopFileName || target.resourceClass || target.resourceName || \"\").toString();\n"
                "        const cap = (target.caption || \"\").toString();\n"
                "        callDBus(\"org.cesar.kscreentime\", \"/Tracker\", \"org.cesar.kscreentime.Tracker\", \"RecordActiveApp\", cls, cap);\n"
                "    } else {\n"
                "        callDBus(\"org.cesar.kscreentime\", \"/Tracker\", \"org.cesar.kscreentime.Tracker\", \"RecordActiveApp\", \"\", \"\");\n"
                "    }\n"
                "}\n"
                "report();\n"
                "workspace.windowActivated.connect(report);\n");
            f.write(js.toUtf8());
            f.close();

            QDBusInterface kwinScripting(QStringLiteral("org.kde.KWin"),
                                         QStringLiteral("/Scripting"),
                                         QStringLiteral("org.kde.kwin.Scripting"),
                                         bus);
            if (kwinScripting.isValid()) {
                const QDBusReply<int> loadReply = kwinScripting.call(QStringLiteral("loadScript"), scriptPath);
                if (loadReply.isValid() && loadReply.value() >= 0) {
                    m_kwinScriptId = loadReply.value();
                    const QString scriptObjPath = QStringLiteral("/Scripting/Script%1").arg(m_kwinScriptId);
                    QDBusInterface scriptIface(QStringLiteral("org.kde.KWin"),
                                               scriptObjPath,
                                               QStringLiteral("org.kde.kwin.Script"),
                                               bus);
                    scriptIface.call(QStringLiteral("run"));
                }
            }
        }
    }

    return m_kwinScriptId >= 0;
}

void KWinWindowListener::stopLiveTracking()
{
    if (!m_liveMode) {
        return;
    }
    m_liveMode = false;

    if (m_kwinScriptId >= 0) {
        const QString scriptObjPath = QStringLiteral("/Scripting/Script%1").arg(m_kwinScriptId);
        QDBusInterface scriptIface(QStringLiteral("org.kde.KWin"),
                                   scriptObjPath,
                                   QStringLiteral("org.kde.kwin.Script"),
                                   QDBusConnection::sessionBus());
        if (scriptIface.isValid()) {
            scriptIface.call(QStringLiteral("stop"));
        }
        m_kwinScriptId = -1;
    }
}

bool KWinWindowListener::isScreenLocked()
{
    QDBusInterface screenSaver(QStringLiteral("org.freedesktop.ScreenSaver"),
                               QStringLiteral("/ScreenSaver"),
                               QStringLiteral("org.freedesktop.ScreenSaver"),
                               QDBusConnection::sessionBus());
    if (!screenSaver.isValid()) {
        return false;
    }
    const QDBusReply<bool> reply = screenSaver.call(QStringLiteral("GetActive"));
    return reply.isValid() && reply.value();
}

void KWinWindowListener::sendDesktopNotification(const QString &title, const QString &body)
{
    QDBusInterface notifyIface(QStringLiteral("org.freedesktop.Notifications"),
                               QStringLiteral("/org/freedesktop/Notifications"),
                               QStringLiteral("org.freedesktop.Notifications"),
                               QDBusConnection::sessionBus());
    if (!notifyIface.isValid()) {
        return;
    }

    notifyIface.call(QStringLiteral("Notify"),
                     QStringLiteral("KScreenTime"),
                     uint(0),
                     QStringLiteral("preferences-system-time"),
                     title,
                     body,
                     QStringList(),
                     QVariantMap(),
                     int(5000));
}
