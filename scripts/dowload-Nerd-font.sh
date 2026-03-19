#!/bin/bash

font_nerds_names=(
    "0xProto Nerd Font"
    "Agave Nerd Font"
    "Arimo Nerd Font"
    "Blex mono Nerd Font"
    "Caskaydia Cove Nerd Font"
    "Comic Shanns mono Nerd Font"
    "Cousine Nerd Font"
    "Daddy Time Mono Nerd Font"
    "Droid Sans Mono Nerd Font"
    "Fantasque Sans Mono Nerd Font"
    "Fira Code Nerd Font"
    "Go Mono Nerd Font"
    "Hack Nerd Font"
    "iM Writing Nerd Font"
    "Inconsolata Nerd Font"
    "Intone Mono Nerd Font"
    "Iosevka Nerd Font"
    "JetBrains Mono Nerd Font"
    "liberation nerd font"
    "Martian Mono Nerd Font"
    "Monoid Nerd Font"
    "Mplus Nerd Font"
    "Open Dyslexic Nerd Font"
    "ProFont Nerd Font"
    "RecMono Nerd Font"
    "Space Mono Nerd Font"
    "Ubuntu Mono Nerd Font"
    "Ubuntu Sans Nerd Font"
    "Zed Mono Nerd Font"
)

# install brew if not installed
if ! command -v brew &> /dev/null
then
    echo "Brew not found, installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# update brew and upgrade

brew update
brew upgrade

# Download Nerd Fonts brew install --cask font-<FONT NAME>-nerd-font


# replace spaces with - in font names
for i in "${!font_nerds_names[@]}"; do
    font_nerds_names[$i]=$(echo "${font_nerds_names[$i]}" | tr ' ' '-')
done

for font in "${font_nerds_names[@]}"; do
    echo "Downloading $font"
    brew install --cask font-"$font"
done