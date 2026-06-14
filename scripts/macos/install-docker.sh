#!/bin/bash
# install-docker.sh - Install Docker on macOS
echo "Download Docker Desktop for macOS:"
if [[ $(uname -m) == "arm64" ]]; then
    echo "  Apple Silicon: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
else
    echo "  Intel: https://desktop.docker.com/mac/main/amd64/Docker.dmg"
fi
echo "Or: brew install --cask docker"