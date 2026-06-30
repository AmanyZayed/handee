#!/usr/bin/env bash
# Safe cleanup for full C: — Git Bash. Run: bash scripts/free_space_on_c.sh
set -u

echo "=== C: before ==="
df -h /c | head -2

clean() {
  local p="$1"
  if [[ -e "$p" || -d "$p" ]]; then
    echo "Removing: $p"
    rm -rf "$p" 2>/dev/null || true
  fi
}

# Temp + Flutter compiler cache
clean "/c/Users/Asus/AppData/Local/Temp/flutter_tools."*
clean "/c/Users/Asus/AppData/Local/Temp/dart"*
find "/c/Users/Asus/AppData/Local/Temp" -maxdepth 1 -type f -mtime +7 -delete 2>/dev/null || true

# Gradle (will re-download on next build — use D: run.bat after this)
clean "/c/Users/Asus/.gradle/caches"
clean "/c/Users/Asus/AppData/Local/HandeeGradleHome/caches"

# Old Handee copy on Desktop (you build from D:\Handee now)
clean "/c/Users/Asus/Desktop/Handee/handee/build"
clean "/c/Users/Asus/Desktop/Handee/handee/.dart_tool"
clean "/c/Users/Asus/Desktop/Handee/handee/android/.gradle"
clean "/c/Users/Asus/Desktop/Handee/handee/android/app/build"

# Pub / pip on C (Flutter on D: uses D:\dev\pub-cache when using run.bat)
clean "/c/Users/Asus/AppData/Local/Pub/Cache"
clean "/c/Users/Asus/AppData/Local/pip/Cache"

echo ""
echo "=== C: after ==="
df -h /c | head -2
echo ""
echo "Then run: cd /d/Handee/handee && ./run.sh R58M775JX2W"
