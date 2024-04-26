set -euo pipefail
IFS=$'\n\t'

source /home/steven/dotfiles/scripts/init-env-vars.sh
/usr/bin/zsh /home/steven/dotfiles/functions/source-all-functions.sh
/usr/bin/notify-send "Sourcing Functions!" "$(datestamp)"
/usr/bin/echo "sourcing functions works" "$(datestamp)" &>/tmp/cron_testing_4.log
