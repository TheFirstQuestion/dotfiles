# Play a sound (helpful to chain after a long-running command)
notify() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        paplay "$HOME/.minecraft/assets/objects/01/0113fbf3e047f4fa4ef680ae7781326427e30f02"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        afplay /System/Library/Sounds/Submarine.aiff -v 10
    fi
}