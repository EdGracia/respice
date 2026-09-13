import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "respice"

  // Shared quote state: BarWidget is the long-lived root (Panel.qml is
  // recreated by the Loader), and the reminder timer below needs a quote
  // pool even while the panel is closed. Panel.qml reaches back in via its
  // injected `hostWidget` rather than owning its own copy, so "Next
  // reflection" clicks and added reflections are visible to the timer too.
  //
  // The four defaults below seed reflectionsFile the first time it's
  // created (see onLoadFailed) — after that, the file *is* the pool.
  // Deliberately not re-merged back in on every load: that would silently
  // undo a user deleting one, which is the whole point of putting them in
  // an editable file instead of leaving them hardcoded and permanent.
  readonly property var defaultReflections: [
    "Memento mori.",
    "You have power over your mind, not outside events.",
    "Waste no more time arguing what a good man should be. Be one.",
    "The obstacle is the way."
  ]

  property var reflections: []
  property int index: 0

  function next() {
    if (root.reflections.length === 0) return
    root.index = (root.index + 1) % root.reflections.length
  }

  function addReflection(text) {
    root.reflections = root.reflections.concat([text])
    root.index = root.reflections.length - 1
    root.saveReflections()
  }

  // Returns null (not []) for invalid/missing content, distinct from a
  // valid empty array — the caller needs to tell "user emptied it on
  // purpose" apart from "file is corrupt or unreadable".
  function parseReflections(raw) {
    try {
      var data = JSON.parse(raw)
      return Array.isArray(data) ? data.filter(function(item) {
        return typeof item === "string" && item.trim() !== ""
      }) : null
    } catch (e) {
      return null
    }
  }

  function saveReflections() {
    reflectionsFile.setText(JSON.stringify(root.reflections, null, 2) + "\n")
  }

  // Namespaced under a per-plugin subdirectory (like the built-in shell's
  // own `indicators/`, `notifications/`) rather than flat under the
  // omarchy state root — two respice-* files at the top level starts to
  // clutter a directory other plugins share. FileView.setText() creates
  // missing parent directories on write (QDir::mkpath), so this subdir
  // needs no separate setup step.
  FileView {
    id: reflectionsFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/respice/reflections.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      var parsed = root.parseReflections(text())
      root.reflections = parsed !== null ? parsed : root.defaultReflections
      if (root.index >= root.reflections.length) root.index = 0
    }
    // File doesn't exist yet — first run, or a user deleted it. Seed it
    // with the defaults so there's something in the pool *and* something
    // on disk to hand-edit right away, rather than defaults living only
    // in memory until the first "Add reflection".
    onLoadFailed: {
      root.reflections = root.defaultReflections
      root.saveReflections()
    }
    onFileChanged: reload()
  }

  // Random-interval reminders, echoing the Roman practice of a servant
  // periodically whispering memento mori to a general in triumph. No
  // active-hours restriction yet — planned for a future settings UI.
  readonly property int minReminderMs: 1 * 60 * 60 * 1000
  readonly property int maxReminderMs: 5 * 60 * 60 * 1000

  // Panel toggle to turn the periodic notification off entirely. Persisted
  // the same way as reflections (own FileView, same load/save shape, same
  // respice/ subdirectory) so the setting survives a shell restart.
  property bool reminderEnabled: true

  function setReminderEnabled(enabled) {
    root.reminderEnabled = enabled
    root.saveSettings()
  }

  function parseSettings(raw) {
    try {
      var data = JSON.parse(raw)
      return (data && typeof data.reminderEnabled === "boolean") ? data.reminderEnabled : true
    } catch (e) {
      return true
    }
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({ reminderEnabled: root.reminderEnabled }, null, 2) + "\n")
  }

  FileView {
    id: settingsFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/respice/settings.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.reminderEnabled = root.parseSettings(text())
    onLoadFailed: root.reminderEnabled = true
    onFileChanged: reload()
  }

  function randomReminderInterval() {
    return minReminderMs + Math.floor(Math.random() * (maxReminderMs - minReminderMs))
  }

  // Fires through the built-in Omarchy notification popup rather than a
  // custom panel, per the plugin's design: the timer lives here, but the
  // actual reminder UI is the shell's own notification system.
  function sendReminder() {
    if (root.reflections.length === 0) return
    var quote = root.reflections[Math.floor(Math.random() * root.reflections.length)]
    Quickshell.execDetached(["omarchy-notification-send", "-g", "🧔🏼", "Respice", quote])
  }

  // `repeat: true` (rather than a one-shot restarted from onTriggered) so
  // `running` can stay bound to `reminderEnabled` — toggling the panel
  // switch just pauses/resumes the countdown via the binding. An explicit
  // start()/stop() call would sever that binding, since assigning `running`
  // imperatively anywhere overrides it for good.
  Timer {
    id: reminderTimer
    running: root.reminderEnabled
    repeat: true
    interval: root.randomReminderInterval()
    onTriggered: {
      root.sendReminder()
      interval = root.randomReminderInterval()
    }
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  // Shape contract for shell.summon/hide/toggle routing (Bar.findPanelWidget
  // requires open/close/opened on the bar-widget root, not the nested panel).
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "🏛️"
    tooltipText: "Respice"
    onPressed: function(b) {
      root.toggle()
    }
  }
}
