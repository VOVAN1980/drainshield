import 'dart:convert';
import 'dart:io';

void main() {
  final dir = Directory('assets/i18n');
  if (!dir.existsSync()) {
    print('Directory assets/i18n not found');
    exit(1);
  }

  bool hasError = false;
  for (final file in dir.listSync()) {
    if (file is File && file.path.endsWith('.json')) {
      try {
        final content = file.readAsStringSync();
        json.decode(content);
        print('OK: ${file.path}');
      } catch (e) {
        print('ERROR in ${file.path}: $e');
        hasError = true;
      }
    }
  }

  if (hasError) {
    exit(1);
  }
}
