import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/services/storage_inspector.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('storage_inspector_test');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<File> writeFile(String relativePath, int bytes) async {
    final File f = File('${tmp.path}${Platform.pathSeparator}$relativePath');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(List<int>.filled(bytes, 0));
    return f;
  }

  group('CacheBreakdown', () {
    test('total is the sum of hive and download bytes', () {
      const CacheBreakdown b = CacheBreakdown(hiveBytes: 30, downloadBytes: 12);
      expect(b.totalBytes, 42);
    });

    test('defaults to zero', () {
      expect(const CacheBreakdown().totalBytes, 0);
    });
  });

  group('StorageInspector.sumFiles', () {
    test('returns 0 for a non-existent directory', () async {
      final Directory missing = Directory('${tmp.path}${Platform.pathSeparator}nope');
      expect(await StorageInspector.sumFiles(missing), 0);
    });

    test('returns 0 for an empty directory', () async {
      expect(await StorageInspector.sumFiles(tmp), 0);
    });

    test('sums every file (non-recursive, top level)', () async {
      await writeFile('a.bin', 100);
      await writeFile('b.bin', 50);
      expect(await StorageInspector.sumFiles(tmp), 150);
    });

    test('applies the include filter', () async {
      await writeFile('box.hive', 200);
      await writeFile('box.hivec', 30);
      await writeFile('ignored.txt', 999);
      final int hive = await StorageInspector.sumFiles(
        tmp,
        include: (String p) =>
            p.toLowerCase().endsWith('.hive') ||
            p.toLowerCase().endsWith('.hivec'),
      );
      expect(hive, 230);
    });

    test('descends into subdirectories when recursive', () async {
      await writeFile('top.bin', 10);
      await writeFile('nested${Platform.pathSeparator}deep.bin', 40);

      final int shallow = await StorageInspector.sumFiles(tmp);
      expect(shallow, 10);

      final int deep = await StorageInspector.sumFiles(tmp, recursive: true);
      expect(deep, 50);
    });
  });

  group('StorageInspector without a wired UpdateService', () {
    test('downloadBytes is 0 when no service is injected', () async {
      final StorageInspector inspector = StorageInspector();
      expect(await inspector.downloadBytes(), 0);
      expect(await inspector.clearDownloadCache(), 0);
    });
  });
}
