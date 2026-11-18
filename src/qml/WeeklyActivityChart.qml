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
    Layout.preferredHeight: 196
    radius: 16
    color: CachyTheme.cardBackground
    border.width: 1
    border.color: CachyTheme.specularBorder

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            Layout.fillWidth: true
            text: "Actividad de los Últimos 7 Días (haz clic en un día para inspeccionar)"
            color: CachyTheme.textPrimary
            font.pixelSize: 13
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

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
                            color: dayBarItem.modelData.isSelected ? CachyTheme.accentColor : CachyTheme.textSecondary
                            font.pixelSize: 10
                            font.weight: dayBarItem.modelData.isSelected ? Font.Bold : Font.Normal
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: 6
                            Layout.rightMargin: 6
                            radius: 8
                            color: dayBarItem.modelData.isSelected
                                ? CachyTheme.withAlpha(CachyTheme.accentColor, 0.14)
                                : CachyTheme.surfacePill
                            border.width: 1
                            border.color: dayBarItem.modelData.isSelected
                                ? CachyTheme.accentColor
                                : CachyTheme.specularBorder

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
                                opacity: dayBarItem.modelData.isSelected ? 0.95 : 0.55

                                Behavior on height {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
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
                            color: dayBarItem.modelData.isSelected ? CachyTheme.accentColor : CachyTheme.textSecondary
                            font.pixelSize: 11
                            font.weight: dayBarItem.modelData.isSelected ? Font.Bold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
