#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────
#  Moonlight RPi Kiosk Installer
#  Run on a fresh Raspberry Pi OS Lite (Bookworm).
#  Builds Moonlight and configures it to auto-start.
# ─────────────────────────────────────────────────────────

ARCH="$(uname -m)"
case "$ARCH" in
    aarch64) PI_ARCH="arm64" ;;
    armv7l)  PI_ARCH="armhf" ;;
    *)
        echo "Unsupported architecture: $ARCH (expected aarch64 or armv7l)"
        exit 1
        ;;
esac

echo "========================================="
echo " Moonlight RPi Kiosk Installer"
echo " Arch: $PI_ARCH"
echo "========================================="
echo ""

# ── Install build deps ──────────────────────────────────
echo "Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential pkg-config \
    qt6-base-dev qt6-declarative-dev libqt6svg6-dev \
    qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-templates qml6-module-qtqml-workerscript \
    qml6-module-qtquick-window \
    libegl1-mesa-dev libgl1-mesa-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libsdl2-dev libsdl2-ttf-dev \
    libopus-dev libssl-dev \
    libdrm-dev libxkbcommon-dev \
    ca-certificates curl git 2>/dev/null

# ── Build Moonlight ─────────────────────────────────────
echo "Building Moonlight..."
git submodule update --init --recursive
mkdir -p build && cd build
qmake6 .. \
    CONFIG+=embedded \
    CONFIG+=gpuslow \
    CONFIG+=disable-wayland \
    CONFIG+=disable-libva \
    CONFIG+=disable-libvdpau \
    QMAKE_CFLAGS_ISYSTEM=
make -j"$(nproc)" release
cd ..

# ── Install Moonlight binary ────────────────────────────
echo "Installing Moonlight..."
sudo cp build/app/moonlight /usr/local/bin/

# ── Build kiosk shell ──────────────────────────────────
echo "Building kiosk shell..."
sudo apt-get install -y -qq qt6-quickcontrols2-6.5-dev \
    qml6-module-qtquick-controls2 2>/dev/null || true

mkdir -p build-kiosk && cd build-kiosk
qmake6 ../kiosk-shell CONFIG+=embedded QMAKE_CFLAGS_ISYSTEM=
make -j"$(nproc)" release
cd ..

echo "Installing kiosk shell..."
sudo cp build-kiosk/moonlight-kiosk /usr/local/bin/
sudo cp app/deploy/linux/rpi/moonlight-kiosk-launcher.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/moonlight-kiosk-launcher.sh

# ── Install systemd service (kiosk) ─────────────────────
echo "Installing kiosk service..."

sudo tee /etc/systemd/system/moonlight-rpi.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=Moonlight Kiosk (Raspberry Pi)
After=network.target multi-user.target

[Service]
Type=simple
User=pi
Group=pi
Environment=HOME=/home/pi
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_ALWAYS_SET_MODE=1
Environment=QT_QPA_EGLFS_FORCEVSYNC=1
Environment=SDL_VIDEODRIVER=kmsdrm
Environment=SDL_HINT_KMSDRM_REQUIRE_DRM_MASTER=0
Environment=DISPLAY=
ExecStartPre=/bin/sh -c 'while ! [ -c /dev/dri/card0 ]; do sleep 1; done'
ExecStart=/usr/local/bin/moonlight-kiosk-launcher.sh
Restart=on-failure
RestartSec=5
Nice=-10

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload

# ── Configure boot ──────────────────────────────────────
echo "Configuring boot settings..."
CONFIG_TXT=""
for f in /boot/firmware/config.txt /boot/config.txt; do
    [ -f "$f" ] && CONFIG_TXT="$f" && break
done

if [ -n "$CONFIG_TXT" ]; then
    sudo sed -i 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-fkms-v3d/g' "$CONFIG_TXT" 2>/dev/null || true

    # rpivid is Pi 5 only
    if [ "$PI_ARCH" = "arm64" ] && [ "$(grep -c 'BCM2712' /proc/cpuinfo 2>/dev/null)" -gt 0 ]; then
        if ! grep -q "rpivid-v4l2" "$CONFIG_TXT" 2>/dev/null; then
            echo "" | sudo tee -a "$CONFIG_TXT" > /dev/null
            echo "# Enable rpivid HEVC decoder for Moonlight" | sudo tee -a "$CONFIG_TXT" > /dev/null
            echo "dtoverlay=rpivid-v4l2" | sudo tee -a "$CONFIG_TXT" > /dev/null
        fi
    fi

    if grep -q "^gpu_mem=" "$CONFIG_TXT" 2>/dev/null; then
        sudo sed -i 's/^gpu_mem=.*/gpu_mem=256/' "$CONFIG_TXT"
    else
        echo "gpu_mem=256" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
fi

# ── Enable kiosk ────────────────────────────────────────
echo "Enabling kiosk mode..."
sudo rm -f /etc/systemd/system/display-manager.service 2>/dev/null || true
sudo systemctl disable lightdm gdm gdm3 2>/dev/null || true
sudo systemctl enable moonlight-rpi
sudo systemctl set-default multi-user.target 2>/dev/null || true

# ── Enable SSH (headless access) ────────────────────────
sudo systemctl enable ssh 2>/dev/null || true

echo ""
echo "========================================="
echo " Done!"
echo ""
echo " Moonlight is installed and will start"
echo " automatically on next boot."
echo ""
echo " Reboot now:"
echo "   sudo reboot"
echo "========================================="
