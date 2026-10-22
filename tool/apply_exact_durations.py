import json

with open('tool/durations_cache.json', 'r', encoding='utf-8') as f:
    durations = json.load(f)

with open('assets/data/mutun_shuruh_videos.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

updated_count = 0
for book in data['books']:
    for scholar in book['shuyookh']:
        for vid in scholar['videos']:
            v_id = vid['video_id']
            # If video has explicit segment end_seconds and start_seconds, use segment duration
            if 'end_seconds' in vid and 'start_seconds' in vid:
                seg_sec = vid['end_seconds'] - vid['start_seconds']
                vid['duration_minutes'] = max(1, round(seg_sec / 60))
                continue
            if v_id in durations:
                sec, mins = durations[v_id]
                old_min = vid.get('duration_minutes')
                if old_min != mins:
                    vid['duration_minutes'] = mins
                    updated_count += 1

print(f"Updated {updated_count} video durations in mutun_shuruh_videos.json!")

with open('assets/data/mutun_shuruh_videos.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Saved updated assets/data/mutun_shuruh_videos.json")
