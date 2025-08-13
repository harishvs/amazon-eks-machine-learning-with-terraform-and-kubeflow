#!/bin/bash

# Pre-installation script
# Install tmux terminal multiplexer

echo "Installing tmux..."
sudo dnf install -y tmux || sudo yum install -y tmux

echo "tmux installation completed"