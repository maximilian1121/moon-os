#!/bin/bash
set -e

echo "========================================="
echo " Moonlight RPi Kiosk Uninstaller"
echo "========================================="
echo ""

# ── Stop and remove service ────────────────────────────
if systemctl is-enabled moonlight-rpi &>/dev/null; then
    echo "Stopping and disabling moonlight-rpi service..."
    sudo systemctl stop moonlight-rpi 2>/dev/null || true
    sudo systemctl disable moonlight-rpi 2>/dev/null || true
fi

if [ -f /etc/systemd/system/moonlight-rpi.service ]; then
    sudo rm /etc/systemd/system/moonlight-rpi.service
    sudo systemctl daemon-reload
fi

# ── Remove binaries ────────────────────────────────────
for bin in moonlight moonlight-kiosk moonlight-kiosk-launcher.sh; do
    if [ -f "/usr/local/bin/$bin" ]; then
        echo "Removing /usr/local/bin/$bin..."
        sudo rm "/usr/local/bin/$bin"
    fi
done

# ── Restore display manager (re-enable desktop) ───────
echo "Restoring desktop environment..."
for dm in lightdm gdm gdm3 sddm; do
    sudo systemctl enable "$dm" 2>/dev/null || true
done
sudo systemctl set-default graphical.target 2>/dev/null || true

# ── Revert config.txt (if we changed it) ────────────────
CONFIG_TXT=""
for f in /boot/firmware/config.txt /boot/config.txt; do
    [ -f "$f" ] && CONFIG_TXT="$f" && break
done

if [ -n "$CONFIG_TXT" ]; then
    echo "Reverting display driver in $CONFIG_TXT..."
    # Switch FKMS back to KMS
    sudo sed -i 's/dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-kms-v3d/g' "$CONFIG_TXT" 2>/dev/null || true
    # Remove rpivid overlay  
    sudo sed -i '/dtoverlay=rpivid-v4l2/d' "$CONFIG_TXT" 2>/dev/null || true
    # Remove the comment above rpivid
    sudo sed -i '/# Enable rpivid HEVC decoder for Moonlight/d' "$CONFIG_TXT" 2>/dev/null || true
    # Reset gpu_mem to default
    sudo sed -i 's/^gpu_mem=256/gpu_mem=64/' "$CONFIG_TXT" 2>/dev/null || true
fi

# ── Remove first-boot flag ─────────────────────────────
sudo rm -f /etc/moonlight-firstboot-done 2>/dev/null || true
sudo rm -f /usr/lib/moonlight-firstboot.sh 2>/dev/null || true
sudo rm -f /etc/systemd/system/moonlight-firstboot.service 2>/dev/null || true

echo ""
echo "========================================="
echo " Moonlight has been removed."
echo ""
echo " Reboot to restore the desktop:"
echo "   sudo reboot"
echo "========================================="
