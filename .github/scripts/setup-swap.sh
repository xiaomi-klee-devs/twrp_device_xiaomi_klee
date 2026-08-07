#!/usr/bin/env bash
set -euo pipefail

SWAPFILE=/swapfile
SWAPSIZE=8G   # غيّر الحجم حسب الحاجة (مثلاً 8G، 12G، ...)

if sudo swapon --show=NAME | awk '{print $1}' | grep -qx "$SWAPFILE"; then
  echo "Swap already active at $SWAPFILE — skipping creation."
  exit 0
fi

if [ -f "$SWAPFILE" ]; then
  echo "$SWAPFILE exists but not active — attempting to recreate."
  sudo swapoff "$SWAPFILE" || true
  sudo rm -f "$SWAPFILE"
fi

echo "Creating swapfile $SWAPFILE size $SWAPSIZE"

if ! sudo fallocate -l "$SWAPSIZE" "$SWAPFILE" 2>/dev/null; then
  echo "fallocate failed — falling back to dd (slower)..."
  if [[ "$SWAPSIZE" =~ ^([0-9]+)G$ ]]; then
    MB=$(( ${BASH_REMATCH[1]} * 1024 ))
    sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count="$MB" status=progress
  else
    echo "Unsupported SWAPSIZE format: $SWAPSIZE"
    exit 1
  fi
fi

sudo chmod 600 "$SWAPFILE"
sudo mkswap "$SWAPFILE"
sudo swapon "$SWAPFILE"
echo "Swap enabled:"
sudo swapon --show
free -h
