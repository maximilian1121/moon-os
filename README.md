# Moonlight RPi Kiosk

Stripped-down Moonlight Qt for Raspberry Pi 4/5. Boots straight into Moonlight — no desktop, no login.

## Install on a fresh Raspberry Pi OS Lite

```sh
sudo apt update && sudo apt install -y git
git clone https://github.com/your-fork/moonlight-qt
cd moonlight-qt
./install.sh
sudo reboot
```

That's it. The script installs build deps, compiles Moonlight with optimal Pi settings (`embedded` + `gpuslow` + FKMS), sets up a systemd kiosk service that starts at boot, and configures `config.txt`.

## Build on another machine (Docker)

```sh
./scripts/docker-build-rpi.sh arm64
```

Outputs a tarball you can `scp` to the Pi and extract to `/`.
