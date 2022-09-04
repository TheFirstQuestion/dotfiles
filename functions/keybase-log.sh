# log is a built-in program that we're overwriting, so it goes here rather than in functions
log() {
  WHO="$(hostname)"
  WHEN="$(date '+%A, %B %d, %Y, %I:%M:%S %p %Z')"
  keybase chat send sophie_opferman --channel logs "$WHO -- $WHEN -- $1"
}
