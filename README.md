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