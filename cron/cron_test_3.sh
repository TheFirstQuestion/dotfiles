set -euo pipefail
IFS=$'\n\t'

/usr/bin/notify-send "Strict Mode!"
/usr/bin/echo "strict mode works" &>/tmp/cron_testing_3.log
