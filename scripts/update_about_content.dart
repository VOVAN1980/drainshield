import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, String> translations = {
    'en': """DrainShield is a premium blockchain security suite dedicated to protecting digital assets in the evolving Web3 landscape. Our application provides real-time monitoring, advanced threat intelligence, and seamless vulnerability assessment directly on your device.

Our Mission:
To empower blockchain users with institutional-grade security tools, ensuring every transaction is safe and every approval is transparent.

DrainShield is developed with a privacy-first approach, ensuring that your keys never leave your device and your security remains your own.

Website: https://ibiticoin.com
Email: info@ibiticoin.com""",

    'ru': """DrainShield — это премиальный пакет безопасности блокчейна, предназначенный для защиты цифровых активов в развивающемся мире Web3. Наше приложение обеспечивает мониторинг в реальном времени, расширенную аналитику угроз и бесшовную оценку уязвимостей прямо на вашем устройстве.

Наша миссия:
Предоставить пользователям блокчейна инструменты безопасности институционального уровня, гарантируя безопасность каждой транзакции и прозрачность каждого разрешения.

DrainShield разработан с упором на конфиденциальность, гарантируя, что ваши ключи никогда не покинут ваше устройство, а ваша безопасность останется в ваших руках.

Веб-сайт: https://ibiticoin.com
Email: info@ibiticoin.com""",

    'de': """DrainShield ist eine Premium-Blockchain-Sicherheitssuite, die sich dem Schutz digitaler Vermögenswerte in der sich entwickelnden Web3-Landschaft widmet. Unsere Anwendung bietet Echtzeit-Überwachung, fortschrittliche Bedrohungsanalyse und nahtlose Schwachstellenbewertung direkt auf Ihrem Gerät.

Unsere Mission:
Blockchain-Nutzer mit Sicherheitstools auf institutionellem Niveau auszustatten und sicherzustellen, dass jede Transaktion sicher und jede Genehmigung transparent ist.

DrainShield wurde mit einem Privacy-First-Ansatz entwickelt, um sicherzustellen, dass Ihre Schlüssel niemals Ihr Gerät verlassen und Ihre Sicherheit Ihre eigene bleibt.

Website: https://ibiticoin.com
E-Mail: info@ibiticoin.com""",

    'fr': """DrainShield est une suite de sécurité blockchain premium dédiée à la protection des actifs numériques dans le paysage évolutif du Web3. Notre application fournit une surveillance en temps réel, une intelligence avancée sur les menaces et une évaluation fluide des vulnérabilités directement sur votre appareil.

Notre Mission :
Donner aux utilisateurs de la blockchain les moyens d'utiliser des outils de sécurité de niveau institutionnel, en garantissant que chaque transaction est sûre et que chaque approbation est transparente.

DrainShield est développé avec une approche axée sur la confidentialité, garantissant que vos clés ne quittent jamais votre appareil et que votre sécurité reste la vôtre.

Site Web : https://ibiticoin.com
E-mail : info@ibiticoin.com""",

    'es': """DrainShield es una suite de seguridad de blockchain premium dedicada a proteger los activos digitales en el cambiante panorama de Web3. Nuestra aplicación proporciona monitoreo en tiempo real, inteligencia de amenazas avanzada y evaluación de vulnerabilidades sin problemas directamente en su dispositivo.

Nuestra Misión:
Empoderar a los usuarios de blockchain con herramientas de seguridad de grado institucional, asegurando que cada transacción sea segura y cada aprobación sea transparente.

DrainShield se ha desarrollado con un enfoque centrado en la privacidad, garantizando que sus claves nunca salgan de su dispositivo y que su seguridad siga siendo suya.

Sitio web: https://ibiticoin.com
Correo electrónico: info@ibiticoin.com""",

    'pt': """O DrainShield é um conjunto de segurança blockchain premium dedicado à proteção de ativos digitais no cenário em constante evolução da Web3. A nossa aplicação fornece monitorização em tempo real, inteligência de ameaças avançada e avaliação de vulnerabilidades contínua diretamente no seu dispositivo.

A nossa Missão:
Capacitar os utilizadores de blockchain com ferramentas de segurança de nível institucional, garantindo que cada transação é segura e cada aprovação é transparente.

O DrainShield foi desenvolvido com uma abordagem centrada na privacidade, garantindo que as suas chaves nunca saem do seu dispositivo e que a sua segurança permanece sua.

Website: https://ibiticoin.com
E-mail: info@ibiticoin.com""",

    'tr': """DrainShield, gelişen Web3 dünyasında dijital varlıkları korumaya adanmış birinci sınıf bir blok zinciri güvenlik paketidir. Uygulamamız, doğrudan cihazınızda gerçek zamanlı izleme, gelişmiş tehdit istihbaratı ve sorunsuz güvenlik açığı değerlendirmesi sağlar.

Misyonumuz:
Blok zinciri kullanıcılarını kurumsal düzeyde güvenlik araçlarıyla güçlendirmek, her işlemin güvenli ve her onayın şeffaf olmasını sağlamaktır.

DrainShield, anahtarlarınızın asla cihazınızdan çıkmamasını ve güvenliğinizin size ait kalmasını sağlayarak gizlilik odaklı bir yaklaşımla geliştirilmiştir.

Web sitesi: https://ibiticoin.com
E-posta: info@ibiticoin.com""",

    'ar': """DrainShield عبارة عن مجموعة أمان بلوكشين متميزة مخصصة لحماية الأصول الرقمية في مشهد Web3 المتطور. يوفر تطبيقنا مراقبة في الوقت الفعلي واستخبارات متقدمة للتهديدات وتقييمًا سلسًا لنقاط الضعف مباشرة على جهازك.

مهمتنا:
تمكين مستخدمي البلوكشين من خلال أدوات أمان على مستوى المؤسسات، وضمان أن تكون كل معاملة آمنة وكل موافقة شفافة.

تم تطوير DrainShield بنهج يركز على الخصوصية، مما يضمن عدم مغادرة مفاتيحك لجهازك أبدًا وتظل أمانك ملكًا لك.

الموقع الإلكتروني: https://ibiticoin.com
البريد الإلكتروني: info@ibiticoin.com""",

    'zh': """DrainShield 是一款高端区块链安全套件，致力于在不断发展的 Web3 领域保护数字资产。我们的应用程序直接在您的设备上提供实时监控、高级威胁情报和无缝漏洞评估。

我们的使命：
为区块链用户提供机构级安全工具，确保每笔交易安全，每项授权透明。

DrainShield 采用隐私优先的方法开发，确保您的密钥永远不会离开您的设备，您的安全由您掌控。

网站：https://ibiticoin.com
电子邮件：info@ibiticoin.com""",

    'hi': """DrainShield एक प्रीमियम ब्लॉकचेन सुरक्षा सूट है जो विकसित होते वेब3 परिदृश्य में डिजिटल संपत्तियों की सुरक्षा के लिए समर्पित है। हमारा एप्लिकेशन सीधे आपके डिवाइस पर वास्तविक समय की निगरानी, उन्नत खतरे की खुफिया जानकारी और निर्बाध भेद्यता मूल्यांकन प्रदान करता है।

हमारा मिशन:
ब्लॉकचेन उपयोगकर्ताओं को संस्थागत-ग्रेड सुरक्षा उपकरणों के साथ सशक्त बनाना, यह सुनिश्चित करना कि प्रत्येक लेनदेन सुरक्षित है और प्रत्येक अनुमोदन पारदर्शी है।

DrainShield को गोपनीयता-प्रथम दृष्टिकोण के साथ विकसित किया गया है, यह सुनिश्चित करते हुए कि आपकी चाबियां आपके डिवाइस से कभी बाहर नहीं निकलती हैं और आपकी सुरक्षा आपकी अपनी बनी रहती है।

वेबसाइट: https://ibiticoin.com
ईमेल: info@ibiticoin.com""",

    'ja': """DrainShieldは、進化するWeb3の状況においてデジタル資産を保護することに特化したプレミアムブロックチェーンセキュリティスイートです。当社のアプリケーションは、リアルタイムのモニタリング、高度な脅威インテリジェンス、およびシームレスな脆弱性評価をデバイス上で直接提供します。

当社の使命：
ブロックチェーンユーザーに機関投資家レベルのセキュリティツールを提供し、すべての取引が安全で、すべての承認が透明であることを保証することです。

DrainShieldはプライバシー優先のアプローチで開発されており、お客様の鍵がデバイスから離れることはなく、お客様のセキュリティはお客様自身のものであり続けることを保証します。

ウェブサイト：https://ibiticoin.com
メール：info@ibiticoin.com""",

    'ko': """DrainShield는 진화하는 Web3 환경에서 디지털 자산을 보호하는 데 전념하는 프리미엄 블록체인 보안 제품군입니다. 당사의 애플리케이션은 귀하의 장치에서 직접 실시간 모니터링, 고급 위협 인텔리전스 및 원활한 취약점 평가를 제공합니다.

당사의 사명:
블록체인 사용자에게 기관 수준의 보안 도구를 제공하여 모든 트랜잭션이 안전하고 모든 승인이 투명하게 이루어지도록 하는 것입니다.

DrainShield는 개인 정보 보호 우선 원칙으로 개발되어 귀하의 키가 장치를 떠나지 않으며 귀하의 보안이 귀하의 것으로 유지되도록 보장합니다.

웹사이트: https://ibiticoin.com
이메일: info@ibiticoin.com""",

    'it': """DrainShield è una suite di sicurezza blockchain premium dedicata alla protezione delle risorse digitali nel panorama Web3 in continua evoluzione. La nostra applicazione fornisce monitoraggio in tempo reale, intelligence avanzata sulle minacce e valutazione continua delle vulnerabilità direttamente sul tuo dispositivo.

La nostra missione:
Fornire agli utenti blockchain strumenti di sicurezza di livello istituzionale, garantendo che ogni transazione sia sicura e ogni approvazione sia trasparente.

DrainShield è sviluppato con un approccio basato sulla privacy, garantendo che le tue chiavi non lascino mai il tuo dispositivo e che la tua sicurezza rimanga tua.

Sito web: https://ibiticoin.com
E-mail: info@ibiticoin.com""",

    'pl': """DrainShield to pakiet bezpieczeństwa blockchain klasy premium, dedykowany ochronie aktywów cyfrowych w ewoluującym krajobrazie Web3. Nasza aplikacja zapewnia monitorowanie в czasie rzeczywistym, zaawansowaną analizę zagrożeń i bezproblemową ocenę luk bezpośrednio na Twoim urządzeniu.

Nasza Misja:
Wyposażenie użytkowników blockchain w narzędzia bezpieczeństwa klasy instytucjonalnej, zapewniające, że każda transakcja jest bezpieczna, а każde zatwierdzenie przejrzyste.

DrainShield jest rozwijany z podejściem kładącym nacisk na prywatność, co gwarantuje, że Twoje klucze nigdy nie opuszczają Twojego urządzenia, а Twoje bezpieczeństwo pozostaje w Twoich rękach.

Strona internetowa: https://ibiticoin.com
E-mail: info@ibiticoin.com""",

    'uk': """DrainShield — це преміальний пакет безпеки блокчейну, призначений для захисту цифрових активів у світі Web3, що постійно змінюється. Наш додаток забезпечує моніторинг у реальному часі, розширену аналітику загроз та безперешкодну оцінку вразливостей безпосередньо на вашому пристрої.

Наша місія:
Надати користувачам блокчейну інструменти безпеки інституційного рівня, гарантуючи безпеку кожної транзакції та прозорість кожного дозволу.

DrainShield розроблено з пріоритетом на конфіденційність, що гарантує, що ваші ключі ніколи не залишають ваш пристрій, а ваша безпека залишається у ваших руках.

Веб-сайт: https://ibiticoin.com
Електронна пошта: info@ibiticoin.com""",

    'id': """DrainShield adalah rangkaian keamanan blockchain premium yang didedikasikan untuk melindungi aset digital dalam lanskap Web3 yang terus berkembang. Aplikasi kami menyediakan pemantauan real-time, intelijen ancaman tingkat lanjut, dan penilaian kerentanan yang lancar langsung di perangkat Anda.

Misi Kami:
Memberdayakan pengguna blockchain dengan alat keamanan tingkat institusi, memastikan setiap transaksi aman dan setiap persetujuan transparan.

DrainShield dikembangkan dengan pendekatan privasi diutamakan, memastikan kunci Anda tidak pernah meninggalkan perangkat Anda dan keamanan Anda tetap menjadi milik Anda.

Situs web: https://ibiticoin.com
Email: info@ibiticoin.com""",

    'vi': """DrainShield là một bộ bảo mật blockchain cao cấp chuyên bảo vệ các tài sản kỹ thuật số trong bối cảnh Web3 đang phát triển. Ứng dụng của chúng tôi cung cấp khả năng giám sát theo thời gian thực, thông tin tình báo về mối đe dọa tiên tiến và đánh giá lỗ hổng bảo mật liền mạch trực tiếp trên thiết bị của bạn.

Sứ mệnh của Chúng tôi:
Trao quyền cho người dùng blockchain bằng các công cụ bảo mật cấp tổ chức, đảm bảo mọi giao dịch đều an toàn và mọi phê duyệt đều minh bạch.

DrainShield được phát triển với phương pháp tiếp cận ưu tiên quyền riêng tư, đảm bảo rằng mã khóa của bạn không bao giờ rời khỏi thiết bị và bảo mật của bạn luôn là của riêng bạn.

Trang web: https://ibiticoin.com
Email: info@ibiticoin.com"""
  };

  translations.forEach((lang, policy) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsAboutContent'] = policy;
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated About Content in assets/i18n/$lang.json');
    }
  });
}
