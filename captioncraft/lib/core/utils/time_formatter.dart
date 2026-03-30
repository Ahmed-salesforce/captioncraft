abstract final class TimeFormatter {
  /// Formats milliseconds as `HH:mm:ss,mmm`
  static String formatMs(int ms) {
    if (ms < 0) ms = 0;
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;
    return '${_pad2(hours)}:${_pad2(minutes)}:${_pad2(seconds)},${_pad3(millis)}';
  }

  /// Parses `HH:mm:ss,mmm` back to milliseconds.
  static int parseMs(String s) {
    final parts = s.split(RegExp('[,:]'));
    if (parts.length != 4) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    final millis = int.tryParse(parts[3]) ?? 0;
    return hours * 3600000 + minutes * 60000 + seconds * 1000 + millis;
  }

  /// Formats milliseconds as short `m:ss` for timeline ticks.
  static String formatMsShort(int ms) {
    if (ms < 0) ms = 0;
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${_pad2(seconds)}';
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _pad3(int n) => n.toString().padLeft(3, '0');
}
