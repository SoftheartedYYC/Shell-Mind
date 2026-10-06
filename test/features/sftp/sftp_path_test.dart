import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/sftp/domain/sftp_path.dart';

void main() {
  group('SftpPath.join', () {
    test('joins onto the initial working directory', () {
      expect(SftpPath.join('.', 'etc'), '/etc');
      expect(SftpPath.join('/', 'etc'), '/etc');
      expect(SftpPath.join('', 'etc'), '/etc');
    });

    test('joins onto an absolute directory', () {
      expect(SftpPath.join('/var/log', 'syslog'), '/var/log/syslog');
    });

    test('tolerates trailing slashes', () {
      expect(SftpPath.join('/var/log/', 'syslog'), '/var/log/syslog');
    });

    test('an absolute name replaces the directory', () {
      expect(SftpPath.join('/var/log', '/etc/hosts'), '/etc/hosts');
    });
  });

  group('SftpPath.parent', () {
    test('walks up one level', () {
      expect(SftpPath.parent('/var/log'), '/var');
      expect(SftpPath.parent('/var/log/'), '/var');
      expect(SftpPath.parent('/etc'), '/');
    });

    test('stays put at a root', () {
      expect(SftpPath.parent('/'), '/');
      expect(SftpPath.parent('.'), '.');
    });
  });

  group('SftpPath.baseName', () {
    test('returns the final segment', () {
      expect(SftpPath.baseName('/var/log/syslog'), 'syslog');
      expect(SftpPath.baseName('syslog'), 'syslog');
      expect(SftpPath.baseName('/'), '');
      expect(SftpPath.baseName('.'), '');
    });
  });
}
