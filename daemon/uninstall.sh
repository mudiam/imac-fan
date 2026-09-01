#!/usr/bin/env bash
# Remove the imac-fan daemon. Run with sudo.  Leaves nothing behind except a
# fan handed back to the firmware.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "run as root: sudo $0" >&2
  exit 1
fi

systemctl disable --now imac-fan.service 2>/dev/null || true
rm -f /usr/local/bin/imac-fan \
      /etc/systemd/system/imac-fan.service \
      /usr/lib/tmpfiles.d/imac-fan.conf
rm -rf /etc/imac-fan /var/lib/imac-fan
systemctl daemon-reload

echo "removed. The bar widget, if installed, is separate:"
echo "  omarchy plugin remove imac-fan"
