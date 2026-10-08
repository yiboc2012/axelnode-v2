import cv2
import threading
from flask import Flask, Response, jsonify
import time
import logging
import signal
import sys
import os
import glob
import subprocess
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Initialize Pygame Mixer for beeps if possible
try:
    import pygame
    pygame.mixer.init(frequency=44100, size=-16, channels=1)
    logger.info("Pygame mixer initialized for alerts.")
except Exception as e:
    logger.warning(f"Could not initialize pygame mixer: {e}")

def play_beep_sound(frequency=1000, duration=0.3):
    """Generates and plays a beep sound using Pygame mixer."""
    try:
        sample_rate = 44100
        n_samples = int(sample_rate * duration)
        # Generate sine wave
        t = np.linspace(0, duration, n_samples, False)
        wave = np.sin(2 * np.pi * frequency * t) * 32767
        wave = wave.astype(np.int16)

        sound = pygame.sndarray.make_sound(wave)
        sound.play()
        return True
    except Exception as e:
        logger.error(f"Pygame beep failed: {e}")
        # Fallback to system command
        try:
            subprocess.run(["aplay", "/usr/share/sounds/alsa/Front_Center.wav"], timeout=1)
            return True
        except:
            return False

class CameraManager:
    def __init__(self, camera_index=None):
        self.camera_index = camera_index if camera_index is not None else int(os.environ.get('CAMERA_INDEX', 0))
        self.cap = None
        self.encoded_frame = None
        self.lock = threading.Lock()
        self.new_frame_event = threading.Condition(self.lock)
        self.running = True

        self.width = int(os.environ.get('CAMERA_WIDTH', 1920))
        self.height = int(os.environ.get('CAMERA_HEIGHT', 1080))
        self.fps = max(1, int(os.environ.get('CAMERA_FPS', 100)))

    def _open_camera(self):
        devices = glob.glob("/dev/video*")
        devices.sort(key=lambda x: int(x.replace("/dev/video", "")))

        search_indices = []
        if self.camera_index is not None:
            search_indices.append(self.camera_index)
        search_indices.extend([0, 1, 2, 19, 20, 21, 22])

        for d in devices:
            try:
                idx = int(d.replace("/dev/video", ""))
                if idx not in search_indices:
                    search_indices.append(idx)
            except:
                continue

        for idx in search_indices:
            logger.info(f"Checking camera device at index {idx}...")
            cap = cv2.VideoCapture(idx, cv2.CAP_V4L2)
            if not cap.isOpened():
                cap = cv2.VideoCapture(idx)

            if cap.isOpened():
                cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
                cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
                cap.set(cv2.CAP_PROP_FPS, self.fps)
                ret, frame = cap.read()
                if ret:
                    logger.info(f"Successfully connected to camera at index {idx}")
                    self.camera_index = idx
                    return cap
            cap.release()
        return None

    def capture_loop(self):
        while self.running:
            if self.cap is None:
                self.cap = self._open_camera()
                if self.cap is None:
                    time.sleep(2)
                    continue

            success, frame = self.cap.read()
            if not success:
                self.cap.release()
                self.cap = None
                time.sleep(0.5)
                continue

            ret, buffer = cv2.imencode('.jpg', frame)
            if ret:
                with self.lock:
                    self.encoded_frame = buffer.tobytes()
                    self.new_frame_event.notify_all()
            time.sleep(1.0 / self.fps)

    def stop(self):
        self.running = False
        with self.lock:
            self.new_frame_event.notify_all()
        if self.cap:
            self.cap.release()
            self.cap = None

    def get_latest_encoded_frame(self):
        with self.lock:
            return self.encoded_frame

    def generate_mjpeg_stream(self):
        while self.running:
            with self.new_frame_event:
                if not self.new_frame_event.wait(timeout=1.0):
                    continue
                frame_bytes = self.encoded_frame
            if frame_bytes and self.running:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

app = Flask(__name__)
camera_manager = CameraManager()

@app.route('/')
def index():
    return "AXEL NODE Smart Cart Server - OK"

@app.route('/alert', methods=['POST'])
def sound_alert():
    """Triggers a beep alert on the Raspberry Pi."""
    success = play_beep_sound()
    if success:
        return jsonify({"status": "alert_triggered"}), 200
    else:
        return jsonify({"error": "Failed to play sound"}), 500

@app.route('/weight')
def get_weight():
    import random
    simulated_weight = round(random.uniform(5.0, 50.0), 2)
    return jsonify({"weight": simulated_weight, "unit": "kg", "timestamp": time.time()})

@app.route('/status')
def status():
    return jsonify({
        "status": "online" if camera_manager.cap is not None else "offline",
        "camera_index": camera_manager.camera_index,
        "resolution": f"{camera_manager.width}x{camera_manager.height}",
        "fps": camera_manager.fps
    })

@app.route('/video_feed')
def video_feed():
    return Response(camera_manager.generate_mjpeg_stream(), mimetype='multipart/x-mixed-replace; boundary=frame')

@app.route('/snapshot')
def snapshot():
    frame_bytes = camera_manager.get_latest_encoded_frame()
    if frame_bytes is None: return "No frame", 404
    return Response(frame_bytes, mimetype='image/jpeg')

def signal_handler(sig, frame):
    camera_manager.stop()
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    t = threading.Thread(target=camera_manager.capture_loop, daemon=True)
    t.start()
    app.run(host='0.0.0.0', port=5000, threaded=True, use_reloader=False)
