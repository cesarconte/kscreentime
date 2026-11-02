/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: glassRoot

    property bool liquidGlass: false
    property bool isHighlighted: false
    // "shell" (outer container), "recessed" (inner well), or "card" (floating bubble/bar)
    property string glassStyle: "card"
    property real glassOpacity: 1.0

    radius: Kirigami.Units.smallSpacing

    // Respects KDE Plasma / Breeze theme natively (supports both light and dark themes)
    color: {
        if (isHighlighted) {
            return Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16);
        }
        if (glassStyle === "recessed") {
            return Kirigami.Theme.backgroundColor;
        }
        return Kirigami.Theme.alternateBackgroundColor;
    }

    border.width: 1
    border.color: {
        if (isHighlighted) {
            return Kirigami.Theme.highlightColor;
        }
        return Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.14);
    }
}

