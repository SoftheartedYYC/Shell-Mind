import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../domain/entities/remote_file.dart';

/// Thin wrapper around `dartssh2`'s [SftpClient] exposing domain-level
/// operations (list / read / write / mkdir / delete / rename / download).
///
/// All methods throw on transport errors; the provider layer converts those
/// into user-facing failures. The caller owns the underlying [SftpClient] and
/// must call [close] when done.
class SftpService {
  SftpService(this._client);

  final SftpClient _client;

  /// Resolves [path] to its canonical absolute form.
  Future<String> absolute(String path) => _client.absolute(path);

  /// Lists [path], omitting `.` and `..` and mapping to [RemoteFileEntry]s.
  /// Directories first, then case-insensitive by name.
  Future<List<RemoteFileEntry>> list(String path) async {
    final List<SftpName> names = await _client.listdir(path);
    final List<RemoteFileEntry> entries = <RemoteFileEntry>[
      for (final SftpName n in names)
        if (n.filename != '.' && n.filename != '..')
          RemoteFileEntry(
            name: n.filename,
            isDirectory: n.attr.isDirectory,
            isSymbolicLink: n.attr.isSymbolicLink,
            size: n.attr.size,
            modifiedAt: n.attr.modifyTime != null
                ? DateTime.fromMillisecondsSinceEpoch(n.attr.modifyTime! * 1000)
                : null,
            permissions: _permissionString(n.attr),
          ),
    ];
    entries.sort((RemoteFileEntry a, RemoteFileEntry b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  /// Reads up to [maxBytes] of [path] as UTF-8 text (for previewing).
  Future<String> readText(String path, {int maxBytes = 256 * 1024}) async {
    final SftpFile file = await _client.open(path, mode: SftpFileOpenMode.read);
    try {
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final Uint8List chunk in file.read()) {
        builder.add(chunk);
        if (builder.length >= maxBytes) break;
      }
      return utf8.decode(builder.takeBytes(), allowMalformed: true);
    } finally {
      await file.close();
    }
  }

  /// Streams [path] into [destination] (a file sink), reporting progress.
  Future<int> download(
    String path,
    StreamSink<List<int>> destination, {
    void Function(int bytesRead)? onProgress,
  }) =>
      _client.download(path, destination, onProgress: onProgress);

  /// Writes [content] to [path], creating/truncating it.
  Future<void> writeText(String path, String content) async {
    final SftpFile file = await _client.open(
      path,
      mode: SftpFileOpenMode.write |
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate,
    );
    try {
      await file.writeBytes(utf8.encode(content));
    } finally {
      await file.close();
    }
  }

  Future<void> mkdir(String path) => _client.mkdir(path);

  Future<void> delete(String path) => _client.remove(path);

  Future<void> rename(String oldPath, String newPath) =>
      _client.rename(oldPath, newPath);

  Future<void> close() => _client.close();
}

String? _permissionString(SftpFileAttrs attr) {
  final SftpFileMode? mode = attr.mode;
  if (mode == null) return null;
  final StringBuffer sb = StringBuffer();
  sb.write(switch (mode.type) {
    SftpFileType.directory => 'd',
    SftpFileType.symbolicLink => 'l',
    SftpFileType.regularFile => '-',
    _ => '?',
  });
  sb.write(mode.userRead ? 'r' : '-');
  sb.write(mode.userWrite ? 'w' : '-');
  sb.write(mode.userExecute ? 'x' : '-');
  sb.write(mode.groupRead ? 'r' : '-');
  sb.write(mode.groupWrite ? 'w' : '-');
  sb.write(mode.groupExecute ? 'x' : '-');
  sb.write(mode.otherRead ? 'r' : '-');
  sb.write(mode.otherWrite ? 'w' : '-');
  sb.write(mode.otherExecute ? 'x' : '-');
  return sb.toString();
}
