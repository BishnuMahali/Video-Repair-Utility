# 🎬 Video Repair Utility

A powerful, dual-GUI video repair tool that automatically scans, detects, and fixes corrupted or problematic video files using FFmpeg.

## ✨ Features

- **Dual GUI** — Modern graphical interface in both **PowerShell WPF** and **Python Tkinter** with dark/light theme support
- **Smart Launcher** — Auto-detects Python availability; falls back to PowerShell seamlessly
- **VFR Detection & Fix** — Detects Variable Frame Rate (common in smartphone recordings) and forces CFR re-encoding
- **Multi-Strategy Repair** — Codec recovery → Light fix (stream copy) → Force fix (re-encode) with automatic escalation
- **Hardware Acceleration** — GPU encoding via NVIDIA (NVENC), AMD (AMF), Intel (QSV) with automatic CPU fallback
- **Quality Preservation** — Extracts original bitrate and applies 120% to prevent quality loss during re-encoding
- **Batch Processing** — Scan entire directories with optional recursive subdirectory scanning
- **Resume & Cache** — Skip already-processed files across sessions
- **Settings Memory** — Remembers your last used configuration between launches
- **Real-Time Dashboard** — Live progress bar, file counter, elapsed timer, per-file statistics, and colored log console

## 📋 Requirements

- **FFmpeg** — must be installed and added to your system PATH
- **Windows** — PowerShell 5.1+ (for WPF version) or Python 3.8+ with tkinter (for Python version)

## 🚀 Usage

### Quick Start (Recommended)
Double-click `Video Repair Utility.bat` — it will automatically choose the best GUI for your system.

### Manual Override
```batch
:: Force Python GUI
"Video Repair Utility.bat" /py

:: Force PowerShell GUI
"Video Repair Utility.bat" /ps
```

### Run via Web (No Download Required)
Open PowerShell in your target folder and run:
```powershell
irm https://raw.githubusercontent.com/BishnuMahali/Video-Repair-Utility/main/Video%20Repair%20Utility.ps1 | Out-String | iex
```

## 🔧 Repair Strategies

| Strategy | Speed | Quality | Use Case |
|----------|-------|---------|----------|
| **Codec Recovery** | ⚡ Instant | Lossless | Legacy containers with missing codec metadata (.avi, .wmv) |
| **Light Fix** | ⚡ Fast | Lossless | Corrupted headers, incomplete downloads |
| **VFR Fix** | 🐢 Slow | Near-lossless | Smartphone VFR recordings with timestamp jitter |
| **Force Fix** | 🐢 Slow | Near-lossless | Severely corrupted streams, dropped frames |

## 🎛️ Supported Codecs & Encoders

| Codec | CPU | NVIDIA | AMD | Intel |
|-------|-----|--------|-----|-------|
| H.264 | libx264 | h264_nvenc | h264_amf | h264_qsv |
| HEVC | libx265 | hevc_nvenc | hevc_amf | hevc_qsv |
| AV1 | libsvtav1 | av1_nvenc | av1_amf | av1_qsv |

> If a GPU encoder fails during repair, the tool automatically falls back to the CPU encoder.

## 📁 File Structure

```
Video Repair Utility/
├── Video Repair Utility.bat    ← Smart launcher
├── Video Repair Utility.ps1    ← PowerShell WPF GUI
├── video_repair_utility.py     ← Python Tkinter GUI
├── LICENSE
└── README.md
```

## License

This project is licensed under the MIT License.

Copyright (c) 2026 Bishnu Mahali

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 🤝 Support & Connect

These projects are simple utility scripts built to solve everyday problems. If you find them helpful in your workflow and would like to support me, any small contribution is deeply appreciated! ❤️

<p align="center">
  <a href="https://buymeacoffee.com/Bishnu"><img src="https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee"></a>
  <a href="https://ko-fi.com/Bishnu"><img src="https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi"></a>
  <a href="https://patreon.com/Bishnu"><img src="https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon"></a>
  <a href="https://paypal.me/beingaash"><img src="https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="PayPal"></a>
</p>

<p align="center">
  <a href="https://github.com/BishnuMahali"><img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"></a>
  <a href="https://bmahali.com"><img src="https://img.shields.io/badge/Website-333333?style=for-the-badge&logo=firefox&logoColor=white" alt="Website"></a>
  <a href="https://youtube.com/@BishnuMahaliPro"><img src="https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="YouTube"></a>
  <a href="https://instagram.com/itsBishnuMahali"><img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram"></a>
  <a href="https://facebook.com/itsBishnuMahali"><img src="https://img.shields.io/badge/Facebook-1877F2?style=for-the-badge&logo=facebook&logoColor=white" alt="Facebook"></a>
  <a href="https://x.com/itsBishnuMahli"><img src="https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white" alt="X (Twitter)"></a>
  <a href="https://linkedin.com/in/bishnumahali"><img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn"></a>
</p>