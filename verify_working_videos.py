import os
import subprocess

FFMPEG = r"C:\ffmpeg-8.1-essentials_build\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe"

VIDEO_FOLDER = r"assets\signs_final_300"
OUTPUT_FILE = "real_working_words.txt"
BAD_FILE = "bad_videos.txt"

working = []
bad = []

for file in os.listdir(VIDEO_FOLDER):
    if not file.lower().endswith(".mp4"):
        continue

    path = os.path.join(VIDEO_FOLDER, file)
    word = file.replace(".mp4", "")

    command = [
        FFMPEG,
        "-v", "error",
        "-i", path,
        "-f", "null",
        "-"
    ]

    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    if result.returncode == 0:
        working.append(word)
        print(f"Working: {word}")
    else:
        bad.append(word)
        print(f"BAD: {word}")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    for word in sorted(working):
        f.write(word + "\n")

with open(BAD_FILE, "w", encoding="utf-8") as f:
    for word in sorted(bad):
        f.write(word + "\n")

print("\nDONE")
print("Working videos:", len(working))
print("Bad videos:", len(bad))
print("Created:", OUTPUT_FILE)
print("Created:", BAD_FILE)