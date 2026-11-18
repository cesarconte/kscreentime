/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#pragma once

#include <QHash>
#include <QString>

struct DesktopEntryMeta {
    QString displayName;
    QString iconName;
    QString categoriesRaw;
};

class AppClassifier
{
public:
    static const QHash<QString, DesktopEntryMeta> &installedDesktopEntries();
    static QString classifyAppCategory(const QString &appId);
    static QString formatDuration(int totalSeconds);
    static QString displayNameForApp(const QString &appId);
    static QString iconNameForApp(const QString &appId);
    static QString iconNameForCategory(const QString &category);
    static QString normalizeAppId(const QString &rawAppClass);
};
