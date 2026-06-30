#!/usr/bin/env bash
# Git Bash: use this instead of `flutter run` or `run.bat` (run.bat is CMD-only).
# Example: ./run.sh R58M775JX2W
exec "$(dirname "$0")/scripts/run_on_d.sh" "$@"
