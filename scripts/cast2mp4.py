#!/usr/bin/env python3
"""Convert asciinema .cast to mp4 using pyte + Pillow + ffmpeg."""

import json, os, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# Config
CAST_FILE = sys.argv[1] if len(sys.argv) > 1 else "demo/demo-v9.1.cast"
OUTPUT = sys.argv[2] if len(sys.argv) > 2 else "demo/demo-v9.1.mp4"
FPS = 10  # Lower FPS for terminal content
FONT_SIZE = 18

# ANSI 16 colors
ANSI_COLORS = [
    "#000000", "#cc0000", "#4e9a06", "#c4a000",
    "#3465a4", "#75507b", "#06989a", "#d3d7cf",
    "#555753", "#ef2929", "#8ae234", "#fce94f",
    "#729fcf", "#ad7fa8", "#34e2e2", "#eeeeec",
]

BG = "#0a0a0a"
FG = "#cccccc"


def load_font():
    for f in [
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
    ]:
        if os.path.exists(f):
            return ImageFont.truetype(f, FONT_SIZE)
    return ImageFont.load_default()


def parse_cast(filepath):
    events = []
    with open(filepath, "r") as f:
        header = json.loads(f.readline())
        for line in f:
            parts = json.loads(line)
            if len(parts) >= 3 and parts[1] == "o":
                events.append((parts[0], parts[2]))
    return header, events


def render_screen(screen, font, cols, rows):
    """Render pyte screen to PIL Image with colors."""
    char_w = FONT_SIZE * 0.6
    char_h = FONT_SIZE * 1.35
    img_w = int(cols * char_w) + 20
    img_h = int(rows * char_h) + 20

    img = Image.new("RGB", (img_w, img_h), BG)
    draw = ImageDraw.Draw(img)

    for row_idx in range(rows):
        line = screen.buffer[row_idx]
        y = 10 + int(row_idx * char_h)
        for col_idx in range(cols):
            char = line[col_idx]
            c = char.data if char.data else " "
            if c.strip():
                # Determine color
                fg = FG
                if char.fg and char.fg != "default":
                    try:
                        idx = int(char.fg)
                        if 0 <= idx < 16:
                            fg = ANSI_COLORS[idx]
                    except ValueError:
                        if char.fg.startswith("#"):
                            fg = char.fg
                        else:
                            fg = FG
                if char.bold:
                    fg = "#ffffff"

                x = 10 + int(col_idx * char_w)
                draw.text((x, y), c, fill=fg, font=font)

    return img


def main():
    print(f"Parsing {CAST_FILE}...")
    header, events = parse_cast(CAST_FILE)

    cols = header.get("width", 80)
    rows = header.get("height", 24)
    print(f"Screen: {cols}x{rows}, {len(events)} events")

    import pyte

    screen = pyte.Screen(cols, rows)
    stream = pyte.Stream(screen)

    total_time = events[-1][0]
    print(f"Duration: {total_time:.1f}s")

    font = load_font()
    frames_dir = "/tmp/cast_frames"
    os.makedirs(frames_dir, exist_ok=True)

    # Step 1: process all events, snapshot at intervals
    snapshot_interval = 1.0 / FPS  # seconds between snapshots
    next_snapshot = 0.0
    event_idx = 0
    frame_num = 0

    print("Rendering frames...")

    for event_time, event_data in events:
        stream.feed(event_data)

        # Snapshot if we've passed the next snapshot time
        while event_time >= next_snapshot:
            img = render_screen(screen, font, cols, rows)
            img.save(f"{frames_dir}/frame_{frame_num:06d}.png")
            frame_num += 1
            next_snapshot += snapshot_interval

    # Final frame
    img = render_screen(screen, font, cols, rows)
    img.save(f"{frames_dir}/frame_{frame_num:06d}.png")
    frame_num += 1

    print(f"Generated {frame_num} frames, encoding mp4...")

    # ffmpeg
    ret = os.system(
        f'ffmpeg -y -framerate {FPS} -i {frames_dir}/frame_%06d.png '
        f'-c:v libx264 -pix_fmt yuv420p -preset fast -crf 20 '
        f'"{OUTPUT}" 2>&1 | tail -3'
    )

    # Cleanup
    import shutil
    shutil.rmtree(frames_dir)

    if os.path.exists(OUTPUT):
        size_kb = os.path.getsize(OUTPUT) / 1024
        print(f"Done: {OUTPUT} ({size_kb:.0f} KB, {frame_num} frames @ {FPS}fps)")
    else:
        print("Error: ffmpeg failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
