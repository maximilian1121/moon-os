#!/bin/sh
#
# Build Moonlight for Raspberry Pi in an isolated Docker container.
#
# Uses QEMU binfmt + buildx to cross-compile for ARM.
# No host dependencies beyond Docker itself.
#
# Usage:
#   ./scripts/docker-build-rpi.sh                    # Build for arm64 (Pi 4/5)
#   ./scripts/docker-build-rpi.sh pi5                # Pi 5 (arm64)
#   ./scripts/docker-build-rpi.sh pi4                # Pi 4 (arm64, 64-bit OS)
#   ./scripts/docker-build-rpi.sh armhf              # Pi 4 (32-bit OS)
#   ./scripts/docker-build-rpi.sh arm64 --push       # Build + push to registry
#
# Output:
#   build/Moonlight-RPi-<version>-<arch>.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_ROOT="$SOURCE_ROOT/build"

PLATFORM="${1:-arm64}"
PUSH="${2:-}"

case "$PLATFORM" in
    arm64|aarch64|pi5|pi4)
        DOCKER_PLATFORM="linux/arm64"
        TAR_ARCH="arm64"
        ;;
    armhf|armv7l|arm/v7)
        DOCKER_PLATFORM="linux/arm/v7"
        TAR_ARCH="armhf"
        ;;
    *)
        echo "Usage: $0 [arm64|armhf|pi5|pi4]" >&2
        exit 1
        ;;
esac

echo "========================================"
echo " Moonlight Raspberry Pi Docker Builder"
echo " Platform:  $DOCKER_PLATFORM"
echo " Output:    $BUILD_ROOT/"
echo "========================================"

# ----- Check Docker ----------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker not found" >&2
    exit 1
fi

# ----- Set up QEMU binfmt for cross-arch builds -----------------------------
HOST_ARCH="$(uname -m)"
if [ "$HOST_ARCH" != "aarch64" ] && [ "$HOST_ARCH" != "armv7l" ]; then
    echo "Setting up QEMU binfmt for multi-arch..."
    docker run --privileged --rm tonistiigi/binfmt --install all 2>/dev/null || {
        # Fallback: check if buildx already handles it
        echo "Note: Continuing without QEMU setup (buildx may handle it)"
    }
fi

# ----- Create buildx builder if needed --------------------------------------
docker buildx inspect moonlight-builder >/dev/null 2>&1 || \
    docker buildx create --name moonlight-builder --driver docker-container --bootstrap

# ----- Build ----------------------------------------------------------------
VERSION="$(cat "$SOURCE_ROOT/app/version.txt")"
IMAGE_TAG="moonlight-rpi-builder:$VERSION-$TAR_ARCH"
TARBALL="$BUILD_ROOT/Moonlight-RPi-$VERSION-$TAR_ARCH.tar.gz"

mkdir -p "$BUILD_ROOT"

PUSH_FLAG=""
[ -n "$PUSH" ] && PUSH_FLAG="--push"

echo ""
echo "Building Moonlight $VERSION for $DOCKER_PLATFORM..."
echo ""

docker buildx build \
    --builder moonlight-builder \
    --platform "$DOCKER_PLATFORM" \
    --tag "$IMAGE_TAG" \
    --output "type=tar,dest=$BUILD_ROOT/_image.tar" \
    $PUSH_FLAG \
    -f "$SCRIPT_DIR/docker/Dockerfile.rpi" \
    "$SOURCE_ROOT" \
    || exit 1

# ----- Extract tarball from the image tar -----------------------------------
echo ""
echo "Extracting artifacts..."
mkdir -p "$BUILD_ROOT/_extract"
tar xf "$BUILD_ROOT/_image.tar" -C "$BUILD_ROOT/_extract" 2>/dev/null || true

# Collect the binary, service, autostart from the layers
mkdir -p "$BUILD_ROOT/_pkg/usr/bin" \
         "$BUILD_ROOT/_pkg/usr/lib/systemd/system" \
         "$BUILD_ROOT/_pkg/etc/xdg/autostart"

# Find and copy moonlight binary from layers
find "$BUILD_ROOT/_extract" -name "moonlight" -type f \
    -exec cp {} "$BUILD_ROOT/_pkg/usr/bin/" \; 2>/dev/null || true

# Find service and autostart files
find "$BUILD_ROOT/_extract" -name "moonlight-rpi.service" -type f \
    -exec cp {} "$BUILD_ROOT/_pkg/usr/lib/systemd/system/" \; 2>/dev/null || true
find "$BUILD_ROOT/_extract" -name "moonlight.desktop" -type f \
    -exec cp {} "$BUILD_ROOT/_pkg/etc/xdg/autostart/" \; 2>/dev/null || true

# Create tarball
tar czf "$TARBALL" -C "$BUILD_ROOT/_pkg" .

# Cleanup
rm -rf "$BUILD_ROOT/_extract" "$BUILD_ROOT/_pkg" "$BUILD_ROOT/_image.tar"

echo ""
echo "========================================"
echo " Build complete!"
echo "   Image:  $IMAGE_TAG"
echo "   Tarball: $TARBALL"
echo "   Size:    $(du -h "$TARBALL" | cut -f1)"
echo ""
echo " To deploy on your Pi:"
echo "   scp $TARBALL pi@raspberrypi:/tmp/"
echo "   ssh pi@raspberrypi 'sudo tar xzf /tmp/$(basename $TARBALL) -C / && sudo ldconfig'"
echo ""
echo " For kiosk boot (no desktop):"
echo "   ssh pi@raspberrypi 'sudo systemctl enable moonlight-rpi && sudo systemctl start moonlight-rpi'"
echo "========================================"
