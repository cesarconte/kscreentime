/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "appclassifier.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QStandardPaths>
#include <QStringList>

const QHash<QString, DesktopEntryMeta> &AppClassifier::installedDesktopEntries()
{
    static QHash<QString, DesktopEntryMeta> cache;
    static bool initialized = false;
    if (initialized) {
        return cache;
    }
    initialized = true;

    const QStringList appDirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    for (const QString &dirPath : appDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) {
            continue;
        }
        const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.desktop")}, QDir::Files);
        for (const QFileInfo &fi : files) {
            QFile file(fi.absoluteFilePath());
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                continue;
            }

            QString nameEs;
            QString nameDefault;
            QString icon;
            QString categories;
            QString wmClass;
            QString execBin;
            bool inMainGroup = false;

            while (!file.atEnd()) {
                const QString line = QString::fromUtf8(file.readLine()).trimmed();
                if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
                    continue;
                }
                if (line.startsWith(QLatin1Char('['))) {
                    inMainGroup = (line == QStringLiteral("[Desktop Entry]"));
                    continue;
                }
                if (!inMainGroup) {
                    continue;
                }

                const int eqIdx = line.indexOf(QLatin1Char('='));
                if (eqIdx <= 0) {
                    continue;
                }
                const QString key = line.left(eqIdx).trimmed();
                const QString val = line.mid(eqIdx + 1).trimmed();

                if (key == QStringLiteral("Name[es]")) {
                    nameEs = val;
                } else if (key == QStringLiteral("Name") && nameDefault.isEmpty()) {
                    nameDefault = val;
                } else if (key == QStringLiteral("Icon") && icon.isEmpty()) {
                    icon = val;
                } else if (key == QStringLiteral("Categories") && categories.isEmpty()) {
                    categories = val;
                } else if (key == QStringLiteral("StartupWMClass") && wmClass.isEmpty()) {
                    wmClass = val.toLower();
                } else if (key == QStringLiteral("Exec") && execBin.isEmpty()) {
                    QString token = val.split(QLatin1Char(' '), Qt::SkipEmptyParts).value(0);
                    token.remove(QLatin1Char('"'));
                    execBin = QFileInfo(token).baseName().toLower();
                }
            }

            DesktopEntryMeta meta;
            meta.displayName = !nameEs.isEmpty() ? nameEs : nameDefault;
            meta.iconName = icon;
            meta.categoriesRaw = categories;

            if (meta.displayName.isEmpty()) {
                continue;
            }

            const QString stem = fi.completeBaseName().toLower();
            if (!cache.contains(stem)) {
                cache.insert(stem, meta);
            }
            const int lastDot = stem.lastIndexOf(QLatin1Char('.'));
            if (lastDot >= 0 && lastDot + 1 < stem.size()) {
                const QString shortStem = stem.mid(lastDot + 1);
                if (!cache.contains(shortStem)) {
                    cache.insert(shortStem, meta);
                }
            }
            if (!wmClass.isEmpty() && !cache.contains(wmClass)) {
                cache.insert(wmClass, meta);
            }
            if (!execBin.isEmpty() && !cache.contains(execBin)) {
                cache.insert(execBin, meta);
            }
        }
    }
    return cache;
}

QString AppClassifier::classifyAppCategory(const QString &appId)
{
    const QString norm = normalizeAppId(appId);
    const auto &entries = installedDesktopEntries();
    if (entries.contains(norm)) {
        const QString cats = entries.value(norm).categoriesRaw.toLower();
        if (cats.contains(QStringLiteral("development")) || cats.contains(QStringLiteral("ide"))
            || cats.contains(QStringLiteral("terminalemulator"))) {
            return QStringLiteral("Desarrollo");
        }
        if (cats.contains(QStringLiteral("webbrowser"))) {
            return QStringLiteral("Navegación");
        }
        if (cats.contains(QStringLiteral("instantmessaging")) || cats.contains(QStringLiteral("email"))
            || cats.contains(QStringLiteral("chat")) || cats.contains(QStringLiteral("ircclient"))) {
            return QStringLiteral("Comunicación");
        }
        if (cats.contains(QStringLiteral("audiovideo")) || cats.contains(QStringLiteral("audio"))
            || cats.contains(QStringLiteral("video")) || cats.contains(QStringLiteral("graphics"))
            || cats.contains(QStringLiteral("photography"))) {
            return QStringLiteral("Multimedia");
        }
    }

    static const QStringList kDevKeywords = {
        QStringLiteral("code"), QStringLiteral("vscodium"), QStringLiteral("kate"),
        QStringLiteral("kdevelop"), QStringLiteral("konsole"), QStringLiteral("yakuake"),
        QStringLiteral("alacritty"), QStringLiteral("kitty"), QStringLiteral("wezterm"),
        QStringLiteral("ghostty"), QStringLiteral("nvim"), QStringLiteral("vim"),
        QStringLiteral("jetbrains"), QStringLiteral("clion"), QStringLiteral("pycharm"),
        QStringLiteral("idea"), QStringLiteral("qtcreator"), QStringLiteral("cursor"),
        QStringLiteral("zed"), QStringLiteral("antigravity")
    };
    for (const QString &kw : kDevKeywords) {
        if (norm.contains(kw)) {
            return QStringLiteral("Desarrollo");
        }
    }

    static const QStringList kBrowserKeywords = {
        QStringLiteral("firefox"), QStringLiteral("chrome"), QStringLiteral("chromium"),
        QStringLiteral("brave"), QStringLiteral("vivaldi"), QStringLiteral("librewolf"),
        QStringLiteral("zen"), QStringLiteral("falkon"), QStringLiteral("edge"),
        QStringLiteral("opera"), QStringLiteral("tor")
    };
    for (const QString &kw : kBrowserKeywords) {
        if (norm.contains(kw)) {
            return QStringLiteral("Navegación");
        }
    }

    static const QStringList kMediaKeywords = {
        QStringLiteral("spotify"), QStringLiteral("vlc"), QStringLiteral("mpv"),
        QStringLiteral("elisa"), QStringLiteral("haruna"), QStringLiteral("kdenlive"),
        QStringLiteral("obs"), QStringLiteral("gimp"), QStringLiteral("inkscape"),
        QStringLiteral("krita"), QStringLiteral("blender"), QStringLiteral("audacity"),
        QStringLiteral("gwenview"), QStringLiteral("okular"), QStringLiteral("easyeffects"),
        QStringLiteral("kvoicememos")
    };
    for (const QString &kw : kMediaKeywords) {
        if (norm.contains(kw)) {
            return QStringLiteral("Multimedia");
        }
    }

    static const QStringList kCommKeywords = {
        QStringLiteral("telegram"), QStringLiteral("discord"), QStringLiteral("vesktop"),
        QStringLiteral("slack"), QStringLiteral("signal"), QStringLiteral("thunderbird"),
        QStringLiteral("kmail"), QStringLiteral("neochat"), QStringLiteral("element"),
        QStringLiteral("whatsapp"), QStringLiteral("zoom"), QStringLiteral("teams"),
        QStringLiteral("proton")
    };
    for (const QString &kw : kCommKeywords) {
        if (norm.contains(kw)) {
            return QStringLiteral("Comunicación");
        }
    }

    return QStringLiteral("Sistema");
}

QString AppClassifier::formatDuration(int totalSeconds)
{
    if (totalSeconds <= 0) {
        return QStringLiteral("0m");
    }
    const int hours = totalSeconds / 3600;
    const int minutes = (totalSeconds % 3600) / 60;
    const int seconds = totalSeconds % 60;

    if (hours > 0) {
        return QStringLiteral("%1h %2m").arg(hours).arg(minutes);
    }
    if (minutes > 0) {
        return QStringLiteral("%1m").arg(minutes);
    }
    return QStringLiteral("%1s").arg(seconds);
}

QString AppClassifier::displayNameForApp(const QString &appId)
{
    const QString norm = normalizeAppId(appId);
    const auto &entries = installedDesktopEntries();
    if (entries.contains(norm) && !entries.value(norm).displayName.isEmpty()) {
        return entries.value(norm).displayName;
    }

    const int lastDot = norm.lastIndexOf(QLatin1Char('.'));
    if (lastDot >= 0 && lastDot + 1 < norm.size()) {
        const QString shortKey = norm.mid(lastDot + 1);
        if (entries.contains(shortKey) && !entries.value(shortKey).displayName.isEmpty()) {
            return entries.value(shortKey).displayName;
        }
    }

    QString cleaned = appId.trimmed();
    if (cleaned.endsWith(QStringLiteral(".desktop"), Qt::CaseInsensitive)) {
        cleaned.chop(8);
    }
    const int dotIdx = cleaned.lastIndexOf(QLatin1Char('.'));
    if (dotIdx >= 0 && dotIdx + 1 < cleaned.size()) {
        cleaned = cleaned.mid(dotIdx + 1);
    }
    if (!cleaned.isEmpty()) {
        cleaned[0] = cleaned[0].toUpper();
    }
    return cleaned;
}

QString AppClassifier::iconNameForApp(const QString &appId)
{
    const QString norm = normalizeAppId(appId);
    const auto &entries = installedDesktopEntries();
    if (entries.contains(norm)) {
        const QString icon = entries.value(norm).iconName;
        if (!icon.isEmpty() && (QIcon::hasThemeIcon(icon) || QFileInfo::exists(icon))) {
            return icon;
        }
    }

    const int lastDot = norm.lastIndexOf(QLatin1Char('.'));
    if (lastDot >= 0 && lastDot + 1 < norm.size()) {
        const QString shortKey = norm.mid(lastDot + 1);
        if (entries.contains(shortKey)) {
            const QString icon = entries.value(shortKey).iconName;
            if (!icon.isEmpty() && (QIcon::hasThemeIcon(icon) || QFileInfo::exists(icon))) {
                return icon;
            }
        }
    }

    return iconNameForCategory(classifyAppCategory(appId));
}

QString AppClassifier::iconNameForCategory(const QString &category)
{
    if (category == QStringLiteral("Desarrollo")) {
        return QStringLiteral("applications-development");
    }
    if (category == QStringLiteral("Navegación")) {
        return QStringLiteral("applications-internet");
    }
    if (category == QStringLiteral("Multimedia")) {
        return QStringLiteral("applications-multimedia");
    }
    if (category == QStringLiteral("Comunicación")) {
        return QStringLiteral("mail-message");
    }
    return QStringLiteral("applications-system");
}

QString AppClassifier::normalizeAppId(const QString &rawAppClass)
{
    QString s = rawAppClass.trimmed().toLower();
    if (s.endsWith(QStringLiteral(".desktop"))) {
        s.chop(8);
    }
    return s;
}
