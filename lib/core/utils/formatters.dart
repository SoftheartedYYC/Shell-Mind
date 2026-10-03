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

/// Formats an elapsed [Duration] as a compact, human-friendly execution time.
///
/// Tuned for the sub-minute durations a shell command typically takes:
/// `850 ms`, `1.24 s`, `2 min 5 s`. Returns `—` for negative input so call
/// sites can render a placeholder instead of a bogus value.
String formatElapsed(Duration d) {
  if (d.isNegative) return '—';
  final int ms = d.inMilliseconds;
  if (ms < 1000) return '$ms ms';
  if (d.inMinutes < 1) {
    return '${(ms / 1000).toStringAsFixed(2)} s';
  }
  final int m = d.inMinutes;
  final int s = d.inSeconds % 60;
  return '$m min $s s';
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

/// Masks a host/IP [address] for privacy display: `43.***.***.50`.
///
/// IPv4 keeps the first and last octet; anything else (IPv6, hostnames,
/// already-short strings) collapses to `***` after a trimmed 1-char head.
/// Returns the input unchanged when it is empty or [enabled] is false.
String maskHostAddress(String address, {bool enabled = true}) {
  if (!enabled || address.trim().isEmpty) return address;
  final String host = address.trim();
  // IPv4: keep first + last octet.
  final List<String> octets = host.split('.');
  if (octets.length == 4 && octets.every((String o) => o.isNotEmpty)) {
    return '${octets.first}.***.***.${octets.last}';
  }
  // Fallback: show a trimmed head, mask the rest.
  if (host.length <= 2) return '***';
  return '${host.substring(0, 1)}***';
}