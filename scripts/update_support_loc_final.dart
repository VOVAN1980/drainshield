import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, Map<String, String>> translations = {
    'en': { 'label': 'Email Support', 'time': 'Response time: < 24h', 'title': 'How can we help?', 'sub': 'Our team is here to help you 24/7.' },
    'ru': { 'label': 'Поддержка по почте', 'time': 'Ответ в течение 24ч', 'title': 'Как мы можем помочь?', 'sub': 'Наша команда на связи 24/7.' },
    'de': { 'label': 'E-Mail-Unterstützung', 'time': 'Antwortzeit: < 24 Std.', 'title': 'Wie können wir helfen?', 'sub': 'Unser Team ist 24/7 für Sie da.' },
    'fr': { 'label': 'Support par e-mail', 'time': 'Délai de réponse : < 24h', 'title': 'Comment pouvons-nous aider ?', 'sub': 'Notre équipe est là pour vous 24/7.' },
    'es': { 'label': 'Soporte por correo', 'time': 'Tiempo de respuesta: < 24h', 'title': '¿Cómo podemos ayudar?', 'sub': 'Nuestro equipo está aquí 24/7.' },
    'pt': { 'label': 'Suporte por e-mail', 'time': 'Tempo de resposta: < 24h', 'title': 'Como podemos ajudar?', 'sub': 'Nossa equipe está aqui 24/7.' },
    'tr': { 'label': 'E-posta Destek', 'time': 'Yanıt süresi: < 24 saat', 'title': 'Nasıl yardımcı olabiliriz?', 'sub': 'Ekibimiz 7/24 hizmetinizdedir.' },
    'ar': { 'label': 'الدعم عبر البريد', 'time': 'وقت الرد: أقل من 24 ساعة', 'title': 'كيف يمكننا مساعدتك؟', 'sub': 'فريقنا هنا لمساعدتك 24/7.' },
    'zh': { 'label': '邮件支持', 'time': '响应时间：< 24小时', 'title': '我们能为您做些什么？', 'sub': '我们的团队全天候为您服务。' },
    'hi': { 'label': 'ईमेल सहायता', 'time': 'जवाब का समय: < 24 घंटे', 'title': 'हम आपकी क्या सहायता कर सकते हैं?', 'sub': 'हमारी टीम आपकी सहायता के लिए 24/7 यहाँ है।' },
    'ja': { 'label': 'メールサポート', 'time': '返信時間：24時間以内', 'title': 'どのようにお手伝いできますか？', 'sub': '私たちのチームが24時間体制でサポートします。' },
    'ko': { 'label': '이메일 지원', 'time': '응답 시간: 24시간 이내', 'title': '무엇을 도와드릴까요?', 'sub': '저희 팀이 연중무휴로 도와드립니다.' },
    'it': { 'label': 'Supporto e-mail', 'time': 'Tempo di risposta: < 24 ore', 'title': 'Come possiamo aiutarti?', 'sub': 'Il nostro team è qui per te 24/7.' },
    'pl': { 'label': 'Wsparcie e-mail', 'time': 'Czas odpowiedzi: < 24h', 'title': 'W czym możemy pomóc?', 'sub': 'Nasz zespół jest dostępny 24/ Польше.' }, // Fixed Polish time later
    'uk': { 'label': 'Підтримка поштою', 'time': 'Відповідь протягом 24г', 'title': 'Як ми можемо допомогти?', 'sub': 'Наша команда на зв\'язку 24/7.' },
    'id': { 'label': 'Dukungan Email', 'time': 'Waktu respon: < 24 jam', 'title': 'Ada yang bisa kami bantu?', 'sub': 'Tim kami siap membantu Anda 24/7.' },
    'vi': { 'label': 'Hỗ trợ qua email', 'time': 'Thời gian phản hồi: < 24 giờ', 'title': 'Chúng tôi có thể giúp gì cho bạn?', 'sub': 'Đội ngũ của chúng tôi luôn trực 24/7.' }
  };

  // Correction for Polish time
  translations['pl']!['time'] = 'Czas odpowiedzi: < 24h';
  translations['pl']!['sub'] = 'Nasz zespół jest dostępny 24/7.';

  translations.forEach((lang, values) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsSupportEmailLabel'] = values['label'];
      content['settingsSupportEmailValue'] = 'info@ibiticoin.com';
      content['settingsSupportResponseTime'] = values['time'];
      content['settingsSupportTitle'] = values['title'];
      content['settingsSupportSub'] = values['sub'];
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated assets/i18n/$lang.json');
    }
  });
}
