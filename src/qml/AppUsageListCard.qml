/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    required property var trackerObj

    function categoryAccentColor(cat: string): color {
        if (cat === "Desarrollo") return "#007AFF";
        if (cat === "Navegación") return "#32ADE6";
        if (cat === "Multimedia") return "#AF52DE";
        if (cat === "Comunicación") return "#34C759";
        return "#FF9500";
    }

    Layout.fillWidth: true
    implicitHeight: appListColumn.implicitHeight + 28
    radius: 16
    color: CachyTheme.cardBackground
    border.width: 1
    border.color: CachyTheme.specularBorder

    ColumnLayout {
        id: appListColumn
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Uso Real por Aplicación y Límites Diarios"
            color: CachyTheme.textPrimary
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            visible: !root.trackerObj || root.trackerObj.appUsageList.length === 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "No hay actividad de aplicaciones registrada en esta fecha."
            color: CachyTheme.textSecondary
            font.pixelSize: 12
        }

        Repeater {
            model: root.trackerObj ? root.trackerObj.appUsageList : []

            Rectangle {
                id: appCard
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 62
                radius: 12
                color: appCard.modelData.limitExceeded
                    ? "#1FFF3B30"
                    : CachyTheme.surfacePill
                border.width: 1
                border.color: appCard.modelData.limitExceeded
                    ? "#FF3B30"
                    : CachyTheme.specularBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    CachyIcon {
                        name: appCard.modelData.iconName
                        size: 28
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        colored: false
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: appCard.modelData.displayName
                                color: CachyTheme.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: appCard.modelData.category
                                color: root.categoryAccentColor(appCard.modelData.category)
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: appCard.modelData.formattedDuration + " (" + Math.round(appCard.modelData.ratio * 100) + "%)"
                                color: CachyTheme.accentColor
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: CachyTheme.withAlpha(CachyTheme.textMuted, 0.18)

                            Rectangle {
                                width: Math.max(6, parent.width * Math.min(1.0, appCard.modelData.ratio))
                                height: parent.height
                                radius: 3
                                color: appCard.modelData.limitExceeded
                                    ? "#FF3B30"
                                    : root.categoryAccentColor(appCard.modelData.category)
                            }
                        }
                    }

                    // Daily Limit Pills (15m, 30m, 60m, ∞)
                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "15m", mins: 15 },
                                { label: "30m", mins: 30 },
                                { label: "60m", mins: 60 },
                                { label: "∞", mins: 0 }
                            ]

                            Rectangle {
                                id: limitPill
                                required property var modelData
                                readonly property bool isSelected: appCard.modelData.limitMinutes === limitPill.modelData.mins
                                height: 24
                                implicitWidth: 34
                                radius: 12
                                color: isSelected ? CachyTheme.accentColor : "transparent"
                                border.width: 1
                                border.color: isSelected ? CachyTheme.accentColor : CachyTheme.specularBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: limitPill.modelData.label
                                    font.pixelSize: 10
                                    font.weight: limitPill.isSelected ? Font.Bold : Font.Medium
                                    color: limitPill.isSelected ? "#FFFFFF" : CachyTheme.textSecondary
                                }

                                TapHandler {
                                    onTapped: {
                                        if (root.trackerObj) {
                                            root.trackerObj.setAppLimit(appCard.modelData.appId, limitPill.modelData.mins);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
