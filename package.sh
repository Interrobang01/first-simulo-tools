#!/bin/bash

# Get the parent directory and its parent directory
current_dir="$(dirname "$(realpath "$0")")"
output_dir="$(dirname "$current_dir")"

# Define the output tar.gz file name
package_name="$(basename "$current_dir")"
output_file="$output_dir/${package_name}.tar.gz"

# Create the tar.gz package including only the specified files and folders
tar -czf "$output_file" -C "$current_dir" lib tools package.toml icon.png

echo "Package created at: $output_file"
