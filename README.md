# CR2 Cold Storage Backup Script

A simple Bash script for photographers who shoot RAW (or RAW+JPG) and want an
easy way to back up their CR2 RAW files — and their Darktable/Lightroom `.xmp`
sidecar files — to a separate "cold storage" location, without disturbing the
local working folder structure.

## What it does

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
- Runs in **verbose mode**, printing progress to the terminal as it goes
- Writes a timestamped **audit log** (`cr2_copy_log_YYYYMMDD-HHMMSS.txt`)
  into the destination folder, recording every file copied or skipped,
  file sizes, and a final summary

## Requirements

- Bash (Linux or macOS)
- Standard coreutils (`find`, `stat`, `awk`) — all present by default on
  both Linux and macOS

## Usage

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
pair of leading/trailing quotes automatically if present.

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

## Sample output

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
Log saved to: /my-destination/folder/cr2_copy_log_20260724-091203.txt
```

## Important notes

- This script **only copies** — it never deletes anything from the
  source. Deleting local RAW files after backup is a separate, manual
  step, done only after verifying the cold storage copy.
- Before deleting anything locally based on this backup, spot-check the
  file count and open a handful of copied RAWs at random to confirm
  they're intact.
- Re-running the script is safe: it will simply skip files already
  present at the destination and log them as skipped.

## Roadmap / v2 ideas

- Smarter handling of sidecar files: detect when an `.xmp` at the
  destination is an *older, unedited* version (vs. a newer edited one
  from re-visiting a RAW in Darktable), and version the older file
  (`.xmp.1`, `.xmp.2`, etc.) rather than just skipping it.
- Likely detection method: check the `darktable:history_end` value
  inside the xmp (a value of `0` means unedited; anything higher means
  edit history exists), using file size as a cheap first-pass filter
  before reading file contents.

## Disclaimer

Always verify your backups. This script is provided as-is with no
warranty — test it on a small folder first before relying on it for
your full photo library.