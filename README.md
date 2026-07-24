# RAW Photo Backup Toolkit

A pair of simple Bash scripts for photographers who shoot RAW (or RAW+JPG)
and want an easy, safe way to:

1. **Back up** CR2 RAW files (and their `.xmp` sidecars) to a separate
   "cold storage" location, without disturbing the local folder structure
2. **Free up local space** afterwards by deleting local CR2s that already
   have a JPG sibling — leaving RAW-only folders completely untouched

Together they support a "cold storage RAWs, work locally with JPGs"
workflow: keep every RAW safe on a backup drive, but only keep the RAWs
you actually still need on your working/laptop drive.

## Scripts

| Script | Purpose |
|---|---|
| `copy_cr2_backup.sh` | Copies all CR2 + xmp files to a backup location, preserving folder structure |
| `delete_cr2_with_jpg_backup.sh` | Deletes local CR2s (+ xmp) *only* where a matching JPG already exists |

**Recommended order:** always run the copy script first, verify the
backup, *then* run the delete script — never the other way round.

## Requirements

- Bash (Linux or macOS)
- Standard coreutils (`find`, `stat`, `awk`) — all present by default on
  both Linux and macOS

---

## 1. `copy_cr2_backup.sh`

### What it does

- Prompts you for a **source** directory and a **destination** directory
- Recursively searches the source for any file with `cr2` anywhere in its
  name (case-insensitive), which catches:
  - `.CR2` / `.cr2` RAW files
  - `.CR2.xmp` / `.cr2.xmp` sidecar files (e.g. Darktable naming convention)
- Copies matching files to the destination, **preserving the original
  folder structure** (no flattening, so there's no risk of same-named
  files from different shoots/cameras overwriting one another)
- **Never overwrites** an existing file at the destination — if a match
  already exists there, it's skipped and logged instead
- Asks for confirmation before creating a missing destination folder, and
  again before the copy runs (both showing the resolved paths) — catches
  typos before anything happens
- Runs in **verbose mode**, printing progress to the terminal as it goes
- Writes a timestamped **audit log** (`cr2_copy_log_YYYYMMDD-HHMMSS.txt`)
  into the destination folder, recording every file copied or skipped,
  file sizes, and a final summary

### Usage

```bash
chmod +x copy_cr2_backup.sh
./copy_cr2_backup.sh
```

You'll be prompted for two paths:

```
Enter SOURCE directory (folder to search):
Enter DESTINATION directory (cold storage root):
```

Paths with spaces or special characters (e.g. apostrophes) are fine —
you can type them plain or wrapped in quotes; the script strips a single
pair of leading/trailing quotes automatically if present, and doesn't
use `eval`, so apostrophes in the path (e.g. `Claude's`) won't break it.

Example:

```
Enter SOURCE directory (folder to search): /my/source/folder
Enter DESTINATION directory (cold storage root): /my/destination/folder
```

If the destination folder doesn't exist yet, you'll be asked to confirm
before it's created:

```
Destination folder does not exist: /my/destination/folder
Would you like to create it? [y/n]:
```

Either way, you'll then get a final confirmation before anything is
copied — a last chance to catch a typo in either path:

```
Please confirm before proceeding:
  Source:      /my/source/folder
  Destination: /my/destination/folder
Proceed? [y/n]:
```

### Sample output

```
CR2 backup run started: Fri 24 Jul 2026 09:12:03 BST
Source:      /my/source/folder
Destination: /my/destination/folder
----------------------------------------
COPIED: 2026-07-20-canal-walk/IMG_5669.CR2 (25184304 bytes)
COPIED: 2026-07-20-canal-walk/IMG_5669.CR2.xmp (1602 bytes)
SKIPPED (already exists): 2026-06-14-market/IMG_4220.CR2
----------------------------------------
Run finished: Fri 24 Jul 2026 09:14:51 BST
Files copied:  842
Files skipped (already existed): 1204
Total size copied: 21384.60 MB
Log saved to: /my/destination/folder/cr2_copy_log_20260724-091203.txt
```

### Important notes

- This script **only copies** — it never deletes anything from the
  source.
- Before running the delete script, spot-check the file count and open a
  handful of copied RAWs at random to confirm they're intact.
- Re-running the script is safe: it will simply skip files already
  present at the destination and log them as skipped.

---

## 2. `delete_cr2_with_jpg_backup.sh`

### What it does

- Prompts you for a **target folder** to clean up
- Validates the folder exists
- Recursively searches for `.CR2` files only (never touches `.xmp`
  sidecars directly — those are only removed alongside their CR2, see
  below)
- Runs a **dry-run preview** first: checks every CR2 for a matching JPG
  sibling in the same folder (matching case-insensitively against `.jpg`,
  `.JPG`, `.jpeg`, `.JPEG`) and reports how many would be deleted vs left
  alone — **nothing is deleted at this stage**
- Requires **two confirmations**, the second shown only after the dry-run
  counts are known, and requiring you to type `yes` in full
- For each CR2 with a JPG sibling: deletes the CR2, then checks for and
  deletes a matching `.xmp`/`.XMP` sidecar if one exists
- CR2 files with **no** JPG sibling are left completely untouched
- Writes a timestamped **audit log**
  (`cr2_delete_log_YYYYMMDD-HHMMSS.txt`) to your home folder (kept
  separate from the folder being cleaned up), recording every deletion
  and a final summary

### Usage

```bash
chmod +x delete_cr2_with_jpg_backup.sh
./delete_cr2_with_jpg_backup.sh
```

```
Enter the folder to search (CR2 files will be deleted where a JPG sibling exists):
```

You'll then see two warnings before anything happens:

```
YOU ARE ABOUT TO DELETE CR2 FILES (and their .xmp sidecars) FROM THIS LOCATION:
  /my/target/folder
Only CR2 files that have a matching JPG in the same folder will be touched.
Are you sure you want to continue? [y/n]:
```

```
DRY RUN RESULT:
  CR2 files with a JPG sibling (WILL be deleted): 842
  CR2 files with NO JPG sibling (will be left alone): 156
----------------------------------------

ARE YOU REALLY SURE YOU WANT TO PERMANENTLY DELETE THESE 842 CR2 FILES
(AND ANY MATCHING .xmp SIDECARS) FROM:
  /my/target/folder
THERE IS NO GOING BACK.
Type 'yes' to proceed:
```

### Sample output

```
CR2 deletion run started: Fri 24 Jul 2026 16:37:41 BST
Target folder: /my/target/folder
----------------------------------------
DELETED CR2: 2026-07-20-canal-walk/IMG_5669.CR2
DELETED XMP: 2026-07-20-canal-walk/IMG_5669.CR2.xmp
DELETED CR2: 2026-06-14-market/IMG_4220.CR2
----------------------------------------
Run finished: Fri 24 Jul 2026 16:37:41 BST
CR2 files deleted:  842
XMP sidecars deleted: 601
CR2 files left alone (no JPG sibling): 156
Log saved to: /my/target/folder/cr2_delete_log_20260724-163741.txt
```

### Important notes

- **Only run this after** confirming your CR2 backup (via
  `copy_cr2_backup.sh` or otherwise) is complete and verified — this
  script permanently deletes local files.
- Folders containing RAW-only files (no JPG) are never touched.
- Test on a small/sample folder first before pointing it at your full
  library.

---

## Roadmap / future ideas

- **Smarter sidecar handling on copy:** detect when an `.xmp` at the
  destination is an *older, unedited* version (vs. a newer edited one
  from re-visiting a RAW in Darktable), and version the older file
  (`.xmp.1`, `.xmp.2`, etc.) rather than just skipping it. Likely
  detection method: check the `darktable:history_end` value inside the
  xmp (a value of `0` means unedited; anything higher means edit history
  exists), using file size as a cheap first-pass filter before reading
  file contents.
- **JPG + xmp backup variant:** apply the same incremental copy logic
  (preserve structure, skip existing, versioned sidecars) to JPG +
  sidecar backups, since the underlying mechanics are the same.

## Disclaimer

Always verify your backups before deleting anything locally. These
scripts are provided as-is with no warranty — test on a small folder
first before relying on them for your full photo library.