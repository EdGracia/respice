import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "respice"
  ipcTarget: "respice"

  property var anchorItem: null

  // The bar tracks the widget mounted in its slot — BarWidget.qml — not this
  // nested panel, so keyboard Tab-switching between bar panels needs that
  // identity rather than root's.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  readonly property var quotes: [
    "Memento mori.",
    "You have power over your mind, not outside events.",
    "Waste no more time arguing what a good man should be. Be one.",
    "The obstacle is the way."
  ]
  property int index: 0

  function next() {
    root.index = (root.index + 1) % root.quotes.length
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(quoteColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onReturnRequested: root.next()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: quoteColumn
        width: parent.width
        spacing: Style.space(20)
        topPadding: Style.space(24)
        bottomPadding: Style.space(24)
        leftPadding: Style.space(24)
        rightPadding: Style.space(24)

        Text {
          width: parent.width - Style.space(48)
          text: root.quotes[root.index]
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.title
          wrapMode: Text.WordWrap
        }

        Rectangle {
          width: nextLabel.implicitWidth + Style.space(24)
          height: nextLabel.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: nextArea.containsMouse ? Style.hoverFillFor(root.bar.foreground, Color.accent) : "transparent"
          border.width: 1
          border.color: Qt.darker(root.bar.foreground, 1.4)

          Text {
            id: nextLabel
            anchors.centerIn: parent
            text: "Next reflection"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
          }

          MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.next()
          }
        }
      }
    }
  }
}
