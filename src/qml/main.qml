/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Screen Time — KScreenTime.
 * Diseño macOS Golden Gate / Liquid Glass (CachyOS.UI).
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    title: "Tiempo de uso — KScreenTime"
    width: 980
    height: 700
    minimumWidth: 820
    minimumHeight: 560
    visible: root.trackerObj ? root.trackerObj.windowVisible : true

    showTrafficLights: true
    showTitleBarDivider: false
    showWindowFrame: true
    sidebarVisible: true
    sidebarWidthExpanded: 240
    cornerRadius: CachyTheme.radiusWindow
    contentBackground: CachyPalette.contentBackground

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
                color: CachyPalette.textSecondary
            }
        }
    ]

    headerCenter: [
        RowLayout {
            anchors.centerIn: parent
            visible: root.activeSection === "activity"

            CachySegmentedControl {
                model: ["Semana", "Día"]
                currentIndex: (root.trackerObj && root.trackerObj.chartViewMode === "daily") ? 1 : 0
                accentSelected: true
                onCurrentIndexChanged: {
                    if (root.trackerObj) {
                        root.trackerObj.setChartViewMode(currentIndex === 1 ? "daily" : "weekly");
                    }
                }
            }
        }
    ]

    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            CachyButton {
                text: "Reiniciar"
                iconName: "refresh"
                pillStyle: true
                enabled: Boolean(root.trackerObj && root.trackerObj.todayTotalSeconds > 0)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: "Reiniciar historial de tiempo de uso"
                QQC2.ToolTip.delay: 450
                onClicked: {
                    if (root.trackerObj) {
                        root.trackerObj.clearAllData();
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 3. MAIN SCROLLABLE CONTENT (MULTIPLE GOLDEN GATE PANES)
    // =========================================================================
    contentData: [
        QQC2.ScrollView {
            id: mainScroll
            anchors.fill: parent
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            clip: true

            Item {
                width: mainScroll.availableWidth
                implicitHeight: contentLoader.implicitHeight + 32

                Loader {
                    id: contentLoader
                    width: parent.width - 32
                    x: 16
                    y: 16
                    sourceComponent: {
                        if (root.activeSection === "downtime") return downtimeComp;
                        if (root.activeSection === "limits") return limitsComp;
                        if (root.activeSection === "alwaysAllowed") return alwaysAllowedComp;
                        if (root.activeSection === "live") return liveComp;
                        return activityComp;
                    }
                }
            }
        },

        Component {
            id: activityComp
            ColumnLayout {
                spacing: 14

                SummaryCardsRow {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }

                WeeklyActivityChart {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }

                AppUsageListCard {
                    Layout.fillWidth: true
                    trackerObj: root.trackerObj
                }
            }
        },

        Component {
            id: downtimeComp
            DowntimePane {
                trackerObj: root.trackerObj
            }
        },

        Component {
            id: limitsComp
            AppLimitsPane {
                trackerObj: root.trackerObj
            }
        },

        Component {
            id: alwaysAllowedComp
            AlwaysAllowedPane {
                trackerObj: root.trackerObj
            }
        },

        Component {
            id: liveComp
            LiveWindowPane {
                trackerObj: root.trackerObj
            }
        }
    ]
}
