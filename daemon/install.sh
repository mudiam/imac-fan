#!/usr/bin/env bash
# Install the imac-fan daemon, service and config. Run with sudo.
#   sudo daemon/install.sh
# The Omarchy bar widget (manifest.json + BarWidget.qml at the repo root) is a
# per-user file installed separately with `omarchy plugin add` — see ../README.md.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

cd "$(cd "$(dirname "$0")" && pwd)"

echo "==> /usr/local/bin/imac-fan"
install -Dm755 imac-fan /usr/local/bin/imac-fan

echo "==> /usr/lib/tmpfiles.d/imac-fan.conf"
install -Dm644 imac-fan.tmpfiles.conf /usr/lib/tmpfiles.d/imac-fan.conf

echo "==> /etc/systemd/system/imac-fan.service"
install -Dm644 imac-fan.service /etc/systemd/system/imac-fan.service

if [[ -e /etc/imac-fan/config ]]; then
  echo "==> /etc/imac-fan/config exists — leaving it; new copy at config.new"
  install -Dm644 imac-fan.conf /etc/imac-fan/config.new
else
  echo "==> /etc/imac-fan/config"
  install -Dm644 imac-fan.conf /etc/imac-fan/config
fi

echo "==> systemd-tmpfiles"
systemd-tmpfiles --create /usr/lib/tmpfiles.d/imac-fan.conf

echo "==> enable + (re)start"
systemctl daemon-reload
systemctl enable imac-fan.service
systemctl restart imac-fan.service

echo
systemctl --no-pager --full status imac-fan.service | sed -n '1,8p' || true
echo
echo "done.  imac-fan status"
