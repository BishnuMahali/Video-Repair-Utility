import os
import sys
import json
import subprocess
import shutil
from datetime import datetime

# GUI for directory selection
try:
    import tkinter as tk
    from tkinter import filedialog
    TK_AVAILABLE = True
except ImportError:
    TK_AVAILABLE = False

# Single key press utility
try:
    import msvcrt
    def getch():
        return msvcrt.getch().decode('utf-8', 'ignore')
except ImportError:
    import tty, termios
    def getch():
        try:
            fd = sys.stdin.fileno()
            old_settings = termios.tcgetattr(fd)
            try:
                tty.setraw(sys.stdin.fileno())
                ch = sys.stdin.read(1)
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
            return ch
        except Exception:
            # Fallback for environments where termios fails (like some basic terminals or CI)
            return input()[:1]

def select_folder(current_dir):
    if TK_AVAILABLE:
        root = tk.Tk()
        root.withdraw()
        folder_selected = filedialog.askdirectory(initialdir=current_dir, title="Select Directory to Scan")
        if folder_selected:
            return os.path.normpath(folder_selected)
    else:
        print("tkinter not available for GUI folder selection.")
        new_dir = input(f"Enter directory path (leave blank to keep '{current_dir}'): ")
        if new_dir.strip() and os.path.isdir(new_dir.strip()):
            return os.path.normpath(new_dir.strip())
    return current_dir

# ================= CONFIG =================
VIDEO_EXTENSIONS = ('.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv')
CACHE_FILE = "repair_cache.json"
LOG_FILE = "repair_log.txt"
BROKEN_FOLDER = "Broken Files"

directory = os.getcwd()
use_force_fix = False
delete_instead = False
use_recurse = False
use_gpu = True

# ================= UTILS =================
def detect_gpu():
    encoders = [("NVIDIA", "h264_nvenc"), ("AMD", "h264_amf"), ("Intel", "h264_qsv")]
    for name, encoder in encoders:
        cmd = ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "color=c=black:s=16x16:d=0.1", "-c:v", encoder, "-f", "null", "-"]
        try:
            result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if result.returncode == 0:
                return name, encoder
        except Exception:
            pass
    return "None", "libx264"

gpu_name, gpu_encoder = detect_gpu()

def clear_host():
    os.system('cls' if os.name == 'nt' else 'clear')

def safe_log(msg):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        f.write(f"{timestamp} - {msg}\n")

def count_files(dir_path):
    parent_count = 0
    sub_count = 0

    for root_dir, dirs, files in os.walk(dir_path):
        for file in files:
            if file.lower().endswith(VIDEO_EXTENSIONS) and ".tmp." not in file:
                if root_dir == dir_path:
                    parent_count += 1
                else:
                    sub_count += 1
    return {'Parent': parent_count, 'Sub': sub_count}

def get_all_files(dir_path, recurse):
    all_files = []
    if recurse:
        for root_dir, dirs, files in os.walk(dir_path):
            for file in files:
                if file.lower().endswith(VIDEO_EXTENSIONS) and ".tmp." not in file:
                    all_files.append(os.path.join(root_dir, file))
    else:
        for file in os.listdir(dir_path):
            file_path = os.path.join(dir_path, file)
            if os.path.isfile(file_path) and file.lower().endswith(VIDEO_EXTENSIONS) and ".tmp." not in file:
                all_files.append(file_path)
    return all_files

# ================= INPUT UI WIZARD =================
clear_host()
print("==========================================")
print(" 🎬  ULTIMATE VIDEO REPAIR UTILITY  🎬 ")
print("==========================================")
print()

while True:
    print(f"Current Directory: {directory}")
    counts = count_files(directory)
    print(f"Parent Folder: {counts['Parent']} Files, Sub-Folders: {counts['Sub']} Files")
    if gpu_name != "None":
        print(f"GPU Mode: Auto ({gpu_name}) [Use Custom Preset to select CPU]")
    else:
        print("GPU Mode: Auto (CPU) [No GPU Detected]")

    print("\n[P] Proceed  |  [C] Change Directory")
    print("Press a key: ", end='', flush=True)

    while True:
        key = getch().upper()
        if key in ('P', 'C'):
            print(key)
            break

    if key == 'C':
        new_dir = select_folder(directory)
        if new_dir:
            directory = new_dir
        clear_host()
        print("==========================================")
        print(" 🎬  ULTIMATE VIDEO REPAIR UTILITY  🎬 ")
        print("==========================================")
        print()
    else:
        break

clear_host()
print("==========================================")
print(" 🎬  ULTIMATE VIDEO REPAIR UTILITY  🎬 ")
print("==========================================")
print()
print("Select Preset:")
print("[1] Standard        (Current Dir, Light Fix, Move broken)")
print("[2] Deep Standard   (Subfolders, Light Fix, Move broken)")
print("[3] Aggressive      (Current Dir, Force Fix, Move broken)")
print("[4] Deep Aggressive (Subfolders, Force Fix, Move broken)")
print("[5] Custom Settings")
print("\nPress 1-5: ", end='', flush=True)

while True:
    key = getch()
    if key in ('1', '2', '3', '4', '5'):
        print(key)
        break

if key == '1':
    use_recurse, use_force_fix, delete_instead = False, False, False
elif key == '2':
    use_recurse, use_force_fix, delete_instead = True, False, False
elif key == '3':
    use_recurse, use_force_fix, delete_instead = False, True, False
elif key == '4':
    use_recurse, use_force_fix, delete_instead = True, True, False
elif key == '5':
    print("\nEnter custom settings (4 characters: Y/N for [Subfolders][Force Fix][Delete Broken][Use GPU]): ", end='')
    custom = input().strip().upper()
    if len(custom) >= 4:
        use_recurse = (custom[0] == 'Y')
        use_force_fix = (custom[1] == 'Y')
        delete_instead = (custom[2] == 'Y')
        use_gpu = (custom[3] == 'Y')
    elif len(custom) >= 3:
        use_recurse = (custom[0] == 'Y')
        use_force_fix = (custom[1] == 'Y')
        delete_instead = (custom[2] == 'Y')
        use_gpu = True
    else:
        print("Invalid input, defaulting to Standard...")
        use_recurse, use_force_fix, delete_instead, use_gpu = False, False, False, True

print("\n==========================================")
print(" Configuration Saved! ")
print("==========================================")

clear_host()
print("🚀 Starting Scan...")

# ================= INIT =================
broken_path = os.path.join(directory, BROKEN_FOLDER)
if not os.path.exists(broken_path):
    os.makedirs(broken_path)

if os.path.exists(CACHE_FILE):
    try:
        with open(CACHE_FILE, 'r', encoding='utf-8') as f:
            processed = json.load(f)
            if not isinstance(processed, dict):
                processed = {}
    except Exception:
        processed = {}
else:
    processed = {}

all_files = get_all_files(directory, use_recurse)
total = len(all_files)
count = 0

print(f"🔍 Found {total} video files\n")

stats = {
    'Total': total,
    'OK': 0,
    'FixedLight': 0,
    'FixedForce': 0,
    'Failed': 0,
    'Ignored': 0
}

# ================= FUNCTIONS =================
def test_video(filepath):
    if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
        return "File empty or not found"

    try:
        # Fast Validation
        probe_cmd = ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", filepath]
        result = subprocess.run(probe_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if not result.stdout.strip() or "Invalid data found" in result.stderr:
            return "Not a valid media file or fatally corrupted header"

        # Fast Demuxing Test
        test_cmd = ["ffmpeg", "-v", "error", "-i", filepath, "-c", "copy", "-f", "null", "-"]
        result2 = subprocess.run(test_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result2.returncode != 0 or result2.stderr.strip():
            return result2.stderr.strip() or "FFmpeg error"

        return ""
    except FileNotFoundError:
        print("\nERROR: ffmpeg/ffprobe not found. Please make sure they are installed and in your PATH.")
        sys.exit(1)

def fix_video_light(filepath):
    out = filepath + ".tmp.light.mp4"
    if os.path.exists(out):
        try: os.remove(out)
        except: pass

    cmd = ["ffmpeg", "-y", "-i", filepath, "-c", "copy", out]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return out

def fix_video_force(filepath):
    out = filepath + ".tmp.force.mp4"
    if os.path.exists(out):
        try: os.remove(out)
        except: pass

    encoder_to_use = gpu_encoder if (use_gpu and gpu_encoder != "libx264") else "libx264"
    cmd = ["ffmpeg", "-y", "-err_detect", "ignore_err", "-fflags", "+genpts+discardcorrupt", "-async", "1", "-i", filepath, "-c:v", encoder_to_use, "-c:a", "aac", out]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return out

# ================= MAIN LOOP =================
for filepath in all_files:
    count += 1
    try:
        file_size = os.path.getsize(filepath)
    except FileNotFoundError:
        continue

    cache_key = f"{filepath}|{file_size}"

    print(f"[{count}/{total}] ⏳ Processing: {filepath}", end='')

    if cache_key in processed:
        print("\n   ⏭️ Skipped (already processed)")
        stats['Ignored'] += 1
        continue

    print() # newline after file path

    error_msg = test_video(filepath)

    if not error_msg:
        print("   ✅ OK")
        processed[cache_key] = "OK"
        stats['OK'] += 1
        with open(CACHE_FILE, 'w', encoding='utf-8') as f:
            json.dump(processed, f, indent=2)
        continue

    print("   ⚠️ Errors detected. Attempting light fix...")
    fixed_light = fix_video_light(filepath)

    if not test_video(fixed_light):
        print("   🛠️ Light fix successful")
        try:
            shutil.move(fixed_light, filepath)
            processed[cache_key] = "Fixed-Light"
            stats['FixedLight'] += 1
        except Exception as e:
            print(f"   ❌ Error replacing original file. Temp file left at {fixed_light}")
            safe_log(f"Error replacing: {filepath}. Exception: {e}")

        with open(CACHE_FILE, 'w', encoding='utf-8') as f:
            json.dump(processed, f, indent=2)
        continue

    if os.path.exists(fixed_light):
        try: os.remove(fixed_light)
        except: pass

    if use_force_fix:
        print("   🔥 Attempting FORCE fix...")
        fixed_force = fix_video_force(filepath)

        if not test_video(fixed_force):
            print("   🛠️ Force fix successful")
            try:
                shutil.move(fixed_force, filepath)
                processed[cache_key] = "Fixed-Force"
                stats['FixedForce'] += 1
            except Exception as e:
                print(f"   ❌ Error replacing original file. Temp file left at {fixed_force}")
                safe_log(f"Error replacing: {filepath}. Exception: {e}")

            with open(CACHE_FILE, 'w', encoding='utf-8') as f:
                json.dump(processed, f, indent=2)
            continue

        if os.path.exists(fixed_force):
            try: os.remove(fixed_force)
            except: pass

    print("   ❌ FAILED to repair")
    safe_log(f"Failed: {filepath}")

    try:
        if delete_instead:
            os.remove(filepath)
            print("   🗑️ Deleted")
        else:
            shutil.move(filepath, os.path.join(broken_path, os.path.basename(filepath)))
            print("   📁 Moved to Broken Files")
        processed[cache_key] = "Broken"
    except Exception as e:
        print("   ❌ Error moving/deleting file. It might be locked.")
        safe_log(f"Error moving/deleting: {filepath}. Exception: {e}")

    stats['Failed'] += 1

    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        json.dump(processed, f, indent=2)

# ================= SUMMARY =================
print("\n==========================================")
print(" 📊 SUMMARY ")
print("==========================================")
print(f" 🔢 Total Scanned : {stats['Total']}")
print(f" ✅ OK            : {stats['OK']}")
print(f" ⏭️ Ignored       : {stats['Ignored']}")
print(f" 🛠️ Light Fixed   : {stats['FixedLight']}")
print(f" 🔥 Force Fixed   : {stats['FixedForce']}")
print(f" ❌ Failed        : {stats['Failed']}")
print("==========================================")

print(f"\n📝 Log saved to {LOG_FILE}")
print(f"💾 Cache saved to {CACHE_FILE}")
print("\nDone!")
