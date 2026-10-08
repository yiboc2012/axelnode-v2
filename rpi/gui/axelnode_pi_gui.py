import pygame
import cv2
import sys
import os
import time
import threading
import numpy as np
from flask import Flask, Response, jsonify
import random
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Colors (Exact Flutter Theme)
GREEN_ACCENT = (0, 255, 170)
DARK_SURFACE = (10, 14, 10)
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GREY = (158, 158, 158)
RED = (255, 82, 82)
BLUE_ACCENT = (68, 138, 255)
CYAN = (0, 255, 255)

class AxelNodeGUI:
    def __init__(self):
        pygame.init()
        # Initialize mixer for local beep
        try:
            pygame.mixer.init(frequency=44100, size=-16, channels=1)
        except:
            pass

        # Resolution detection (1024x600)
        info = pygame.display.Info()
        self.screen_width = info.current_w
        self.screen_height = info.current_h
        if self.screen_width <= 0: self.screen_width = 1024
        if self.screen_height <= 0: self.screen_height = 600

        try:
            self.screen = pygame.display.set_mode((self.screen_width, self.screen_height), pygame.FULLSCREEN)
        except:
            self.screen = pygame.display.set_mode((self.screen_width, self.screen_height))

        # Scaling based on 1024x600 reference
        self.sw = self.screen_width / 1024.0
        self.sh = self.screen_height / 600.0

        pygame.display.set_caption("AXEL NODE - Smart Cart")
        self.clock = pygame.time.Clock()
        self.running = True

        # States: SPLASH, STATUS, DRIVE, CART_AI, VISION_AI
        self.state = "SPLASH"

        # Fonts (Made SMALLER as requested)
        self.font_title = pygame.font.SysFont('Arial', int(50 * self.sh), bold=True)
        self.font_header = pygame.font.SysFont('Arial', int(36 * self.sh), bold=True)
        self.font_medium = pygame.font.SysFont('Arial', int(22 * self.sh), bold=True)
        self.font_small = pygame.font.SysFont('Arial', int(16 * self.sh), bold=True)
        self.font_nano = pygame.font.SysFont('Arial', int(13 * self.sh), bold=True)

        # Camera & AI Data
        self.camera_frame = None
        self.encoded_frame = None
        self.camera_lock = threading.Lock()
        self.new_frame_event = threading.Condition(self.camera_lock)
        self.detections = []
        self.last_beep_time = 0

        # Navigation
        self.nav_height = int(60 * self.sh)
        self.tabs = ["Status", "Drive", "Cart AI", "Vision AI"]
        self.nav_buttons = []

        # Log History
        self.log_history = []

        # Plant Health Simulation
        self.plant_health = 0
        self.plant_recommendation = "Awaiting scan..."
        self.is_plant_detected = False

        # Camera Capture Config
        self.cap_width = 1920
        self.cap_height = 1080
        self.cap_fps = 100

    def trigger_beep(self):
        """Internal beep logic (can be expanded)."""
        current_time = time.time()
        if current_time - self.last_beep_time > 2.0:
            self.last_beep_time = current_time
            # Play sound if implemented

    def start_camera_and_server(self):
        # 1. Start Capture Thread (Direct OpenCV)
        def _capture_loop():
            cap = cv2.VideoCapture(0, cv2.CAP_V4L2)
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.cap_width)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.cap_height)
            cap.set(cv2.CAP_PROP_FPS, self.cap_fps)
            cap.set(cv2.CAP_PROP_BUFFERSIZE, 1) # Minimal latency

            face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
            lower_green = np.array([35, 40, 40])
            upper_green = np.array([85, 255, 255])

            while self.running:
                ret, frame = cap.read()
                if not ret:
                    time.sleep(0.1)
                    continue

                proc_frame = frame.copy()
                new_detections = []
                plant_found = False

                # AI Processing only if NOT in DRIVE mode to maintain max FPS
                if self.state != "DRIVE":
                    gray = cv2.cvtColor(proc_frame, cv2.COLOR_BGR2GRAY)

                    # Face Detection
                    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
                    for (x, y, w, h) in faces:
                        if self.state == "CART_AI":
                            cv2.rectangle(proc_frame, (x, y), (x+w, y+h), RED, 3)
                            cv2.putText(proc_frame, "USER IDENTIFIED", (x, y-15), cv2.FONT_HERSHEY_SIMPLEX, 0.8, RED, 2)
                        new_detections.append("USER DETECTED")

                    # Plant Detection
                    hsv = cv2.cvtColor(proc_frame, cv2.COLOR_BGR2HSV)
                    mask = cv2.inRange(hsv, lower_green, upper_green)
                    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                    for cnt in contours:
                        if cv2.contourArea(cnt) > 15000:
                            x, y, w, h = cv2.boundingRect(cnt)
                            plant_found = True
                            if self.state in ["CART_AI", "VISION_AI"]:
                                cv2.rectangle(proc_frame, (x, y), (x+w, y+h), GREEN_ACCENT, 3)
                                cv2.putText(proc_frame, "ORGANIC TARGET", (x, y-15), cv2.FONT_HERSHEY_SIMPLEX, 0.8, GREEN_ACCENT, 2)
                            new_detections.append("ORGANIC ACQUIRED")

                # Prepare Display Frame
                target_h = int(self.screen_height * 0.6)
                target_w = int(target_h * (16/9))
                display_frame = cv2.resize(proc_frame, (target_w, target_h), interpolation=cv2.INTER_NEAREST)
                rgb_frame = cv2.cvtColor(display_frame, cv2.COLOR_BGR2RGB)
                surf = pygame.surfarray.make_surface(rgb_frame.swapaxes(0, 1))

                # Encode for remote stream
                _, buffer = cv2.imencode('.jpg', cv2.resize(frame, (640, 360)))
                encoded = buffer.tobytes()

                with self.camera_lock:
                    self.camera_frame = surf
                    self.encoded_frame = encoded
                    self.detections = new_detections
                    self.is_plant_detected = plant_found
                    if plant_found:
                        self.plant_health = random.randint(67, 76)
                        self.plant_recommendation = "Growth stable. Maintain nitrogen levels."

                    if new_detections:
                        t = time.strftime("%H:%M:%S")
                        for d in new_detections:
                            if not self.log_history or d != self.log_history[-1].split("] ")[1]:
                                self.log_history.append(f"[{t}] {d}")
                                if len(self.log_history) > 15: self.log_history.pop(0)

                    self.new_frame_event.notify_all()

            cap.release()

        # 2. Start Flask Server Thread (In-Process)
        server_app = Flask(__name__)

        @server_app.route('/video_feed')
        def video_feed():
            def generate():
                while self.running:
                    with self.new_frame_event:
                        self.new_frame_event.wait()
                        frame = self.encoded_frame
                    if frame:
                        yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
            return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

        @server_app.route('/snapshot')
        def snapshot():
            with self.camera_lock:
                frame = self.encoded_frame
            if frame:
                return Response(frame, mimetype='image/jpeg')
            return "No frame", 404

        @server_app.route('/status')
        def status():
            return jsonify({"status": "online", "fps": self.cap_fps, "res": "1080p"})

        def _run_server():
            server_app.run(host='0.0.0.0', port=5000, threaded=True, use_reloader=False)

        # Launch Threads
        threading.Thread(target=_capture_loop, daemon=True).start()
        threading.Thread(target=_run_server, daemon=True).start()

    def draw_nav_bar(self):
        rect = pygame.Rect(0, self.screen_height - self.nav_height, self.screen_width, self.nav_height)
        pygame.draw.rect(self.screen, (20, 20, 20), rect)
        pygame.draw.line(self.screen, (40, 40, 40), (0, rect.top), (self.screen_width, rect.top), 1)

        tab_w = self.screen_width // len(self.tabs)
        self.nav_buttons = []

        for i, tab in enumerate(self.tabs):
            btn_rect = pygame.Rect(i * tab_w, rect.top, tab_w, self.nav_height)
            self.nav_buttons.append((btn_rect, tab.upper()))
            is_active = (self.state == tab.upper().replace(" ", "_")) or (self.state == "STATUS" and tab == "Status")
            color = GREEN_ACCENT if is_active else GREY
            pygame.draw.circle(self.screen, color, (btn_rect.centerx, btn_rect.top + 15 * self.sh), 4)
            text_surf = self.font_nano.render(tab.upper(), True, color)
            text_rect = text_surf.get_rect(center=(btn_rect.centerx, btn_rect.top + 40 * self.sh))
            self.screen.blit(text_surf, text_rect)

    def draw_back_button(self):
        self.btn_back = pygame.Rect(20, 20, int(90 * self.sw), int(40 * self.sh))
        pygame.draw.rect(self.screen, (30, 30, 30), self.btn_back, border_radius=int(10 * self.sh))
        pygame.draw.rect(self.screen, GREY, self.btn_back, 1, border_radius=int(10 * self.sh))
        t = self.font_nano.render("BACK", True, WHITE)
        self.screen.blit(t, t.get_rect(center=self.btn_back.center))

    def draw_splash(self):
        for i in range(self.screen_height):
            ratio = i / self.screen_height
            g = int(40 * (1 - ratio))
            self.screen.fill((0, g, 0), (0, i, self.screen_width, 1))

        cx, cy = self.screen_width // 2, self.screen_height // 2
        logo_y = int(120 * self.sh)
        logo_r = int(70 * self.sh)
        for r in range(logo_r + 15, logo_r, -1):
            alpha = int(40 * (1 - (r - logo_r) / 15))
            glow = pygame.Surface((r*2, r*2), pygame.SRCALPHA)
            pygame.draw.circle(glow, (*GREEN_ACCENT, alpha), (r, r), r)
            self.screen.blit(glow, (cx - r, logo_y - r))

        pygame.draw.circle(self.screen, GREEN_ACCENT, (cx, logo_y), logo_r, 3)
        pygame.draw.rect(self.screen, GREEN_ACCENT, (cx - 20, logo_y - 15, 40, 30), 3)

        title_surf = self.font_header.render("AXEL NODE", True, GREEN_ACCENT)
        self.screen.blit(title_surf, title_surf.get_rect(center=(cx, int(230 * self.sh))))

        sub_surf = self.font_nano.render("SMART CART ECOSYSTEM", True, GREY)
        self.screen.blit(sub_surf, sub_surf.get_rect(center=(cx, int(270 * self.sh))))

        # ENTER BUTTON
        btn_w, btn_h = int(400 * self.sw), int(60 * self.sh)
        self.btn_enter = pygame.Rect(cx - btn_w//2, self.screen_height - int(200 * self.sh), btn_w, btn_h)
        pygame.draw.rect(self.screen, GREEN_ACCENT, self.btn_enter, border_radius=int(15 * self.sh))
        btn_text = self.font_medium.render("ENTER CONTROL COCKPIT", True, BLACK)
        self.screen.blit(btn_text, btn_text.get_rect(center=self.btn_enter.center))

        # EXIT BUTTON
        self.btn_exit = pygame.Rect(cx - btn_w//2, self.screen_height - int(120 * self.sh), btn_w, btn_h)
        pygame.draw.rect(self.screen, RED, self.btn_exit, border_radius=int(15 * self.sh))
        exit_text = self.font_medium.render("EXIT APP", True, WHITE)
        self.screen.blit(exit_text, exit_text.get_rect(center=self.btn_exit.center))

    def draw_status(self):
        self.screen.fill(BLACK)
        self.draw_back_button()
        t = self.font_medium.render("SYSTEM STATUS", True, GREEN_ACCENT)
        self.screen.blit(t, (140, 25))

        card = pygame.Rect(40, 80, self.screen_width - 80, 240)
        pygame.draw.rect(self.screen, (20, 20, 20), card, border_radius=15)

        y = 110
        items = [("NETWORK", "CONNECTED"), ("PI IP", "LOCAL HOST"), ("SENSORS", "ACTIVE"), ("AI ENGINE", "INTEGRATED")]
        for label, val in items:
            l_surf = self.font_small.render(label, True, GREY)
            v_surf = self.font_small.render(val, True, WHITE)
            self.screen.blit(l_surf, (70, y))
            self.screen.blit(v_surf, (card.right - v_surf.get_width() - 30, y))
            y += 50
        self.draw_nav_bar()

    def draw_drive(self):
        self.screen.fill(BLACK)
        self.draw_back_button()
        with self.camera_lock:
            if self.camera_frame:
                rect = self.camera_frame.get_rect(center=(self.screen_width//2, self.screen_height//2 - 20))
                self.screen.blit(self.camera_frame, rect)
                pygame.draw.rect(self.screen, GREEN_ACCENT, rect.inflate(4, 4), 2)

        # FPS Counter
        fps = self.clock.get_fps()
        fps_surf = self.font_nano.render(f"LIVE FEED: {fps:.1f} FPS", True, GREEN_ACCENT)
        self.screen.blit(fps_surf, (self.screen_width - 150, 25))
        self.draw_nav_bar()

    def draw_cart_ai(self):
        self.screen.fill(BLACK)
        self.draw_back_button()
        t = self.font_medium.render("CART AI: HOME SCANNER", True, GREEN_ACCENT)
        self.screen.blit(t, (140, 25))

        with self.camera_lock:
            if self.camera_frame:
                rect = self.camera_frame.get_rect(topleft=(40, 80))
                self.screen.blit(self.camera_frame, rect)

                # Scanlines overlay
                scan_y = int((time.time() * 100) % rect.height)
                pygame.draw.line(self.screen, (0, 100, 0), (rect.left, rect.top + scan_y), (rect.right, rect.top + scan_y), 1)

                log_rect = pygame.Rect(rect.right + 30, 80, self.screen_width - rect.right - 70, rect.height)
                pygame.draw.rect(self.screen, (15, 15, 15), log_rect, border_radius=10)
                y = log_rect.top + 10
                t_title = self.font_nano.render("HOME OBJECT LOG", True, GREY)
                self.screen.blit(t_title, (log_rect.left + 10, y))
                y += 25
                for log in self.log_history[-10:]:
                    color = RED if "HAZARD" in log else GREEN_ACCENT
                    if "DEVICE" in log: color = CYAN
                    if "SURFACE" in log: color = BLUE_ACCENT
                    t_log = self.font_nano.render(log, True, color)
                    self.screen.blit(t_log, (log_rect.left + 10, y))
                    y += 18
        self.draw_nav_bar()

    def draw_vision_ai(self):
        self.screen.fill(BLACK)
        self.draw_back_button()
        t = self.font_medium.render("VISION AI: BIO-SCANNER", True, BLUE_ACCENT)
        self.screen.blit(t, (140, 25))

        with self.camera_lock:
            if self.camera_frame:
                # Left Side: Camera Feed
                cam_rect = self.camera_frame.get_rect(topleft=(40, 80))
                self.screen.blit(self.camera_frame, cam_rect)
                pygame.draw.rect(self.screen, BLUE_ACCENT, cam_rect, 2)

                # Right Side: Health Dashboard
                dash_rect = pygame.Rect(cam_rect.right + 30, 80, self.screen_width - cam_rect.right - 70, cam_rect.height)
                pygame.draw.rect(self.screen, (15, 15, 25), dash_rect, border_radius=15)

                y = dash_rect.top + 20
                h_title = self.font_small.render("PLANT HEALTH INDEX", True, GREY)
                self.screen.blit(h_title, (dash_rect.left + 20, y))

                y += 40
                health_color = GREEN_ACCENT if self.is_plant_detected else GREY
                score_text = f"{self.plant_health}%" if self.is_plant_detected else "---%"
                h_val = self.font_title.render(score_text, True, health_color)
                self.screen.blit(h_val, (dash_rect.left + 20, y))

                # Health Bar
                y += 70
                bar_bg = pygame.Rect(dash_rect.left + 20, y, dash_rect.width - 40, 20)
                pygame.draw.rect(self.screen, (30, 30, 50), bar_bg, border_radius=10)
                if self.is_plant_detected:
                    fill_w = int((bar_bg.width * self.plant_health) / 100)
                    bar_fill = pygame.Rect(bar_bg.left, bar_bg.top, fill_w, 20)
                    pygame.draw.rect(self.screen, health_color, bar_fill, border_radius=10)

                y += 50
                r_title = self.font_nano.render("AI RECOMMENDATION:", True, BLUE_ACCENT)
                self.screen.blit(r_title, (dash_rect.left + 20, y))

                y += 25
                rec_text = self.plant_recommendation
                r_val = self.font_small.render(rec_text, True, WHITE)
                self.screen.blit(r_val, (dash_rect.left + 20, y))

                # Status Indicator
                status_color = GREEN_ACCENT if self.is_plant_detected else RED
                status_text = "TARGET ACQUIRED" if self.is_plant_detected else "SEARCHING..."
                s_surf = self.font_nano.render(status_text, True, status_color)
                s_rect = s_surf.get_rect(center=(dash_rect.centerx, dash_rect.bottom - 40))
                self.screen.blit(s_surf, s_rect)

        self.draw_nav_bar()

    def handle_click(self, pos):
        if self.state == "SPLASH":
            if self.btn_enter.collidepoint(pos):
                self.state = "STATUS"
                return
            if self.btn_exit.collidepoint(pos):
                self.running = False
                return
        else:
            if self.btn_back.collidepoint(pos):
                self.state = "SPLASH"
                return

        for rect, label in self.nav_buttons:
            if rect.collidepoint(pos):
                self.state = label.replace(" ", "_")
                break

    def run(self):
        self.start_camera_and_server()
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                if event.type == pygame.MOUSEBUTTONDOWN:
                    self.handle_click(pygame.mouse.get_pos())
                if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                    self.running = False

            if self.state == "SPLASH": self.draw_splash()
            elif self.state == "STATUS": self.draw_status()
            elif self.state == "DRIVE": self.draw_drive()
            elif self.state == "CART_AI": self.draw_cart_ai()
            elif self.state == "VISION_AI": self.draw_vision_ai()

            pygame.display.flip()
            self.clock.tick(120) # Target 120 GUI updates for smooth 100fps feed
        pygame.quit()
        sys.exit()

if __name__ == "__main__":
    gui = AxelNodeGUI()
    gui.run()
