# imac-fan

Quiet the runaway fan on an Apple iMac running Linux — a "Macs Fan Control"
replacement, with an optional [Omarchy](https://omarchy.org) bar widget.

> **Status: v0.1.0, early.** Working and in daily use on one machine
> (`iMac12,2`). Other models should work but are untested — see
> [Compatibility](#compatibility).

## The problem

The 2010–2011 iMacs have three fans: `ODD`, `HDD`, `CPU`. When the original
Apple hard drive is replaced with a third-party SSD, the SMC loses that drive's
temperature signal and pins the **HDD fan at its maximum RPM** — permanently,
no matter how cool the machine is. macOS users reach for *Macs Fan Control*.
On Linux there was no tidy answer; this is one.

`imac-fan` is a small root daemon that takes **only that one fan** onto a quiet,
temperature-aware curve (regulating on the hotter of CPU package and GPU
diode). The `CPU` and `ODD` fans stay under the firmware's control. A CLI and
an Omarchy bar widget switch modes without root.

```
quiet   hold at the fan's minimum
auto    follow the curve (default) — silent when cool, ramps if the machine heats up
max     full speed
off     hand the fan back to the firmware
```

## Install

### Daemon (required)

```bash
git clone https://github.com/mudiam/imac-fan
cd imac-fan
sudo daemon/install.sh
imac-fan status
```

Needs Python 3 (stdlib only), systemd, and the `applesmc` module (loaded
automatically on Apple hardware). No other dependencies.

### Omarchy bar widget (optional)

```bash
omarchy plugin add https://github.com/mudiam/imac-fan --enable
sudo ~/.config/omarchy/plugins/imac-fan/daemon/install.sh
```

`omarchy plugin add` clones the repo to `~/.config/omarchy/plugins/imac-fan/`
and drops the widget on the bar; the second line installs the daemon it talks
to.

![the fan widget on the Omarchy bar](docs/widget.png)

The widget shows the fan RPM; **left** cycles quiet/auto/max, **right**
forces full speed, **middle** sends a status notification. It turns to a
fan-alert glyph if the fan is pinned near max with no daemon running.

## Use

```
imac-fan status        # RPM, mode, regulating temperature
imac-fan quiet|auto|max|off
imac-fan set 1600      # fixed custom RPM
imac-fan cycle         # quiet -> auto -> max -> quiet
```

## Configure

`/etc/imac-fan/config`, then `sudo systemctl restart imac-fan`:

| key | default | meaning |
|---|---|---|
| `FAN` | `2` | applesmc fan to control (`2` = `HDD` on the 27" 2011) |
| `QUIET_RPM` | `1100` | RPM for `quiet` mode (this fan's firmware minimum) |
| `CURVE` | `55:1100 68:1900 78:3200 85:4800` | `degC:RPM` points for `auto`, linearly interpolated |
| `CRITICAL_TEMP` | `92` | force max RPM at/above this, in any mode |
| `RESTORE_ON_EXIT` | `1` | hand the fan back to firmware when the daemon stops |
| `DEFAULT_MODE` | `auto` | mode before the CLI/widget has set one |

**Which fan is yours?** `sensors | grep -i fan` or
`for f in /sys/devices/platform/applesmc.*/fan?_label; do echo "$f $(cat $f)"; done`.
Pick the one that is stuck near its max; set `FAN` to its number.

## Privilege model

Only the daemon writes to `/sys` (that needs root); systemd starts it at boot.
The CLI and widget write one keyword to `/var/lib/imac-fan/mode`, which the
daemon polls and **sanitises** — it reduces any content to
`quiet|auto|max|off|fixed:<int>` and clamps the RPM to the fan's own limits, so
a bogus or hostile value can do nothing worse than select the `auto` curve.
That file is `root:wheel`, group-writable, so switching modes needs no
password. If `wheel` doesn't exist the daemon falls back to world-writable.

## Compatibility

Tested on a mid-2011 27" iMac (`iMac12,2`, Intel HD 3000 + Radeon HD 6970M).
Should work on any Mac the `applesmc` driver supports; `FAN` and `CURVE` are
the only model-specific settings. Not for Apple Silicon.

Running it on another model? Please [open an
issue](https://github.com/mudiam/imac-fan/issues/new) with your Mac model and
the output of `sensors` and
`for f in /sys/devices/platform/applesmc.*/fan?_label; do echo "$f $(cat $f)"; done`
— it helps build a known-good `FAN`/`CURVE` table.

## Prior art

[`mbpfan`](https://github.com/linux-on-mac/mbpfan) and
[`macfanctld`](https://launchpad.net/macfanctld) are general Apple fan daemons.
`imac-fan` is narrower on purpose: it fixes the one SSD-swap failure mode,
leaves the firmware in charge of everything else, and integrates with the
Omarchy bar.

## Uninstall

```bash
sudo daemon/uninstall.sh
omarchy plugin remove imac-fan     # if the widget was installed
```

## License

MIT
