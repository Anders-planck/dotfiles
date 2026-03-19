#!/bin/bash

# Variables
REPO_URL="https://github.com/ryanoasis/nerd-fonts"
REPO_DIR="nerd-fonts"
SOURCE_FILE="bin/scripts/lib/fonts.json"
DEST_FILE="font.json"

# Clone the repository with filter and no checkout
git clone -n --depth=1 --filter=tree:0 "$REPO_URL"
REPO_NAME=$(basename "$REPO_URL" .git)
cd "$REPO_NAME" || exit

# Enable sparse checkout
git sparse-checkout init --cone

# Set the sparse-checkout to the target file
git sparse-checkout set --no-cone "$SOURCE_FILE"

# Checkout the file
git checkout

# Copy the fonts.json file to the destination
echo "Updating the font.json file..."
cp "$SOURCE_FILE" "../$DEST_FILE"

# Go back to the parent directory and remove the repository directory
cd ..
rm -rf "$REPO_DIR"

echo "font.json file has been updated."