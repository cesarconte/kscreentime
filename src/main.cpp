/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "screentimetracker.h"

#include <QApplication>
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

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    ScreenTimeTracker tracker;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Tracker"), &tracker);
    engine.load(QUrl(QStringLiteral("qrc:/org/cesar/kscreentime/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
