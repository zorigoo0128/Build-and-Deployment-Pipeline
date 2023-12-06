# Replace '/path/to/your/directory' with the actual directory path where you want to start the search
directory="$ARCHIVE_DIR/LinuxServer/"
file_name="Server-Linux"

# Use the find command to search for files
found_files=$(find "$directory" -type f -name "*$file_name*")

# Capture the first found file's path
first_file_path=$(echo "$found_files" | head -n 1)

# Remove the specified substring from the found file paths
cleaned_path=$(echo "$first_file_path" | sed "s|$directory||")

echo "$cleaned_path"