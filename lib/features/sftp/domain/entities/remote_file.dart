import 'package:flutter/foundation.dart';

/// A single entry in a remote SFTP directory listing.
///
/// A pure value object distilled from `dartssh2`'s `SftpName`/`SftpFileAttrs`
/// so the presentation layer never imports protocol types.
@immutable
class RemoteFileEntry {
  const RemoteFileEntry({
    required this.name,
    required this.isDirectory,
    required this.isSymbolicLink,
    this.size,
    this.modifiedAt,
    this.permissions,
  });

  final String name;

  final bool isDirectory;

  final bool isSymbolicLink;

  /// File size in bytes (`null` for directories / unknown).
  final int? size;

  final DateTime? modifiedAt;

  /// Human-readable permission string (e.g. `-rw-r--r--`), or `null`.
  final String? permissions;

  /// True for a regular file (not a directory and not a symlink).
  bool get isFile => !isDirectory && !isSymbolicLink;

  @override
  String toString() =>
      'RemoteFileEntry($name, dir: $isDirectory, size: $size)';
}
