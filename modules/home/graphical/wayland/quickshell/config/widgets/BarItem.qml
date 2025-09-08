import Quickshell // for PanelWindow
import Quickshell.Widgets
import QtQuick // for Text
import QtQuick.Layouts
import "../components"

WrapperRectangle {
    required property string text

    antialiasing: true
    color: Theme.foreground
    margin: 2
    radius: 6

    Text {
        id: timeText

        color: Theme.text
        text: parent.text
    }
}
