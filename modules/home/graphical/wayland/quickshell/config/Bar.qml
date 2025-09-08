import Quickshell // for PanelWindow
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick // for Text
import QtQuick.Layouts
import "components"
import "widgets"

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        PanelWindow {
            color: "transparent"
            implicitHeight: 30
            screen: scope.modelData

            anchors {
                left: true
                right: true
                top: true
            }

            RowLayout {
                anchors.right: parent.right
                spacing: 5

                BarItem {
                    text: Vdesk.vdesk
                }

                BarItem {
                    text: Time.date
                }

                BarItem {
                    text: Time.time
                }
            }
        }
    }
}
