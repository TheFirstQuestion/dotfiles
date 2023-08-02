source $SOURCE_ALL_FUNCTIONS

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

diveIntoDir() {
    # Identify git repo
    if [[ $(git -C "$1" status 2>/dev/null) ]]; then
        # Skip (for now)
        return 0
    fi

    # Process the files in this directory
    processFiles "$1"

    # And recurse downwards
    for thisDirPath in $(find "$1" -type d -maxdepth 1); do
        nameOf1=$(basename $1)
        thisDir=$(basename $thisDirPath)

        # Compare to any ignored dirs
        # Also prevent infinite loop -- don't call on the current directory
        if [[ -n $(echo ".git node_modules compiled __pycache__ build .AppleDouble .npm .sass-cache .ipynb_checkpoints profile_default .AppleDB .AppleDesktop Network Trash Folder Temporary Items .apdisk $nameOf1" | grep "$thisDir") ]]; then
            continue
        fi

        diveIntoDir "$thisDirPath"
    done
}

processFiles() {
    # for thisFilePath in $(find "$1" -type f -maxdepth 1)
    # do
    #     # sed to escape square brackets (via https://superuser.com/a/1383431)
    #     thisFile=$(basename $thisFilePath | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    #
    #     # Compare to any ignored filenames
    #     if [[ -n $(echo ".DS_Store ipython_config.py local.properties google-services.json .DocumentRevisions-V100 .fseventsd .Spotlight-V100 .TemporaryItems .Trashes .VolumeIcon.icns .com.apple.timemachine.donotpresent" | grep "$thisFile") ]]; then
    #         continue
    #     fi
    #
    #     rsync -hmPCa --dry-run "$thisFilePath"
    # done
    rsync -vhmPCa --dry-run --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" "$1" "$DESTINATION"
}

############################## EXECUTION BEGINS HERE #############################

# Confirm that Archive exists and is a valid directory
if [ ! -d "$HOME/Archive" ]; then
    echo -e "${RED}error: ~/Archive not found${NC}"
    exit 1
fi

# Create the timestamped directory
thisBackupLogDir="$HOME/Archive/.backups/$(timestamp)"
mkdir -p "$thisBackupLogDir"

# Redirect output to both terminal and file
exec > >(tee "${thisBackupLogDir}/00_script_output.txt") 2>&1

# Check that (a) a drive is connected and (b) the computer is charging
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Mint
    for i in /mnt/media/Drive*; do
        if [ -d "$i" ]; then
            DESTINATION="$i"
            break
        fi
    done
    # Fedora
    # Mount the drive
    # TODO: make more robust (not throw error if already mounted, mount more drives, etc)
    udisksctl mount -b /dev/sda1
    for i in /run/media/steven/Drive*; do
        if [ -d "$i" ]; then
            DESTINATION="$i"
            break
        fi
    done
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Adapted from https://apple.stackexchange.com/a/116435
    isCharging=$(system_profiler SPPowerDataType | grep -A3 -B7 'Condition' | grep "Charging" | awk '{print $2}')
    if [ $isCharging != "Yes" ]; then
        echo 'error: computer is not currently charging'
        exit 1
    fi
    for i in /Volumes/Drive*; do
        if [ -d "$i" ]; then
            DESTINATION="$i"
            break
        fi
    done
fi

# Confirm that DESTINATION exists and is valid
if [ ! -d "$DESTINATION" ]; then
    echo -e "${RED}error: Destination not found${NC}"
    exit 1
fi

# Log that we are starting, because it may take a while
echo -e "${GREEN}beginning backup to $DESTINATION...${NC}"
log "beginning backup to $DESTINATION"

# Call init-archive script on Archive and Destination, to ensure we have the right directories
run_script init-archive "$HOME/Archive"
run_script init-archive "$DESTINATION"
echo

# Start recursing
rsync -vhmPCa --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" $HOME/Archive/* "$DESTINATION"

echo
echo

# Copy .config directory, in case I mess something up with my dotfiles
rsync -vhmPCa --exclude '*[Cc][Aa][Cc][Hh][Ee]*' --exclude="*google-chrome/*" --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" $HOME/.config/* "$thisBackupLogDir/dot_config"
echo '✔ Copied .config!'
# Copy ~/.local/share/applications, which holds .desktop files to integrate applications into rofi
rsync -vhmPCa --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" $HOME/.local/share/applications/* "$thisBackupLogDir/local_share_applications"
echo '✔ Copied .desktop files!'
# Copy .zsh_history, in case I did some command that I don't remember
rsync -vhmPCa "$HOME/.zsh_history" "$thisBackupLogDir/zsh_history"
echo '✔ Copied zsh history!'

echo
echo

# Back up the list of packages installed
echo -e "${GREEN}Backing up package lists...${NC}"
# Packages installed via dnf
dnf history userinstalled >"${thisBackupLogDir}/dnf_package_list.txt" && echo '✔ Backed up dnf packages!'

# Packages installed via pip
pip freeze >"${thisBackupLogDir}/pip_packages.txt" && echo '✔ Backed up pip packages!'

################################################ Conda environments and packages
source ~/miniconda3/etc/profile.d/conda.sh

# Get the list of Conda environments
envs=$(conda env list --json | jq -r '.envs[]')
# Manually adjust the envs list
envs="${envs//$HOME\/miniconda3/}" # Remove specific path
envs="${envs// \/miniconda3/}"     # Remove leading space and path
envs+=" base"                      # Add base environment

# Iterate through each environment
for env in $envs; do
    env_name=$(basename "$env")
    conda activate "$env_name"
    # Export the environment specifications to a YAML file
    conda env export --name "$env_name" >"${thisBackupLogDir}/conda_environment_${env_name}.yml"
done
echo '✔ Backed up conda envs!'

echo -e "${GREEN}Backed up package lists${NC}"

# Print out size information
echo
echo
echo "Storage:"
echo
df -H "$HOME/Archive/" "$DESTINATION"
echo
du -hsc $HOME/Archive/* | sort -hr | head -n 10

echo
echo

# Copy this backup folder
echo -e "${GREEN}Copying backup folder...${NC}"
rsync -vhmPCa --exclude '*[Cc][Aa][Cc][Hh][Ee]*' --exclude="*google-chrome/*" --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" "$thisBackupLogDir" $DESTINATION/.backups/
echo -e "${GREEN}Copied backup folder${NC}"
echo
echo

notify 'Backup completed!'

echo 'Backup completed!'
echo "👉😎👉"
# TODO: send log files to Keybase

exit 0
