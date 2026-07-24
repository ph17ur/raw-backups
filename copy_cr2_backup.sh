#!/usr/bin/env bash
set -euo pipefail

# --- CR2 RAW backup/copy script ---
# Finds all files containing "cr2" (case-insensitive) anywhere in the filename
# (e.g. .CR2, .cr2, IMG_1234.CR2.xmp) recursively under a source folder,
# and copies them to a destination folder, preserving the original folder
# structure. Produces a timestamped audit log in the destination folder.
#
# Existing files at the destination are never overwritten — they are
# skipped and logged instead.

# Strips a single pair of matching leading/trailing quotes (" or '), if present.
# This means it doesn't matter whether you type the path plain or wrapped in quotes.
strip_quotes() {
    local input="$1"
    input="${input%\"}"; input="${input#\"}"
    input="${input%\'}"; input="${input#\'}"
    echo "$input"
}

read -rp "Enter SOURCE directory (folder to search): " SRC_DIR
read -rp "Enter DESTINATION directory (cold storage root): " DEST_DIR

SRC_DIR=$(strip_quotes "$SRC_DIR")
DEST_DIR=$(strip_quotes "$DEST_DIR")

# Expand ~ and resolve to absolute paths
SRC_DIR=$(eval echo "$SRC_DIR")
DEST_DIR=$(eval echo "$DEST_DIR")
SRC_DIR=$(cd "$SRC_DIR" 2>/dev/null && pwd || echo "$SRC_DIR")

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Source directory does not exist: $SRC_DIR"
    exit 1
fi

# If the destination doesn't exist yet, confirm before creating it —
# catches typos in the destination path before they silently create
# a new (wrong) folder.
if [ ! -d "$DEST_DIR" ]; then
    read -rp "Destination folder does not exist: $DEST_DIR
Would you like to create it? [y/n]: " CREATE_CONFIRM
    case "$CREATE_CONFIRM" in
        [Yy]*) mkdir -p "$DEST_DIR" ;;
        *) echo "Aborted — destination not created. No files copied."; exit 1 ;;
    esac
fi

DEST_DIR=$(cd "$DEST_DIR" && pwd)

# Final confirmation before doing anything — last chance to catch a typo
# in either path.
echo ""
echo "Please confirm before proceeding:"
echo "  Source:      $SRC_DIR"
echo "  Destination: $DEST_DIR"
read -rp "Proceed? [y/n]: " RUN_CONFIRM
case "$RUN_CONFIRM" in
    [Yy]*) ;;
    *) echo "Aborted by user. No files copied."; exit 1 ;;
esac
echo ""

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$DEST_DIR/cr2_copy_log_${TIMESTAMP}.txt"

echo "CR2 backup run started: $(date)" | tee "$LOG_FILE"
echo "Source:      $SRC_DIR" | tee -a "$LOG_FILE"
echo "Destination: $DEST_DIR" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

FILE_COUNT=0
TOTAL_BYTES=0
SKIPPED_COUNT=0

while IFS= read -r -d '' FILE; do
    REL_PATH="${FILE#"$SRC_DIR"/}"
    DEST_PATH="$DEST_DIR/$REL_PATH"
    DEST_FOLDER=$(dirname "$DEST_PATH")

    mkdir -p "$DEST_FOLDER"

    if [ -e "$DEST_PATH" ]; then
        echo "SKIPPED (already exists): $REL_PATH" | tee -a "$LOG_FILE"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    cp -p "$FILE" "$DEST_PATH"
    FILE_SIZE=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE")
    TOTAL_BYTES=$((TOTAL_BYTES + FILE_SIZE))
    FILE_COUNT=$((FILE_COUNT + 1))

    echo "COPIED: $REL_PATH ($FILE_SIZE bytes)" | tee -a "$LOG_FILE"

done < <(find "$SRC_DIR" -type f -iname "*cr2*" -print0)

TOTAL_MB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_BYTES/1048576}")

echo "----------------------------------------" | tee -a "$LOG_FILE"
echo "Run finished: $(date)" | tee -a "$LOG_FILE"
echo "Files copied:  $FILE_COUNT" | tee -a "$LOG_FILE"
echo "Files skipped (already existed): $SKIPPED_COUNT" | tee -a "$LOG_FILE"
echo "Total size copied: ${TOTAL_MB} MB" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"