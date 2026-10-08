#!/bin/bash

# Navigate to the script directory
cd "$(dirname "$0")"

# Set environment variables if needed
export CAMERA_INDEX=0
export CAMERA_WIDTH=640
export CAMERA_HEIGHT=480

# Check if pygame is installed, if not, try to install it
python3 -m pip show pygame > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Pygame not found. Installing..."
    python3 -m pip install pygame
fi

# Run the GUI
echo "Starting AXEL NODE Pi GUI..."
python3 axelnode_pi_gui.py
