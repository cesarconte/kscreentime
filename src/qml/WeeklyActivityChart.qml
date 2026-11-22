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

    Layout.fillWidth: true
    Layout.preferredHeight: 204
    radius: 14
    color: CachyPalette.cardBackground
    border.width: 1
    border.color: CachyPalette.specularBorder

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Actividad de la semana"
                color: CachyPalette.text
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Haz clic en un día para filtrar el detalle"
                color: CachyPalette.textMuted
                font.pixelSize: 11
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Subtle background horizontal grid lines (0%, 50%, 100%)
            Rectangle {
                anchors.left: parent.left
                anchors.right: axisCol.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 18
                height: 1
                color: CachyPalette.separator
                opacity: 0.4
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: axisCol.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: CachyPalette.separator
                opacity: 0.3
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: axisCol.left
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                height: 1
                color: CachyPalette.separator
                opacity: 0.5
            }

            // Right Y-Axis labels
            ColumnLayout {
                id: axisCol
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: 32
                spacing: 0

                Text {
                    text: "Max"
                    color: CachyPalette.textMuted
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
                Item { Layout.fillHeight: true }
                Text {
                    text: "Med"
                    color: CachyPalette.textMuted
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
                Item { Layout.fillHeight: true }
                Text {
                    text: "0"
                    color: CachyPalette.textMuted
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                }
            }

            // Days Bars Row
            RowLayout {
                anchors.left: parent.left
                anchors.right: axisCol.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 12

                Repeater {
                    model: root.trackerObj ? root.trackerObj.weeklyChartData : []

                    Item {
                        id: dayBarItem
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: dayBarItem.modelData.formattedDuration
                                color: dayBarItem.modelData.isSelected ? CachyTheme.accentColor : CachyPalette.textSecondary
                                font.pixelSize: 10
                                font.weight: dayBarItem.modelData.isSelected ? Font.Bold : Font.Normal
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                radius: 8
                                color: dayBarItem.modelData.isSelected
                                    ? Qt.alpha(CachyTheme.accentColor, 0.16)
                                    : CachyPalette.surfacePill
                                border.width: 1
                                border.color: dayBarItem.modelData.isSelected
                                    ? CachyTheme.accentColor
                                    : CachyPalette.specularBorder

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 3
                                    height: dayBarItem.modelData.totalSeconds > 0
                                        ? Math.max(6, (parent.height - 6) * dayBarItem.modelData.ratio)
                                        : 0
                                    radius: 6
                                    color: CachyTheme.accentColor
                                    opacity: dayBarItem.modelData.isSelected ? 0.95 : 0.60
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    onTapped: {
                                        if (root.trackerObj) {
                                            root.trackerObj.selectDate(dayBarItem.modelData.date);
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: dayBarItem.modelData.dayLabel
                                color: dayBarItem.modelData.isSelected ? CachyTheme.accentColor : CachyPalette.textSecondary
                                font.pixelSize: 11
                                font.weight: dayBarItem.modelData.isSelected ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }
}
