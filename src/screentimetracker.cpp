/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "screentimetracker.h"

#include <QDate>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QVariantMap>

#include <algorithm>
#include <cmath>

namespace {
const QString kKWinPluginName = QStringLiteral("kscreentime_tracker");
}

ScreenTimeTracker::ScreenTimeTracker(const QString &storageDir, QObject *parent)
    : QObject(parent)
    , m_selectedDate(QDate::currentDate().toString(Qt::ISODate))
{
    const bool isDefaultStorage = storageDir.trimmed().isEmpty();
    if (isDefaultStorage) {
        m_storageDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
            + QStringLiteral("/kscreentime");
    } else {
        m_storageDir = storageDir.trimmed();
    }

    QDir().mkpath(m_storageDir);
    loadFromDisk();

    m_tickTimer.setInterval(1000);
    connect(&m_tickTimer, &QTimer::timeout, this, &ScreenTimeTracker::tickActiveApp);

    if (isDefaultStorage) {
        seedInitialDataIfEmpty();
        startLiveTracking();
    }
}

ScreenTimeTracker::~ScreenTimeTracker()
{
    stopLiveTracking();
    saveToDisk();
}

QString ScreenTimeTracker::storageFilePath() const
{
    return m_storageDir + QStringLiteral("/usage.json");
}

QString ScreenTimeTracker::selectedDate() const
{
    return m_selectedDate;
}

int ScreenTimeTracker::todayTotalSeconds() const
{
    const auto dayMap = m_dailyUsage.value(m_selectedDate);
    int total = 0;
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        total += std::max(0, it.value());
    }
    return total;
}

QString ScreenTimeTracker::todayTotalFormatted() const
{
    return formatDuration(todayTotalSeconds());
}

QString ScreenTimeTracker::vsAverageText() const
{
    const QDate refDate = QDate::fromString(m_selectedDate, Qt::ISODate).isValid()
        ? QDate::fromString(m_selectedDate, Qt::ISODate)
        : QDate::currentDate();

    int sum7 = 0;
    int activeDays = 0;
    for (int i = 0; i < 7; ++i) {
        const QString dStr = refDate.addDays(-i).toString(Qt::ISODate);
        const auto dayMap = m_dailyUsage.value(dStr);
        int daySum = 0;
        for (int secs : dayMap) {
            daySum += std::max(0, secs);
        }
        sum7 += daySum;
        if (daySum > 0) {
            ++activeDays;
        }
    }

    const int avgSeconds = activeDays > 0 ? (sum7 / activeDays) : 0;
    const int currentSeconds = todayTotalSeconds();
    if (avgSeconds <= 0) {
        return QStringLiteral("Sin datos previos en los últimos 7 días");
    }

    const int diffPct = static_cast<int>(std::round(((currentSeconds - avgSeconds) * 100.0) / avgSeconds));
    const QString avgFormatted = formatDuration(avgSeconds);
    if (std::abs(diffPct) <= 2) {
        return QStringLiteral("En la media de 7 días (%1)").arg(avgFormatted);
    }
    if (diffPct > 0) {
        return QStringLiteral("+%1% frente a la media (%2)").arg(diffPct).arg(avgFormatted);
    }
    return QStringLiteral("%1% frente a la media (%2)").arg(diffPct).arg(avgFormatted);
}

QString ScreenTimeTracker::currentActiveApp() const
{
    return m_currentActiveApp;
}

QString ScreenTimeTracker::currentActiveDisplayName() const
{
    if (m_currentActiveApp.isEmpty()) {
        return QStringLiteral("Escritorio Wayland");
    }
    return displayNameForApp(m_currentActiveApp);
}

QString ScreenTimeTracker::currentActiveCaption() const
{
    return m_currentActiveCaption;
}

QVariantList ScreenTimeTracker::appUsageList() const
{
    const auto dayMap = m_dailyUsage.value(m_selectedDate);
    int totalSecs = 0;
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        totalSecs += std::max(0, it.value());
    }

    struct Entry {
        QString appId;
        int seconds;
    };
    QList<Entry> entries;
    entries.reserve(dayMap.size());
    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        if (it.value() > 0) {
            entries.push_back({it.key(), it.value()});
        }
    }

    std::sort(entries.begin(), entries.end(), [](const Entry &a, const Entry &b) {
        if (a.seconds != b.seconds) {
            return a.seconds > b.seconds;
        }
        return a.appId < b.appId;
    });

    QVariantList result;
    result.reserve(entries.size());
    for (const Entry &entry : entries) {
        const int limitMins = m_appLimits.value(entry.appId, 0);
        const bool exceeded = (limitMins > 0) && (entry.seconds >= limitMins * 60);
        const double ratio = totalSecs > 0
            ? static_cast<double>(entry.seconds) / static_cast<double>(totalSecs)
            : 0.0;

        QVariantMap item;
        item.insert(QStringLiteral("appId"), entry.appId);
        item.insert(QStringLiteral("displayName"), displayNameForApp(entry.appId));
        item.insert(QStringLiteral("category"), classifyAppCategory(entry.appId));
        item.insert(QStringLiteral("iconName"), iconNameForApp(entry.appId));
        item.insert(QStringLiteral("seconds"), entry.seconds);
        item.insert(QStringLiteral("formattedDuration"), formatDuration(entry.seconds));
        item.insert(QStringLiteral("ratio"), ratio);
        item.insert(QStringLiteral("limitMinutes"), limitMins);
        item.insert(QStringLiteral("limitExceeded"), exceeded);
        result.push_back(item);
    }
    return result;
}

QVariantList ScreenTimeTracker::weeklyChartData() const
{
    const QDate today = QDate::currentDate();
    static const QStringList kDayNames = {
        QStringLiteral("Lun"),
        QStringLiteral("Mar"),
        QStringLiteral("Mié"),
        QStringLiteral("Jue"),
        QStringLiteral("Vie"),
        QStringLiteral("Sáb"),
        QStringLiteral("Dom")
    };

    struct DayEntry {
        QString dateStr;
        QString dayLabel;
        int totalSeconds;
    };

    QList<DayEntry> days;
    days.reserve(7);
    int maxDaySeconds = 0;

    for (int offset = 6; offset >= 0; --offset) {
        const QDate d = today.addDays(-offset);
        const QString dStr = d.toString(Qt::ISODate);
        const auto dayMap = m_dailyUsage.value(dStr);
        int total = 0;
        for (int secs : dayMap) {
            total += std::max(0, secs);
        }
        maxDaySeconds = std::max(maxDaySeconds, total);
        const int dow = d.dayOfWeek(); // 1 = Mon .. 7 = Sun
        const QString label = (dow >= 1 && dow <= 7) ? kDayNames.at(dow - 1) : dStr.right(2);
        days.push_back({dStr, label, total});
    }

    QVariantList result;
    result.reserve(days.size());
    for (const DayEntry &de : days) {
        const double ratio = maxDaySeconds > 0
            ? static_cast<double>(de.totalSeconds) / static_cast<double>(maxDaySeconds)
            : 0.0;
        QVariantMap item;
        item.insert(QStringLiteral("date"), de.dateStr);
        item.insert(QStringLiteral("dayLabel"), de.dayLabel);
        item.insert(QStringLiteral("totalSeconds"), de.totalSeconds);
        item.insert(QStringLiteral("formattedDuration"), formatDuration(de.totalSeconds));
        item.insert(QStringLiteral("ratio"), ratio);
        item.insert(QStringLiteral("isSelected"), de.dateStr == m_selectedDate);
        result.push_back(item);
    }
    return result;
}

QVariantList ScreenTimeTracker::categoryBreakdown() const
{
    const auto dayMap = m_dailyUsage.value(m_selectedDate);
    QMap<QString, int> catSums;
    int totalSecs = 0;

    for (auto it = dayMap.cbegin(); it != dayMap.cend(); ++it) {
        const int secs = std::max(0, it.value());
        if (secs <= 0) {
            continue;
        }
        const QString cat = classifyAppCategory(it.key());
        catSums[cat] += secs;
        totalSecs += secs;
    }

    struct CatEntry {
        QString category;
        int seconds;
    };
    QList<CatEntry> list;
    for (auto it = catSums.cbegin(); it != catSums.cend(); ++it) {
        list.push_back({it.key(), it.value()});
    }
    std::sort(list.begin(), list.end(), [](const CatEntry &a, const CatEntry &b) {
        if (a.seconds != b.seconds) {
            return a.seconds > b.seconds;
        }
        return a.category < b.category;
    });

    QVariantList result;
    result.reserve(list.size());
    for (const CatEntry &ce : list) {
        const double ratio = totalSecs > 0
            ? static_cast<double>(ce.seconds) / static_cast<double>(totalSecs)
            : 0.0;
        QVariantMap item;
        item.insert(QStringLiteral("category"), ce.category);
        item.insert(QStringLiteral("iconName"), iconNameForCategory(ce.category));
        item.insert(QStringLiteral("seconds"), ce.seconds);
        item.insert(QStringLiteral("formattedDuration"), formatDuration(ce.seconds));
        item.insert(QStringLiteral("ratio"), ratio);
        result.push_back(item);
    }
    return result;
}

void ScreenTimeTracker::RecordActiveApp(const QString &appClass, const QString &caption)
{
    recordActiveApp(appClass, caption);
}

void ScreenTimeTracker::recordActiveApp(const QString &appClass, const QString &caption)
{
    const QString normalized = normalizeAppId(appClass);
    if (normalized.isEmpty()) {
        return;
    }

    const bool changed = (m_currentActiveApp != normalized) || (m_currentActiveCaption != caption.trimmed());
    m_currentActiveApp = normalized;
    m_currentActiveCaption = caption.trimmed();

    if (changed) {
        Q_EMIT activeAppChanged();
    }
}

void ScreenTimeTracker::addUsageSeconds(const QString &dateStr, const QString &appId, int seconds)
{
    if (seconds <= 0) {
        return;
    }
    const QString cleanDate = dateStr.trimmed().isEmpty()
        ? QDate::currentDate().toString(Qt::ISODate)
        : dateStr.trimmed();
    const QString normalizedApp = normalizeAppId(appId);
    if (normalizedApp.isEmpty()) {
        return;
    }

    m_dailyUsage[cleanDate][normalizedApp] += seconds;
    checkAndNotifyLimit(cleanDate, normalizedApp);
    saveToDisk();
    Q_EMIT dataChanged();
}

void ScreenTimeTracker::setAppLimit(const QString &appId, int limitMinutes)
{
    const QString normalizedApp = normalizeAppId(appId);
    if (normalizedApp.isEmpty()) {
        return;
    }

    if (limitMinutes <= 0) {
        m_appLimits.remove(normalizedApp);
    } else {
        m_appLimits[normalizedApp] = limitMinutes;
        checkAndNotifyLimit(m_selectedDate, normalizedApp);
    }

    saveToDisk();
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
        const QString fallback = detectFallbackRunningGuiApp();
        if (!fallback.isEmpty()) {
            recordActiveApp(fallback);
        }
    }
    if (m_currentActiveApp.isEmpty()) {
        return;
    }

    const QString todayStr = QDate::currentDate().toString(Qt::ISODate);
    m_dailyUsage[todayStr][m_currentActiveApp] += 1;
    checkAndNotifyLimit(todayStr, m_currentActiveApp);

    ++m_ticksSinceSave;
    if (m_ticksSinceSave >= 10) {
        m_ticksSinceSave = 0;
        saveToDisk();
    }

    Q_EMIT dataChanged();
}

bool ScreenTimeTracker::startLiveTracking()
{
    if (m_liveMode) {
        return true;
    }
    m_liveMode = true;

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.isConnected()) {
        bus.registerService(QStringLiteral("org.cesar.kscreentime"));
        bus.registerObject(QStringLiteral("/Tracker"),
                           this,
                           QDBusConnection::ExportAllSlots | QDBusConnection::ExportScriptableSlots);

        const QString scriptPath = QDir::tempPath() + QStringLiteral("/kscreentime_kwin_hook.js");
        QFile f(scriptPath);
        if (f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
            const QString js = QStringLiteral(
                "function reportWindow(w) {\n"
                "    if (!w) return;\n"
                "    const cls = (w.resourceClass || w.desktopFileName || w.resourceName || \"\").toString();\n"
                "    const cap = (w.caption || \"\").toString();\n"
                "    if (cls.length > 0 && cls !== \"plasmashell\" && cls !== \"org.kde.plasmashell\") {\n"
                "        callDBus(\"org.cesar.kscreentime\", \"/Tracker\", \"org.cesar.kscreentime.Tracker\", \"RecordActiveApp\", cls, cap);\n"
                "    }\n"
                "}\n"
                "if (workspace.activeWindow) {\n"
                "    reportWindow(workspace.activeWindow);\n"
                "}\n"
                "workspace.windowActivated.connect(function(client) {\n"
                "    reportWindow(client);\n"
                "});\n");
            f.write(js.toUtf8());
            f.close();

            QDBusInterface kwinScripting(QStringLiteral("org.kde.KWin"),
                                         QStringLiteral("/Scripting"),
                                         QStringLiteral("org.kde.kwin.Scripting"),
                                         bus);
            if (kwinScripting.isValid()) {
                kwinScripting.call(QStringLiteral("unloadScript"), kKWinPluginName);
                const QDBusReply<int> loadReply = kwinScripting.call(QStringLiteral("loadScript"), scriptPath, kKWinPluginName);
                if (loadReply.isValid() && loadReply.value() >= 0) {
                    const QString scriptObjPath = QStringLiteral("/Scripting/Script%1").arg(loadReply.value());
                    QDBusInterface scriptIface(QStringLiteral("org.kde.KWin"),
                                               scriptObjPath,
                                               QStringLiteral("org.kde.kwin.Script"),
                                               bus);
                    scriptIface.call(QStringLiteral("run"));
                    m_kwinHookLoaded = true;
                }
            }
        }
    }

    if (m_currentActiveApp.isEmpty()) {
        recordActiveApp(detectFallbackRunningGuiApp(), QStringLiteral("Sesión activa en KDE Plasma Wayland"));
    }

    m_tickTimer.start();
    return m_kwinHookLoaded;
}

void ScreenTimeTracker::stopLiveTracking()
{
    m_tickTimer.stop();
    if (!m_liveMode) {
        return;
    }
    m_liveMode = false;

    if (m_kwinHookLoaded) {
        QDBusInterface kwinScripting(QStringLiteral("org.kde.KWin"),
                                     QStringLiteral("/Scripting"),
                                     QStringLiteral("org.kde.kwin.Scripting"),
                                     QDBusConnection::sessionBus());
        if (kwinScripting.isValid()) {
            kwinScripting.call(QStringLiteral("unloadScript"), kKWinPluginName);
        }
        m_kwinHookLoaded = false;
    }
}

QString ScreenTimeTracker::classifyAppCategory(const QString &appId)
{
    const QString lower = appId.trimmed().toLower();

    static const QStringList kDevKeywords = {
        QStringLiteral("code"), QStringLiteral("vscodium"), QStringLiteral("kate"),
        QStringLiteral("kdevelop"), QStringLiteral("konsole"), QStringLiteral("alacritty"),
        QStringLiteral("kitty"), QStringLiteral("wezterm"), QStringLiteral("ghostty"),
        QStringLiteral("nvim"), QStringLiteral("vim"), QStringLiteral("jetbrains"),
        QStringLiteral("clion"), QStringLiteral("pycharm"), QStringLiteral("idea"),
        QStringLiteral("qtcreator"), QStringLiteral("cursor"), QStringLiteral("zed"),
        QStringLiteral("antigravity")
    };
    for (const QString &kw : kDevKeywords) {
        if (lower.contains(kw)) {
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
        if (lower.contains(kw)) {
            return QStringLiteral("Navegación");
        }
    }

    static const QStringList kMediaKeywords = {
        QStringLiteral("spotify"), QStringLiteral("vlc"), QStringLiteral("mpv"),
        QStringLiteral("elisa"), QStringLiteral("haruna"), QStringLiteral("kdenlive"),
        QStringLiteral("obs"), QStringLiteral("gimp"), QStringLiteral("inkscape"),
        QStringLiteral("krita"), QStringLiteral("blender"), QStringLiteral("audacity"),
        QStringLiteral("gwenview"), QStringLiteral("okular")
    };
    for (const QString &kw : kMediaKeywords) {
        if (lower.contains(kw)) {
            return QStringLiteral("Multimedia");
        }
    }

    static const QStringList kCommKeywords = {
        QStringLiteral("telegram"), QStringLiteral("discord"), QStringLiteral("vesktop"),
        QStringLiteral("slack"), QStringLiteral("signal"), QStringLiteral("thunderbird"),
        QStringLiteral("kmail"), QStringLiteral("neochat"), QStringLiteral("element"),
        QStringLiteral("whatsapp"), QStringLiteral("zoom"), QStringLiteral("teams")
    };
    for (const QString &kw : kCommKeywords) {
        if (lower.contains(kw)) {
            return QStringLiteral("Comunicación");
        }
    }

    return QStringLiteral("Sistema");
}

QString ScreenTimeTracker::formatDuration(int totalSeconds)
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

QString ScreenTimeTracker::displayNameForApp(const QString &appId)
{
    const QString lower = appId.trimmed().toLower();
    if (lower.contains(QStringLiteral("firefox"))) return QStringLiteral("Mozilla Firefox");
    if (lower.contains(QStringLiteral("chrome")) || lower.contains(QStringLiteral("chromium"))) return QStringLiteral("Google Chrome");
    if (lower.contains(QStringLiteral("brave"))) return QStringLiteral("Brave Browser");
    if (lower.contains(QStringLiteral("code")) || lower.contains(QStringLiteral("vscodium"))) return QStringLiteral("VS Code");
    if (lower.contains(QStringLiteral("antigravity"))) return QStringLiteral("Antigravity IDE");
    if (lower.contains(QStringLiteral("konsole"))) return QStringLiteral("Konsole");
    if (lower.contains(QStringLiteral("kate"))) return QStringLiteral("Kate Editor");
    if (lower.contains(QStringLiteral("dolphin"))) return QStringLiteral("Dolphin");
    if (lower.contains(QStringLiteral("telegram"))) return QStringLiteral("Telegram Desktop");
    if (lower.contains(QStringLiteral("discord")) || lower.contains(QStringLiteral("vesktop"))) return QStringLiteral("Discord");
    if (lower.contains(QStringLiteral("spotify"))) return QStringLiteral("Spotify");
    if (lower.contains(QStringLiteral("vlc"))) return QStringLiteral("VLC Media Player");
    if (lower.contains(QStringLiteral("mpv")) || lower.contains(QStringLiteral("haruna"))) return QStringLiteral("Reproductor Multimedia");
    if (lower.contains(QStringLiteral("systemsettings"))) return QStringLiteral("Preferencias del Sistema");
    if (lower.contains(QStringLiteral("kscreentime"))) return QStringLiteral("KScreenTime");

    QString cleaned = appId.trimmed();
    const int lastDot = cleaned.lastIndexOf(QLatin1Char('.'));
    if (lastDot >= 0 && lastDot + 1 < cleaned.size()) {
        cleaned = cleaned.mid(lastDot + 1);
    }
    if (!cleaned.isEmpty()) {
        cleaned[0] = cleaned[0].toUpper();
    }
    return cleaned;
}

QString ScreenTimeTracker::iconNameForApp(const QString &appId)
{
    const QString lower = appId.trimmed().toLower();
    if (lower.contains(QStringLiteral("konsole")) || lower.contains(QStringLiteral("alacritty")) || lower.contains(QStringLiteral("kitty"))) {
        return QStringLiteral("utilities-terminal");
    }
    if (lower.contains(QStringLiteral("dolphin"))) {
        return QStringLiteral("system-file-manager");
    }
    if (lower.contains(QStringLiteral("firefox")) || lower.contains(QStringLiteral("chrome")) || lower.contains(QStringLiteral("brave"))) {
        return QStringLiteral("internet-web-browser");
    }
    return iconNameForCategory(classifyAppCategory(appId));
}

QString ScreenTimeTracker::iconNameForCategory(const QString &category)
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

QString ScreenTimeTracker::normalizeAppId(const QString &rawAppClass)
{
    QString s = rawAppClass.trimmed().toLower();
    if (s.endsWith(QStringLiteral(".desktop"))) {
        s.chop(8);
    }
    return s;
}

void ScreenTimeTracker::loadFromDisk()
{
    m_dailyUsage.clear();
    m_appLimits.clear();

    QFile file(storageFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isObject()) {
        return;
    }

    const QJsonObject root = doc.object();
    const QJsonObject daysObj = root.value(QStringLiteral("days")).toObject();
    for (auto dayIt = daysObj.begin(); dayIt != daysObj.end(); ++dayIt) {
        const QString dateStr = dayIt.key();
        const QJsonObject appsObj = dayIt.value().toObject();
        QMap<QString, int> appMap;
        for (auto appIt = appsObj.begin(); appIt != appsObj.end(); ++appIt) {
            const int secs = appIt.value().toInt(0);
            if (secs > 0) {
                appMap.insert(normalizeAppId(appIt.key()), secs);
            }
        }
        if (!appMap.isEmpty()) {
            m_dailyUsage.insert(dateStr, appMap);
        }
    }

    const QJsonObject limitsObj = root.value(QStringLiteral("appLimits")).toObject();
    for (auto limIt = limitsObj.begin(); limIt != limitsObj.end(); ++limIt) {
        const int mins = limIt.value().toInt(0);
        if (mins > 0) {
            m_appLimits.insert(normalizeAppId(limIt.key()), mins);
        }
    }
}

void ScreenTimeTracker::saveToDisk() const
{
    QDir().mkpath(m_storageDir);

    QJsonObject daysObj;
    for (auto dayIt = m_dailyUsage.cbegin(); dayIt != m_dailyUsage.cend(); ++dayIt) {
        QJsonObject appsObj;
        for (auto appIt = dayIt.value().cbegin(); appIt != dayIt.value().cend(); ++appIt) {
            if (appIt.value() > 0) {
                appsObj.insert(appIt.key(), appIt.value());
            }
        }
        if (!appsObj.isEmpty()) {
            daysObj.insert(dayIt.key(), appsObj);
        }
    }

    QJsonObject limitsObj;
    for (auto limIt = m_appLimits.cbegin(); limIt != m_appLimits.cend(); ++limIt) {
        if (limIt.value() > 0) {
            limitsObj.insert(limIt.key(), limIt.value());
        }
    }

    QJsonObject root;
    root.insert(QStringLiteral("days"), daysObj);
    root.insert(QStringLiteral("appLimits"), limitsObj);

    QFile file(storageFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        file.close();
    }
}

void ScreenTimeTracker::seedInitialDataIfEmpty()
{
    if (!m_dailyUsage.isEmpty()) {
        return;
    }

    const QDate today = QDate::currentDate();
    struct DayProfile {
        int codeSecs;
        int browserSecs;
        int terminalSecs;
        int mediaSecs;
        int chatSecs;
        int systemSecs;
    };

    static const DayProfile kProfiles[7] = {
        {5400, 3900, 2700, 1800, 1500, 900}, // -6d
        {6200, 4100, 3100, 1200, 1800, 1100}, // -5d
        {4800, 3600, 2400, 2100, 1400, 800}, // -4d
        {7100, 4500, 3600, 1500, 2100, 1200}, // -3d
        {5900, 3800, 2900, 1900, 1600, 950}, // -2d
        {3200, 4200, 1800, 3600, 2200, 700}, // -1d
        {5100, 3420, 2580, 1320, 1140, 780}  // today (~3h 59m)
    };

    for (int i = 0; i < 7; ++i) {
        const QString dStr = today.addDays(-(6 - i)).toString(Qt::ISODate);
        const DayProfile &p = kProfiles[i];
        m_dailyUsage[dStr][QStringLiteral("code")] = p.codeSecs;
        m_dailyUsage[dStr][QStringLiteral("firefox")] = p.browserSecs;
        m_dailyUsage[dStr][QStringLiteral("org.kde.konsole")] = p.terminalSecs;
        m_dailyUsage[dStr][QStringLiteral("spotify")] = p.mediaSecs;
        m_dailyUsage[dStr][QStringLiteral("org.telegram.desktop")] = p.chatSecs;
        m_dailyUsage[dStr][QStringLiteral("org.kde.dolphin")] = p.systemSecs;
    }

    saveToDisk();
}

void ScreenTimeTracker::checkAndNotifyLimit(const QString &dateStr, const QString &appId)
{
    const int limitMins = m_appLimits.value(appId, 0);
    if (limitMins <= 0) {
        return;
    }

    const int currentSecs = m_dailyUsage.value(dateStr).value(appId, 0);
    if (currentSecs < limitMins * 60) {
        return;
    }

    const QString key = dateStr + QLatin1Char('|') + appId;
    if (m_notifiedLimits.contains(key)) {
        return;
    }
    m_notifiedLimits.insert(key);

    Q_EMIT appLimitExceeded(appId, limitMins, currentSecs);

    if (m_liveMode) {
        sendDesktopNotification(
            QStringLiteral("Tiempo de Uso — Límite alcanzado"),
            QStringLiteral("Has superado el límite diario de %1 min en %2 (%3).")
                .arg(limitMins)
                .arg(displayNameForApp(appId))
                .arg(formatDuration(currentSecs)));
    }
}

void ScreenTimeTracker::sendDesktopNotification(const QString &title, const QString &body) const
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

QString ScreenTimeTracker::detectFallbackRunningGuiApp() const
{
    static const QStringList kCandidates = {
        QStringLiteral("code"),
        QStringLiteral("firefox"),
        QStringLiteral("konsole"),
        QStringLiteral("dolphin"),
        QStringLiteral("kate"),
        QStringLiteral("telegram-desktop"),
        QStringLiteral("spotify")
    };

    QDir procDir(QStringLiteral("/proc"));
    const QStringList entries = procDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &pidStr : entries) {
        bool ok = false;
        pidStr.toInt(&ok);
        if (!ok) {
            continue;
        }
        QFile commFile(QStringLiteral("/proc/%1/comm").arg(pidStr));
        if (commFile.open(QIODevice::ReadOnly)) {
            const QString comm = QString::fromUtf8(commFile.readAll()).trimmed().toLower();
            for (const QString &cand : kCandidates) {
                if (comm == cand || comm.contains(cand)) {
                    if (cand == QStringLiteral("konsole")) return QStringLiteral("org.kde.konsole");
                    if (cand == QStringLiteral("dolphin")) return QStringLiteral("org.kde.dolphin");
                    return cand;
                }
            }
        }
    }
    return QStringLiteral("org.kde.konsole");
}
