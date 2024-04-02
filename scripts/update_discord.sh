#!/bin/bash

# Adapted from https://github.com/Cfell01/discord-updater

LAST=$1

wget -O ~/Downloads/discord.tar.gz "https://discordapp.com/api/download?platform=linux&format=tar.gz"

echo 'Download Complete'

mkdir -p ~/temp_applications

echo 'Temp Directory Created'

tar xzf ~/Downloads/discord.tar.gz -C ~/temp_applications

echo 'Archive Extracted to /temp_applications'

sudo cp -r ~/temp_applications/Discord /usr/share/

if [ $? -eq 0 ]; then
  echo 'Copied Discord pkg to /usr/share'
else
  echo 'FAIL cp to /usr/share'
fi

sudo rm -rfd /usr/share/discord

if [ $? -eq 0 ]; then
  echo 'Removed previous version of Discord'
else
  echo 'Failed to remove existing Discord version'
fi

sudo mv /usr/share/Discord /usr/share/discord

if [ $? -eq 0 ]; then
  echo 'Discord updated successfully'
else
  echo 'Unable to rename /usr/share/Discord to /usr/share/discord. Please rename manually'
fi

sudo rm -rfd ~/Downloads/discord*.tar.gz

if [ $? -eq 0 ]; then
  echo 'Deleted Discord download'
else
  echo 'Failed to delete Discord download'
fi

sudo rm -rfd ~/temp_applications

if [ $? -eq 0 ]; then
  echo 'Deleted temp directory'
else
  echo 'Failed to delete temp directory'
fi

cp /usr/share/discord/discord.desktop ~/.local/share/applications/discord.desktop
