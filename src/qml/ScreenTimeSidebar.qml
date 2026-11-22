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
        text: "Tiempo de uso"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: CachyPalette.textMuted
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Actividad de apps"
        iconName: "chart-bar"
        iconColor: "#0A84FF"
        squircleIconBadge: true
        accentSelected: true
        selected: root.activeSection === "activity"
        onClicked: root.sectionSelected("activity")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Tiempo de inactividad"
        iconName: "bed"
        iconColor: "#5856D6"
        squircleIconBadge: true
        accentSelected: true
        selected: root.activeSection === "downtime"
        onClicked: root.sectionSelected("downtime")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Límites de apps"
        iconName: "hourglass"
        iconColor: "#FF9500"
        squircleIconBadge: true
        accentSelected: true
        badgeText: (root.trackerObj && root.trackerObj.allLimitsList) ? String(root.trackerObj.allLimitsList.length) : "0"
        selected: root.activeSection === "limits"
        onClicked: root.sectionSelected("limits")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Siempre permitido"
        iconName: "shield-check"
        iconColor: "#34C759"
        squircleIconBadge: true
        accentSelected: true
        badgeText: (root.trackerObj && root.trackerObj.alwaysAllowedApps) ? String(root.trackerObj.alwaysAllowedApps.length) : "0"
        selected: root.activeSection === "alwaysAllowed"
        onClicked: root.sectionSelected("alwaysAllowed")
    }

    CachySidebarItem {
        Layout.fillWidth: true
        text: "Ventana activa (KWin)"
        iconName: "apps"
        iconColor: "#30B0C7"
        squircleIconBadge: true
        accentSelected: true
        selected: root.activeSection === "live"
        onClicked: root.sectionSelected("live")
    }

    Item { Layout.fillHeight: true }

    // Bottom Live Wayland Active Window Pill inside Sidebar
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: liveSidebarCol.implicitHeight + 18
        radius: 12
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

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
                        : CachyPalette.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: "KWin Wayland Live"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: CachyPalette.textMuted
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyPalette.text
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
