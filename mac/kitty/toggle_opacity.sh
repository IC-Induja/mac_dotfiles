#!/bin/bash
exec >> /tmp/kitty-opacity-debug.log 2>&1
echo "--- $(date) ---"
echo "KITTY_LISTEN_ON=$KITTY_LISTEN_ON"
echo "KITTY_PID=$KITTY_PID"

TOGGLE_FILE="/tmp/kitty-opacity-${KITTY_PID:-default}"
if [ -f "$TOGGLE_FILE" ]; then
    rm "$TOGGLE_FILE"
    kitty @ set-background-opacity 1.0
    echo "Set to 1.0, exit=$?"
else
    touch "$TOGGLE_FILE"
    kitty @ set-background-opacity 0.75
    echo "Set to 0.75, exit=$?"
fi
