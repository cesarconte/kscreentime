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
    property string filterQuery: ""

    function categoryAccentColor(cat: string): color {
        if (cat === "Desarrollo") return "#0A84FF";
        if (cat === "Navegación") return "#32ADE6";
        if (cat === "Multimedia") return "#AF52DE";
        if (cat === "Comunicación") return "#34C759";
        return "#FF9500";
    }

    Layout.fillWidth: true
    implicitHeight: appListColumn.implicitHeight + 28
    radius: 14
    color: CachyPalette.cardBackground
    border.width: 1
    border.color: CachyPalette.specularBorder

    ColumnLayout {
        id: appListColumn
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Uso por aplicación y límites diarios"
                color: CachyPalette.text
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            CachySearchField {
                id: searchBox
                Layout.preferredWidth: 180
                placeholderText: "Buscar app…"
                onTextChanged: root.filterQuery = text.toLowerCase().trim()
            }
        }

        Text {
            visible: !root.trackerObj || root.trackerObj.appUsageList.length === 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "No hay actividad de aplicaciones registrada en esta fecha."
            color: CachyPalette.textSecondary
            font.pixelSize: 12
        }

        Repeater {
            model: {
                if (!root.trackerObj || !root.trackerObj.appUsageList) return [];
                const list = root.trackerObj.appUsageList;
                if (!root.filterQuery) return list;
                return list.filter(function(item) {
                    return item.displayName.toLowerCase().indexOf(root.filterQuery) !== -1 ||
                           item.category.toLowerCase().indexOf(root.filterQuery) !== -1;
                });
            }

            Rectangle {
                id: appCard
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 60
                radius: 10
                color: appCard.modelData.limitExceeded
                    ? (CachyPalette.isDark ? "#33FF3B30" : "#1AFF3B30")
                    : CachyPalette.surfacePill
                border.width: 1
                border.color: appCard.modelData.limitExceeded
                    ? "#FF3B30"
                    : CachyPalette.specularBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    CachyIcon {
                        name: appCard.modelData.iconName
                        size: 26
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
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
                                color: CachyPalette.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
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
                            Layout.preferredHeight: 5
                            radius: 2.5
                            color: Qt.alpha(CachyPalette.textMuted, 0.20)

                            Rectangle {
                                width: Math.max(5, parent.width * Math.min(1.0, appCard.modelData.ratio))
                                height: parent.height
                                radius: 2.5
                                color: appCard.modelData.limitExceeded
                                    ? "#FF3B30"
                                    : root.categoryAccentColor(appCard.modelData.category)
                            }
                        }
                    }

                    // Daily Limit Pills (15m, 30m, 1h, ∞)
                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "15m", mins: 15 },
                                { label: "30m", mins: 30 },
                                { label: "1h", mins: 60 },
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
                                border.color: isSelected ? CachyTheme.accentColor : CachyPalette.specularBorder

                                Text {
                                    anchors.centerIn: parent
                                    text: limitPill.modelData.label
                                    font.pixelSize: 10
                                    font.weight: limitPill.isSelected ? Font.Bold : Font.Normal
                                    color: limitPill.isSelected ? "#FFFFFF" : CachyPalette.textSecondary
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
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
