import os
import subprocess

FFMPEG = r"C:\ffmpeg-8.1-essentials_build\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe"

INPUT_FOLDER = r"assets\signs"
OUTPUT_FOLDER = r"assets\signs_cropped"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

for filename in os.listdir(INPUT_FOLDER):
    if not filename.lower().endswith(".mp4"):
        continue

    input_path = os.path.join(INPUT_FOLDER, filename)
    output_path = os.path.join(OUTPUT_FOLDER, filename)

    if os.path.exists(output_path):
        print(f"Skipping existing: {filename}")
        continue

    print(f"Cropping: {filename}")

    command = [
        FFMPEG,
        "-y",
        "-i", input_path,

        # Centered crop, portrait output
        "-vf",
        "scale=720:-2,crop=720:min(960\\,ih):(iw-720)/2:(ih-min(960\\,ih))/2,scale=720:960",

        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "28",
        "-an",
        output_path,
    ]

    try:
        subprocess.run(command, check=True)
        print(f"Saved: {output_path}")
    except subprocess.CalledProcessError:
        print(f"Failed: {filename}")

print("Done cropping videos.")