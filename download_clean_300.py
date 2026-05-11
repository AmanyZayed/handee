import os
import re
import json
import shutil
import requests
import subprocess
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

FFMPEG = r"C:\ffmpeg-8.1-essentials_build\ffmpeg-8.1-essentials_build\bin\ffmpeg.exe"

WORDS_FILE = "selected_300_words.txt"
WLASL_FILE = "WLASL_v0.3.json"

OUTPUT_FOLDER = r"assets\signs_clean_300"
TEMP_FOLDER = r"temp_downloads"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)
os.makedirs(TEMP_FOLDER, exist_ok=True)

HEADERS = {
    "User-Agent": "Mozilla/5.0"
}

ALIASES = {
    "tv": "television",
    "callonphone": "call",
    "dad": "father",
    "mom": "mother",
    "grandma": "grandmother",
    "grandpa": "grandfather",
    "kitty": "cat",
    "puppy": "dog",
    "glasswindow": "window",
    "minemy": "mine",
    "shhh": "quiet",
    "weus": "we",
    "hesheit": "he",
    "haveto": "need",
    "fireman": "firefighter",
    "frenchfries": "french fries",
    "icecream": "ice cream",
}

def clean_word(word):
    return re.sub(r"[^a-z0-9]", "", word.lower())

def is_valid_video(path):
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

    return result.returncode == 0

def download_url(url, output_path):
    try:
        r = requests.get(
            url,
            headers=HEADERS,
            timeout=25,
            verify=False,
            allow_redirects=True
        )

        if r.status_code != 200:
            return False

        if len(r.content) < 50 * 1024:
            return False

        with open(output_path, "wb") as f:
            f.write(r.content)

        return is_valid_video(output_path)

    except Exception:
        return False

with open(WORDS_FILE, "r", encoding="utf-8") as f:
    target_words = [clean_word(w.strip()) for w in f if w.strip()]

with open(WLASL_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

# Build searchable dictionary from WLASL
dataset = {}

for entry in data:
    gloss_raw = entry.get("gloss", "")
    gloss_clean = clean_word(gloss_raw)

    if gloss_clean:
        dataset[gloss_clean] = entry.get("instances", [])

print("Target words:", len(target_words))

downloaded = []
missing = []

for target_word in target_words:
    final_path = os.path.join(OUTPUT_FOLDER, f"{target_word}.mp4")

    if os.path.exists(final_path) and is_valid_video(final_path):
        print(f"Already valid: {target_word}")
        downloaded.append(target_word)
        continue

    search_word = ALIASES.get(target_word, target_word)
    search_clean = clean_word(search_word)

    instances = dataset.get(search_clean)

    if not instances:
        print(f"Missing in WLASL: {target_word} searched as {search_word}")
        missing.append(target_word)
        continue

    success = False

    for i, inst in enumerate(instances):
        url = inst.get("url", "")

        if ".mp4" not in url.lower():
            continue

        temp_path = os.path.join(TEMP_FOLDER, f"{target_word}_{i}.mp4")

        print(f"Trying {target_word}: {url}")

        if download_url(url, temp_path):
            shutil.copy2(temp_path, final_path)
            print(f"SAVED: {target_word}")
            downloaded.append(target_word)
            success = True
            break
        else:
            print(f"Bad video skipped: {target_word}")

    if not success:
        print(f"FAILED: {target_word}")
        missing.append(target_word)

with open("clean_working_words.txt", "w", encoding="utf-8") as f:
    for word in downloaded:
        f.write(word + "\n")

with open("clean_missing_words.txt", "w", encoding="utf-8") as f:
    for word in missing:
        f.write(word + "\n")

print("\nDONE")
print("Working videos:", len(downloaded))
print("Missing videos:", len(missing))
print("Output folder:", OUTPUT_FOLDER)
print("Working list: clean_working_words.txt")
print("Missing list: clean_missing_words.txt")