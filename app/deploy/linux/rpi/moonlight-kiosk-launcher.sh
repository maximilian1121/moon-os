#!/bin/bash
# Moonlight Kiosk Launcher Wrapper
# Handles handoff between kiosk shell and Moonlight streaming
# The kiosk exits with code 0 to signal "launch Moonlight now"

set -e

while true; do
    /usr/local/bin/moonlight-kiosk "$@"
    case $? in
        0)
            # Launch Moonlight (takes over EGLFS)
            /usr/local/bin/moonlight
            ;;
        1)
            # Clean exit
            exit 0
            ;;
        *)
            # Crash - restart kiosk
            sleep 2
            ;;
    esac
done
