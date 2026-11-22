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

    required property var trackerObj
    spacing: 16

    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Límites de apps"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: CachyPalette.text
            }

            Text {
                text: "Establece límites de tiempo diarios para aplicaciones o categorías."
                font.pixelSize: 12
                color: CachyPalette.textSecondary
            }
        }

        CachyButton {
            text: "Añadir límite…"
            iconName: "add"
            pillStyle: true
            onClicked: addLimitPopover.open()

            CachyPopover {
                id: addLimitPopover
                preferredEdge: Qt.BottomEdge
                contentItem: ColumnLayout {
                    width: 260
                    spacing: 10

                    Text {
                        text: "Nuevo límite de uso"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: CachyPalette.text
                    }

                    CachyComboBox {
                        id: appSelectCombo
                        Layout.fillWidth: true
                        model: {
                            if (!root.trackerObj || !root.trackerObj.appUsageList) return [];
                            return root.trackerObj.appUsageList.map(function(item) {
                                return item.displayName;
                            });
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Tiempo:"
                            color: CachyPalette.text
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        CachyComboBox {
                            id: limitMinsCombo
                            model: ["15m", "30m", "45m", "1h", "1h 30m", "2h", "3h"]
                            currentIndex: 1
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }

                        CachyButton {
                            text: "Cancelar"
                            pillStyle: true
                            onClicked: addLimitPopover.close()
                        }

                        CachyButton {
                            text: "Guardar"
                            accent: true
                            pillStyle: true
                            onClicked: {
                                if (root.trackerObj && appSelectCombo.currentIndex >= 0) {
                                    const rawItem = root.trackerObj.appUsageList[appSelectCombo.currentIndex];
                                    if (rawItem) {
                                        const minsTable = [15, 30, 45, 60, 90, 120, 180];
                                        const mins = minsTable[limitMinsCombo.currentIndex] || 30;
                                        root.trackerObj.setAppLimit(rawItem.appId, mins);
                                    }
                                }
                                addLimitPopover.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // Limits List Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(120, limitsListCol.implicitHeight + 24)
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

        ColumnLayout {
            id: limitsListCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                visible: !root.trackerObj || !root.trackerObj.allLimitsList || root.trackerObj.allLimitsList.length === 0
                Layout.fillWidth: true
                text: "No hay límites activos configurados actualmente."
                color: CachyPalette.textSecondary
                font.pixelSize: 12
            }

            Repeater {
                model: (root.trackerObj && root.trackerObj.allLimitsList) ? root.trackerObj.allLimitsList : []

                Item {
                    id: limitItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 46

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            CachyIcon {
                                name: limitItem.modelData.iconName
                                size: 24
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                colored: false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: limitItem.modelData.displayName
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: CachyPalette.text
                                }

                                Text {
                                    text: limitItem.modelData.category
                                    font.pixelSize: 11
                                    color: CachyPalette.textMuted
                                }
                            }

                            Text {
                                text: limitItem.modelData.formattedLimit + " / día"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: CachyTheme.accentColor
                            }

                            CachyButton {
                                text: "Eliminar"
                                pillStyle: true
                                onClicked: {
                                    if (root.trackerObj) {
                                        root.trackerObj.setAppLimit(limitItem.modelData.appId, 0);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            height: 1
                            color: CachyPalette.separator
                            visible: limitItem.index < (root.trackerObj.allLimitsList.length - 1)
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
