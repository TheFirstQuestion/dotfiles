alert() {
  WHO="$(hostname)"
  WHEN="$(date '+%A, %B %d, %Y, %I:%M:%S %p %Z')"
  keybase chat send sophie_opferman --channel alerts "$WHO -- $WHEN -- $1"
}