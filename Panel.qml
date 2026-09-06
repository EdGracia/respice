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

  property var quotes: [
    "Memento mori.",
    "You have power over your mind, not outside events.",
    "Waste no more time arguing what a good man should be. Be one.",
    "The obstacle is the way."
  ]
  property int index: 0

  function next() {
    root.index = (root.index + 1) % root.quotes.length
  }

  readonly property int maxReflectionWords: 20
  property bool addingReflection: false

  // Editor closes with the panel so it never reopens on stale text.
  onOpenedChanged: if (!opened) cancelReflection()

  function wordCount(text) {
    var trimmed = String(text).trim()
    return trimmed === "" ? 0 : trimmed.split(/\s+/).length
  }

  function limitWords(text, maxWords) {
    var words = String(text).trim().split(/\s+/)
    return words.length <= maxWords ? text : words.slice(0, maxWords).join(" ")
  }

  function toggleAddReflection() {
    if (root.addingReflection) cancelReflection()
    else {
      root.addingReflection = true
      Qt.callLater(function() { reflectionField.forceActiveFocus() })
    }
  }

  function cancelReflection() {
    root.addingReflection = false
    reflectionField.text = ""
  }

  function submitReflection() {
    var text = reflectionField.text.trim()
    if (text === "") return
    root.quotes = root.quotes.concat([text])
    root.index = root.quotes.length - 1
    cancelReflection()
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
      blocked: root.addingReflection
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

        Row {
          spacing: Style.space(10)

          Button {
            text: "Next reflection"
            bordered: true
            foreground: root.bar.foreground
            onClicked: root.next()
          }

          Button {
            text: root.addingReflection ? "Cancel" : "Add reflection"
            bordered: true
            foreground: root.bar.foreground
            onClicked: root.toggleAddReflection()
          }
        }

        Column {
          visible: root.addingReflection
          width: parent.width
          spacing: Style.space(10)

          TextField {
            id: reflectionField
            width: quoteColumn.width - Style.space(48)
            placeholderText: "Type a short reflection…"
            foreground: root.bar.foreground
            onTextChanged: {
              var limited = root.limitWords(text, root.maxReflectionWords)
              if (limited !== text) text = limited
            }
            onAccepted: root.submitReflection()
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.cancelReflection()
                event.accepted = true
              }
            }
          }

          Row {
            spacing: Style.space(10)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.wordCount(reflectionField.text) + " / " + root.maxReflectionWords + " words"
              color: Qt.darker(root.bar.foreground, 1.5)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Button {
              text: "Save"
              bordered: true
              foreground: root.bar.foreground
              onClicked: root.submitReflection()
            }
          }
        }
      }
    }
  }
}
