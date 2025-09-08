// Time.qml
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property QtObject by_meaning: QtObject {
        id: meaning

        readonly property color border: penumbra.sun
        readonly property color foreground: penumbra.shade_plus
        readonly property color text: penumbra.sky_plus
    }
    readonly property QtObject by_mneumonic: QtObject {
        id: mneumonic

        readonly property color blue: "#6EB2FD"
        readonly property color cyan: "#00C4D7"
        readonly property color green: "#54C794"
        readonly property color magenta: "#E58CC5"
        readonly property color orange: "#E09F47"
        readonly property color purple: "#B69CF6"
        readonly property color red: "#F58C81"
        readonly property color yellow: "#A9B852"
    }
    readonly property QtObject penumbra: QtObject {
        id: penumbra

        readonly property color shade: "#181B1F" //  main background colour
        readonly property color shade_minus: "#0D0F13" // “black”, de-emphasized/receded background elements, selections, dark UI elements
        readonly property color shade_plus: "#3E4044" // foreground UI elements, rulers, indentation guides and similar
        readonly property color sky: "#AEAEAE" // foreground, code, main content colour, text both in editors and UI elements
        readonly property color sky_minus: "#636363" // comments, de-emphasized content
        readonly property color sky_plus: "#DEDEDE" // emphasized content and emphasized UI text
        readonly property color sun: "#FFF7ED" // selections, light borders, strongly emphasized content
        readonly property color sun_plus: "#FFFDFB" // “white”, text in highlighted sections, emphasized borders
    }
}
