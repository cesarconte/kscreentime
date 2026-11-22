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

    Text {
        text: "Tiempo de inactividad"
        font.pixelSize: 20
        font.weight: Font.Bold
        color: CachyPalette.text
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Durante el tiempo de inactividad, solo estarán disponibles las apps que elijas permitir y las llamadas telefónicas o mensajes esenciales."
        font.pixelSize: 12
        color: CachyPalette.textSecondary
    }

    // Main Grouped Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: downtimeCardCol.implicitHeight + 24
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

        ColumnLayout {
            id: downtimeCardCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Activar tiempo de inactividad programado"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                    }

                    Text {
                        text: "Se activará automáticamente durante el horario fijado"
                        font.pixelSize: 11
                        color: CachyPalette.textSecondary
                    }
                }

                CachySwitch {
                    checked: Boolean(root.trackerObj && root.trackerObj.downtimeEnabled)
                    onToggled: {
                        if (root.trackerObj) {
                            root.trackerObj.setDowntimeEnabled(checked);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
            }

            RowLayout {
                Layout.fillWidth: true
                opacity: (root.trackerObj && root.trackerObj.downtimeEnabled) ? 1.0 : 0.4
                enabled: Boolean(root.trackerObj && root.trackerObj.downtimeEnabled)

                Text {
                    text: "Inicio"
                    font.pixelSize: 13
                    color: CachyPalette.text
                    Layout.preferredWidth: 80
                }

                Item { Layout.fillWidth: true }

                CachyComboBox {
                    id: startCombo
                    model: ["20:00", "21:00", "22:00", "23:00", "00:00"]
                    currentIndex: Math.max(0, model.indexOf(root.trackerObj ? root.trackerObj.downtimeStart : "22:00"))
                    onActivated: {
                        if (root.trackerObj) {
                            root.trackerObj.setDowntimeStart(currentText);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
            }

            RowLayout {
                Layout.fillWidth: true
                opacity: (root.trackerObj && root.trackerObj.downtimeEnabled) ? 1.0 : 0.4
                enabled: Boolean(root.trackerObj && root.trackerObj.downtimeEnabled)

                Text {
                    text: "Fin"
                    font.pixelSize: 13
                    color: CachyPalette.text
                    Layout.preferredWidth: 80
                }

                Item { Layout.fillWidth: true }

                CachyComboBox {
                    id: endCombo
                    model: ["06:00", "06:30", "07:00", "07:30", "08:00", "09:00"]
                    currentIndex: Math.max(0, model.indexOf(root.trackerObj ? root.trackerObj.downtimeEnd : "07:00"))
                    onActivated: {
                        if (root.trackerObj) {
                            root.trackerObj.setDowntimeEnd(currentText);
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
            }

            RowLayout {
                Layout.fillWidth: true
                opacity: (root.trackerObj && root.trackerObj.downtimeEnabled) ? 1.0 : 0.4
                enabled: Boolean(root.trackerObj && root.trackerObj.downtimeEnabled)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Bloquear al llegar al tiempo de inactividad"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                    }

                    Text {
                        text: "Requiere confirmación explícita para solicitar más tiempo"
                        font.pixelSize: 11
                        color: CachyPalette.textSecondary
                    }
                }

                CachySwitch {
                    checked: Boolean(root.trackerObj && root.trackerObj.downtimeBlockAtLimit)
                    onToggled: {
                        if (root.trackerObj) {
                            root.trackerObj.setDowntimeBlockAtLimit(checked);
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
