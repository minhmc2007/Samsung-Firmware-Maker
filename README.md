# Samsung Firmware AP Packaging Script

## .tar.md5 maker
## Overview

This bash script finds `.img` and `.bin` firmware files in the current directory, compresses them using LZ4, creates a TAR archive of the compressed files, and appends an MD5 checksum to create an Odin-compatible firmware package (`.tar.md5` format).

## Requirements

- Linux/Unix environment
- Required commands:
  - `lz4` (for compression)
  - `md5sum` (for checksum generation)
  - `tar` (for archive creation)

## Features

- Automatically finds and compresses firmware files
- Creates standardized Odin-compatible packages
- Performs cleanup of intermediate files
- Includes comprehensive error handling
- Preserves file permissions in the archive

## Usage

```bash
bash img2AP.sh
```

## Process

1. **Cleanup**: Removes any existing intermediate or output files
2. **Compression**: Finds and compresses `.img` and `.bin` files to `.lz4` format
3. **Archiving**: Creates a TAR archive of the compressed files
4. **Checksum**: Appends MD5 checksum and renames to `.tar.md5`
5. **Final Cleanup**: Removes intermediate compressed files

## Output

The script generates a single output file named `CUSTOM-AP-FIRMWARE.tar.md5` in the current directory.

## Notes

- The script runs in the current directory only
- Set to exit immediately if any command fails
- Uses a temporary file to track created `.lz4` files
