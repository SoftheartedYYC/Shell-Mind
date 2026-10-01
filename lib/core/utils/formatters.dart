/// Small human-readable formatting helpers shared across the UI.
library;

/// Formats a byte count using binary units (`1.5 MB`), which matches what
/// users expect from a file manager / download indicator.
///
/// Returns an empty string for negative input so call sites can render
/// `—` instead of a bogus value.
String formatBytes(num bytes, {int decimals = 1}) {
  if (bytes < 0) return '';
  if (bytes == 0) return '0 B';

  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double value = bytes.toDouble();
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }

  // Bytes are integral — a decimal there is just noise.
  final String text =
      i == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(decimals);
  return '$text ${units[i]}';
}

/// Formats a duration as a compact `mm:ss` (or `h:mm:ss`) string, used by the
/// download ETA readout.
String formatDuration(Duration d) {
  if (d.isNegative) return '—';
  final int h = d.inHours;
  final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final String s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Relative "time ago" phrasing for release timestamps (`3 days ago`).
String formatTimeAgo(DateTime time, {DateTime? now}) {
  final Duration diff = (now ?? DateTime.now()).difference(time);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final int m = diff.inMinutes;
    return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
  }
  if (diff.inHours < 24) {
    final int h = diff.inHours;
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inDays < 30) {
    final int d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  if (diff.inDays < 365) {
    final int mo = diff.inDays ~/ 30;
    return '$mo ${mo == 1 ? 'month' : 'months'} ago';
  }
  final int y = diff.inDays ~/ 365;
  return '$y ${y == 1 ? 'year' : 'years'} ago';
}
