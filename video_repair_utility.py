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
KNOWN_VIDEO_EXTENSIONS = {'.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.asf', '.mpeg', '.mpg', '.webm', '.vob', '.mp4v', '.m4v', '.3gp', '.3g2', '.ts', '.mts', '.m2ts', '.divx', '.xvid', '.f4v', '.rmvb'}
IGNORED_EXTENSIONS = {
    '.txt', '.pdf', '.zip', '.rar', '.7z', '.tar', '.gz', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp',
    '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.exe', '.dll', '.sys', '.ini', '.cfg', '.xml', '.json', '.html',
    '.css', '.js', '.py', '.ps1', '.bat', '.sh', '.iso', '.bin', '.cue', '.md', '.log', '.srt', '.sub', '.ass', '.vtt'
}
CACHE_FILE = "repair_cache.json"
LOG_FILE = "repair_log.txt"
BROKEN_FOLDER = "Broken Files"

def check_video_file_with_ffprobe(filepath):
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=codec_type', '-of', 'default=noprint_wrappers=1:nokey=1', filepath],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        return 'video' in result.stdout
    except Exception:
        return False

def is_video_file(filepath):
    if ".tmp." in filepath:
        return False

    # Ignore Broken Files directory
    if BROKEN_FOLDER in os.path.split(os.path.dirname(filepath)):
         return False
    if BROKEN_FOLDER in filepath.split(os.sep):
         return False

    ext = os.path.splitext(filepath)[1].lower()

    if not ext:
        # Ignore files without extensions to be safe and avoid scanning everything
        return False

    if ext in KNOWN_VIDEO_EXTENSIONS:
        return True

    if ext in IGNORED_EXTENSIONS:
        return False

    # Extension is unknown, run ffprobe
    if check_video_file_with_ffprobe(filepath):
        KNOWN_VIDEO_EXTENSIONS.add(ext)
        return True
    else:
        IGNORED_EXTENSIONS.add(ext)
        return False

directory = os.getcwd()
use_force_fix = False
delete_instead = False
use_recurse = False
use_gpu = True

# ================= UTILS =================
ENCODERS = {
    "H.264": {"CPU": "libx264", "NVIDIA": "h264_nvenc", "AMD": "h264_amf", "Intel": "h264_qsv"},
    "HEVC": {"CPU": "libx265", "NVIDIA": "hevc_nvenc", "AMD": "hevc_amf", "Intel": "hevc_qsv"},
    "AV1": {"CPU": "libsvtav1", "NVIDIA": "av1_nvenc", "AMD": "av1_amf", "Intel": "av1_qsv"}
}

def detect_gpu(codec):
    vendors = ["NVIDIA", "AMD", "Intel"]
    for vendor in vendors:
        encoder = ENCODERS[codec][vendor]
        cmd = ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "color=c=black:s=16x16:d=0.1", "-c:v", encoder, "-f", "null", "-"]
        try:
            result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if result.returncode == 0:
                return vendor, encoder
        except Exception:
            pass
    return "None", ENCODERS[codec]["CPU"]

gpu_codec = "H.264"
gpu_name = "Auto"
gpu_encoder = "auto"

def clear_host():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_box(lines, title=None, color_title="", color_text=""):
    width = 50
    print(f"╭{'─' * (width - 2)}╮")
    if title:
        print(f"│ {color_title}{title.center(width - 4)}\033[0m │")
        print(f"├{'─' * (width - 2)}┤")
    for line in lines:
        if line == "-":
            print(f"├{'─' * (width - 2)}┤")
        else:
            print(f"│ {color_text}{line.ljust(width - 4)}\033[0m │")
    print(f"╰{'─' * (width - 2)}╯")

def print_header():
    clear_host()
    print_box(["🎬 ULTIMATE VIDEO REPAIR UTILITY 🎬"], color_text="\033[1;36m")
    print()

def safe_log(msg):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        f.write(f"{timestamp} - {msg}\n")

def count_files(dir_path):
    parent_count = 0
    sub_count = 0

    for root_dir, dirs, files in os.walk(dir_path):
        if BROKEN_FOLDER in dirs:
            dirs.remove(BROKEN_FOLDER)

        for file in files:
            file_path = os.path.join(root_dir, file)
            if is_video_file(file_path):
                if root_dir == dir_path:
                    parent_count += 1
                else:
                    sub_count += 1
    return {'Parent': parent_count, 'Sub': sub_count}

def get_all_files(dir_path, recurse):
    all_files = []
    if recurse:
        for root_dir, dirs, files in os.walk(dir_path):
            if BROKEN_FOLDER in dirs:
                dirs.remove(BROKEN_FOLDER)

            for file in files:
                file_path = os.path.join(root_dir, file)
                if is_video_file(file_path):
                    all_files.append(file_path)
    else:
        for file in os.listdir(dir_path):
            if file == BROKEN_FOLDER:
                continue
            file_path = os.path.join(dir_path, file)
            if os.path.isfile(file_path) and is_video_file(file_path):
                all_files.append(file_path)
    return all_files

# ================= INPUT UI WIZARD =================
print_header()

while True:
    counts = count_files(directory)
    print_box([
        f"Dir: {directory}",
        "-",
        f"Parent: {counts['Parent']} Files",
        f"Sub:    {counts['Sub']} Files",
        "-",
        "[P] Proceed | [C] Change Dir"
    ], title="Directory Info", color_title="\033[1;33m")

    print("\nPress a key: ", end='', flush=True)

    while True:
        key = getch().upper()
        if key in ('P', 'C'):
            print(key)
            break

    if key == 'C':
        new_dir = select_folder(directory)
        if new_dir:
            directory = new_dir
        print_header()
    else:
        break

print_header()
print_box([
    "[1] H.264 (Standard/Legacy)",
    "[2] HEVC  (H.265 / High Efficiency)",
    "[3] AV1   (Next-Gen)"
], title="Select Target Codec", color_title="\033[1;35m")
print("\nPress 1-3: ", end='', flush=True)

while True:
    key = getch()
    if key in ('1', '2', '3'):
        print(key)
        if key == '1': gpu_codec = "H.264"
        elif key == '2': gpu_codec = "HEVC"
        elif key == '3': gpu_codec = "AV1"
        break

print_header()
print_box([
    f"[1] Auto   (Detects {gpu_codec} hardware)",
    f"[2] CPU    ({ENCODERS[gpu_codec]['CPU']})",
    f"[3] NVIDIA ({ENCODERS[gpu_codec]['NVIDIA']})",
    f"[4] AMD    ({ENCODERS[gpu_codec]['AMD']})",
    f"[5] Intel  ({ENCODERS[gpu_codec]['Intel']})"
], title="Select Hardware", color_title="\033[1;34m")
print("\nPress 1-5: ", end='', flush=True)

while True:
    key = getch()
    if key in ('1', '2', '3', '4', '5'):
        print(key)
        break

if key == '1':
    auto_name, auto_enc = detect_gpu(gpu_codec)
    gpu_name, gpu_encoder = auto_name, auto_enc
elif key == '2':
    gpu_name, gpu_encoder = "CPU", ENCODERS[gpu_codec]["CPU"]
elif key == '3':
    gpu_name, gpu_encoder = "NVIDIA", ENCODERS[gpu_codec]["NVIDIA"]
elif key == '4':
    gpu_name, gpu_encoder = "AMD", ENCODERS[gpu_codec]["AMD"]
elif key == '5':
    gpu_name, gpu_encoder = "Intel", ENCODERS[gpu_codec]["Intel"]

use_gpu = (gpu_name != "CPU" and gpu_name != "None")

print_header()
print_box([
    "[1] Standard   (Dir only, Light, Move broken)",
    "[2] Deep Std   (Subfolders, Light, Move broken)",
    "[3] Aggressive (Dir only, Force, Move broken)",
    "[4] Deep Aggr  (Subfolders, Force, Move broken)",
    "[5] Custom Settings"
], title="Select Preset", color_title="\033[1;32m")
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
    print("\nEnter custom settings (3 characters: Y/N for [Subfolders][Force Fix][Delete Broken]): ", end='')
    custom = input().strip().upper()
    if len(custom) >= 3:
        use_recurse = (custom[0] == 'Y')
        use_force_fix = (custom[1] == 'Y')
        delete_instead = (custom[2] == 'Y')
    else:
        print("Invalid input, defaulting to Standard...")
        use_recurse, use_force_fix, delete_instead = False, False, False

print_header()
print_box([
    "Configuration Saved!",
    "-",
    f"Codec:   {gpu_codec}",
    f"Encoder: {gpu_name} ({gpu_encoder})"
], title="Success", color_title="\033[1;32m")

print("\n🚀 Starting Scan...\n")

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
    'FixedCodec': 0,
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

        # Check for Codec Mismatch (e.g., HEVC/AV1 in AVI appearing as rawvideo)
        ext = os.path.splitext(filepath)[1].lower()
        if ext in ['.avi', '.wmv', '.flv', '.vob', '.ts', '.mpg', '.mpeg', '.m2ts', '.mts']:
            codec_cmd = ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=codec_name", "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            codec_res = subprocess.run(codec_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if "rawvideo" in codec_res.stdout.lower():
                return "Codec metadata missing"

        # Fast Demuxing Test
        test_cmd = ["ffmpeg", "-v", "error", "-i", filepath, "-c", "copy", "-f", "null", "-"]
        result2 = subprocess.run(test_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result2.returncode != 0 or result2.stderr.strip():
            return result2.stderr.strip() or "FFmpeg error"

        return ""
    except FileNotFoundError:
        print("\nERROR: ffmpeg/ffprobe not found. Please make sure they are installed and in your PATH.")
        sys.exit(1)

def fix_video_codec_remux(filepath):
    out = os.path.splitext(filepath)[0] + ".tmp.codec.mp4"
    if os.path.exists(out):
        try: os.remove(out)
        except: pass

    # First try HEVC
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-c:v", "hevc", "-i", filepath, "-c", "copy", "-movflags", "+faststart", out]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        # Try AV1
        if os.path.exists(out):
            try: os.remove(out)
            except: pass
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-c:v", "av1", "-i", filepath, "-c", "copy", "-movflags", "+faststart", out]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    return out

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

    cmd = ["ffmpeg", "-y", "-err_detect", "ignore_err", "-fflags", "+genpts+discardcorrupt", "-async", "1", "-i", filepath, "-c:v", gpu_encoder, "-c:a", "aac", out]
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

    # Format output path to be concise
    dir_name = os.path.dirname(filepath)
    file_name = os.path.basename(filepath)
    if os.path.normpath(dir_name) == os.path.normpath(directory):
        display_path = file_name
    else:
        display_path = f"../{os.path.basename(dir_name)}/{file_name}"

    print(f"[{count}/{total}] ⏳ Processing: {display_path}", end='')

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

    if "Codec metadata missing" in error_msg:
        print("   🔍 Codec missing detected. Attempting HEVC/AV1 recovery...")
        fixed_codec = fix_video_codec_remux(filepath)
        if not test_video(fixed_codec):
            print("   🪄 Codec recovery successful")
            try:
                # We need to change the extension to .mp4 since we are remuxing
                new_filepath = os.path.splitext(filepath)[0] + ".mp4"
                if os.path.exists(new_filepath) and new_filepath.lower() != filepath.lower():
                     os.remove(new_filepath)
                shutil.move(fixed_codec, new_filepath)
                if new_filepath.lower() != filepath.lower():
                    if delete_instead:
                        os.remove(filepath)
                    else:
                        shutil.move(filepath, os.path.join(broken_path, os.path.basename(filepath)))
                processed[cache_key] = "Fixed-Codec"
                stats['FixedCodec'] += 1
            except Exception as e:
                print(f"   ❌ Error replacing original file. Temp file left at {fixed_codec}")
                safe_log(f"Error replacing: {filepath}. Exception: {e}")

            with open(CACHE_FILE, 'w', encoding='utf-8') as f:
                json.dump(processed, f, indent=2)
            continue
        
        # Cleanup codec fix temp file on failure
        if os.path.exists(fixed_codec):
            try: os.remove(fixed_codec)
            except: pass

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

    # Cleanup light fix temp file on failure
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

        # Cleanup force fix temp file on failure
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
print(f" 🪄 Codec Remux   : {stats['FixedCodec']}")
print(f" 🛠️ Light Fixed   : {stats['FixedLight']}")
print(f" 🔥 Force Fixed   : {stats['FixedForce']}")
print(f" ❌ Failed        : {stats['Failed']}")
print("==========================================")

print(f"\n📝 Log saved to {LOG_FILE}")
print(f"💾 Cache saved to {CACHE_FILE}")
print("\nDone!")
