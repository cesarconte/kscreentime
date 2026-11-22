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
        text: "Siempre permitido"
        font.pixelSize: 20
        font.weight: Font.Bold
        color: CachyPalette.text
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Las apps permitidas están siempre disponibles durante el tiempo de inactividad y cuando se alcanza el límite de uso."
        font.pixelSize: 12
        color: CachyPalette.textSecondary
    }

    // Allowed Apps Card
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: allowedCardCol.implicitHeight + 24
        radius: 14
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

        ColumnLayout {
            id: allowedCardCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                text: "APLICACIONES PERMITIDAS"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyPalette.textMuted
            }

            Repeater {
                model: (root.trackerObj && root.trackerObj.alwaysAllowedApps) ? root.trackerObj.alwaysAllowedApps : []

                Item {
                    id: allowedItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 38

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        // Remove button (-) red circle
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: "#FF3B30"

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 2
                                radius: 1
                                color: "#FFFFFF"
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }

                            TapHandler {
                                onTapped: {
                                    if (root.trackerObj) {
                                        root.trackerObj.removeAlwaysAllowedApp(allowedItem.modelData);
                                    }
                                }
                            }
                        }

                        CachyIcon {
                            name: allowedItem.modelData
                            size: 20
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            colored: false
                        }

                        Text {
                            Layout.fillWidth: true
                            text: allowedItem.modelData
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: CachyPalette.text
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: CachyPalette.separator
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            Text {
                text: "OTRAS APLICACIONES DISPONIBLES"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyPalette.textMuted
            }

            Repeater {
                model: {
                    if (!root.trackerObj || !root.trackerObj.appUsageList) return [];
                    const allowed = root.trackerObj.alwaysAllowedApps || [];
                    return root.trackerObj.appUsageList.filter(function(item) {
                        return allowed.indexOf(item.appId) === -1;
                    });
                }

                Item {
                    id: candidateItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 38

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        // Add button (+) green circle
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: "#34C759"

                            Item {
                                anchors.centerIn: parent
                                width: 10
                                height: 10

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 2
                                    radius: 1
                                    color: "#FFFFFF"
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 2
                                    height: 10
                                    radius: 1
                                    color: "#FFFFFF"
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }

                            TapHandler {
                                onTapped: {
                                    if (root.trackerObj) {
                                        root.trackerObj.addAlwaysAllowedApp(candidateItem.modelData.appId);
                                    }
                                }
                            }
                        }

                        CachyIcon {
                            name: candidateItem.modelData.iconName
                            size: 20
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            colored: false
                        }

                        Text {
                            Layout.fillWidth: true
                            text: candidateItem.modelData.displayName
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: CachyPalette.text
                        }

                        Text {
                            text: candidateItem.modelData.category
                            font.pixelSize: 11
                            color: CachyPalette.textMuted
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
