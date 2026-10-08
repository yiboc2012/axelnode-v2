import os
import subprocess
import time

PI_IP = "192.168.68.90"
PI_USER = "rpi"
PI_PASS = "Ilove67"
REMOTE_DIR = "/home/rpi/axelnode_rpi"

print(f"--- Deploying AXEL NODE to {PI_IP} ---")

def run_with_expect(cmd):
    expect_script = f"""
    spawn {cmd}
    expect {{
        "*password:" {{
            send "{PI_PASS}\\r"
            exp_continue
        }}
        eof
    }}
    """
    with open("temp_expect.sh", "w") as f:
        f.write(f"#!/usr/bin/expect -f\n{expect_script}")
    os.chmod("temp_expect.sh", 0o755)
    result = subprocess.run(["./temp_expect.sh"], capture_output=True, text=True)
    os.remove("temp_expect.sh")
    return result.stdout

# 1. Prepare directory and copy files
print("Creating remote directory and syncing files...")
run_with_expect(f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} mkdir -p {REMOTE_DIR}/assets")
run_with_expect(f"scp -o StrictHostKeyChecking=no -r rpi/. {PI_USER}@{PI_IP}:{REMOTE_DIR}/")

# 2. Generate a simple icon on the Pi using python
print("Generating icon on Pi...")
icon_gen_cmd = f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} 'python3 -c \"from PIL import Image, ImageDraw; img = Image.new(\\'RGB\\', (128, 128), color=\\'green\\'); draw = ImageDraw.Draw(img); draw.ellipse([20, 20, 108, 108], fill=\\'white\\'); img.save(\\'{REMOTE_DIR}/assets/icon.png\\')\" || true'"
run_with_expect(icon_gen_cmd)

# 3. Setup permissions and desktop shortcut
print("Setting up desktop shortcut...")
run_with_expect(f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} chmod +x {REMOTE_DIR}/scripts/start_all.sh")

# Update .desktop file with the new icon path
update_icon_cmd = f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} \"sed -i 's|Icon=video-display|Icon={REMOTE_DIR}/assets/icon.png|' {REMOTE_DIR}/scripts/axel_node.desktop\""
run_with_expect(update_icon_cmd)

run_with_expect(f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} cp {REMOTE_DIR}/scripts/axel_node.desktop /home/rpi/Desktop/")
run_with_expect(f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} chmod +x /home/rpi/Desktop/axel_node.desktop")

# 4. Start the system
print("Starting AXEL NODE system...")
run_with_expect(f"ssh -o StrictHostKeyChecking=no {PI_USER}@{PI_IP} cd {REMOTE_DIR} && scripts/start_all.sh")

# 5. Verify
time.sleep(3)
print("\nVerifying Camera Server Status:")
os.system(f"curl -m 2 http://{PI_IP}:5000/status")

print("\n--- Deployment Finished ---")
print(f"Check logs on Pi at {REMOTE_DIR}/camera.log and {REMOTE_DIR}/gui.log")
print("The 'AXEL NODE' desktop shortcut has been updated with a green icon.")
