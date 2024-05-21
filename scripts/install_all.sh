#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo -e "${GREEN}Installing PulseAudio Control...${NC}"
# PulseAudio Control polybar module
# https://github.com/marioortizmanero/polybar-pulseaudio-control?tab=readme-ov-file#other-linux
sudo wget https://raw.githubusercontent.com/marioortizmanero/polybar-pulseaudio-control/master/pulseaudio-control -O /usr/bin/pulseaudio-control
sudo chmod +x /usr/bin/pulseaudio-control
