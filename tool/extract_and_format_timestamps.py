import subprocess
import re
import imageio_ffmpeg

ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

def get_silences(url, db=-19, dur=0.3):
    cmd = [ffmpeg, '-i', url, '-af', f'silencedetect=n={db}dB:d={dur}', '-f', 'null', '-']
    proc = subprocess.Popen(cmd, stderr=subprocess.PIPE, stdout=subprocess.DEVNULL, text=True, encoding='utf-8', errors='ignore')
    _, err = proc.communicate()
    
    # Extract total duration from metadata: Duration: HH:MM:SS.ms
    dur_match = re.search(r'Duration:\s*(\d+):(\d+):([0-9\.]+)', err)
    if dur_match:
        h, m, s = dur_match.groups()
        total_sec = int(h) * 3600 + int(m) * 60 + float(s)
    else:
        total_sec = 2400.0

    pattern = r'silence_start:\s*([0-9\.]+).*?silence_end:\s*([0-9\.]+)\s*\|\s*silence_duration:\s*([0-9\.]+)'
    matches = re.findall(pattern, err, re.DOTALL)
    candidates = [(float(start), float(end), float(d)) for start, end, d in matches]
    return total_sec, candidates

def select_timestamps(total_sec, candidates, k):
    # k is total paragraphs. We need k timestamps starting with 0.
    # So we need k-1 breakpoints from candidates.
    target_interval = total_sec / k
    ideal_points = [i * target_interval for i in range(1, k)]
    
    # We want to pick k-1 candidates that are strictly ascending
    # and closest to ideal_points, heavily weighting candidate silence duration.
    # Using dynamic programming to find optimal sequence
    # Cost function: (candidate_time - ideal_time)^2 / (1 + duration)
    
    ends = [c[1] for c in candidates if 10.0 <= c[1] <= total_sec - 10.0]
    durations = {c[1]: c[2] for c in candidates}
    
    # Deduplicate ends if very close (< 2 sec)
    deduped = []
    for e in sorted(ends):
        if not deduped or (e - deduped[-1]) >= 3.0:
            deduped.append(e)
            
    # Dynamic programming: select k-1 indices from deduped
    n = len(deduped)
    m = k - 1
    
    # dp[i][j]: min cost to pick i breakpoints from first j candidates
    # parent[i][j]: previous candidate index
    INF = float('inf')
    dp = [[INF] * (n + 1) for _ in range(m + 1)]
    parent = [[-1] * (n + 1) for _ in range(m + 1)]
    
    for j in range(n + 1):
        dp[0][j] = 0.0
        
    for i in range(1, m + 1):
        ideal = ideal_points[i - 1]
        for j in range(i, n + 1):
            cand_time = deduped[j - 1]
            cand_dur = durations.get(cand_time, 0.3)
            # Cost emphasizes matching progress and rewarding long pauses
            dist = abs(cand_time - ideal)
            penalty = (dist ** 1.5) / (1.0 + cand_dur * 2.0)
            
            # Find best previous candidate
            best_prev = INF
            best_idx = -1
            for p in range(i - 1, j):
                if dp[i - 1][p] < INF:
                    prev_time = deduped[p - 1] if p > 0 else 0.0
                    # Ensure at least 5s gap
                    if cand_time - prev_time >= 5.0:
                        cost = dp[i - 1][p] + penalty
                        if cost < best_prev:
                            best_prev = cost
                            best_idx = p
            dp[i][j] = best_prev
            parent[i][j] = best_idx
            
    # Find best end
    best_last = min(range(m, n + 1), key=lambda j: dp[m][j])
    
    chosen = []
    curr = best_last
    for i in range(m, 0, -1):
        chosen.append(deduped[curr - 1])
        curr = parent[i][curr]
    chosen.reverse()
    
    # Convert to integer milliseconds, with first element 0
    timestamps_ms = [0] + [int(round(t * 1000)) for t in chosen]
    return timestamps_ms

if __name__ == '__main__':
    books = [
        ('bk_arbaeen_nawawi', 'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3', 42, -19, 0.35),
        ('bk_wasitiyyah', 'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0404AlWaasitiyyah_AbdulAzizAsSini.mp3', 35, -21, 0.35),
        ('bk_ajrumiyyah', 'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3', 30, -21, 0.35),
    ]
    
    for book_id, url, count, db, dur in books:
        print(f'=== Processing {book_id} (count={count}) ===')
        total_sec, candidates = get_silences(url, db, dur)
        print(f'Total audio duration: {total_sec:.2f}s, candidates: {len(candidates)}')
        ts = select_timestamps(total_sec, candidates, count)
        print(f'Generated {len(ts)} timestamps (starts with {ts[0]}, ends with {ts[-1]} ms)')
        
        # Verify strict ascending
        for i in range(len(ts) - 1):
            assert ts[i] < ts[i+1], f'Not ascending at {i}: {ts[i]} >= {ts[i+1]}'
            gap = ts[i+1] - ts[i]
            assert gap <= 600000, f'Gap too large at {i}: {gap} ms'
            
        print(f'// {book_id}: {count} paragraphs')
        print(f'paragraphTimestamps: {ts},')
        print()
