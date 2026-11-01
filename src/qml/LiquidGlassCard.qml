/*
    SPDX-FileCopyrightText: 2026 Kiri contributors
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: glassRoot

    property bool liquidGlass: true
    property bool isHighlighted: false
    // "shell" (outer container), "recessed" (inner well), or "card" (floating bubble/bar)
    property string glassStyle: "card"
    property real glassOpacity: 0.86

    radius: glassStyle === "shell" ? Kirigami.Units.largeSpacing : Kirigami.Units.mediumSpacing

    // Base refractive fill matching KDropover's Liquid Glass aesthetic
    color: {
        if (!liquidGlass) {
            return isHighlighted
                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
                : Kirigami.Theme.alternateBackgroundColor;
        }
        if (isHighlighted) {
            return Qt.rgba(0.0, 0.58, 0.78, 0.28);
        }
        if (glassStyle === "shell") {
            return Qt.rgba(0.08, 0.09, 0.13, glassOpacity);
        }
        if (glassStyle === "recessed") {
            return Qt.rgba(0.02, 0.03, 0.05, 0.36);
        }
        return Qt.rgba(0.11, 0.13, 0.18, 0.78);
    }

    // Outer luminous refractive border
    border.width: isHighlighted && glassStyle === "shell" ? 2 : 1
    border.color: {
        if (isHighlighted) {
            return liquidGlass
                ? "#00e5ff"
                : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.45);
        }
        if (!liquidGlass) {
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12);
        }
        if (glassStyle === "shell") {
            return Qt.rgba(1.0, 1.0, 1.0, 0.24);
        }
        return Qt.rgba(1.0, 1.0, 1.0, 0.15);
    }

    // Top-to-bottom refractive luminance sheen (macOS Tahoe / Golden Gate Liquid Glass)
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, glassRoot.radius - 1)
        visible: glassRoot.liquidGlass
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1.0, 1.0, 1.0, glassRoot.isHighlighted ? 0.20 : (glassRoot.glassStyle === "recessed" ? 0.08 : 0.15))
            }
            GradientStop {
                position: 0.35
                color: Qt.rgba(1.0, 1.0, 1.0, 0.02)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0.0, 0.0, 0.0, glassRoot.glassStyle === "recessed" ? 0.20 : 0.14)
            }
        }
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, glassRoot.isHighlighted ? 0.26 : 0.10)
    }
}
