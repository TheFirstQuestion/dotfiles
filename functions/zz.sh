# Jump to a directory like `z`, then start a fresh `claude` session there.
zz() {
  z "$@" && claude
}
