#!/bin/bash

# Function to check if a display is busy
is_display_busy() {
    local display_num=$1
    # Check for X server lock file
    if [ -f "/tmp/.X${display_num}-lock" ]; then
        return 0 # Busy
    fi
    # Check if a display server is running on that display
    # by trying to open it. If it fails, it's likely busy.
    # We use a timeout to prevent hanging.
    if xdpyinfo -display ":$display_num" > /dev/null 2>&1; then
        return 0 # Busy (an X server is responding)
    fi
    return 1 # Not busy
}

# Find an available display number
XEPHYR_DISPLAY=""
for i in $(seq 0 9); do # Check display numbers from :0 to :9
    if ! is_display_busy "$i"; then
        XEPHYR_DISPLAY=":$i"
        echo "Found available display: $XEPHYR_DISPLAY"
        break
    fi
    echo "Display :$i is busy."
done

if [ -z "$XEPHYR_DISPLAY" ]; then
    echo "Error: No available display found from :0 to :9. Exiting."
    exit 1
fi

# Start Xephyr in the background
Xephyr -br -ac -noreset -screen 1024x768 "$XEPHYR_DISPLAY" &

# Store the Process ID of Xephyr
XEPHYR_PID=$!

# Give Xephyr a moment to start up
sleep 5

# Start a D-Bus session and then launch XFCE
# This ensures DBUS_SESSION_BUS_ADDRESS is set for xfce4-session
env DISPLAY="$XEPHYR_DISPLAY" WAYLAND_DISPLAY="" dbus-launch --exit-with-session xfce4-session &

# Optional: Wait for Xephyr process to finish (when you close the window)
wait "$XEPHYR_PID"
