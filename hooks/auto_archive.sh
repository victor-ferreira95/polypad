#!/usr/bin/env bash
# polypad auto-archive hook
# Archives napkin if oldest narrative block is > 3 days old.

set -euo pipefail

NAPKIN=".agents/napkin.md"
ARCHIVE_DIR=".agents/archive"
MAX_AGE_DAYS=3

[ ! -f "$NAPKIN" ] && exit 0

separator_line=$(grep -n '^---$' "$NAPKIN" | head -1 | cut -d: -f1 || echo "")
[ -z "$separator_line" ] && exit 0

narrative=$(tail -n +"$separator_line" "$NAPKIN")
oldest_date=$(echo "$narrative" | grep -oE '^## \[[a-z-]+\] [0-9]{4}-[0-9]{2}-[0-9]{2}' | awk '{print $3}' | sort | head -1 || echo "")

[ -z "$oldest_date" ] && exit 0

if date -d "$oldest_date" +%s >/dev/null 2>&1; then
    oldest_epoch=$(date -d "$oldest_date" +%s)
else
    oldest_epoch=$(date -j -f "%Y-%m-%d" "$oldest_date" +%s)
fi
now_epoch=$(date +%s)
age_days=$(( (now_epoch - oldest_epoch) / 86400 ))

[ "$age_days" -lt "$MAX_AGE_DAYS" ] && exit 0

mkdir -p "$ARCHIVE_DIR"
today=$(date +%Y-%m-%d)
archive_path="$ARCHIVE_DIR/napkin-$today.md"
suffix=2
while [ -f "$archive_path" ]; do
    archive_path="$ARCHIVE_DIR/napkin-$today-$suffix.md"
    suffix=$((suffix + 1))
done

cp "$NAPKIN" "$archive_path"

{
    echo "<!-- started $today, previous archived to $archive_path -->"
    echo ""
    echo "# napkin"
    echo ""
    sed -n '/^# napkin$/,/^---$/p' "$NAPKIN" | sed '1d;$d' | sed '/^<!--/,/-->$/d'
    echo "---"
    echo ""
} > "$NAPKIN.tmp"

mv "$NAPKIN.tmp" "$NAPKIN"

echo "Archived previous napkin (${age_days} days old) to $archive_path. Agent headers carried forward."
