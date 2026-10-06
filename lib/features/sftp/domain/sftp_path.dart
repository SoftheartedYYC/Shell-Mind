/// POSIX-style path helpers for the remote SFTP browser.
///
/// Deliberately dependency-free and pure so the navigation logic is
/// unit-testable without a live SFTP session. Remote paths are always
/// forward-slash separated; `.` denotes the session's initial working
/// directory.
abstract final class SftpPath {
  /// Joins [name] onto [dir] (`.`, `/`, or an absolute path).
  static String join(String dir, String name) {
    if (name.isEmpty) return dir;
    if (name.startsWith('/')) return name;
    if (dir.isEmpty || dir == '.' || dir == '/') return '/$name';
    return '${dir.replaceAll(RegExp(r'/+$'), '')}/$name';
  }

  /// The parent of [path], or [path] itself when already at a root.
  static String parent(String path) {
    if (path.isEmpty || path == '.' || path == '/') return path;
    final String trimmed = path.replaceAll(RegExp(r'/+$'), '');
    final int idx = trimmed.lastIndexOf('/');
    if (idx < 0) return '.';
    if (idx == 0) return '/';
    return trimmed.substring(0, idx);
  }

  /// The final segment of [path] (empty for a root).
  static String baseName(String path) {
    if (path.isEmpty || path == '/' || path == '.') return '';
    final String trimmed = path.replaceAll(RegExp(r'/+$'), '');
    final int idx = trimmed.lastIndexOf('/');
    return idx < 0 ? trimmed : trimmed.substring(idx + 1);
  }
}
