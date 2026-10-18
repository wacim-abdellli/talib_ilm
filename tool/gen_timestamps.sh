#!/usr/bin/env bash
# tool/gen_timestamps.sh — Generate paragraph timestamps via ffmpeg silence detection

set -euo pipefail

# Priority Audio URLs
URL_ARBAEEN="https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0204AlArbaunAnNawawiyah_AbdulAzizAsSini.mp3"
URL_WASITIYYAH="https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0404AlWaasitiyyah_AbdulAzizAsSini.mp3"
URL_AJRUMIYYAH="https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0403AlAajurrumiyyah_AbdulAzizAsSini.mp3"

detect_timestamps() {
  local name="$1"
  local url="$2"
  local target_count="$3"
  echo "=== Detecting timestamps for $name (target: $target_count paragraphs) ==="
  
  ffmpeg -i "$url" -af "silencedetect=n=-38dB:d=1.0" -f null - 2>&1 \
    | grep "silence_end" \
    | awk '{for(i=1;i<=NF;i++) if($i=="silence_end:") print $(i+1)}'
}

echo "Generating silence detection timestamps..."
detect_timestamps "bk_arbaeen_nawawi" "$URL_ARBAEEN" 42
detect_timestamps "bk_wasitiyyah" "$URL_WASITIYYAH" 35
detect_timestamps "bk_ajrumiyyah" "$URL_AJRUMIYYAH" 30
