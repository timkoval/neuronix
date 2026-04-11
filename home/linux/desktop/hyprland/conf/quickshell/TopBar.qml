import QtQuick
import QtQuick.Layouts
import Quickshell

Variants {
  model: Quickshell.screens

  delegate: Component {
    PanelWindow {
      id: bar
      required property var modelData

      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 36
      color: "#101418dd"

      SystemClock {
        id: clock
        precision: SystemClock.Seconds
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Text {
          text: "Neuronix"
          color: "#d6dde5"
          font.pixelSize: 13
        }

        Item {
          Layout.fillWidth: true
        }

        Text {
          text: Qt.formatDateTime(clock.date, "ddd MMM d  HH:mm")
          color: "#d6dde5"
          font.pixelSize: 13
        }
      }
    }
  }
}
