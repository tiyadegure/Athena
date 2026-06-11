#!/bin/bash
# Athena Demo Video Recording Script
# Records terminal demo + voiceover into MP4

set -e
DEMO_DIR="/root/projects/glm-code/demo"
DISPLAY_NUM=:99
RESOLUTION=1280x800

# Kill any existing Xvfb on :99
pkill -f "Xvfb $DISPLAY_NUM" 2>/dev/null || true
sleep 0.5

# Start Xvfb
Xvfb $DISPLAY_NUM -screen 0 ${RESOLUTION}x24 -ac &
XVFB_PID=$!
sleep 1

# Start ffmpeg screen recording in background
export DISPLAY=$DISPLAY_NUM
ffmpeg -y \
  -f x11grab -framerate 24 -video_size $RESOLUTION -i $DISPLAY_NUM \
  -i "$DEMO_DIR/voice/final.ogg" \
  -c:v libx264 -preset ultrafast -crf 23 \
  -c:a aac -b:a 128k \
  -shortest \
  "$DEMO_DIR/athena-demo-raw.mp4" &
FFMPEG_PID=$!
sleep 1

# Run demo in xterm with dark theme
xterm \
  -bg black -fg white \
  -fn "-misc-fixed-medium-r-normal--18-*-*-*-c-*-iso8859-1" \
  -fa "DejaVu Sans Mono" -fs 14 \
  -geometry 100x40 \
  -title "Athena Demo" \
  -e bash -c "
    export TERM=xterm-256color
    stty cols 100 rows 40
    cd $DEMO_DIR/..
    bash $DEMO_DIR/DEMO.sh
    sleep 3
  " &
XTERM_PID=$!

# Wait for xterm to finish
wait $XTERM_PID 2>/dev/null || true

# Give ffmpeg time to flush
sleep 2

# Stop ffmpeg gracefully
kill -INT $FFMPEG_PID 2>/dev/null || true
wait $FFMPEG_PID 2>/dev/null || true

# Cleanup
kill $XVFB_PID 2>/dev/null || true
wait $XVFB_PID 2>/dev/null || true

echo "=== Recording complete ==="
echo "Output: $DEMO_DIR/athena-demo-raw.mp4"
ls -lh "$DEMO_DIR/athena-demo-raw.mp4"
