# GIF Converter

A simple Windows tool that adds "Convert to GIF" to your right-click menu for video and animation files.

## Features

- Convert videos and animations to GIF with a simple right-click
- Automatic optimization for smaller file sizes
- Supports a wide range of formats:
  - Common video formats (MP4, MKV, AVI, MOV, etc.)
  - Animation formats (WebP, APNG, SWF, etc.)
- Output GIFs are automatically:
  - Scaled to a reasonable size (512px width)
  - Set to 15 FPS for smooth playback
  - Optimized for file size while maintaining quality

## Installation

1. Download `Install.cmd`
2. Right-click `Install.cmd` and select "Run as administrator"
3. Wait for the installation to complete
   - The installer will automatically download and install required dependencies (FFmpeg and Gifsicle)
   - If needed, it will also install the Scoop package manager

## Usage

1. Right-click any supported video or animation file
2. Select "Convert to GIF"
3. Wait for the conversion to complete
4. The converted GIF will appear in the same folder as the source file

## Uninstallation

1. Navigate to `C:\Program Files\GifConverter`
2. Run `Uninstall.cmd` as administrator

Note: The uninstaller will remove the context menu entries and converter scripts, but will leave FFmpeg and Gifsicle installed on your system.

## Requirements

- Windows 10 or later
- Administrator privileges for installation/uninstallation
- Internet connection for downloading dependencies

## Credits

GIF conversion code by [Enderman](https://x.com/endermanch).
