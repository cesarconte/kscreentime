/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Screen Time — KScreenTime.
 * Diseño Golden Gate / Liquid Glass (CachyOS.UI).
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    title: "Screen Time — KScreenTime"
    width: 980
    height: 700
    minimumWidth: 800
    minimumHeight: 560
    visible: root.trackerObj ? root.trackerObj.windowVisible : true

    showTrafficLights: true
    showTitleBarDivider: true
    showWindowFrame: true
    sidebarVisible: true
    sidebarWidthExpanded: 232
    cornerRadius: CachyTheme.radiusWindow

    property string activeSection: "activity"
    readonly property var trackerObj: typeof Tracker !== "undefined" ? Tracker : null

    onClosing: (close) => {
        if (root.trackerObj) {
            close.accepted = false;
            root.trackerObj.windowVisible = false;
        }
    }

    Connections {
        target: root.trackerObj
        function onShowWindowRequested() {
            root.show();
            root.raise();
            root.requestActivate();
        }
    }

    // =========================================================================
    // 1. GOLDEN GATE EDGE-TO-EDGE SCREEN TIME SIDEBAR
    // =========================================================================
    sidebar: [
        ScreenTimeSidebar {
            activeSection: root.activeSection
            trackerObj: root.trackerObj
            onSectionSelected: function(section) {
                root.activeSection = section;
            }
        }
    ]

    // =========================================================================
    // 2. GOLDEN GATE 44PX HEADER TOOLBAR
    // =========================================================================
    headerLeading: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            CachySidebarToggleButton {
                targetWindow: root
                visible: true
            }

            Text {
                text: "Fecha: " + (root.trackerObj ? root.trackerObj.selectedDate : "Hoy")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyTheme.textSecondary
            }
        }
    ]

    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            CachyToolbarButton {
                text: "Reiniciar"
                iconName: "edit-clear-history"
                implicitWidth: 84
                enabled: Boolean(root.trackerObj && root.trackerObj.todayTotalSeconds > 0)
                tooltipText: "Reiniciar historial de tiempo de uso"
                onClicked: {
                    if (root.trackerObj) {
                        root.trackerObj.clearAllData();
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 3. MAIN SCROLLABLE DASHBOARD
    // =========================================================================
    contentData: [
        QQC2.ScrollView {
            id: mainScroll
            anchors.fill: parent
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            clip: true

            ColumnLayout {
                width: mainScroll.availableWidth - 32
                x: 16
                y: 16
                spacing: 14

                // Top Row: 3 Summary Cards
                SummaryCardsRow {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }

                // Middle Card: 7-Day Activity Chart
                WeeklyActivityChart {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }

                // Bottom Card: App Usage List & Limits
                AppUsageListCard {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }
            }
        }
    ]
}
