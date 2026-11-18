/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

RowLayout {
    id: root

    required property var trackerObj

    function categoryAccentColor(cat: string): color {
        if (cat === "Desarrollo") return "#007AFF";
        if (cat === "Navegación") return "#32ADE6";
        if (cat === "Multimedia") return "#AF52DE";
        if (cat === "Comunicación") return "#34C759";
        return "#FF9500";
    }

    spacing: 12

    // Card 1: Daily Total & vs Average
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumHeight: 118
        radius: 16
        color: CachyTheme.cardBackground
        border.width: 1
        border.color: CachyTheme.specularBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: "Tiempo de Uso (" + (root.trackerObj ? root.trackerObj.selectedDate : "Hoy") + ")"
                color: CachyTheme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                color: CachyTheme.textPrimary
                font.pixelSize: 28
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.vsAverageText : ""
                color: CachyTheme.accentColor
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    // Card 2: Active KWin Wayland Window
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.minimumHeight: 118
        radius: 16
        color: CachyTheme.cardBackground
        border.width: 1
        border.color: CachyTheme.specularBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0) ? "#34C759" : CachyTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: "Ventana Activa (Wayland / KWin)"
                    color: CachyTheme.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                color: CachyTheme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (!root.trackerObj) return "";
                    const cap = root.trackerObj.currentActiveCaption;
                    const app = root.trackerObj.currentActiveApp;
                    if (app.length === 0) return "Esperando foco de ventana en KWin…";
                    return cap.length > 0 ? (app + " — " + cap) : app;
                }
                color: CachyTheme.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    // Card 3: Categories Breakdown
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredWidth: 1.2
        Layout.minimumHeight: 118
        radius: 16
        color: CachyTheme.cardBackground
        border.width: 1
        border.color: CachyTheme.specularBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Desglose por Categorías"
                color: CachyTheme.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                visible: !root.trackerObj || root.trackerObj.categoryBreakdown.length === 0
                text: "Sin actividad registrada en esta fecha"
                color: CachyTheme.textSecondary
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Flow {
                visible: Boolean(root.trackerObj && root.trackerObj.categoryBreakdown.length > 0)
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                Repeater {
                    model: root.trackerObj ? root.trackerObj.categoryBreakdown : []

                    Rectangle {
                        id: catBadge
                        required property var modelData
                        height: 24
                        implicitWidth: catRow.implicitWidth + 14
                        radius: 12
                        color: CachyTheme.surfacePill
                        border.width: 1
                        border.color: root.categoryAccentColor(catBadge.modelData.category)

                        RowLayout {
                            id: catRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: catBadge.modelData.category
                                color: CachyTheme.textPrimary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: catBadge.modelData.formattedDuration
                                color: root.categoryAccentColor(catBadge.modelData.category)
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }
    }
}
