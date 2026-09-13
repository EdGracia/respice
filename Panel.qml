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

  // Quote state lives on hostWidget (BarWidget.qml), not here, so the
  // reminder timer and this panel share one pool. See BarWidget.qml.
  function next() {
    if (root.hostWidget) root.hostWidget.next()
  }

  readonly property int maxReflectionWords: 30
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
    if (root.hostWidget) root.hostWidget.addReflection(text)
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
          text: root.hostWidget ? root.hostWidget.quotes[root.hostWidget.index] : ""
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

        // A hand-rolled compact switch rather than the shared `Toggle`: this
        // theme's [controls] tokens pin both normal-color and selected-color
        // to the same literal hex (differing only by alpha), so the shared
        // component's `accent` prop has no way to force a distinct on-color.
        // Off keeps the real Style.normal* helpers (matches every other
        // theme's default look); on is a hardcoded green so the state reads
        // unambiguously regardless of theme.
        Item {
          width: quoteColumn.width - Style.space(48)
          height: reminderRow.implicitHeight

          Row {
            id: reminderRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(8)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Random Reminders"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            Rectangle {
              id: reminderTrack
              readonly property bool on: root.hostWidget ? root.hostWidget.reminderEnabled : true
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(30)
              height: Style.space(16)
              radius: height / 2
              color: on ? "#2ecc71" : Style.normalFillFor(root.bar.foreground, Color.accent)
              border.width: on ? 0 : Style.normalBorderWidth
              border.color: Style.normalBorderFor(root.bar.foreground, Color.accent)

              Rectangle {
                width: parent.height - Style.space(4)
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: reminderTrack.on ? parent.width - width - Style.space(2) : Style.space(2)
                color: reminderTrack.on ? "white" : Qt.darker(root.bar.foreground, 1.25)
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.hostWidget) root.hostWidget.setReminderEnabled(!reminderTrack.on)
              }
            }
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
