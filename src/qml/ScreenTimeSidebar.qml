/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

ColumnLayout {
    id: root

    required property string activeSection
    required property var trackerObj
    signal sectionSelected(string section)

    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.bottomMargin: 12
    spacing: 4

    Text {
        Layout.leftMargin: 8
        Layout.bottomMargin: 4
        text: "Screen Time"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: CachyTheme.textMuted
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "App & Website Activity"
        iconName: "office-chart-bar"
        iconColor: "#007AFF"
        squircleIconBadge: true
        selected: root.activeSection === "activity"
        onClicked: root.sectionSelected("activity")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Active Window (KWin)"
        iconName: "window"
        iconColor: "#34C759"
        squircleIconBadge: true
        selected: root.activeSection === "live"
        onClicked: root.sectionSelected("live")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Categories Breakdown"
        iconName: "tag"
        iconColor: "#AF52DE"
        squircleIconBadge: true
        selected: root.activeSection === "categories"
        onClicked: root.sectionSelected("categories")
    }

    Text {
        Layout.leftMargin: 8
        Layout.topMargin: 10
        Layout.bottomMargin: 4
        text: "Limit Usage"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: CachyTheme.textMuted
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "App Limits"
        iconName: "chronometer"
        iconColor: "#FF9500"
        squircleIconBadge: true
        badgeText: root.trackerObj ? String(root.trackerObj.appUsageList.length) : "0"
        selected: root.activeSection === "limits"
        onClicked: root.sectionSelected("limits")
    }

    Item { Layout.fillHeight: true }

    // Bottom Live Wayland Active Window Pill inside Sidebar
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: liveSidebarCol.implicitHeight + 18
        radius: 12
        color: CachyTheme.cardBackground
        border.width: 1
        border.color: CachyTheme.specularBorder

        ColumnLayout {
            id: liveSidebarCol
            anchors.fill: parent
            anchors.margins: 9
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: 3.5
                    color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                        ? "#34C759"
                        : CachyTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: "KWin Wayland Live"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: CachyTheme.textMuted
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyTheme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: CachyTheme.accentColor
                elide: Text.ElideRight
            }
        }
    }
}
