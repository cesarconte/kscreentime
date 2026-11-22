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
        text: "Ventana activa (KWin Wayland)"
        font.pixelSize: 20
        font.weight: Font.Bold
        color: CachyPalette.text
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Monitoreo en tiempo real de la ventana con foco en el compositor KWin de KDE Plasma 6 Wayland."
        font.pixelSize: 12
        color: CachyPalette.textSecondary
    }

    // Active App Hero Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: liveCardCol.implicitHeight + 32
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

        ColumnLayout {
            id: liveCardCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 12
                    color: CachyPalette.surfacePill
                    border.width: 1
                    border.color: CachyPalette.specularBorder

                    CachyIcon {
                        anchors.centerIn: parent
                        name: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                            ? root.trackerObj.currentActiveApp
                            : "window"
                        size: 32
                        colored: false
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                                ? "#34C759"
                                : CachyPalette.textMuted
                        }

                        Text {
                            text: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                                ? "EN SEGUIMIENTO ACTIVO"
                                : "ESCRITORIO WAYLAND / INACTIVO"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                                ? "#34C759"
                                : CachyPalette.textMuted
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        color: CachyPalette.text
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackerObj ? ("App ID: " + root.trackerObj.currentActiveApp) : ""
                        font.pixelSize: 11
                        color: CachyPalette.textMuted
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Título de la ventana (Caption):"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyPalette.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WrapAnywhere
                    text: (root.trackerObj && root.trackerObj.currentActiveCaption.length > 0)
                        ? root.trackerObj.currentActiveCaption
                        : "(Sin ventana con foco)"
                    font.pixelSize: 13
                    color: CachyPalette.text
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
            }

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Tiempo total acumulado hoy:"
                        font.pixelSize: 11
                        color: CachyPalette.textMuted
                    }

                    Text {
                        text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: CachyTheme.accentColor
                    }
                }

                CachyButton {
                    text: "Reiniciar datos"
                    iconName: "edit-clear-history"
                    pillStyle: true
                    enabled: Boolean(root.trackerObj && root.trackerObj.todayTotalSeconds > 0)
                    onClicked: {
                        if (root.trackerObj) {
                            root.trackerObj.clearAllData();
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
