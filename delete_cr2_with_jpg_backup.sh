#!/usr/bin/env bash
set -euo pipefail

# --- Delete CR2 files that have a JPG sibling ---
# Recursively searches a given folder for .CR2 files. For each one found,
# checks whether a same-named JPG exists in the same folder. If so, the
# CR2 (and its .xmp sidecar, if present) is deleted — on the assumption
# you already have the CR2 safely backed up elsewhere (see
# copy_cr2_backup.sh) and only need the JPG locally.
#
# CR2 files with NO matching JPG are left completely untouched.
#
# Runs a dry-run preview first so your final confirmation is based on
# real numbers, then deletes, logging everything to an audit log.

# Strips a single pair of matching leading/trailing quotes (" or '), if present.
strip_quotes() {
    local input="$1"
    input="${input%\"}"; input="${input#\"}"
    input="${input%\'}"; input="${input#\'}"
    echo "$input"
}

read -rp "Enter the folder to search (CR2 files will be deleted where a JPG sibling exists): " TARGET_DIR
TARGET_DIR=$(strip_quotes "$TARGET_DIR")
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "ERROR: Folder does not exist: $TARGET_DIR"
    exit 1
fi

TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

echo ""
echo "YOU ARE ABOUT TO DELETE CR2 FILES (and their .xmp sidecars) FROM THIS LOCATION:"
echo "  $TARGET_DIR"
echo "Only CR2 files that have a matching JPG in the same folder will be touched."
read -rp "Are you sure you want to continue? [y/n]: " CONFIRM_1
case "$CONFIRM_1" in
    [Yy]*) ;;
    *) echo "Aborted. No files deleted."; exit 1 ;;
esac

echo ""
echo "Scanning for CR2 files under: $TARGET_DIR"
echo "(this may take a little while for large folders)"

# Collect all .CR2 files (case-insensitive), but NOT .CR2.xmp sidecars —
# -iname '*.CR2' only matches files ending in .CR2/.cr2 etc, never .xmp.
mapfile -d '' -t CR2_FILES < <(find "$TARGET_DIR" -type f -iname "*.CR2" -print0)

TOTAL_CR2=${#CR2_FILES[@]}
echo "Found $TOTAL_CR2 CR2 file(s) in total."
echo ""
echo "Checking which have a JPG sibling (dry run — nothing deleted yet)..."

TO_DELETE=()
TO_SKIP_COUNT=0

for CR2_FILE in "${CR2_FILES[@]}"; do
    DIR=$(dirname "$CR2_FILE")
    FILENAME=$(basename "$CR2_FILE")
    BASE="${FILENAME%.*}"

    JPG_FOUND=""
    for EXT in jpg JPG jpeg JPEG; do
        CANDIDATE="$DIR/$BASE.$EXT"
        if [ -e "$CANDIDATE" ]; then
            JPG_FOUND="$CANDIDATE"
            break
        fi
    done

    if [ -n "$JPG_FOUND" ]; then
        TO_DELETE+=("$CR2_FILE")
    else
        TO_SKIP_COUNT=$((TO_SKIP_COUNT + 1))
    fi
done

DELETE_COUNT=${#TO_DELETE[@]}

echo ""
echo "----------------------------------------"
echo "DRY RUN RESULT:"
echo "  CR2 files with a JPG sibling (WILL be deleted): $DELETE_COUNT"
echo "  CR2 files with NO JPG sibling (will be left alone): $TO_SKIP_COUNT"
echo "----------------------------------------"

if [ "$DELETE_COUNT" -eq 0 ]; then
    echo "Nothing to delete. Exiting."
    exit 0
fi

echo ""
echo "ARE YOU REALLY SURE YOU WANT TO PERMANENTLY DELETE THESE $DELETE_COUNT CR2 FILES"
echo "(AND ANY MATCHING .xmp SIDECARS) FROM:"
echo "  $TARGET_DIR"
echo "THERE IS NO GOING BACK."
read -rp "Type 'yes' to proceed: " CONFIRM_2
if [ "$CONFIRM_2" != "yes" ]; then
    echo "Aborted. No files deleted."
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="$HOME/cr2_delete_log_${TIMESTAMP}.txt"

echo ""
echo "CR2 deletion run started: $(date)" | tee "$LOG_FILE"
echo "Target folder: $TARGET_DIR" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

DELETED_CR2_COUNT=0
DELETED_XMP_COUNT=0

for CR2_FILE in "${TO_DELETE[@]}"; do
    REL_PATH="${CR2_FILE#"$TARGET_DIR"/}"

    rm -f "$CR2_FILE"
    DELETED_CR2_COUNT=$((DELETED_CR2_COUNT + 1))
    echo "DELETED CR2: $REL_PATH" | tee -a "$LOG_FILE"

    # Check for an associated xmp sidecar (e.g. IMG_1234.CR2.xmp) and
    # delete it too, if present.
    for XMP_EXT in xmp XMP; do
        XMP_FILE="$CR2_FILE.$XMP_EXT"
        if [ -e "$XMP_FILE" ]; then
            REL_XMP="${XMP_FILE#"$TARGET_DIR"/}"
            rm -f "$XMP_FILE"
            DELETED_XMP_COUNT=$((DELETED_XMP_COUNT + 1))
            echo "DELETED XMP: $REL_XMP" | tee -a "$LOG_FILE"
        fi
    done
done

echo "----------------------------------------" | tee -a "$LOG_FILE"
echo "Run finished: $(date)" | tee -a "$LOG_FILE"
echo "CR2 files deleted:  $DELETED_CR2_COUNT" | tee -a "$LOG_FILE"
echo "XMP sidecars deleted: $DELETED_XMP_COUNT" | tee -a "$LOG_FILE"
echo "CR2 files left alone (no JPG sibling): $TO_SKIP_COUNT" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"