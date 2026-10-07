import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Saves [bytes] to a user-chosen location via the system "Save as" dialog
/// (on Android this is the Storage Access Framework's `ACTION_CREATE_DOCUMENT`,
/// so the user can pick Downloads, a Documents folder, Drive providers, etc.).
///
/// Returns the chosen file path/name, or `null` when the user cancels. A
/// failure (unavailable picker, I/O error) propagates as an exception so the
/// caller can surface a localised error message.
Future<String?> saveBytesAsFile({
  required String fileName,
  required Uint8List bytes,
  required List<String> allowedExtensions,
}) {
  return FilePicker.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    bytes: bytes,
  );
}
