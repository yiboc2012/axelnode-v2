#!/bin/bash
cd /home/rpi/camera_server
export PYTHONUNBUFFERED=1
# Try to set display if available, but don't fail if not
export DISPLAY=:0
xhost +local:$(whoami) > /dev/null 2>&1 || true
python3 camera_server.py
