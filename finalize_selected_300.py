import os
import shutil

SOURCE_FOLDER = r"assets\signs_cutout"
OUTPUT_FOLDER = r"assets\signs_final_300"
WORDS_FILE = "selected_300_words.txt"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Similar meaning replacements
replacements = {
    "callonphone": "call",
    "dad": "father",
    "mom": "mother",
    "kitty": "cat",
    "puppy": "dog",
    "glasswindow": "window",
    "shhh": "quiet",
    "weus": "we",
    "hesheit": "he",
    "grandma": "mother",
    "grandpa": "father",
    "fireman": "police",
    "haveto": "need",
    "minemy": "your",
    "frenchfries": "food",
    "icecream": "food",
    "backyard": "outside",
    "bedroom": "room",
    "cheek": "face",
    "chin": "face",
    "lips": "mouth",
    "feet": "shoe",
    "finger": "hand",
    "pen": "pencil",
    "refrigerator": "kitchen",
    "toothbrush": "tooth",
    "owie": "hurt",
    "yucky": "bad",
}

# Extra common fallback words
fallback_words = [
    "good", "eat", "help", "home", "school", "teacher", "student", "friend",
    "family", "name", "need", "want", "more", "work", "write", "read",
    "day", "week", "cold", "hot", "doctor", "money", "problem", "remember",
    "different", "change", "easy", "late", "window", "door", "house",
    "bathroom", "coffee", "buy", "you", "your", "with", "woman", "man",
]

def exists(word):
    return os.path.exists(os.path.join(SOURCE_FOLDER, f"{word}.mp4"))

def copy_video(source_word, target_word):
    src = os.path.join(SOURCE_FOLDER, f"{source_word}.mp4")
    dst = os.path.join(OUTPUT_FOLDER, f"{target_word}.mp4")
    shutil.copy2(src, dst)

with open(WORDS_FILE, "r", encoding="utf-8") as f:
    selected_words = [w.strip().lower() for w in f if w.strip()]

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

# Fill remaining missing words with fallback common words
for word in fallback_words:
    if len(final_words) >= 300:
        break

    if word not in final_words and exists(word):
        copy_video(word, word)
        final_words.append(word)
        print(f"Added fallback: {word}")

print("\nDONE")
print("Final videos:", len(os.listdir(OUTPUT_FOLDER)))
print("Still missing original words:", len(missing))

with open("final_300_words.txt", "w", encoding="utf-8") as f:
    for word in final_words:
        f.write(word + "\n")

print("Created final_300_words.txt")
print("Output folder:", OUTPUT_FOLDER)