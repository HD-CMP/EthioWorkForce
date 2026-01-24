# Audio Assets

This directory should contain the following audio files for enhanced user feedback:

- **success.mp3** - Played when attendance is successfully registered
- **error.mp3** - Played when an error occurs (invalid QR code, network error, etc.)
- **warning.mp3** - Played when a worker is already registered

## Fallback Behavior

If audio files are not available, the app will gracefully fall back to:
- Amharic TTS (Text-to-Speech) voice announcements only
- Visual feedback overlays will still work normally

This ensures the app never crashes due to missing audio files.

## Audio File Specifications

- **Format**: MP3 or WAV
- **Duration**: 0.5-2 seconds (short feedback sounds)
- **Quality**: 128kbps MP3 or 16-bit WAV
- **Volume**: Normalized to -3dB to prevent clipping

## Adding Audio Files

1. Place audio files in this directory
2. Ensure filenames match exactly: `success.mp3`, `error.mp3`, `warning.mp3`
3. Run `flutter pub get` to refresh assets
4. Test audio feedback in Settings > Accessibility > Audio Feedback
