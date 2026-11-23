IFS=$'\n\t'

source /home/steven/dotfiles/scripts/init-env-vars.sh
/usr/bin/zsh /home/steven/dotfiles/functions/source-all-functions.sh

# Check the last time the backup was run
# Backup script creates "$HOME/Archive/.backups/$(timestamp)" directory
# So, parse the timestamp from the most recent backup directory
latest_folder_path=$(ls -trd "$HOME/Archive/.backups"/*/ 2>/dev/null | tail -n 1)
latest_folder_name=$(basename "$latest_folder_path")

# Split into date and time parts
date_part="${latest_folder_name:0:10}"
time_part="${latest_folder_name:11:16}"

# Convert time part to 24-hour format
hour="${time_part:1:2}"
minute="${time_part:4:6}"
if [ "${time_part:0:1}" = "p" ] && [ hour != "12" ]; then
  ((hour += 12))
fi
time_24h="${hour}:${minute}"

# Parse the date and time parts
backup_date=$(date -d "$date_part $time_24h" +"%Y-%m-%d %H:%M:%S")
backup_timestamp=$(date -d "$backup_date" +%s)

# Get the current date and time
now=$(date +"%Y-%m-%d %H:%M:%S")
now_timestamp=$(date -d "$now" +%s)

# Calculate the time between the last backup and now
time_between=$((now_timestamp - backup_timestamp))

# If the time between the last backup and now is less than 1 hour, exit
if [ "$time_between" -lt 86400 ]; then
  echo 'Backup was run less than an hour ago. Exiting!'
  exit 0
else
  echo 'Backup was run more than an hour ago. Running backup script...'
  run_script backup
  exit 0
fi
