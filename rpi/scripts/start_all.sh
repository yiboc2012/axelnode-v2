#!/bin/bash
# AXEL NODE Startup Script

echo "------------------------------------------"
echo "   AXEL NODE SMART CART ECOSYSTEM       "
echo "------------------------------------------"

# Full path to project
PROJECT_DIR="/home/rpi/axelnode_rpi"
cd "$PROJECT_DIR" || exit

# Kill old instances
echo "Stopping old processes..."
pkill -f camera_server.py
pkill -f axelnode_pi_gui.py
sleep 1

echo "Starting AXEL NODE (GUI + Integrated Server)..."
export DISPLAY=:0
# Run GUI in foreground - now handles its own camera and server
python3 gui/axelnode_pi_gui.py

echo "GUI closed. Done."
sleep 2
