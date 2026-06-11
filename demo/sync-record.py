#!/usr/bin/env python3
"""Synchronized demo recorder: terminal + MiMo TTS voiceover"""
import subprocess, time, os, signal

DEMO_DIR = "/root/projects/glm-code/demo"
VOICE_DIR = os.path.join(DEMO_DIR, "voice")
DISPLAY = ":99"
RES = "1280x800"

SEGMENTS = [
    ("01-intro.mp3", 9.984),
    ("02-step1.mp3", 16.536),
    ("03-step2.mp3", 12.528),
    ("04-step3.mp3", 11.424),
    ("05-step4.mp3", 17.808),
    ("06-step5.mp3", 13.008),
    ("07-step6.mp3", 14.928),
    ("08-step7.mp3", 19.728),
    ("09-step8.mp3", 19.584),
    ("10-closing.mp3", 22.608),
]

def run_bg(cmd):
    return subprocess.Popen(cmd, shell=True, preexec_fn=os.setsid)

def run_fg(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

# Kill old Xvfb
run_fg(f"pkill -f 'Xvfb {DISPLAY}' 2>/dev/null; sleep 0.5")

# Start Xvfb
xvfb = run_bg(f"Xvfb {DISPLAY} -screen 0 {RES}x24 -ac")
time.sleep(1)

# Start ffmpeg screen recording
os.environ["DISPLAY"] = DISPLAY
ffmpeg = run_bg(
    f'ffmpeg -y -f x11grab -framerate 24 -video_size {RES} -i {DISPLAY} '
    f'-c:v libx264 -preset ultrafast -crf 23 '
    f'{DEMO_DIR}/demo-video-only.mp4'
)
time.sleep(1)

# Start xterm running the demo script
xterm = run_bg(
    f'xterm -bg black -fg white -fa "DejaVu Sans Mono" -fs 13 '
    f'-geometry 105x38 -title "Athena Demo" '
    f'-e bash {DEMO_DIR}/demo-sync.sh'
)
time.sleep(1)

# Play audio segments in sync using ffplay
print("Playing voiceover segments...")
for i, (audio_file, duration) in enumerate(SEGMENTS):
    print(f"  Playing {audio_file} ({duration:.1f}s)")
    audio_path = os.path.join(VOICE_DIR, audio_file)
    audio_proc = run_bg(f"ffplay -nodisp -autoexit -loglevel quiet {audio_path}")
    time.sleep(duration + 0.3)

# Wait for xterm to finish
time.sleep(3)

# Stop ffmpeg
print("Stopping recording...")
os.kill(ffmpeg.pid, signal.SIGINT)
time.sleep(2)
try:
    ffmpeg.wait(timeout=5)
except:
    pass

# Cleanup
for proc in [xterm, xvfb]:
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    except:
        pass

video_path = f"{DEMO_DIR}/demo-video-only.mp4"
if os.path.exists(video_path):
    print(f"Video saved: {video_path}")
    print(f"Size: {os.path.getsize(video_path) / 1024 / 1024:.1f} MB")
else:
    print("ERROR: Video not created")
