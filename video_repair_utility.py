#!/usr/bin/env python3
# Ultimate Video Repair Utility (Tkinter GUI Edition)
# MIT License | Copyright (c) 2026 Bishnu Mahali

import os
import sys
import json
import subprocess
import shutil
import threading
import time
from datetime import datetime

# GUI
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# ================= CONFIG =================
APP_NAME = "Video Repair Utility"
KNOWN_VIDEO_EXTENSIONS = {'.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.asf', '.mpeg', '.mpg', '.webm', '.vob', '.mp4v', '.m4v', '.3gp', '.3g2', '.ts', '.mts', '.m2ts', '.divx', '.xvid', '.f4v', '.rmvb'}
IGNORED_EXTENSIONS = {
    '.txt', '.pdf', '.zip', '.rar', '.7z', '.tar', '.gz', '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp',
    '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.exe', '.dll', '.sys', '.ini', '.cfg', '.xml', '.json', '.html',
    '.css', '.js', '.py', '.ps1', '.bat', '.sh', '.iso', '.bin', '.cue', '.md', '.log', '.srt', '.sub', '.ass', '.vtt'
}
BROKEN_FOLDER = "Broken Files"

ENCODERS = {
    "H.264": {"CPU": "libx264", "NVIDIA": "h264_nvenc", "AMD": "h264_amf", "Intel": "h264_qsv"},
    "HEVC":  {"CPU": "libx265", "NVIDIA": "hevc_nvenc", "AMD": "hevc_amf", "Intel": "hevc_qsv"},
    "AV1":   {"CPU": "libsvtav1", "NVIDIA": "av1_nvenc", "AMD": "av1_amf", "Intel": "av1_qsv"}
}

# ================= SETTINGS =================
def get_settings_path():
    """Get the settings file path in the script directory."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    settings_dir = os.path.join(script_dir, ".Video Repair Utility")
    if not os.path.exists(settings_dir):
        os.makedirs(settings_dir)
        # Hide the directory on Windows
        if os.name == 'nt':
            try:
                subprocess.run(['attrib', '+H', settings_dir], capture_output=True)
            except Exception:
                pass
    return os.path.join(settings_dir, "settings.json")

def load_settings():
    """Load settings from the settings file."""
    try:
        path = get_settings_path()
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception:
        pass
    return {}

def save_settings(settings):
    """Save settings to the settings file."""
    try:
        path = get_settings_path()
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(settings, f, indent=2)
    except Exception:
        pass

# ================= THEME =================
def get_system_theme():
    """Detect Windows dark/light mode."""
    try:
        import winreg
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                            r"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize")
        value, _ = winreg.QueryValueEx(key, "AppsUseLightTheme")
        winreg.CloseKey(key)
        return "Dark" if value == 0 else "Light"
    except Exception:
        return "Light"

THEMES = {
    "Dark": {
        "bg": "#1B1F23", "card": "#24292E", "text": "#E6EDF3", "text_sub": "#8C959F",
        "border": "#30363D", "input_bg": "#0D1117", "primary": "#3498DB", "accent": "#2980B9",
        "success": "#27AE60", "error": "#E74C3C", "warning": "#F39C12", "hover": "#4AA3DF",
        "progress_bg": "#30363D", "log_bg": "#0D1117", "btn_text": "#FFFFFF",
    },
    "Light": {
        "bg": "#F4F4F9", "card": "#FFFFFF", "text": "#2C3E50", "text_sub": "#7F8C8D",
        "border": "#DCDDE1", "input_bg": "#FDFDFD", "primary": "#3498DB", "accent": "#2980B9",
        "success": "#27AE60", "error": "#E74C3C", "warning": "#F39C12", "hover": "#1B78B7",
        "progress_bg": "#ECF0F1", "log_bg": "#F8F9FA", "btn_text": "#FFFFFF",
    }
}

# ================= UTILITY =================
def check_video_file_with_ffprobe(filepath):
    """Check if a file contains a video stream using ffprobe."""
    try:
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=codec_type',
             '-of', 'default=noprint_wrappers=1:nokey=1', filepath],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
        )
        return 'video' in result.stdout
    except Exception:
        return False

def is_video_file(filepath):
    """Determine if a file is a video file."""
    if ".tmp." in filepath:
        return False
    if BROKEN_FOLDER in filepath.split(os.sep):
        return False
    ext = os.path.splitext(filepath)[1].lower()
    if not ext:
        return False
    if ext in KNOWN_VIDEO_EXTENSIONS:
        return True
    if ext in IGNORED_EXTENSIONS:
        return False
    if check_video_file_with_ffprobe(filepath):
        KNOWN_VIDEO_EXTENSIONS.add(ext)
        return True
    else:
        IGNORED_EXTENSIONS.add(ext)
        return False

def check_ffmpeg():
    """Check if ffmpeg and ffprobe are available."""
    try:
        subprocess.run(['ffmpeg', '-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                      creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        subprocess.run(['ffprobe', '-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                      creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        return True
    except FileNotFoundError:
        return False

def detect_gpu_encoder(codec):
    """Detect available GPU encoders. Returns dict of vendor: (available, encoder_name)."""
    results = {}
    cf = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    for vendor in ["CPU", "NVIDIA", "AMD", "Intel"]:
        encoder = ENCODERS[codec][vendor]
        if vendor == "CPU":
            results[vendor] = (True, encoder)
            continue
        try:
            cmd = ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "color=c=black:s=16x16:d=0.1",
                   "-c:v", encoder, "-f", "null", "-"]
            result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=cf)
            results[vendor] = (result.returncode == 0, encoder)
        except Exception:
            results[vendor] = (False, encoder)
    return results

def get_all_files(dir_path, recurse):
    """Get all video files in directory."""
    all_files = []
    if recurse:
        for root_dir, dirs, files in os.walk(dir_path):
            if BROKEN_FOLDER in dirs:
                dirs.remove(BROKEN_FOLDER)
            if ".Video Repair Utility" in dirs:
                dirs.remove(".Video Repair Utility")
            for file in files:
                file_path = os.path.join(root_dir, file)
                if is_video_file(file_path):
                    all_files.append(file_path)
    else:
        try:
            for file in os.listdir(dir_path):
                if file in (BROKEN_FOLDER, ".Video Repair Utility"):
                    continue
                file_path = os.path.join(dir_path, file)
                if os.path.isfile(file_path) and is_video_file(file_path):
                    all_files.append(file_path)
        except PermissionError:
            pass
    return all_files

# ================= REPAIR ENGINE =================
class RepairEngine:
    """Core repair engine - handles all video testing and fixing logic."""

    def __init__(self, encoder, codec, log_callback=None):
        self.encoder = encoder
        self.codec = codec
        self.cpu_encoder = ENCODERS[codec]["CPU"]
        self.log = log_callback or (lambda msg, sev: None)
        self._cancel = False
        self.cf = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0

    def cancel(self):
        self._cancel = True

    def test_video(self, filepath):
        """
        Test a video file for issues.
        Returns a dict: { 'ok': bool, 'error': str, 'is_vfr': bool }
        """
        result = {'ok': False, 'error': '', 'is_vfr': False}

        if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
            result['error'] = "File empty or not found"
            return result

        try:
            # Fast Validation - check if file has valid duration
            probe_cmd = ["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            res = subprocess.run(probe_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, creationflags=self.cf)
            if not res.stdout.strip() or "Invalid data found" in res.stderr:
                result['error'] = "Not a valid media file or fatally corrupted header"
                return result

            # Check for Codec Mismatch
            ext = os.path.splitext(filepath)[1].lower()
            if ext in ['.avi', '.wmv', '.flv', '.vob', '.ts', '.mpg', '.mpeg', '.m2ts', '.mts']:
                codec_cmd = ["ffprobe", "-v", "error", "-select_streams", "v:0",
                            "-show_entries", "stream=codec_name",
                            "-of", "default=noprint_wrappers=1:nokey=1", filepath]
                codec_res = subprocess.run(codec_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                          text=True, creationflags=self.cf)
                if "rawvideo" in codec_res.stdout.lower():
                    result['error'] = "Codec metadata missing"
                    return result

            # Check for VFR (Variable Frame Rate) / Timestamp Jitter
            vfr_cmd = ["ffprobe", "-v", "error", "-select_streams", "v:0",
                      "-show_entries", "stream=r_frame_rate,avg_frame_rate",
                      "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            vfr_res = subprocess.run(vfr_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                    text=True, creationflags=self.cf)
            rates = [r.strip() for r in vfr_res.stdout.strip().split('\n') if r.strip()]
            if len(rates) >= 2:
                try:
                    def parse_rate(r):
                        if '/' in r:
                            num, den = r.split('/')
                            return float(num) / float(den)
                        return float(r)
                    r_fps = parse_rate(rates[0])
                    avg_fps = parse_rate(rates[1])
                    if abs(r_fps - avg_fps) > 0.1:
                        result['error'] = "Variable Frame Rate (VFR) / Timestamp Jitter detected"
                        result['is_vfr'] = True
                        return result
                except Exception:
                    pass

            # Fast Demuxing Test
            test_cmd = ["ffmpeg", "-v", "error", "-i", filepath, "-c", "copy", "-f", "null", "-"]
            res2 = subprocess.run(test_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 text=True, creationflags=self.cf)
            # Only treat as broken if return code is non-zero
            # OR if stderr contains actual error keywords (not just warnings)
            if res2.returncode != 0:
                result['error'] = res2.stderr.strip() or "FFmpeg error"
                return result
            elif res2.stderr.strip():
                stderr_lower = res2.stderr.lower()
                # Filter out non-fatal warnings
                fatal_keywords = ['error', 'invalid', 'corrupt', 'broken', 'missing', 'failed']
                if any(kw in stderr_lower for kw in fatal_keywords):
                    result['error'] = res2.stderr.strip()
                    return result

            result['ok'] = True
            return result

        except FileNotFoundError:
            result['error'] = "ffmpeg/ffprobe not found in PATH"
            return result

    def verify_repair(self, filepath):
        """
        Lightweight repair verification.
        Only checks if the file is valid and playable - does NOT re-check VFR
        since the force fix already corrected timestamp issues.
        """
        if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
            return False

        try:
            # Check duration exists
            probe_cmd = ["ffprobe", "-v", "error", "-show_entries", "format=duration",
                        "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            res = subprocess.run(probe_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, creationflags=self.cf)
            duration = res.stdout.strip()
            if not duration or "Invalid" in res.stderr:
                return False

            # Verify duration is positive
            try:
                if float(duration) <= 0:
                    return False
            except ValueError:
                return False

            return True
        except Exception:
            return False

    def get_bitrate(self, filepath):
        """Extract format bitrate from file."""
        try:
            cmd = ["ffprobe", "-v", "error", "-show_entries", "format=bit_rate",
                  "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, creationflags=self.cf)
            bitrate = res.stdout.strip()
            if bitrate and bitrate.isdigit():
                return int(bitrate)
        except Exception:
            pass
        return None

    def get_framerate(self, filepath):
        """Extract r_frame_rate from file."""
        try:
            cmd = ["ffprobe", "-v", "error", "-select_streams", "v:0",
                  "-show_entries", "stream=r_frame_rate",
                  "-of", "default=noprint_wrappers=1:nokey=1", filepath]
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, creationflags=self.cf)
            rate = res.stdout.strip()
            if rate and '/' in rate:
                num, den = rate.split('/')
                return float(num) / float(den)
            elif rate:
                return float(rate)
        except Exception:
            pass
        return 30.0  # Default fallback

    def _run_encoder(self, cmd):
        """Run an ffmpeg encode command. If the configured encoder fails, fall back to CPU."""
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True, creationflags=self.cf)
        if res.returncode != 0 and self.encoder != self.cpu_encoder:
            # Encoder failed - try CPU fallback
            self.log(f"GPU encoder failed, falling back to CPU ({self.cpu_encoder})", "WARNING")
            fallback_cmd = [self.cpu_encoder if x == self.encoder else x for x in cmd]
            res = subprocess.run(fallback_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, creationflags=self.cf)
        return res

    def fix_codec_remux(self, filepath):
        """Fix codec metadata missing by remuxing with explicit codec hint."""
        out = os.path.splitext(filepath)[0] + ".tmp.codec.mp4"
        if os.path.exists(out):
            try: os.remove(out)
            except: pass

        # Try HEVC first
        cmd = ["ffmpeg", "-y", "-loglevel", "error", "-c:v", "hevc", "-i", filepath,
               "-c", "copy", "-movflags", "+faststart", out]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, creationflags=self.cf)
        if result.returncode != 0:
            if os.path.exists(out):
                try: os.remove(out)
                except: pass
            # Try AV1
            cmd = ["ffmpeg", "-y", "-loglevel", "error", "-c:v", "av1", "-i", filepath,
                   "-c", "copy", "-movflags", "+faststart", out]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=self.cf)
        return out

    def fix_light(self, filepath):
        """Light fix - stream copy to rebuild container."""
        out = filepath + ".tmp.light.mp4"
        if os.path.exists(out):
            try: os.remove(out)
            except: pass
        cmd = ["ffmpeg", "-y", "-i", filepath, "-c", "copy", out]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=self.cf)
        return out

    def fix_force(self, filepath, is_vfr=False):
        """Force fix - full re-encode with error recovery and optional CFR enforcement."""
        out = filepath + ".tmp.force.mp4"
        if os.path.exists(out):
            try: os.remove(out)
            except: pass

        bitrate = self.get_bitrate(filepath)
        if bitrate:
            target_bitrate = str(int(bitrate * 1.2))
        else:
            target_bitrate = "20M"

        cmd = ["ffmpeg", "-y", "-err_detect", "ignore_err",
               "-fflags", "+genpts+discardcorrupt", "-async", "1",
               "-i", filepath]

        # Force CFR when fixing VFR issues
        if is_vfr:
            fps = self.get_framerate(filepath)
            fps_int = round(fps)
            cmd += ["-fps_mode", "cfr", "-r", str(fps_int)]

        cmd += ["-c:v", self.encoder, "-b:v", target_bitrate,
                "-c:a", "aac", "-b:a", "320k", out]

        self._run_encoder(cmd)
        return out

    def process_files(self, files, directory, recurse, delete_broken, force_fix,
                      use_cache, use_resume, use_log, progress_callback=None):
        """
        Main processing loop. Processes all files and reports progress.
        progress_callback(type, data) where type is 'progress', 'log', 'stat', 'done'
        """
        cb = progress_callback or (lambda t, d: None)
        total = len(files)
        stats = {'ok': 0, 'fixed_light': 0, 'fixed_codec': 0, 'fixed_force': 0, 'failed': 0, 'skipped': 0}

        # Setup broken path
        broken_path = os.path.join(directory, BROKEN_FOLDER)
        if not delete_broken and not os.path.exists(broken_path):
            os.makedirs(broken_path, exist_ok=True)

        # Setup work directory
        work_dir = os.path.join(directory, ".Video Repair Utility")
        if use_cache or use_log:
            os.makedirs(work_dir, exist_ok=True)
            if os.name == 'nt':
                try:
                    subprocess.run(['attrib', '+H', work_dir], capture_output=True)
                except Exception:
                    pass

        cache_file = os.path.join(work_dir, "Cache.json")
        log_file = os.path.join(work_dir, "Log.txt")

        # Load cache
        cache = {}
        if use_resume and os.path.exists(cache_file):
            try:
                with open(cache_file, 'r', encoding='utf-8') as f:
                    cache = json.load(f)
                    if not isinstance(cache, dict):
                        cache = {}
            except Exception:
                cache = {}

        def safe_log(msg):
            if use_log:
                try:
                    with open(log_file, 'a', encoding='utf-8') as f:
                        f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {msg}\n")
                except Exception:
                    pass

        def save_cache():
            if use_cache:
                try:
                    with open(cache_file, 'w', encoding='utf-8') as f:
                        json.dump(cache, f, indent=2)
                except Exception:
                    pass

        for i, filepath in enumerate(files):
            if self._cancel:
                cb('log', ("Operation cancelled by user", "WARNING"))
                break

            file_name = os.path.basename(filepath)
            cb('progress', {'current': i + 1, 'total': total, 'file': file_name})

            # Check cache
            try:
                file_size = os.path.getsize(filepath)
            except (FileNotFoundError, OSError):
                continue
            cache_key = f"{filepath}|{file_size}"

            if use_resume and cache_key in cache:
                cb('log', (f"Cached Skip: {file_name}", "INFO"))
                stats['skipped'] += 1
                cb('stat', stats.copy())
                continue

            # Test file
            test_result = self.test_video(filepath)

            if test_result['ok']:
                cb('log', (f"OK: {file_name}", "SUCCESS"))
                stats['ok'] += 1
                cache[cache_key] = "OK"
                save_cache()
                cb('stat', stats.copy())
                continue

            error_msg = test_result['error']
            is_vfr = test_result['is_vfr']
            cb('log', (f"Issue: {file_name} — {error_msg}", "WARNING"))
            safe_log(f"Issue: {filepath} — {error_msg}")

            fixed = False

            # Strategy 1: Codec Recovery (for codec metadata missing)
            if "Codec metadata missing" in error_msg:
                cb('log', (f"Attempting codec recovery: {file_name}", "INFO"))
                fixed_path = self.fix_codec_remux(filepath)
                if self.verify_repair(fixed_path):
                    try:
                        new_filepath = os.path.splitext(filepath)[0] + ".mp4"
                        if os.path.exists(new_filepath) and new_filepath.lower() != filepath.lower():
                            os.remove(new_filepath)
                        shutil.move(fixed_path, new_filepath)
                        if new_filepath.lower() != filepath.lower():
                            if delete_broken:
                                os.remove(filepath)
                            else:
                                shutil.move(filepath, os.path.join(broken_path, os.path.basename(filepath)))
                        cb('log', (f"CODEC RECOVERED: {file_name}", "SUCCESS"))
                        stats['fixed_codec'] += 1
                        cache[cache_key] = "Fixed-Codec"
                        save_cache()
                        fixed = True
                    except Exception as e:
                        cb('log', (f"Error replacing file: {e}", "ERROR"))
                        safe_log(f"Error replacing: {filepath}. Exception: {e}")
                else:
                    if os.path.exists(fixed_path):
                        try: os.remove(fixed_path)
                        except: pass

            # Strategy 2: VFR Force Fix (always force re-encode for VFR)
            if not fixed and is_vfr:
                cb('log', (f"VFR detected, forcing re-encode: {file_name}", "INFO"))
                fixed_path = self.fix_force(filepath, is_vfr=True)
                if self.verify_repair(fixed_path):
                    try:
                        shutil.move(fixed_path, filepath)
                        cb('log', (f"VFR FIXED: {file_name}", "SUCCESS"))
                        stats['fixed_force'] += 1
                        cache[cache_key] = "Fixed-Force"
                        save_cache()
                        fixed = True
                    except Exception as e:
                        cb('log', (f"Error replacing file: {e}", "ERROR"))
                        safe_log(f"Error replacing: {filepath}. Exception: {e}")
                else:
                    if os.path.exists(fixed_path):
                        try: os.remove(fixed_path)
                        except: pass
                    cb('log', (f"VFR fix failed: {file_name}", "ERROR"))

            # Strategy 3: Light Fix (stream copy)
            if not fixed and not is_vfr:
                cb('log', (f"Attempting light fix: {file_name}", "INFO"))
                fixed_path = self.fix_light(filepath)
                if self.verify_repair(fixed_path):
                    try:
                        shutil.move(fixed_path, filepath)
                        cb('log', (f"LIGHT FIXED: {file_name}", "SUCCESS"))
                        stats['fixed_light'] += 1
                        cache[cache_key] = "Fixed-Light"
                        save_cache()
                        fixed = True
                    except Exception as e:
                        cb('log', (f"Error replacing file: {e}", "ERROR"))
                        safe_log(f"Error replacing: {filepath}. Exception: {e}")
                else:
                    if os.path.exists(fixed_path):
                        try: os.remove(fixed_path)
                        except: pass

            # Strategy 4: Force Fix (full re-encode)
            if not fixed and (force_fix or is_vfr):
                if not is_vfr:  # Skip if already attempted VFR fix above
                    cb('log', (f"Attempting force fix: {file_name}", "INFO"))
                    fixed_path = self.fix_force(filepath, is_vfr=False)
                    if self.verify_repair(fixed_path):
                        try:
                            shutil.move(fixed_path, filepath)
                            cb('log', (f"FORCE FIXED: {file_name}", "SUCCESS"))
                            stats['fixed_force'] += 1
                            cache[cache_key] = "Fixed-Force"
                            save_cache()
                            fixed = True
                        except Exception as e:
                            cb('log', (f"Error replacing file: {e}", "ERROR"))
                            safe_log(f"Error replacing: {filepath}. Exception: {e}")
                    else:
                        if os.path.exists(fixed_path):
                            try: os.remove(fixed_path)
                            except: pass

            # All strategies failed
            if not fixed:
                cb('log', (f"FAILED: {file_name}", "ERROR"))
                safe_log(f"Failed: {filepath}")
                stats['failed'] += 1
                try:
                    if delete_broken:
                        os.remove(filepath)
                        cb('log', (f"Deleted: {file_name}", "INFO"))
                    else:
                        dest = os.path.join(broken_path, os.path.basename(filepath))
                        if os.path.exists(dest):
                            base, ext = os.path.splitext(os.path.basename(filepath))
                            dest = os.path.join(broken_path, f"{base}_{int(time.time())}{ext}")
                        shutil.move(filepath, dest)
                        cb('log', (f"Moved to Broken Files: {file_name}", "INFO"))
                except Exception as e:
                    cb('log', (f"Error moving/deleting: {e}", "ERROR"))
                    safe_log(f"Error moving/deleting: {filepath}. Exception: {e}")
                cache[cache_key] = "Broken"
                save_cache()

            cb('stat', stats.copy())

        cb('done', stats.copy())
        return stats


# ================= GUI APPLICATION =================
class VideoRepairApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Ultimate Video Repair Utility")
        self.root.geometry("960x860")
        self.root.minsize(800, 700)

        # Theme
        self.theme_name = get_system_theme()
        self.theme = THEMES[self.theme_name]

        # Configure root
        self.root.configure(bg=self.theme['bg'])

        # Load saved settings
        self.saved_settings = load_settings()

        # State
        self.is_running = False
        self.engine = None
        self.worker_thread = None
        self.start_time = None
        self.timer_id = None

        # GPU detection cache
        self.gpu_cache = {}

        # Build UI
        self._build_ui()

        # Check FFmpeg
        self._check_ffmpeg()

        # Apply saved settings
        self._apply_saved_settings()

        # Center window
        self.root.update_idletasks()
        x = (self.root.winfo_screenwidth() // 2) - (self.root.winfo_width() // 2)
        y = (self.root.winfo_screenheight() // 2) - (self.root.winfo_height() // 2)
        self.root.geometry(f"+{x}+{y}")

    def _build_ui(self):
        """Build the complete GUI."""
        t = self.theme

        # ---- Scrollable content area ----
        # Main container
        main_frame = tk.Frame(self.root, bg=t['bg'])
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=(15, 0))

        # Header
        header = tk.Frame(main_frame, bg=t['bg'])
        header.pack(fill=tk.X, pady=(0, 15))
        tk.Label(header, text="VIDEO REPAIR PRO", font=("Segoe UI", 20, "bold"),
                bg=t['bg'], fg=t['text']).pack(anchor='w')
        tk.Label(header, text="Automatic scan, verification, and restoration of corrupted media",
                font=("Segoe UI", 11), bg=t['bg'], fg=t['text_sub']).pack(anchor='w')

        # Scrollable canvas
        canvas_frame = tk.Frame(main_frame, bg=t['bg'])
        canvas_frame.pack(fill=tk.BOTH, expand=True)

        self.canvas = tk.Canvas(canvas_frame, bg=t['bg'], highlightthickness=0)
        scrollbar = ttk.Scrollbar(canvas_frame, orient="vertical", command=self.canvas.yview)

        self.scroll_frame = tk.Frame(self.canvas, bg=t['bg'])
        self.scroll_frame.bind("<Configure>", lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")))

        self.canvas.create_window((0, 0), window=self.scroll_frame, anchor="nw")
        self.canvas.configure(yscrollcommand=scrollbar.set)

        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Mouse wheel scrolling
        def _on_mousewheel(event):
            self.canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        self.canvas.bind_all("<MouseWheel>", _on_mousewheel)

        # ---- Cards ----
        # Card 1: Directory
        self._build_directory_card()

        # Card 2+3: Strategy + Intensity (side by side)
        row_frame = tk.Frame(self.scroll_frame, bg=t['bg'])
        row_frame.pack(fill=tk.X, pady=(0, 15))
        row_frame.columnconfigure(0, weight=1)
        row_frame.columnconfigure(1, weight=1)

        self._build_strategy_card(row_frame)
        self._build_intensity_card(row_frame)

        # Card 4: Session Options
        self._build_session_card()

        # Card 5: Progress
        self._build_progress_card()

        # Card 6: Log Console
        self._build_log_card()

        # ---- Bottom bar ----
        bottom = tk.Frame(self.root, bg=t['bg'])
        bottom.pack(fill=tk.X, padx=20, pady=(5, 15))

        # FFmpeg status
        status_frame = tk.Frame(bottom, bg=t['bg'])
        status_frame.pack(side=tk.LEFT)
        tk.Label(status_frame, text="FFmpeg:", font=("Segoe UI", 10),
                bg=t['bg'], fg=t['text']).pack(side=tk.LEFT)
        self.lbl_ffmpeg = tk.Label(status_frame, text="...", font=("Segoe UI", 10, "bold"),
                                  bg=t['bg'], fg=t['text'])
        self.lbl_ffmpeg.pack(side=tk.LEFT, padx=(5, 0))

        # Elapsed time
        self.lbl_elapsed = tk.Label(status_frame, text="", font=("Segoe UI", 10),
                                   bg=t['bg'], fg=t['text_sub'])
        self.lbl_elapsed.pack(side=tk.LEFT, padx=(20, 0))

        # Start button
        self.btn_start = tk.Button(bottom, text="▶  START REPAIR", font=("Segoe UI", 12, "bold"),
                                   bg=t['primary'], fg=t['btn_text'], activebackground=t['hover'],
                                   activeforeground=t['btn_text'], bd=0, padx=30, pady=8,
                                   cursor="hand2", command=self._on_start_click)
        self.btn_start.pack(side=tk.RIGHT)

    def _make_card(self, parent, **kwargs):
        """Create a styled card frame."""
        t = self.theme
        card = tk.Frame(parent, bg=t['card'], bd=1, relief=tk.SOLID, highlightthickness=1,
                       highlightbackground=t['border'], **kwargs)
        return card

    def _build_directory_card(self):
        t = self.theme
        card = self._make_card(self.scroll_frame)
        card.pack(fill=tk.X, pady=(0, 15), ipady=10, ipadx=15)

        tk.Label(card, text="1. SCANNING DIRECTORY", font=("Segoe UI", 10, "bold"),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10, pady=(10, 8))

        path_frame = tk.Frame(card, bg=t['card'])
        path_frame.pack(fill=tk.X, padx=10)

        self.txt_path = tk.Entry(path_frame, font=("Segoe UI", 10), bg=t['input_bg'],
                                fg=t['text'], insertbackground=t['text'], relief=tk.FLAT,
                                highlightthickness=1, highlightbackground=t['border'])
        self.txt_path.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=6)
        self.txt_path.insert(0, os.getcwd())

        self.btn_browse = tk.Button(path_frame, text="Browse", font=("Segoe UI", 10),
                                    bg=t['input_bg'], fg=t['text'], bd=1, relief=tk.SOLID,
                                    cursor="hand2", padx=15, pady=4,
                                    command=self._browse_directory)
        self.btn_browse.pack(side=tk.LEFT, padx=(10, 0))

        opts_frame = tk.Frame(card, bg=t['card'])
        opts_frame.pack(fill=tk.X, padx=10, pady=(10, 5))

        self.chk_recurse_var = tk.BooleanVar()
        self.chk_recurse = tk.Checkbutton(opts_frame, text="Include Subfolders", variable=self.chk_recurse_var,
                                          font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                                          selectcolor=t['input_bg'], activebackground=t['card'],
                                          activeforeground=t['text'])
        self.chk_recurse.pack(side=tk.LEFT)

        self.chk_delete_var = tk.BooleanVar()
        self.chk_delete = tk.Checkbutton(opts_frame, text="Delete broken files", variable=self.chk_delete_var,
                                         font=("Segoe UI", 10), bg=t['card'], fg=t['error'],
                                         selectcolor=t['input_bg'], activebackground=t['card'],
                                         activeforeground=t['error'])
        self.chk_delete.pack(side=tk.LEFT, padx=(20, 0))

    def _build_strategy_card(self, parent):
        t = self.theme
        card = self._make_card(parent)
        card.grid(row=0, column=0, sticky='nsew', padx=(0, 8), ipady=10, ipadx=15)

        tk.Label(card, text="2. STRATEGY", font=("Segoe UI", 10, "bold"),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10, pady=(10, 8))

        tk.Label(card, text="Target Codec", font=("Segoe UI", 9),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10)

        self.combo_codec_var = tk.StringVar(value="H.264")
        self.combo_codec = ttk.Combobox(card, textvariable=self.combo_codec_var,
                                        values=["H.264", "HEVC", "AV1"],
                                        state="readonly", font=("Segoe UI", 10))
        self.combo_codec.pack(fill=tk.X, padx=10, pady=(2, 10))
        self.combo_codec.bind("<<ComboboxSelected>>", lambda e: self._update_gpu_list())

        tk.Label(card, text="Hardware Encoder", font=("Segoe UI", 9),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10)

        self.combo_gpu_var = tk.StringVar()
        self.combo_gpu = ttk.Combobox(card, textvariable=self.combo_gpu_var,
                                      state="readonly", font=("Segoe UI", 10))
        self.combo_gpu.pack(fill=tk.X, padx=10, pady=(2, 5))

        # Encoder name label
        self.lbl_encoder = tk.Label(card, text="", font=("Segoe UI", 9),
                                    bg=t['card'], fg=t['text_sub'])
        self.lbl_encoder.pack(anchor='w', padx=10)

        # Initialize GPU list
        self._update_gpu_list()

    def _build_intensity_card(self, parent):
        t = self.theme
        card = self._make_card(parent)
        card.grid(row=0, column=1, sticky='nsew', padx=(8, 0), ipady=10, ipadx=15)

        tk.Label(card, text="3. INTENSITY", font=("Segoe UI", 10, "bold"),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10, pady=(10, 12))

        self.intensity_var = tk.StringVar(value="standard")

        tk.Radiobutton(card, text="Standard Fix", variable=self.intensity_var, value="standard",
                      font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                      selectcolor=t['input_bg'], activebackground=t['card'],
                      activeforeground=t['text']).pack(anchor='w', padx=10, pady=(0, 8))

        tk.Radiobutton(card, text="Aggressive Fix", variable=self.intensity_var, value="aggressive",
                      font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                      selectcolor=t['input_bg'], activebackground=t['card'],
                      activeforeground=t['text']).pack(anchor='w', padx=10, pady=(0, 8))

        tk.Label(card, text="VFR issues are always force-fixed\nregardless of intensity setting.",
                font=("Segoe UI", 8), bg=t['card'], fg=t['text_sub'],
                justify=tk.LEFT).pack(anchor='w', padx=10, pady=(5, 0))

    def _build_session_card(self):
        t = self.theme
        card = self._make_card(self.scroll_frame)
        card.pack(fill=tk.X, pady=(0, 15), ipady=10, ipadx=15)

        tk.Label(card, text="4. SESSION OPTIONS", font=("Segoe UI", 10, "bold"),
                bg=t['card'], fg=t['text_sub']).pack(anchor='w', padx=10, pady=(10, 8))

        self.chk_resume_var = tk.BooleanVar(value=True)
        tk.Checkbutton(card, text="Enable Resume Functionality", variable=self.chk_resume_var,
                      font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                      selectcolor=t['input_bg'], activebackground=t['card'],
                      activeforeground=t['text']).pack(anchor='w', padx=10, pady=(0, 4))

        self.chk_cache_var = tk.BooleanVar(value=True)
        tk.Checkbutton(card, text="Enable Cache for Faster Processing", variable=self.chk_cache_var,
                      font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                      selectcolor=t['input_bg'], activebackground=t['card'],
                      activeforeground=t['text']).pack(anchor='w', padx=10, pady=(0, 4))

        self.chk_log_var = tk.BooleanVar(value=True)
        tk.Checkbutton(card, text="Enable Log", variable=self.chk_log_var,
                      font=("Segoe UI", 10), bg=t['card'], fg=t['text'],
                      selectcolor=t['input_bg'], activebackground=t['card'],
                      activeforeground=t['text']).pack(anchor='w', padx=10, pady=(0, 5))

    def _build_progress_card(self):
        t = self.theme
        card = self._make_card(self.scroll_frame)
        card.pack(fill=tk.X, pady=(0, 15), ipady=10, ipadx=15)

        # Progress header
        prog_header = tk.Frame(card, bg=t['card'])
        prog_header.pack(fill=tk.X, padx=10, pady=(10, 5))

        self.lbl_progress = tk.Label(prog_header, text="Ready", font=("Segoe UI", 10),
                                     bg=t['card'], fg=t['text'])
        self.lbl_progress.pack(side=tk.LEFT)

        self.lbl_percent = tk.Label(prog_header, text="0%", font=("Segoe UI", 11, "bold"),
                                    bg=t['card'], fg=t['primary'])
        self.lbl_percent.pack(side=tk.RIGHT)

        # Progress bar
        style = ttk.Style()
        style.theme_use('default')
        style.configure("Custom.Horizontal.TProgressbar",
                        troughcolor=t['progress_bg'],
                        background=t['primary'],
                        thickness=12)

        self.progress_bar = ttk.Progressbar(card, style="Custom.Horizontal.TProgressbar",
                                            orient=tk.HORIZONTAL, mode='determinate')
        self.progress_bar.pack(fill=tk.X, padx=10, pady=(0, 10))

        # File counter
        self.lbl_file_count = tk.Label(card, text="0 / 0 files", font=("Segoe UI", 9),
                                       bg=t['card'], fg=t['text_sub'])
        self.lbl_file_count.pack(anchor='w', padx=10, pady=(0, 10))

        # Statistics row
        stats_frame = tk.Frame(card, bg=t['card'])
        stats_frame.pack(fill=tk.X, padx=10, pady=(0, 10))
        stats_frame.columnconfigure(0, weight=1)
        stats_frame.columnconfigure(1, weight=1)
        stats_frame.columnconfigure(2, weight=1)

        # Success stat
        s1 = tk.Frame(stats_frame, bg=t['card'])
        s1.grid(row=0, column=0)
        tk.Label(s1, text="SUCCESS", font=("Segoe UI", 9, "bold"),
                bg=t['card'], fg=t['success']).pack()
        self.stat_success = tk.Label(s1, text="0", font=("Segoe UI", 18, "bold"),
                                     bg=t['card'], fg=t['text'])
        self.stat_success.pack()

        # Fixed stat
        s2 = tk.Frame(stats_frame, bg=t['card'])
        s2.grid(row=0, column=1)
        tk.Label(s2, text="FIXED", font=("Segoe UI", 9, "bold"),
                bg=t['card'], fg=t['accent']).pack()
        self.stat_fixed = tk.Label(s2, text="0", font=("Segoe UI", 18, "bold"),
                                   bg=t['card'], fg=t['text'])
        self.stat_fixed.pack()

        # Failed stat
        s3 = tk.Frame(stats_frame, bg=t['card'])
        s3.grid(row=0, column=2)
        tk.Label(s3, text="FAILED", font=("Segoe UI", 9, "bold"),
                bg=t['card'], fg=t['error']).pack()
        self.stat_failed = tk.Label(s3, text="0", font=("Segoe UI", 18, "bold"),
                                    bg=t['card'], fg=t['text'])
        self.stat_failed.pack()

    def _build_log_card(self):
        t = self.theme
        card = self._make_card(self.scroll_frame)
        card.pack(fill=tk.X, pady=(0, 10), ipady=5, ipadx=5)

        self.txt_log = tk.Text(card, font=("Consolas", 10), bg=t['log_bg'], fg=t['text'],
                              relief=tk.FLAT, height=10, wrap=tk.WORD, state=tk.DISABLED,
                              insertbackground=t['text'], highlightthickness=0)
        self.txt_log.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Configure log tags for colored messages
        self.txt_log.tag_configure("INFO", foreground=t['text_sub'])
        self.txt_log.tag_configure("SUCCESS", foreground=t['success'])
        self.txt_log.tag_configure("WARNING", foreground=t['warning'])
        self.txt_log.tag_configure("ERROR", foreground=t['error'])
        self.txt_log.tag_configure("TIMESTAMP", foreground=t['text_sub'])

    # ================= UI Actions =================
    def _browse_directory(self):
        current = self.txt_path.get()
        folder = filedialog.askdirectory(initialdir=current, title="Select Directory to Scan")
        if folder:
            self.txt_path.delete(0, tk.END)
            self.txt_path.insert(0, os.path.normpath(folder))

    def _check_ffmpeg(self):
        if check_ffmpeg():
            self.lbl_ffmpeg.config(text="ACTIVE", fg=self.theme['success'])
        else:
            self.lbl_ffmpeg.config(text="MISSING", fg=self.theme['error'])

    def _update_gpu_list(self):
        codec = self.combo_codec_var.get()
        if codec in self.gpu_cache:
            gpu_results = self.gpu_cache[codec]
        else:
            gpu_results = detect_gpu_encoder(codec)
            self.gpu_cache[codec] = gpu_results

        values = []
        self._gpu_data = {}
        for vendor in ["CPU", "NVIDIA", "AMD", "Intel"]:
            available, encoder = gpu_results[vendor]
            status = "✓" if available else "✗"
            label = f"{status}  {vendor} ({encoder})"
            values.append(label)
            self._gpu_data[label] = {'vendor': vendor, 'encoder': encoder, 'available': available}

        self.combo_gpu['values'] = values
        self.combo_gpu.set(values[0])
        self._on_gpu_change()
        self.combo_gpu.bind("<<ComboboxSelected>>", lambda e: self._on_gpu_change())

    def _on_gpu_change(self):
        selected = self.combo_gpu_var.get()
        if selected in self._gpu_data:
            data = self._gpu_data[selected]
            status = "Confirmed" if data['available'] else "Not Available"
            self.lbl_encoder.config(text=f"Encoder: {data['encoder']} — {status}")

    def _get_selected_encoder(self):
        selected = self.combo_gpu_var.get()
        if selected in self._gpu_data:
            return self._gpu_data[selected]['encoder']
        return "libx264"

    def _apply_saved_settings(self):
        s = self.saved_settings
        if 'directory' in s and os.path.isdir(s['directory']):
            self.txt_path.delete(0, tk.END)
            self.txt_path.insert(0, s['directory'])
        if 'codec' in s:
            self.combo_codec_var.set(s['codec'])
            self._update_gpu_list()
        if 'gpu' in s:
            values = self.combo_gpu['values']
            for v in values:
                if s['gpu'] in v:
                    self.combo_gpu_var.set(v)
                    self._on_gpu_change()
                    break
        if 'intensity' in s:
            self.intensity_var.set(s['intensity'])
        if 'recurse' in s:
            self.chk_recurse_var.set(s['recurse'])
        if 'delete' in s:
            self.chk_delete_var.set(s['delete'])
        if 'resume' in s:
            self.chk_resume_var.set(s['resume'])
        if 'cache' in s:
            self.chk_cache_var.set(s['cache'])
        if 'log' in s:
            self.chk_log_var.set(s['log'])

    def _save_current_settings(self):
        selected_gpu = self.combo_gpu_var.get()
        gpu_vendor = ""
        if selected_gpu in self._gpu_data:
            gpu_vendor = self._gpu_data[selected_gpu]['vendor']

        settings = {
            'directory': self.txt_path.get(),
            'codec': self.combo_codec_var.get(),
            'gpu': gpu_vendor,
            'intensity': self.intensity_var.get(),
            'recurse': self.chk_recurse_var.get(),
            'delete': self.chk_delete_var.get(),
            'resume': self.chk_resume_var.get(),
            'cache': self.chk_cache_var.get(),
            'log': self.chk_log_var.get(),
        }
        save_settings(settings)

    def _add_log(self, msg, severity="INFO"):
        self.txt_log.config(state=tk.NORMAL)
        timestamp = datetime.now().strftime('%H:%M:%S')
        self.txt_log.insert(tk.END, f"[{timestamp}] ", "TIMESTAMP")
        self.txt_log.insert(tk.END, f"[{severity}] ", severity)
        self.txt_log.insert(tk.END, f"{msg}\n", severity if severity != "INFO" else "")
        self.txt_log.see(tk.END)
        self.txt_log.config(state=tk.DISABLED)

    def _update_elapsed_timer(self):
        if self.is_running and self.start_time:
            elapsed = time.time() - self.start_time
            hours = int(elapsed // 3600)
            minutes = int((elapsed % 3600) // 60)
            seconds = int(elapsed % 60)
            if hours > 0:
                time_str = f"Elapsed: {hours:02d}:{minutes:02d}:{seconds:02d}"
            else:
                time_str = f"Elapsed: {minutes:02d}:{seconds:02d}"
            self.lbl_elapsed.config(text=time_str)
            self.timer_id = self.root.after(1000, self._update_elapsed_timer)

    def _set_ui_state(self, running):
        """Enable/disable UI elements based on running state."""
        state = tk.DISABLED if running else tk.NORMAL
        self.btn_browse.config(state=state)
        self.txt_path.config(state=state)
        self.combo_codec.config(state="disabled" if running else "readonly")
        self.combo_gpu.config(state="disabled" if running else "readonly")
        self.chk_recurse.config(state=state)
        self.chk_delete.config(state=state)

        if running:
            self.btn_start.config(text="⏹  STOP", bg=self.theme['error'],
                                 activebackground="#C0392B")
        else:
            self.btn_start.config(text="▶  START REPAIR", bg=self.theme['primary'],
                                 activebackground=self.theme['hover'])

    def _on_start_click(self):
        if self.is_running:
            # Stop
            if self.engine:
                self.engine.cancel()
            self._add_log("Cancelling...", "WARNING")
            return

        # Validate
        directory = self.txt_path.get()
        if not os.path.isdir(directory):
            messagebox.showerror("Error", "Please select a valid directory.")
            return

        if not check_ffmpeg():
            messagebox.showerror("Error", "FFmpeg is not installed or not in PATH.")
            return

        # Save settings
        self._save_current_settings()

        # Reset stats
        self.stat_success.config(text="0")
        self.stat_fixed.config(text="0")
        self.stat_failed.config(text="0")
        self.progress_bar['value'] = 0
        self.lbl_percent.config(text="0%")
        self.lbl_file_count.config(text="Scanning...")
        self.lbl_progress.config(text="Scanning for video files...")

        # Clear log
        self.txt_log.config(state=tk.NORMAL)
        self.txt_log.delete(1.0, tk.END)
        self.txt_log.config(state=tk.DISABLED)

        self.is_running = True
        self._set_ui_state(True)

        # Start timer
        self.start_time = time.time()
        self._update_elapsed_timer()

        # Launch worker thread
        self.worker_thread = threading.Thread(target=self._worker, daemon=True)
        self.worker_thread.start()

    def _worker(self):
        """Background worker thread for file processing."""
        directory = self.txt_path.get()
        recurse = self.chk_recurse_var.get()
        encoder = self._get_selected_encoder()
        codec = self.combo_codec_var.get()
        force_fix = self.intensity_var.get() == "aggressive"
        delete_broken = self.chk_delete_var.get()
        use_cache = self.chk_cache_var.get()
        use_resume = self.chk_resume_var.get()
        use_log = self.chk_log_var.get()

        # Create engine
        self.engine = RepairEngine(encoder, codec, log_callback=lambda m, s: self.root.after(0, self._add_log, m, s))

        # Scan files
        self.root.after(0, self._add_log, f"Scanning directory: {directory}", "INFO")
        files = get_all_files(directory, recurse)
        total = len(files)

        self.root.after(0, self._add_log, f"Found {total} video file(s)", "INFO")
        self.root.after(0, lambda: self.lbl_file_count.config(text=f"0 / {total} files"))

        if total == 0:
            self.root.after(0, self._add_log, "No video files found in the selected directory.", "WARNING")
            self.root.after(0, self._on_complete, {'ok': 0, 'fixed_light': 0, 'fixed_codec': 0, 'fixed_force': 0, 'failed': 0, 'skipped': 0})
            return

        def progress_callback(msg_type, data):
            if msg_type == 'progress':
                self.root.after(0, self._update_progress, data)
            elif msg_type == 'log':
                self.root.after(0, self._add_log, data[0], data[1])
            elif msg_type == 'stat':
                self.root.after(0, self._update_stats, data)
            elif msg_type == 'done':
                self.root.after(0, self._on_complete, data)

        self.engine.process_files(
            files, directory, recurse, delete_broken, force_fix,
            use_cache, use_resume, use_log, progress_callback
        )

    def _update_progress(self, data):
        current = data['current']
        total = data['total']
        pct = round((current / total) * 100) if total > 0 else 0
        self.progress_bar['value'] = pct
        self.lbl_percent.config(text=f"{pct}%")
        self.lbl_file_count.config(text=f"{current} / {total} files")
        self.lbl_progress.config(text=f"Processing: {data['file']}")

    def _update_stats(self, stats):
        self.stat_success.config(text=str(stats['ok']))
        total_fixed = stats['fixed_light'] + stats['fixed_codec'] + stats['fixed_force']
        self.stat_fixed.config(text=str(total_fixed))
        self.stat_failed.config(text=str(stats['failed']))

    def _on_complete(self, stats):
        self.is_running = False
        self._set_ui_state(False)

        if self.timer_id:
            self.root.after_cancel(self.timer_id)
            self.timer_id = None

        # Final update
        self._update_stats(stats)
        total_fixed = stats['fixed_light'] + stats['fixed_codec'] + stats['fixed_force']

        elapsed = time.time() - self.start_time if self.start_time else 0
        minutes = int(elapsed // 60)
        seconds = int(elapsed % 60)

        self.lbl_progress.config(text="✅ Complete!")
        self.btn_start.config(text="▶  START REPAIR", bg=self.theme['primary'],
                             activebackground=self.theme['hover'])

        self._add_log(f"═══════════════════════════════════════", "INFO")
        self._add_log(f"COMPLETE — OK: {stats['ok']}  |  Fixed: {total_fixed}  |  Failed: {stats['failed']}  |  Skipped: {stats['skipped']}", "SUCCESS")
        self._add_log(f"Total time: {minutes}m {seconds}s", "INFO")
        self._add_log(f"═══════════════════════════════════════", "INFO")

        # Show completion message
        messagebox.showinfo("Repair Complete",
                           f"Scan finished in {minutes}m {seconds}s\n\n"
                           f"✅ OK: {stats['ok']}\n"
                           f"🛠️ Fixed: {total_fixed}\n"
                           f"❌ Failed: {stats['failed']}\n"
                           f"⏭️ Skipped: {stats['skipped']}")

    def run(self):
        self.root.mainloop()


# ================= ENTRY POINT =================
if __name__ == "__main__":
    app = VideoRepairApp()
    app.run()
