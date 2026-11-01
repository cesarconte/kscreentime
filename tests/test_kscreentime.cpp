/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "screentimetracker.h"

#include <QDate>
#include <QFile>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

class TestKScreenTime : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testFormatDuration()
    {
        QCOMPARE(ScreenTimeTracker::formatDuration(0), QStringLiteral("0m"));
        QCOMPARE(ScreenTimeTracker::formatDuration(-15), QStringLiteral("0m"));
        QCOMPARE(ScreenTimeTracker::formatDuration(45), QStringLiteral("45s"));
        QCOMPARE(ScreenTimeTracker::formatDuration(42 * 60), QStringLiteral("42m"));
        QCOMPARE(ScreenTimeTracker::formatDuration(3 * 3600 + 42 * 60), QStringLiteral("3h 42m"));
        QCOMPARE(ScreenTimeTracker::formatDuration(2 * 3600), QStringLiteral("2h 0m"));
    }

    void testClassifyAppCategory()
    {
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("code")), QStringLiteral("Desarrollo"));
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("org.kde.konsole")), QStringLiteral("Desarrollo"));
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("firefox")), QStringLiteral("Navegación"));
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("spotify")), QStringLiteral("Multimedia"));
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("org.telegram.desktop")), QStringLiteral("Comunicación"));
        QCOMPARE(ScreenTimeTracker::classifyAppCategory(QStringLiteral("org.kde.dolphin")), QStringLiteral("Sistema"));
    }

    void testAddUsageSortingAndCategories()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        ScreenTimeTracker tracker(tempDir.path());
        const QString today = tracker.selectedDate();

        tracker.addUsageSeconds(today, QStringLiteral("firefox"), 1800);       // 30m
        tracker.addUsageSeconds(today, QStringLiteral("code"), 5400);          // 1h 30m
        tracker.addUsageSeconds(today, QStringLiteral("spotify"), 900);        // 15m
        tracker.addUsageSeconds(today, QStringLiteral("org.kde.konsole"), 600); // 10m

        QCOMPARE(tracker.todayTotalSeconds(), 8700);
        QCOMPARE(tracker.todayTotalFormatted(), QStringLiteral("2h 25m"));

        const QVariantList apps = tracker.appUsageList();
        QCOMPARE(apps.size(), 4);

        const QVariantMap first = apps.at(0).toMap();
        const QVariantMap second = apps.at(1).toMap();
        const QVariantMap third = apps.at(2).toMap();
        const QVariantMap fourth = apps.at(3).toMap();

        QCOMPARE(first.value(QStringLiteral("appId")).toString(), QStringLiteral("code"));
        QCOMPARE(first.value(QStringLiteral("seconds")).toInt(), 5400);
        QCOMPARE(first.value(QStringLiteral("category")).toString(), QStringLiteral("Desarrollo"));
        QCOMPARE(first.value(QStringLiteral("formattedDuration")).toString(), QStringLiteral("1h 30m"));

        QCOMPARE(second.value(QStringLiteral("appId")).toString(), QStringLiteral("firefox"));
        QCOMPARE(second.value(QStringLiteral("seconds")).toInt(), 1800);

        QCOMPARE(third.value(QStringLiteral("appId")).toString(), QStringLiteral("spotify"));
        QCOMPARE(third.value(QStringLiteral("seconds")).toInt(), 900);

        QCOMPARE(fourth.value(QStringLiteral("appId")).toString(), QStringLiteral("org.kde.konsole"));
        QCOMPARE(fourth.value(QStringLiteral("seconds")).toInt(), 600);

        const QVariantList categories = tracker.categoryBreakdown();
        QCOMPARE(categories.size(), 3); // Desarrollo (6000s), Navegación (1800s), Multimedia (900s)
        const QVariantMap topCat = categories.first().toMap();
        QCOMPARE(topCat.value(QStringLiteral("category")).toString(), QStringLiteral("Desarrollo"));
        QCOMPARE(topCat.value(QStringLiteral("seconds")).toInt(), 6000);
    }

    void testAppLimitsAndExceededDetection()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        ScreenTimeTracker tracker(tempDir.path());
        QSignalSpy limitSpy(&tracker, &ScreenTimeTracker::appLimitExceeded);

        const QString today = tracker.selectedDate();
        tracker.setAppLimit(QStringLiteral("firefox"), 30); // 30 minutes = 1800s

        tracker.addUsageSeconds(today, QStringLiteral("firefox"), 1200); // 20m -> not exceeded
        QVariantList apps = tracker.appUsageList();
        QCOMPARE(apps.size(), 1);
        QCOMPARE(apps.first().toMap().value(QStringLiteral("limitMinutes")).toInt(), 30);
        QCOMPARE(apps.first().toMap().value(QStringLiteral("limitExceeded")).toBool(), false);
        QCOMPARE(limitSpy.count(), 0);

        tracker.addUsageSeconds(today, QStringLiteral("firefox"), 660); // 31m -> exceeded!
        apps = tracker.appUsageList();
        QCOMPARE(apps.first().toMap().value(QStringLiteral("limitExceeded")).toBool(), true);
        QCOMPARE(limitSpy.count(), 1);

        // Removing limit clears limitExceeded
        tracker.setAppLimit(QStringLiteral("firefox"), 0);
        apps = tracker.appUsageList();
        QCOMPARE(apps.first().toMap().value(QStringLiteral("limitMinutes")).toInt(), 0);
        QCOMPARE(apps.first().toMap().value(QStringLiteral("limitExceeded")).toBool(), false);
    }

    void testPersistenceAcrossInstances()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        const QString today = QDate::currentDate().toString(Qt::ISODate);
        {
            ScreenTimeTracker writer(tempDir.path());
            writer.addUsageSeconds(today, QStringLiteral("code"), 3600);
            writer.addUsageSeconds(today, QStringLiteral("firefox"), 1800);
            writer.setAppLimit(QStringLiteral("firefox"), 25);
        }

        QVERIFY(QFile::exists(tempDir.path() + QStringLiteral("/usage.json")));

        ScreenTimeTracker reader(tempDir.path());
        QCOMPARE(reader.todayTotalSeconds(), 5400);
        const QVariantList apps = reader.appUsageList();
        QCOMPARE(apps.size(), 2);
        QCOMPARE(apps.at(0).toMap().value(QStringLiteral("appId")).toString(), QStringLiteral("code"));
        QCOMPARE(apps.at(1).toMap().value(QStringLiteral("appId")).toString(), QStringLiteral("firefox"));
        QCOMPARE(apps.at(1).toMap().value(QStringLiteral("limitMinutes")).toInt(), 25);
        QCOMPARE(apps.at(1).toMap().value(QStringLiteral("limitExceeded")).toBool(), true);
    }

    void testWeeklyChartDataAndSelectDate()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        ScreenTimeTracker tracker(tempDir.path());
        const QDate today = QDate::currentDate();
        const QString todayStr = today.toString(Qt::ISODate);
        const QString yesterdayStr = today.addDays(-1).toString(Qt::ISODate);

        tracker.addUsageSeconds(yesterdayStr, QStringLiteral("code"), 7200);
        tracker.addUsageSeconds(todayStr, QStringLiteral("firefox"), 3600);

        const QVariantList chart = tracker.weeklyChartData();
        QCOMPARE(chart.size(), 7);

        const QVariantMap yesterdayBar = chart.at(5).toMap();
        const QVariantMap todayBar = chart.at(6).toMap();

        QCOMPARE(yesterdayBar.value(QStringLiteral("date")).toString(), yesterdayStr);
        QCOMPARE(yesterdayBar.value(QStringLiteral("totalSeconds")).toInt(), 7200);
        QVERIFY(qFuzzyCompare(yesterdayBar.value(QStringLiteral("ratio")).toDouble(), 1.0));

        QCOMPARE(todayBar.value(QStringLiteral("date")).toString(), todayStr);
        QCOMPARE(todayBar.value(QStringLiteral("totalSeconds")).toInt(), 3600);
        QVERIFY(qFuzzyCompare(todayBar.value(QStringLiteral("ratio")).toDouble(), 0.5));

        tracker.selectDate(yesterdayStr);
        QCOMPARE(tracker.selectedDate(), yesterdayStr);
        QCOMPARE(tracker.todayTotalSeconds(), 7200);
    }

    void testRecordActiveAppAndTick()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        ScreenTimeTracker tracker(tempDir.path());
        tracker.recordActiveApp(QStringLiteral("org.kde.konsole.desktop"), QStringLiteral("zsh"));
        QCOMPARE(tracker.currentActiveApp(), QStringLiteral("org.kde.konsole"));
        QCOMPARE(tracker.currentActiveCaption(), QStringLiteral("zsh"));

        tracker.tickActiveApp();
        QCOMPARE(tracker.todayTotalSeconds(), 1);
    }

    void testQmlCompilation()
    {
        QTemporaryDir tempDir;
        QVERIFY(tempDir.isValid());

        ScreenTimeTracker tracker(tempDir.path());
        QQmlEngine engine;
        engine.rootContext()->setContextProperty(QStringLiteral("Tracker"), &tracker);

        QQmlComponent comp(&engine, QUrl(QStringLiteral("qrc:/org/cesar/kscreentime/qml/main.qml")));
        QVERIFY2(!comp.isError(), qPrintable(comp.errorString()));
    }
};

QTEST_MAIN(TestKScreenTime)
#include "test_kscreentime.moc"
