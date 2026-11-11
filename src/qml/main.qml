/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import CachyOS.UI

CachyWindow {
    id: root

    title: "Screen Time — KScreenTime"
    width: 980
    height: 700
    minimumWidth: 800
    minimumHeight: 560
    visible: root.trackerObj ? root.trackerObj.windowVisible : true

    showTrafficLights: true
    showTitleBarDivider: true
    showWindowFrame: true
    sidebarVisible: root.showSidebar
    sidebarWidth: 232
    cornerRadius: CachyTheme.radiusWindow

    property bool showSidebar: true
    property string activeSection: "activity"
    readonly property var trackerObj: typeof Tracker !== "undefined" ? Tracker : null

    onClosing: (close) => {
        if (root.trackerObj) {
            close.accepted = false;
            root.trackerObj.windowVisible = false;
        }
    }

    Connections {
        target: root.trackerObj
        function onShowWindowRequested() {
            root.show();
            root.raise();
            root.requestActivate();
        }
    }

    function categoryAccentColor(cat: string): color {
        if (cat === "Desarrollo") return "#007AFF";
        if (cat === "Navegación") return "#32ADE6";
        if (cat === "Multimedia") return "#AF52DE";
        if (cat === "Comunicación") return "#34C759";
        return "#FF9500";
    }

    // =========================================================================
    // 1. GOLDEN GATE EDGE-TO-EDGE SCREEN TIME SIDEBAR
    // =========================================================================
    sidebar: [
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 12
            spacing: 4

            Text {
                Layout.leftMargin: 8
                Layout.bottomMargin: 4
                text: "Screen Time"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyTheme.textMuted
            }

            CachySidebarItem {
                Layout.fillWidth: true
                text: "App & Website Activity"
                iconGlyph: "📊"
                iconColor: "#007AFF"
                squircleIconBadge: true
                selected: root.activeSection === "activity"
                onClicked: root.activeSection = "activity"
            }

            CachySidebarItem {
                Layout.fillWidth: true
                text: "Active Window (KWin)"
                iconGlyph: "🪟"
                iconColor: "#34C759"
                squircleIconBadge: true
                selected: root.activeSection === "live"
                onClicked: root.activeSection = "live"
            }

            CachySidebarItem {
                Layout.fillWidth: true
                text: "Categories Breakdown"
                iconGlyph: "🏷"
                iconColor: "#AF52DE"
                squircleIconBadge: true
                selected: root.activeSection === "categories"
                onClicked: root.activeSection = "categories"
            }

            Text {
                Layout.leftMargin: 8
                Layout.topMargin: 10
                Layout.bottomMargin: 4
                text: "Limit Usage"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyTheme.textMuted
            }

            CachySidebarItem {
                Layout.fillWidth: true
                text: "App Limits"
                iconGlyph: "⏳"
                iconColor: "#FF9500"
                squircleIconBadge: true
                badgeText: root.trackerObj ? String(root.trackerObj.appUsageList.length) : "0"
                selected: root.activeSection === "limits"
                onClicked: root.activeSection = "limits"
            }

            Item { Layout.fillHeight: true }

            // Bottom Live Wayland Active Window Pill inside Sidebar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: liveSidebarCol.implicitHeight + 18
                radius: 12
                color: CachyTheme.cardBackground
                border.width: 1
                border.color: CachyTheme.specularBorder

                ColumnLayout {
                    id: liveSidebarCol
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0)
                                ? "#34C759"
                                : CachyTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "KWin Wayland Live"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: CachyTheme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: CachyTheme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: CachyTheme.accentColor
                        elide: Text.ElideRight
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 2. GOLDEN GATE 44PX HEADER TOOLBAR
    // =========================================================================
    headerLeading: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            CachyToolbarButton {
                text: "☰"
                tooltipText: "Mostrar/ocultar barra lateral"
                onClicked: root.showSidebar = !root.showSidebar
            }

            Text {
                text: "Fecha: " + (root.trackerObj ? root.trackerObj.selectedDate : "Hoy")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyTheme.textSecondary
            }
        }
    ]

    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            CachyToolbarButton {
                text: "Reiniciar"
                implicitWidth: 74
                enabled: Boolean(root.trackerObj && root.trackerObj.todayTotalSeconds > 0)
                tooltipText: "Reiniciar historial de tiempo de uso"
                onClicked: {
                    if (root.trackerObj) {
                        root.trackerObj.clearAllData();
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 3. MAIN SCROLLABLE DASHBOARD (Strictly Zero Horizontal Overflow)
    // =========================================================================
    contentData: [
        QQC2.ScrollView {
            id: mainScroll
            anchors.fill: parent
            contentWidth: availableWidth
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            clip: true

            ColumnLayout {
                width: mainScroll.availableWidth - 32
                x: 16
                y: 16
                spacing: 14

                // Top Row: 3 Golden Gate Summary Cards
                RowLayout {
                    Layout.fillWidth: true
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
                                    width: 8
                                    height: 8
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

                // Middle Card: Interactive 7-Day Activity Bar Chart
                Rectangle {
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

                // Bottom Card: Per-Application Usage List & Daily App Limits
                Rectangle {
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

                                    Kirigami.Icon {
                                        source: appCard.modelData.iconName
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
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
                                            height: 6
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
                                                required property var modelData
                                                readonly property bool isSelected: appCard.modelData.limitMinutes === modelData.mins
                                                height: 24
                                                implicitWidth: 34
                                                radius: 12
                                                color: isSelected ? CachyTheme.accentColor : "transparent"
                                                border.width: 1
                                                border.color: isSelected ? CachyTheme.accentColor : CachyTheme.specularBorder

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.pixelSize: 10
                                                    font.weight: isSelected ? Font.Bold : Font.Medium
                                                    color: isSelected ? "#FFFFFF" : CachyTheme.textSecondary
                                                }

                                                TapHandler {
                                                    onTapped: {
                                                        if (root.trackerObj) {
                                                            root.trackerObj.setAppLimit(appCard.modelData.appId, modelData.mins);
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
            }
        }
    ]
}
