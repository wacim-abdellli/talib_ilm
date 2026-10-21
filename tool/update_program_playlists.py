import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("assets/data/mutun_shuruh_videos.json", "r", encoding="utf-8") as f:
    shuruh_data = json.load(f)

# Map book_id to primary playlist_id
playlists = {}
for book in shuruh_data["books"]:
    book_id = book["book_id"]
    if book["shuyookh"]:
        playlists[book_id] = book["shuyookh"][0]["playlist_id"]

with open("assets/data/mutun_program.json", "r", encoding="utf-8") as f:
    prog_data = json.load(f)

updated_count = 0
for level in prog_data["program"]["levels"]:
    for book in level.get("books", []):
        bid = book.get("id")
        if bid in playlists:
            if "resources" not in book:
                book["resources"] = {}
            book["resources"]["video_playlist"] = playlists[bid]
            updated_count += 1

with open("assets/data/mutun_program.json", "w", encoding="utf-8") as f:
    json.dump(prog_data, f, ensure_ascii=False, indent=2)

print(f"Updated {updated_count} books in assets/data/mutun_program.json with verified playlists")
