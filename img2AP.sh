#!/bin/bash

# Script to find .img and .bin files, compress them to .lz4,
# create a tar archive of the .lz4 files, and then append
# an MD5 checksum to the tar file, renaming it to .tar.md5 (Odin style).

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Base name for the output TAR and TAR.MD5 files
readonly OUTPUT_TAR_BASENAME="CUSTOM-AP-FIRMWARE"

# --- Check for required commands ---
if ! command -v lz4 &> /dev/null; then
    echo "Error: lz4 command could not be found. Please install lz4." >&2
    exit 1
fi
if ! command -v md5sum &> /dev/null; then
    echo "Error: md5sum command could not be found. Please install coreutils or a similar package." >&2
    exit 1
fi
if ! command -v tar &> /dev/null; then
    echo "Error: tar command could not be found." >&2
    exit 1
fi

# --- 1. Initial Cleanup in Current Directory ---
echo "Cleaning up old intermediate and output files from the current directory..."
find . -maxdepth 1 -type f -name "*.lz4" -delete
find . -maxdepth 1 -type f -name "${OUTPUT_TAR_BASENAME}.tar" -delete
find . -maxdepth 1 -type f -name "${OUTPUT_TAR_BASENAME}.tar.md5" -delete
echo "Cleanup complete."

# --- 2. Find and Compress *.img and *.bin files ---
echo "Searching for .img and .bin files and compressing them to .lz4 format..."

lz4_created_files_list=$(mktemp)
trap 'rm -f "$lz4_created_files_list"' EXIT

processed_file_count=0

# Use process substitution here: done < <(find ...)
# This ensures 'processed_file_count' is updated in the current shell.
while IFS= read -r -d $'\0' source_file; do
    base_filename=$(basename "$source_file")
    lz4_output_filename="./${base_filename}.lz4"

    echo "Compressing '$source_file' to '$lz4_output_filename'..."
    if lz4 -f -c "$source_file" > "$lz4_output_filename"; then
        echo "${base_filename}.lz4" >> "$lz4_created_files_list"
        processed_file_count=$((processed_file_count + 1)) # This will now be updated in the correct scope
    else
        echo "Warning: Failed to compress '$source_file'. Skipping." >&2
        rm -f "$lz4_output_filename"
    fi
done < <(find . -type f \( -name "*.img" -o -name "*.bin" \) -print0) # MODIFIED LINE

# Check if any files were actually processed and compressed
if [ "$processed_file_count" -eq 0 ]; then
    echo "No .img or .bin files were found to process in the current directory or subdirectories."
    exit 0
fi

sort -u "$lz4_created_files_list" -o "$lz4_created_files_list"

if [ ! -s "$lz4_created_files_list" ]; then
    echo "Error: No .lz4 files were successfully listed for TAR (e.g., all compressions failed or list is empty). Cannot create TAR." >&2
    exit 1
fi

echo "Successfully processed $processed_file_count .img/.bin file(s). Unique .lz4 files generated for archiving might be fewer if basenames clashed."

# --- 3. Create TAR Archive of .lz4 files ---
tar_output_file="./${OUTPUT_TAR_BASENAME}.tar"
echo "Creating TAR archive '$tar_output_file' from the generated .lz4 files..."

tar --create \
    --file="$tar_output_file" \
    --format=gnu \
    --blocking-factor=20 \
    --quoting-style=escape \
    --owner=0 \
    --group=0 \
    --mode='u=rw,go=r' \
    --no-recursion \
    -C . \
    -T "$lz4_created_files_list"

echo "TAR archive created: $tar_output_file"

# --- 4. Append MD5 Checksum to TAR and Rename ---
md5_output_file="./${OUTPUT_TAR_BASENAME}.tar.md5"
echo "Calculating MD5 checksum for '$tar_output_file' and appending it..."

if md5sum "$tar_output_file" >> "$tar_output_file"; then
    echo "MD5 checksum appended. Renaming '$tar_output_file' to '$md5_output_file'..."
    mv "$tar_output_file" "$md5_output_file"
    echo "Final file created: $md5_output_file"
else
    echo "Error: Failed to calculate or append MD5 checksum for '$tar_output_file'." >&2
    rm -f "$tar_output_file"
    exit 1
fi

# --- 5. Final Cleanup of Intermediate .lz4 Files ---
echo "Cleaning up intermediate .lz4 files from the current directory..."
while IFS= read -r lz4_file_to_delete; do
    if [ -n "$lz4_file_to_delete" ]; then
      delete_target="./$lz4_file_to_delete"
      if [ -f "$delete_target" ]; then
          rm -f "$delete_target"
          echo "Deleted intermediate file: $delete_target"
      else
          echo "Warning: Intermediate file '$delete_target' listed for deletion was not found." >&2
      fi
    fi
done < "$lz4_created_files_list"

echo "Script finished successfully."
