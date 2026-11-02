/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: "KScreenTime — Tiempo de Uso"
    width: 980
    height: 760
    minimumWidth: 820
    minimumHeight: 620
    visible: root.trackerObj ? root.trackerObj.windowVisible : true

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
        if (cat === "Desarrollo") return "#00e5ff";
        if (cat === "Navegación") return "#4fc3f7";
        if (cat === "Multimedia") return "#ba68c8";
        if (cat === "Comunicación") return "#66bb6a";
        return "#ffb74d";
    }

    pageStack.initialPage: Kirigami.ScrollablePage {
        id: dashboardPage
        title: "Tiempo de Uso"
        padding: Kirigami.Units.largeSpacing

        ColumnLayout {
            width: dashboardPage.availableWidth
            spacing: Kirigami.Units.largeSpacing

            // Top summary row: 3 Liquid Glass cards
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                // Card 1: Today's Total Screen Time & Comparison vs 7-day average
                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumHeight: 138
                    padding: Kirigami.Units.mediumSpacing

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "preferences-system-time"
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                            }

                            QQC2.Label {
                                text: "Tiempo de Uso (" + (root.trackerObj ? root.trackerObj.selectedDate : "Hoy") + ")"
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        QQC2.Label {
                            text: root.trackerObj ? root.trackerObj.todayTotalFormatted : "0m"
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 34
                            font.bold: true
                        }

                        QQC2.Label {
                            text: root.trackerObj ? root.trackerObj.vsAverageText : ""
                            color: Kirigami.Theme.highlightColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Card 2: Live Active Wayland Window Indicator
                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumHeight: 138
                    padding: Kirigami.Units.mediumSpacing

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: (root.trackerObj && root.trackerObj.currentActiveApp.length > 0) ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                            }

                            QQC2.Label {
                                text: "Ventana Activa (Wayland / KWin)"
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        QQC2.Label {
                            text: root.trackerObj ? root.trackerObj.currentActiveDisplayName : "Escritorio Wayland"
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 22
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        QQC2.Label {
                            text: {
                                if (!root.trackerObj) return "";
                                const cap = root.trackerObj.currentActiveCaption;
                                const app = root.trackerObj.currentActiveApp;
                                if (app.length === 0) return "Esperando foco de ventana en KWin...";
                                return cap.length > 0 ? (app + " — " + cap) : app;
                            }
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Card 3: Category Breakdown Badges
                QQC2.Frame {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1.25
                    Layout.minimumHeight: 138
                    padding: Kirigami.Units.mediumSpacing

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "view-statistics"
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            QQC2.Label {
                                text: "Desglose por Categorías"
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }
                        }

                        QQC2.Label {
                            visible: !root.trackerObj || root.trackerObj.categoryBreakdown.length === 0
                            text: "Sin actividad registrada en esta fecha"
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        Flow {
                            visible: root.trackerObj && root.trackerObj.categoryBreakdown.length > 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Kirigami.Units.smallSpacing

                            Repeater {
                                model: root.trackerObj ? root.trackerObj.categoryBreakdown : []

                                delegate: Rectangle {
                                    id: catBadge
                                    required property var modelData

                                    width: catBadgeRow.implicitWidth + Kirigami.Units.largeSpacing * 1.4
                                    height: 30
                                    radius: Kirigami.Units.smallSpacing
                                    color: Kirigami.Theme.backgroundColor
                                    border.width: 1
                                    border.color: root.categoryAccentColor(catBadge.modelData.category)

                                    RowLayout {
                                        id: catBadgeRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Kirigami.Icon {
                                            source: catBadge.modelData.iconName
                                            Layout.preferredWidth: 15
                                            Layout.preferredHeight: 15
                                        }

                                        QQC2.Label {
                                            text: catBadge.modelData.category
                                            color: Kirigami.Theme.textColor
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        QQC2.Label {
                                            text: catBadge.modelData.formattedDuration
                                            color: Kirigami.Theme.highlightColor
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Middle card: Interactive 7-Day Bar Chart
            QQC2.Frame {
                Layout.fillWidth: true
                Layout.preferredHeight: 230
                padding: Kirigami.Units.mediumSpacing

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.mediumSpacing

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            source: "clock"
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        QQC2.Label {
                            text: "Actividad de los Últimos 7 Días (haz clic en un día para inspeccionar)"
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Kirigami.Units.largeSpacing

                        Repeater {
                            model: root.trackerObj ? root.trackerObj.weeklyChartData : []

                            delegate: Item {
                                id: dayBarItem
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 6

                                    QQC2.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: dayBarItem.modelData.formattedDuration
                                        color: dayBarItem.modelData.isSelected ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 11
                                        font.bold: dayBarItem.modelData.isSelected
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            radius: Kirigami.Units.smallSpacing
                                            color: dayBarItem.modelData.isSelected
                                                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16)
                                                : Kirigami.Theme.alternateBackgroundColor
                                            border.width: 1
                                            border.color: dayBarItem.modelData.isSelected
                                                ? Kirigami.Theme.highlightColor
                                                : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.14)

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                anchors.margins: 3
                                                height: dayBarItem.modelData.totalSeconds > 0
                                                    ? Math.max(6, (parent.height - 6) * dayBarItem.modelData.ratio)
                                                    : 0
                                                radius: 6
                                                color: dayBarItem.modelData.isSelected ? Kirigami.Theme.highlightColor : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.highlightColor, 0.6)
                                                opacity: dayBarItem.modelData.isSelected ? 0.92 : 0.58

                                                Behavior on height {
                                                    NumberAnimation {
                                                        duration: 220
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.trackerObj) {
                                                    root.trackerObj.selectDate(dayBarItem.modelData.date);
                                                }
                                            }
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: dayBarItem.modelData.dayLabel
                                        color: dayBarItem.modelData.isSelected ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 12
                                        font.bold: dayBarItem.modelData.isSelected
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom card: Per-Application Usage List & App Limits
            QQC2.Frame {
                Layout.fillWidth: true
                Layout.minimumHeight: 220
                implicitHeight: appListColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                padding: Kirigami.Units.mediumSpacing

                ColumnLayout {
                    id: appListColumn
                    anchors.fill: parent
                    spacing: Kirigami.Units.mediumSpacing

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            source: "application-x-executable"
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        QQC2.Label {
                            text: "Uso Real por Aplicación y Límites Diarios"
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        QQC2.Button {
                            icon.name: "edit-clear-history"
                            text: "Reiniciar historial"
                            flat: true
                            enabled: root.trackerObj && root.trackerObj.todayTotalSeconds > 0
                            onClicked: {
                                if (root.trackerObj) {
                                    root.trackerObj.clearAllData();
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: !root.trackerObj || root.trackerObj.appUsageList.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        radius: Kirigami.Units.smallSpacing
                        color: Kirigami.Theme.backgroundColor
                        border.width: 1
                        border.color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.14)

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: "No hay actividad de aplicaciones registrada en esta fecha.\nEl monitor de KWin Wayland contabiliza en tiempo real las ventanas activas que utilizas."
                            horizontalAlignment: Text.AlignHCenter
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 13
                        }
                    }

                    Repeater {
                        model: root.trackerObj ? root.trackerObj.appUsageList : []

                        delegate: Rectangle {
                            id: appCard
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.minimumHeight: 68
                            radius: Kirigami.Units.smallSpacing
                            color: appCard.modelData.limitExceeded
                                ? Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.14)
                                : Kirigami.Theme.alternateBackgroundColor
                            border.width: 1
                            border.color: appCard.modelData.limitExceeded
                                ? Kirigami.Theme.negativeTextColor
                                : Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.14)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.mediumSpacing
                                spacing: Kirigami.Units.mediumSpacing

                                Kirigami.Icon {
                                    source: appCard.modelData.iconName
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Kirigami.Units.smallSpacing

                                        QQC2.Label {
                                            text: appCard.modelData.displayName
                                            color: Kirigami.Theme.textColor
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Rectangle {
                                            radius: 4
                                            color: Kirigami.Theme.alternateBackgroundColor
                                            border.width: 1
                                            border.color: root.categoryAccentColor(appCard.modelData.category)
                                            implicitWidth: catText.implicitWidth + 12
                                            implicitHeight: 20

                                            QQC2.Label {
                                                id: catText
                                                anchors.centerIn: parent
                                                text: appCard.modelData.category
                                                color: Kirigami.Theme.textColor
                                                font.pixelSize: 11
                                            }
                                        }

                                        Rectangle {
                                            visible: appCard.modelData.limitExceeded
                                            radius: 4
                                            color: Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.15)
                                            border.width: 1
                                            border.color: Kirigami.Theme.negativeTextColor
                                            implicitWidth: limitAlertRow.implicitWidth + 12
                                            implicitHeight: 20

                                            RowLayout {
                                                id: limitAlertRow
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Kirigami.Icon {
                                                    source: "dialog-warning"
                                                    Layout.preferredWidth: 14
                                                    Layout.preferredHeight: 14
                                                }

                                                QQC2.Label {
                                                    text: "Límite superado (" + appCard.modelData.limitMinutes + "m)"
                                                    color: Kirigami.Theme.negativeTextColor
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        QQC2.Label {
                                            text: appCard.modelData.formattedDuration
                                                + " (" + Math.round(appCard.modelData.ratio * 100) + "%)"
                                            color: Kirigami.Theme.highlightColor
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }

                                    // Usage progress bar
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 8
                                        radius: 4
                                        color: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.10)

                                        Rectangle {
                                            width: Math.max(6, parent.width * Math.min(1.0, appCard.modelData.ratio))
                                            height: parent.height
                                            radius: 4
                                            color: appCard.modelData.limitExceeded
                                                ? Kirigami.Theme.negativeTextColor
                                                : root.categoryAccentColor(appCard.modelData.category)
                                        }
                                    }
                                }

                                // Daily App Limit selector buttons (15m, 30m, 60m, Sin límite)
                                RowLayout {
                                    spacing: 4

                                    QQC2.Label {
                                        text: "Límite:"
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: 11
                                    }

                                    QQC2.Button {
                                        text: "15m"
                                        flat: appCard.modelData.limitMinutes !== 15
                                        highlighted: appCard.modelData.limitMinutes === 15
                                        Layout.preferredHeight: 28
                                        onClicked: {
                                            if (root.trackerObj) {
                                                root.trackerObj.setAppLimit(appCard.modelData.appId, 15);
                                            }
                                        }
                                    }

                                    QQC2.Button {
                                        text: "30m"
                                        flat: appCard.modelData.limitMinutes !== 30
                                        highlighted: appCard.modelData.limitMinutes === 30
                                        Layout.preferredHeight: 28
                                        onClicked: {
                                            if (root.trackerObj) {
                                                root.trackerObj.setAppLimit(appCard.modelData.appId, 30);
                                            }
                                        }
                                    }

                                    QQC2.Button {
                                        text: "60m"
                                        flat: appCard.modelData.limitMinutes !== 60
                                        highlighted: appCard.modelData.limitMinutes === 60
                                        Layout.preferredHeight: 28
                                        onClicked: {
                                            if (root.trackerObj) {
                                                root.trackerObj.setAppLimit(appCard.modelData.appId, 60);
                                            }
                                        }
                                    }

                                    QQC2.Button {
                                        text: "Sin límite"
                                        flat: appCard.modelData.limitMinutes !== 0
                                        highlighted: appCard.modelData.limitMinutes === 0
                                        Layout.preferredHeight: 28
                                        onClicked: {
                                            if (root.trackerObj) {
                                                root.trackerObj.setAppLimit(appCard.modelData.appId, 0);
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
