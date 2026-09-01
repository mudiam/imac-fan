import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// iMac fan widget.
//
//   label   = fan glyph + current RPM  (glyph only on a vertical bar)
//   colour  = urgent when the fan is at max, or pinned near max with no daemon
//   left    = cycle mode   quiet -> auto -> max -> quiet
//   right   = force full speed
//   middle  = desktop notification with the full status
//
// All state comes from `imac-fan json`; mode changes go through `imac-fan`,
// which writes the group-writable mode file and pokes the daemon.
BarWidget {
  id: root
  moduleName: "imac-fan"

  property string mode: "auto"
  property int rpm: -1
  property real temp: 0
  property bool pinned: false
  property bool haveData: false

  readonly property string fanGlyph: "󰈐"     // nf-md-fan        U+F0210
  readonly property string alertGlyph: "󱑬"   // nf-md-fan_alert  U+F146C

  readonly property string glyph: pinned ? alertGlyph : fanGlyph
  readonly property string labelText: {
    if (!haveData)
      return glyph
    if (root.vertical)
      return glyph
    return rpm >= 0 ? glyph + "  " + rpm : glyph + "  " + mode
  }

  function refresh() {
    if (!stateProc.running)
      stateProc.running = true
  }

  function apply(raw) {
    try {
      var d = JSON.parse(raw)
      root.mode = String(d.mode || "auto")
      root.rpm = (d.rpm === null || d.rpm === undefined) ? -1 : Number(d.rpm)
      root.temp = Number(d.temp || 0)
      root.pinned = d.pinned === true
      root.haveData = true
    } catch (e) {
      // leave the last-known values in place
    }
  }

  function act(verb) {
    if (root.bar)
      root.bar.run("imac-fan " + verb)
    soon.restart()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  IpcHandler {
    target: "imac-fan"
    function refresh(): void { root.broadcast("refresh") }
  }

  Process {
    id: stateProc
    command: ["imac-fan", "json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.apply(text)
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // A quick re-poll right after a click so the label reflects the new mode.
  Timer {
    id: soon
    interval: 700
    repeat: false
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.labelText
    fontSize: Style.font.caption
    active: root.pinned || root.mode === "max"
    tooltipText: {
      var t = "iMac fan"
      if (root.haveData) {
        t = (root.rpm >= 0 ? root.rpm + " RPM" : "unknown RPM") + "  ·  mode: " + root.mode
          + "\nregulating temp: " + Math.round(root.temp) + " °C"
        if (root.pinned)
          t += "\n⚠ pinned near max — is imac-fan.service running?"
      }
      t += "\n\nleft: cycle mode   right: full speed   middle: notify"
      return t
    }

    onPressed: function(b) {
      if (b === Qt.RightButton)
        root.act("max")
      else if (b === Qt.MiddleButton)
        root.act("notify")
      else
        root.act("cycle")
    }
  }
}
