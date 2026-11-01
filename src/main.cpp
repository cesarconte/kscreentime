/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "screentimetracker.h"

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kscreentime"));
    app.setApplicationDisplayName(QStringLiteral("KScreenTime — Tiempo de Uso"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("preferences-system-time")));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Wayland Screen Time Tracker & Dashboard for KDE Plasma 6"));
    parser.addHelpOption();
    QCommandLineOption daemonOpt(QStringLiteral("daemon"),
                                 QStringLiteral("Run in background daemon mode tracking Wayland active window time."));
    parser.addOption(daemonOpt);
    parser.process(app);

    const bool isDaemon = parser.isSet(daemonOpt);

    // Check if an instance is already running on D-Bus
    QDBusConnection bus = QDBusConnection::sessionBus();
    QDBusInterface existingIface(QStringLiteral("org.cesar.kscreentime"),
                                 QStringLiteral("/Tracker"),
                                 QStringLiteral("org.cesar.kscreentime.Tracker"),
                                 bus);
    if (existingIface.isValid()) {
        if (!isDaemon) {
            existingIface.call(QStringLiteral("ShowWindow"));
        }
        return 0;
    }

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    if (isDaemon) {
        app.setQuitOnLastWindowClosed(false);
    }

    ScreenTimeTracker tracker;
    tracker.setWindowVisible(!isDaemon);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Tracker"), &tracker);
    engine.load(QUrl(QStringLiteral("qrc:/org/cesar/kscreentime/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
