# log is a built-in program that we're overwriting, so it goes here rather than in functions
# Note: the program being overwritten is the macOS system command /usr/bin/log, replaced here by a simple echo wrapper (so `log show` and friends are shadowed in the shell); run_script and scripts/backup.sh call this function.
log() {
  echo "$1"
}
