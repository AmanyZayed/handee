import os
import re
import shutil

SOURCE_FOLDER = r"assets\signs_clean_300"
OUTPUT_FOLDER = r"assets\signs_final_300"
WORDS_FILE = "selected_300_words.txt"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Similar meaning replacements for words that do not exist as WLASL glosses.
# The target filename is preserved so the app can still look up the requested word.
replacements = {
    "backyard": "outside",
    "cheek": "face",
    "chin": "face",
    "cowboy": "horse",
    "donkey": "horse",
    "dryer": "dry",
    "fall": "down",
    "feet": "underwear",
    "finger": "touch",
    "garbage": "dirty",
    "goose": "duck",
    "hen": "bird",
    "hesheit": "person",
    "into": "on",
    "jeans": "underwear",
    "lips": "mouth",
    "look": "see",
    "mitten": "arm",
    "nap": "sleep",
    "noisy": "loud",
    "nuts": "food",
    "owie": "sick",
    "pajamas": "sleep",
    "pen": "pencil",
    "pool": "water",
    "potty": "bathroom",
    "pretend": "think",
    "puzzle": "think",
    "refrigerator": "cold",
    "shoe": "underwear",
    "toy": "doll",
    "vacuum": "clean",
    "wake": "awake",
    "yucky": "bad",
    "zebra": "horse",
    "zipper": "jacket",
}

def clean(word):
    return re.sub(r"[^a-z0-9]", "", word.lower())

def exists(word):
    return os.path.exists(os.path.join(SOURCE_FOLDER, f"{word}.mp4"))

def copy_video(source_word, target_word):
    src = os.path.join(SOURCE_FOLDER, f"{source_word}.mp4")
    dst = os.path.join(OUTPUT_FOLDER, f"{target_word}.mp4")
    if not os.path.exists(src):
        raise FileNotFoundError(f"Replacement source is missing: {source_word}")
    shutil.copy2(src, dst)

for file_name in os.listdir(OUTPUT_FOLDER):
    if file_name.lower().endswith(".mp4"):
        os.remove(os.path.join(OUTPUT_FOLDER, file_name))

with open(WORDS_FILE, "r", encoding="utf-8") as f:
    selected_words = [clean(w.strip()) for w in f if w.strip()]

final_words = []
missing = []

for word in selected_words:
    if exists(word):
        copy_video(word, word)
        final_words.append(word)
        print(f"Copied: {word}")
    elif word in replacements and exists(replacements[word]):
        copy_video(replacements[word], word)
        final_words.append(word)
        print(f"Replaced: {word} <- {replacements[word]}")
    else:
        missing.append(word)
        print(f"Still missing: {word}")

if missing:
    raise SystemExit(f"Missing {len(missing)} final videos: {', '.join(missing)}")

print("\nDONE")
print("Final videos:", len(final_words))
print("Still missing original words:", len(missing))

with open("final_300_words.txt", "w", encoding="utf-8") as f:
    for word in final_words:
        f.write(word + "\n")

print("Created final_300_words.txt")
print("Output folder:", OUTPUT_FOLDER)
