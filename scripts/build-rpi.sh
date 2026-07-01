#!/bin/sh
#
# Raspberry Pi build script for Moonlight Qt
#
# ╔══════════════════════════════════════════════════════════════╗
# ║  Prefer the Docker build for isolation & cross-compilation: ║
# ║    ./scripts/docker-build-rpi.sh [arm64|armhf]              ║
# ║                                                              ║
# ║  This script is for native builds directly on your Pi       ║
# ║  (when you don't have Docker or want to build in-place).    ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./scripts/build-rpi.sh              # Build natively on Pi
#   ./scripts/build-rpi.sh --install    # Build and install system-wide
#   ./scripts/build-rpi.sh --kiosk      # Build + install + enable kiosk service

set -e

BUILD_CONFIG="release"
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="$SOURCE_ROOT/build"
BUILD_FOLDER="$BUILD_ROOT/build-rpi-$BUILD_CONFIG"
DEPLOY_FOLDER="$BUILD_ROOT/deploy-rpi-$BUILD_CONFIG"

# ----- Safety checks ---------------------------------------------------------
# Protect against rm -rf disasters: verify paths contain our project name.
_safe_rmrf() {
    _path="$1"
    case "$_path" in
        */moonlight-qt/build/*|*/build-rpi-*)
            rm -rf "$_path"
            ;;
        *)
            echo "ERROR: Refusing to delete '$1' - path looks unsafe!" >&2
            exit 1
            ;;
    esac
}

# Also guard the top-level build directory deletion
_safe_rmrf "$BUILD_FOLDER"
_safe_rmrf "$DEPLOY_FOLDER"

mkdir -p "$BUILD_ROOT" "$BUILD_FOLDER" "$DEPLOY_FOLDER"

# ----- Detect architecture ---------------------------------------------------
ARCH="$(uname -m)"
case "$ARCH" in
    aarch64)  PI_ARCH="arm64" ;;
    armv7l|armhf) PI_ARCH="armhf" ;;
    *)
        echo "WARNING: Unrecognized architecture '$ARCH' - proceeding anyway"
        PI_ARCH="$ARCH"
        ;;
esac
echo "Detected architecture: $ARCH ($PI_ARCH)"

# ----- Dependency check / install hint ---------------------------------------
MISSING=""
for pkg in qmake6 libegl1-mesa-dev libopus-dev libsdl2-dev \
           libsdl2-ttf-dev libssl-dev libavcodec-dev libavformat-dev \
           libswscale-dev libdrm-dev libxkbcommon-dev qt6-base-dev \
           qt6-declarative-dev libqt6svg6-dev qml6-module-qtquick-controls \
           qml6-module-qtquick-layouts qml6-module-qtqml-workerscript; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        MISSING="$MISSING $pkg"
    fi
done
if [ -n "$MISSING" ]; then
    echo ""
    echo "Missing packages:$MISSING"
    echo "Install them with:"
    echo "  sudo apt install$MISSING"
    echo ""
    read -p "Attempt to install now? [Y/n] " CONFIRM
    if [ "$CONFIRM" != "n" ] && [ "$CONFIRM" != "N" ]; then
        sudo apt update
        sudo apt install -y $MISSING
    fi
fi

# ----- Check for qmake6 ------------------------------------------------------
QMAKE=""
for cmd in qmake6 qmake; do
    if command -v "$cmd" >/dev/null 2>&1; then
        QMAKE="$cmd"
        break
    fi
done
if [ -z "$QMAKE" ]; then
    echo "ERROR: qmake/qmake6 not found in PATH" >&2
    exit 1
fi

echo "Using qmake: $QMAKE"

# ----- Submodules ------------------------------------------------------------
if [ -d "$SOURCE_ROOT/.git" ]; then
    echo "Updating submodules..."
    git -C "$SOURCE_ROOT" submodule update --init --recursive
fi

# ----- Configure qmake -------------------------------------------------------
echo "Configuring the project..."
EXTRA_CONF=""

# Embedded build: strips windowed mode, Discord links, etc.
EXTRA_CONF="$EXTRA_CONF CONFIG+=embedded"

# GPU slow: prefer KMSDRM over GL/Vulkan - important for Pi's VideoCore GPU
EXTRA_CONF="$EXTRA_CONF CONFIG+=gpuslow"

# Disable Wayland on RPi (no compositor in kiosk / lightweight desktop)
EXTRA_CONF="$EXTRA_CONF CONFIG+=disable-wayland"

# Disable libva/vdpau - not available on RPi
EXTRA_CONF="$EXTRA_CONF CONFIG+=disable-libva CONFIG+=disable-libvdpau"

PREFIX_ARG="PREFIX=$DEPLOY_FOLDER/usr"

$QMAKE "$SOURCE_ROOT/moonlight-qt.pro" \
    $EXTRA_CONF \
    $PREFIX_ARG \
    QMAKE_CFLAGS_ISYSTEM= \
    || exit 1

# ----- Build ----------------------------------------------------------------
echo "Compiling Moonlight ($BUILD_CONFIG)..."
make -j"$(nproc)" "$(echo "$BUILD_CONFIG" | tr '[:upper:]' '[:lower:]')" || exit 1

# ----- Create deploy tarball ------------------------------------------------
echo "Creating deployment bundle..."
make install INSTALL_ROOT="$DEPLOY_FOLDER" || true

mkdir -p "$DEPLOY_FOLDER/usr/bin"
cp "$BUILD_FOLDER/app/moonlight" "$DEPLOY_FOLDER/usr/bin/"

# Copy service and autostart files
mkdir -p "$DEPLOY_FOLDER/usr/lib/systemd/system"
cp "$SOURCE_ROOT/app/deploy/linux/rpi/moonlight-rpi.service" \
   "$DEPLOY_FOLDER/usr/lib/systemd/system/" 2>/dev/null || true

mkdir -p "$DEPLOY_FOLDER/etc/xdg/autostart"
cp "$SOURCE_ROOT/app/deploy/linux/rpi/autostart/moonlight.desktop" \
   "$DEPLOY_FOLDER/etc/xdg/autostart/" 2>/dev/null || true

VERSION="$(cat "$SOURCE_ROOT/app/version.txt")"
TARBALL="$BUILD_ROOT/Moonlight-RPi-$VERSION-$PI_ARCH.tar.gz"
tar czf "$TARBALL" -C "$DEPLOY_FOLDER" .

echo ""
echo "========================================="
echo " Build complete!"
echo "   Binary:  $DEPLOY_FOLDER/usr/bin/moonlight"
echo "   Tarball: $TARBALL"
echo ""
echo " To install system-wide:"
echo "   sudo tar xzf $TARBALL -C /"
echo "   sudo systemctl enable moonlight-rpi"
echo "========================================="

# ----- Optional: system-wide install ----------------------------------------
if [ "$1" = "--install" ] || [ "$1" = "--kiosk" ]; then
    echo "Installing system-wide..."
    sudo tar xzf "$TARBALL" -C /
    sudo ldconfig
fi

# ----- Optional: enable kiosk service ---------------------------------------
if [ "$1" = "--kiosk" ]; then
    echo "Enabling kiosk service (boots directly into Moonlight)..."
    sudo systemctl enable moonlight-rpi
    sudo systemctl daemon-reload
    echo ""
    echo "Kiosk mode enabled! Moonlight will start on next boot."
    echo "Run 'sudo systemctl start moonlight-rpi' to start now."
fi
