# Do a fresh pull and install, so everything is updated and symlinked properly
dotbot() {
    git -C "$DOTFILE_DIR" pull origin main
    $DOTFILE_DIR/install --plugin-dir $DOTFILE_DIR/plugins
}