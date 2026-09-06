import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "respice"

  readonly property var quotes: [
    "Memento mori.",
    "You have power over your mind, not outside events.",
    "Waste no more time arguing what a good man should be. Be one.",
    "The obstacle is the way."
  ]

  property int index: 0

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.index = (root.index + 1) % root.quotes.length
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.quotes[root.index]
    tooltipText: "Respice — click to reflect"
    onPressed: function(b) {
      root.index = (root.index + 1) % root.quotes.length
    }
  }
}
