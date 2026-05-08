# Video Repair Utility (PowerShell + FFmpeg)

A simple but powerful PowerShell tool to:
- Scan video files recursively
- Detect corruption using FFmpeg
- Attempt automatic repair (light + force)
- Move or delete unrecoverable files
- Resume progress using cache

## Requirements
- FFmpeg (added to PATH)
- Windows PowerShell

## Usage

**🌟 Recommended: Run via Web (No Download Required)**
Open PowerShell in your target folder and run the following command to launch the script directly:
```powershell
irm https://raw.githubusercontent.com/BishnuMahali/Video-Repair-Utility/main/Video%20Repair%20Utility.ps1 | iex
```

**Local Execution (Downloaded script):**
1. Run script:
   powershell -ExecutionPolicy Bypass -File "Video Repair Utility.ps1"

2. Choose:
   - Directory
   - Repair mode
   - Delete or move broken files

## Features
- Safe repair workflow
- Logging system
- Resume support
- Batch processing

## Notes
- Light fix = fast, no re-encode
- Force fix = slower, re-encodes video

## License

This project is licensed under the MIT License.

Copyright (c) 2026 Bishnu Mahali

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.