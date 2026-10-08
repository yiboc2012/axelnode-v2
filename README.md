# AxelNode Camera

A Flutter application to view a USB camera stream from a Raspberry Pi 5.

## Features

- **Live Stream**: View MJPEG stream from a USB camera connected to a Raspberry Pi.
- **Configurable IP**: Easily connect to your Pi by entering its IP address.
- **Python Backend**: Lightweight Flask server for the Raspberry Pi.

## Raspberry Pi Setup (Pi 5)

1. Connect your USB camera to the Raspberry Pi.
2. Ensure you have Python installed.
3. Navigate to the `rpi` directory:
   ```bash
   cd rpi
   ```
4. Install the required Python packages:
   ```bash
   pip install -r requirements.txt
   ```
5. Start the camera server:
   ```bash
   python camera_server.py
   ```
   The server will start on `http://<your-pi-ip>:5000/video_feed`.

## Flutter App Setup

1. Ensure you have Flutter installed.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` to start the application.
4. Enter the Raspberry Pi's IP address in the app and tap "Start Stream".

## Project Structure

- `lib/main.dart`: Flutter application code.
- `rpi/`: Python code and requirements for the Raspberry Pi.
- `assets/`: App assets.
