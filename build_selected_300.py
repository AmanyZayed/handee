import os
import re
import shutil
import json

SOURCE_FOLDERS = [
    r"assets\signs_cutout",
    r"assets\signs_cropped",
    r"assets\signs",
]

OUTPUT_FOLDER = r"assets\signs_selected"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

def clean(word):
    return re.sub(r"[^a-z0-9]", "", word.lower())

# Your 250 words
base_words = [
    "TV","after","airplane","all","alligator","animal","another","any","apple","arm",
    "aunt","awake","backyard","bad","balloon","bath","because","bed","bedroom","bee",
    "before","beside","better","bird","black","blow","blue","boat","book","boy",
    "brother","brown","bug","bye","callonphone","can","car","carrot","cat","cereal",
    "chair","cheek","child","chin","chocolate","clean","close","closet","cloud","clown",
    "cow","cowboy","cry","cut","cute","dad","dance","dirty","dog","doll","donkey",
    "down","drawer","drink","drop","dry","dryer","duck","ear","elephant","empty",
    "every","eye","face","fall","farm","fast","feet","find","fine","finger","finish",
    "fireman","first","fish","flag","flower","food","for","frenchfries","frog","garbage",
    "gift","giraffe","girl","give","glasswindow","go","goose","grandma","grandpa","grass",
    "green","gum","hair","happy","hat","hate","have","haveto","head","hear","helicopter",
    "hello","hen","hesheit","hide","high","home","horse","hot","hungry","icecream","if",
    "into","jacket","jeans","jump","kiss","kitty","lamp","later","like","lion","lips",
    "listen","look","loud","mad","make","man","many","milk","minemy","mitten","mom",
    "moon","morning","mouse","mouth","nap","napkin","night","no","noisy","nose","not",
    "now","nuts","old","on","open","orange","outside","owie","owl","pajamas","pen",
    "pencil","penny","person","pig","pizza","please","police","pool","potty","pretend",
    "pretty","puppy","puzzle","quiet","radio","rain","read","red","refrigerator","ride",
    "room","sad","same","say","scissors","see","shhh","shirt","shoe","shower","sick",
    "sleep","sleepy","smile","snack","snow","stairs","stay","sticky","store","story",
    "stuck","sun","table","talk","taste","thankyou","that","there","think","thirsty",
    "tiger","time","tomorrow","tongue","tooth","toothbrush","touch","toy","tree","uncle",
    "underwear","up","vacuum","wait","wake","water","wet","weus","where","white","who",
    "why","will","wolf","yellow","yes","yesterday","yourself","yucky","zebra","zipper"
]

# 50 common daily words I chose
extra_words = [
    "about", "again", "baby", "bathroom", "buy",
    "coffee", "cold", "day", "doctor", "eat",
    "family", "father", "friend", "good", "help",
    "here", "house", "how", "know", "learn",
    "leave", "money", "more", "mother", "name",
    "need", "new", "problem", "remember", "school",
    "share", "small", "soon", "student", "teacher",
    "tired", "want", "week", "with", "woman",
    "work", "write", "you", "your", "change",
    "different", "door", "easy", "late", "window"
]

# If your word name is different from dataset/video name
aliases = {
    "tv": "tv",
    "callonphone": "call",
    "dad": "father",
    "mom": "mother",
    "grandma": "grandmother",
    "grandpa": "grandfather",
    "kitty": "cat",
    "puppy": "dog",
    "glasswindow": "window",
    "minemy": "mine",
    "thankyou": "thankyou",
    "icecream": "icecream",
    "frenchfries": "frenchfries",
    "haveto": "must",
    "fireman": "firefighter",
    "weus": "we",
    "hesheit": "he",
    "shhh": "quiet",
}

all_words = []
for w in base_words + extra_words:
    cw = clean(w)
    if cw not in all_words:
        all_words.append(cw)

copied = []
missing = []

def find_video(source_word):
    source_word = clean(source_word)

    possible_names = [
        f"{source_word}.mp4",
        f"{source_word.lower()}.mp4",
    ]

    for folder in SOURCE_FOLDERS:
        for name in possible_names:
            path = os.path.join(folder, name)
            if os.path.exists(path):
                return path

    return None

for target_word in all_words:
    source_word = aliases.get(target_word, target_word)
    source_path = find_video(source_word)

    if source_path:
        output_path = os.path.join(OUTPUT_FOLDER, f"{target_word}.mp4")
        shutil.copy2(source_path, output_path)
        copied.append(target_word)
        print(f"Copied: {target_word}  <-  {source_word}")
    else:
        missing.append(target_word)
        print(f"Missing: {target_word}  searched as  {source_word}")

with open("selected_300_words.json", "w", encoding="utf-8") as f:
    json.dump({w: f"assets/signs_selected/{w}.mp4" for w in copied}, f, indent=4)

with open("missing_words.txt", "w", encoding="utf-8") as f:
    for w in missing:
        f.write(w + "\n")

print("\nDONE")
print("Requested words:", len(all_words))
print("Copied videos:", len(copied))
print("Missing videos:", len(missing))
print("Output folder:", OUTPUT_FOLDER)