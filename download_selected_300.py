import os
import json
import requests

# ====== CONFIG ======
WORDS_FILE = "selected_300_words.txt"
WLASL_FILE = "WLASL_v0.3.json"
OUTPUT_FOLDER = r"assets\signs_cutout"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# ====== LOAD WORDS ======
with open(WORDS_FILE, "r", encoding="utf-8") as f:
    target_words = [w.strip().lower() for w in f if w.strip()]

print("Total target words:", len(target_words))

# ====== LOAD DATASET ======
with open(WLASL_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

# ====== BUILD DICTIONARY ======
word_to_url = {}

for entry in data:
    gloss = entry["gloss"].lower()

    if gloss not in target_words:
        continue

    instances = entry.get("instances", [])
    if not instances:
        continue

    # take first video
    url = instances[0].get("url")
    if url:
        word_to_url[gloss] = url

# ====== DOWNLOAD ======
downloaded = 0
missing = []

for word in target_words:
    if word not in word_to_url:
        print(f"Missing in dataset: {word}")
        missing.append(word)
        continue

    url = word_to_url[word]
    output_path = os.path.join(OUTPUT_FOLDER, f"{word}.mp4")

    if os.path.exists(output_path):
        print(f"Already exists: {word}")
        continue

    try:
        print(f"Downloading: {word}")
        r = requests.get(url, timeout=10)

        if r.status_code == 200:
            with open(output_path, "wb") as f:
                f.write(r.content)
            downloaded += 1
        else:
            print(f"Failed (status): {word}")
            missing.append(word)

    except Exception as e:
        print(f"Error: {word} -> {e}")
        missing.append(word)

# ====== RESULT ======
print("\nDONE")
print("Downloaded:", downloaded)
print("Missing:", len(missing))

# Save missing words (optional)
with open("still_missing.txt", "w") as f:
    for w in missing:
        f.write(w + "\n")