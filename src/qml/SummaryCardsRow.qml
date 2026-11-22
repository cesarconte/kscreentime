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
        if (cat === "Desarrollo") return "#0A84FF";
        if (cat === "Navegación") return "#32ADE6";
        if (cat === "Multimedia") return "#AF52DE";
        if (cat === "Comunicación") return "#34C759";
        return "#FF9500";
    }

    spacing: 12

    // Card 1: Daily Total & vs Average
    Rectangle {
        id: card1
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: Math.max(136, card1Col.implicitHeight + 28)
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder
        clip: true

        ColumnLayout {
            id: card1Col
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: "Tiempo de uso (" + (root.trackerObj ? root.trackerObj.selectedDate : "Hoy") + ")"
                color: CachyPalette.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                color: CachyPalette.text
                font.pixelSize: 28
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

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
        id: card2
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: Math.max(136, card2Col.implicitHeight + 28)
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder
        clip: true

        ColumnLayout {
            id: card2Col
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
                    color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0) ? "#34C759" : CachyPalette.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: "Ventana activa (Wayland / KWin)"
                    color: CachyPalette.textMuted
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                color: CachyPalette.text
                font.pixelSize: 18
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: {
                    if (!root.trackerObj) return "";
                    const cap = root.trackerObj.currentActiveCaption;
                    const app = root.trackerObj.currentActiveApp;
                    if (app.length === 0) return "Esperando foco de ventana en KWin…";
                    return cap.length > 0 ? (app + " — " + cap) : app;
                }
                color: CachyPalette.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    // Card 3: Categories Breakdown (macOS Golden Gate Style)
    Rectangle {
        id: card3
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1.35
        implicitHeight: Math.max(136, card3Col.implicitHeight + 28)
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder
        clip: true

        ColumnLayout {
            id: card3Col
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Desglose por categorías"
                color: CachyPalette.textMuted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // macOS Screen Time Segmented Proportional Category Bar
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: CachyPalette.surfacePill
                clip: true
                visible: Boolean(root.trackerObj && root.trackerObj.categoryBreakdown.length > 0)

                Row {
                    anchors.fill: parent
                    spacing: 1

                    Repeater {
                        model: root.trackerObj ? root.trackerObj.categoryBreakdown : []

                        Rectangle {
                            id: seg
                            required property var modelData
                            height: parent.height
                            width: Math.max(3, Math.round(parent.width * seg.modelData.ratio))
                            color: root.categoryAccentColor(seg.modelData.category)
                        }
                    }
                }
            }

            Text {
                visible: !root.trackerObj || root.trackerObj.categoryBreakdown.length === 0
                text: "Sin actividad registrada en esta fecha"
                color: CachyPalette.textSecondary
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Flow {
                visible: Boolean(root.trackerObj && root.trackerObj.categoryBreakdown.length > 0)
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.trackerObj ? root.trackerObj.categoryBreakdown : []

                    Rectangle {
                        id: catBadge
                        required property var modelData
                        height: 22
                        implicitWidth: catRow.implicitWidth + 12
                        radius: 11
                        color: Qt.alpha(root.categoryAccentColor(catBadge.modelData.category), CachyPalette.isDark ? 0.20 : 0.12)
                        border.width: 1
                        border.color: Qt.alpha(root.categoryAccentColor(catBadge.modelData.category), 0.45)

                        RowLayout {
                            id: catRow
                            anchors.centerIn: parent
                            spacing: 4

                            Rectangle {
                                Layout.preferredWidth: 6
                                Layout.preferredHeight: 6
                                radius: 3
                                color: root.categoryAccentColor(catBadge.modelData.category)
                            }

                            Text {
                                text: catBadge.modelData.category
                                color: CachyPalette.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: catBadge.modelData.formattedDuration
                                color: root.categoryAccentColor(catBadge.modelData.category)
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
