import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, String> labels = {
    'en': 'Disclaimer',
    'ru': 'Отказ от ответственности',
    'de': 'Haftungsausschluss',
    'fr': 'Clause de non-responsabilité',
    'es': 'Descargo de responsabilidad',
    'pt': 'Aviso Legal',
    'tr': 'Sorumluluk Reddi',
    'ar': 'إخلاء المسؤولية',
    'zh': '免责声明',
    'hi': 'अस्वीकरण',
    'ja': '免責事項',
    'ko': '면책 조항',
    'it': 'Dichiarazione di non responsabilità',
    'pl': 'Zastrzeżenie prawne',
    'uk': 'Відмова від відповідальності',
    'id': 'Penafian',
    'vi': 'Tuyên bố miễn trừ trách nhiệm'
  };

  labels.forEach((lang, label) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsAboutDisclaimer'] = label;
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated labels in assets/i18n/$lang.json');
    }
  });
}
