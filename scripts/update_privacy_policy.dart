import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, String> translations = {
    'en': """Privacy Policy – DrainShield

Last updated: 2026

DrainShield is a mobile security tool designed to help users analyze token approvals and identify potential risks associated with smart-contract permissions.

1. Information We Do Not Collect

DrainShield does not collect or store any of the following:
• Private keys
• Seed phrases
• Wallet passwords
• Personal identity information
• Financial account credentials

DrainShield never requests or has access to your wallet credentials.

2. Wallet Address Usage

When a wallet is connected, the application may temporarily process the public wallet address in order to:
• scan token approvals
• analyze smart-contract permissions
• evaluate potential security risks

Wallet addresses are public blockchain identifiers and are not linked to personal identity by the application.
DrainShield does not store wallet addresses on centralized servers.

3. Blockchain Data

DrainShield reads publicly available blockchain data through third-party RPC providers and indexing services. This may include:
• token approval information
• smart contract metadata
• transaction data

All of this information already exists publicly on the blockchain.

4. Local Storage

DrainShield may store limited information locally on your device to improve functionality, such as:
• application settings
• language preferences
• monitoring configuration
• linked wallet addresses (optional)

No sensitive wallet credentials are stored locally.

5. Third-Party Services

The application may rely on external services to access blockchain data. These providers operate under their own privacy policies.
DrainShield does not share personal user data with third parties.

6. Security

DrainShield is designed to operate without requiring sensitive wallet credentials. All security analysis is performed using publicly available blockchain information.

7. Children's Privacy

DrainShield is not intended for use by individuals under the age of 13.

8. Changes to This Policy

This Privacy Policy may be updated from time to time to reflect service improvements or regulatory requirements.

9. Contact

For support or questions regarding this policy, contact:
info@ibiticoin.com""",

    'ru': """Политика конфиденциальности – DrainShield

Последнее обновление: 2026

DrainShield — это инструмент мобильной безопасности, предназначенный для того, чтобы помочь пользователям анализировать разрешения токенов и выявлять потенциальные риски, связанные с разрешениями смарт-контрактов.

1. Информация, которую мы не собираем

DrainShield не собирает и не хранит ничего из следующего:
• Закрытые ключи
• Сид-фразы
• Пароли кошельков
• Личную идентификационную информацию
• Данные финансовых счетов

DrainShield никогда не запрашивает и не имеет доступа к учетным данным вашего кошелька.

2. Использование адреса кошелька

Когда кошелек подключен, приложение может временно обрабатывать публичный адрес кошелька для:
• сканирования разрешений токенов
• анализа разрешений смарт-контрактов
• оценки потенциальных рисков безопасности

Адреса кошельков являются общедоступными идентификаторами блокчейна и не связываются приложением с личной личностью.
DrainShield не хранит адреса кошельков на централизованных серверах.

3. Данные блокчейна

DrainShield считывает общедоступные данные блокчейна через сторонних поставщиков RPC и службы индексации. Это может включать:
• информацию о разрешениях токенов
• метаданные смарт-контрактов
• данные транзакций

Вся эта информация уже публично существует в блокчейне.

4. Локальное хранилище

DrainShield может хранить ограниченную информацию локально на вашем устройстве для улучшения функциональности, такую как:
• настройки приложения
• языковые предпочтения
• конфигурация мониторинга
• привязанные адреса кошельков (опционально)

Никакие конфиденциальные учетные данные кошелька не хранятся локально.

5. Сторонние службы

Приложение может полагаться на внешние службы для доступа к данным блокчейна. Эти поставщики действуют в соответствии со своими собственными политиками конфиденциальности.
DrainShield не передает личные данные пользователей третьим лицам.

6. Безопасность

DrainShield разработан для работы без необходимости ввода конфиденциальных учетных данных кошелька. Весь анализ безопасности выполняется с использованием общедоступной информации блокчейна.

7. Конфиденциальность детей

DrainShield не предназначен для использования лицами в возрасте до 13 лет.

8. Изменения в этой политике

Эта Политика конфиденциальности может время от времени обновляться для отражения улучшений сервиса или нормативных требований.

9. Контакты

По вопросам поддержки или вопросам, касающимся этой политики, обращайтесь:
info@ibiticoin.com""",

    'de': """Datenschutzerklärung – DrainShield

Zuletzt aktualisiert: 2026

DrainShield ist ein mobiles Sicherheitstool, das Benutzern hilft, Token-Genehmigungen zu analysieren und potenzielle Risiken im Zusammenhang mit Smart-Contract-Berechtigungen zu identifizieren.

1. Informationen, die wir nicht sammeln

DrainShield sammelt oder speichert keine der folgenden Informationen:
• Private Schlüssel
• Seed-Phrasen
• Wallet-Passwörter
• Persönliche Identitätsinformationen
• Zugangsdaten für Finanzkonten

DrainShield fordert niemals Zugriff auf Ihre Wallet-Zugangsdaten an und hat auch keinen Zugriff darauf.

2. Verwendung der Wallet-Adresse

Wenn eine Wallet verbunden ist, kann die Anwendung die öffentliche Wallet-Adresse vorübergehend verarbeiten, um:
• Token-Genehmigungen zu scanen
• Smart-Contract-Berechtigungen zu analysieren
• potenzielle Sicherheitsrisiken zu bewerten

Wallet-Adressen sind öffentliche Blockchain-Identifikatoren und werden von der Anwendung nicht mit der persönlichen Identität verknüpft.
DrainShield speichert Wallet-Adressen nicht auf zentralisierten Servern.

3. Blockchain-Daten

DrainShield liest öffentlich verfügbare Blockchain-Daten über Drittanbieter-RPC-Provider und Indexierungsdienste. Dies kann Folgendes umfassen:
• Informationen über Token-Genehmigungen
• Metadaten von Smart Contracts
• Transaktionsdaten

Alle diese Informationen existieren bereits öffentlich auf der Blockchain.

4. Lokale Speicherung

DrainShield kann begrenzte Informationen lokal auf Ihrem Gerät speichern, um die Funktionalität zu verbessern, wie z. B.:
• Anwendungseinstellungen
• Spracheinstellungen
• Überwachungskonfiguration
• verknüpfte Wallet-Adressen (optional)

Es werden keine sensiblen Wallet-Zugangsdaten lokal gespeichert.

5. Dienste von Drittanbietern

Die Anwendung kann auf externe Dienste angewiesen sein, um auf Blockchain-Daten zuzugreifen. Diese Anbieter unterliegen ihren eigenen Datenschutzrichtlinien.
DrainShield gibt keine persönlichen Benutzerdaten an Dritte weiter.

6. Sicherheit

DrainShield ist so konzipiert, dass es ohne sensible Wallet-Zugangsdaten funktioniert. Alle Sicherheitsanalysen werden unter Verwendung öffentlich verfügbarer Blockchain-Informationen durchgeführt.

7. Privatsphäre von Kindern

DrainShield ist nicht für die Nutzung durch Personen unter 13 Jahren bestimmt.

8. Änderungen an dieser Richtlinie

Diese Datenschutzerklärung kann von Zeit zu Zeit aktualisiert werden, um Serviceverbesserungen oder regulatorische Anforderungen widerzuspiegeln.

9. Kontakt

Bei Supportanfragen oder Fragen zu dieser Richtlinie wenden Sie sich bitte an:
info@ibiticoin.com""",

    'fr': """Politique de confidentialité – DrainShield

Dernière mise à jour : 2026

DrainShield est un outil de sécurité mobile conçu pour aider les utilisateurs à analyser les approbations de jetons et à identifier les risques potentiels associés aux autorisations des contrats intelligents.

1. Informations que nous ne collectons pas

DrainShield ne collecte ni ne stocke aucun des éléments suivants :
• Clés privées
• Phrases de récupération (seed phrases)
• Mots de passe de portefeuille
• Informations d'identité personnelle
• Identifiants de comptes financiers

DrainShield ne demande jamais et n'a jamais accès aux identifiants de votre portefeuille.

2. Utilisation de l'adresse du portefeuille

Lorsqu'un portefeuille est connecté, l'application peut traiter temporairement l'adresse publique du portefeuille afin de :
• scanner les approbations de jetons
• analyser les autorisations des contrats intelligents
• évaluer les risques potentiels pour la sécurité

Les adresses de portefeuille sont des identifiants publics de la blockchain et ne sont pas liées à l'identité personnelle par l'application.
DrainShield ne stocke pas les adresses de portefeuille sur des serveurs centralisés.

3. Données de la blockchain

DrainShield lit les données publiques de la blockchain via des fournisseurs RPC tiers et des services d'indexation. Cela peut inclure :
• des informations sur l'approbation des jetons
• des métadonnées sur les contrats intelligents
• des données sur les transactions

Toutes ces informations existent déjà publiquement sur la blockchain.

4. Stockage local

DrainShield peut stocker des informations limitées localement sur votre appareil pour améliorer les fonctionnalités, telles que :
• les paramètres de l'application
• les préférences linguistiques
• la configuration de la surveillance
• les adresses de portefeuille liées (en option)

Aucun identifiant de portefeuille sensible n'est stocké localement.

5. Services tiers

L'application peut s'appuyer sur des services externes pour accéder aux données de la blockchain. Ces fournisseurs opèrent selon leurs propres politiques de confidentialité.
DrainShield ne partage pas les données personnelles des utilisateurs avec des tiers.

6. Sécurité

DrainShield est conçu pour fonctionner sans nécessiter d'identifiants de portefeuille sensibles. Toutes les analyses de sécurité sont effectuées à l'aide d'informations publiques de la blockchain.

7. Confidentialité des enfants

DrainShield n'est pas destiné à être utilisé par des personnes de moins de 13 ans.

8. Modifications de cette politique

Cette politique de confidentialité peut être mise à jour de temps à autre pour refléter les améliorations du service ou les exigences réglementaires.

9. Contact

Pour toute assistance ou question concernant cette politique, contactez :
info@ibiticoin.com""",

    'es': """Política de privacidad – DrainShield

Última actualización: 2026

DrainShield es una herramienta de seguridad móvil diseñada para ayudar a los usuarios a analizar las aprobaciones de tokens e identificar los riesgos potenciales asociados con los permisos de los contratos inteligentes.

1. Información que no recopilamos

DrainShield no recopila ni almacena nada de lo siguiente:
• Claves privadas
• Frases semilla
• Contraseñas de monederos
• Información de identidad personal
• Credenciales de cuentas financieras

DrainShield nunca solicita ni tiene acceso a las credenciales de su monedero.

2. Uso de la dirección del monedero

Cuando se conecta un monedero, la aplicación puede procesar temporalmente la dirección pública del monedero para:
• escanear aprobaciones de tokens
• analizar permisos de contratos inteligentes
• evaluar posibles riesgos de seguridad

Las direcciones de monedero son identificadores públicos de la blockchain y la aplicación no las vincula con la identidad personal.
DrainShield no almacena direcciones de monederos en servidores centralizados.

3. Datos de la blockchain

DrainShield lee los datos públicos de la blockchain a través de proveedores de RPC de terceros y servicios de indexación. Esto puede incluir:
• información de aprobación de tokens
• metadatos de contratos inteligentes
• datos de transacciones

Toda esta información ya existe públicamente en la blockchain.

4. Almacenamiento local

DrainShield puede almacenar información limitada localmente en su dispositivo para mejorar la funcionalidad, como:
• ajustes de la aplicación
• preferencias de idioma
• configuración de monitorización
• direcciones de monederos vinculados (opcional)

No se almacenan localmente credenciales de monedero sensibles.

5. Servicios de terceros

La aplicación puede depender de servicios externos para acceder a los datos de la blockchain. Estos proveedores operan bajo sus propias políticas de privacidad.
DrainShield no comparte datos personales de los usuarios con terceros.

6. Seguridad

DrainShield está diseñado para funcionar sin requerir credenciales de monedero sensibles. Todo el análisis de seguridad se realiza utilizando información pública de la blockchain.

7. Privacidad de los niños

DrainShield no está destinado a ser utilizado por personas menores de 13 años.

8. Cambios en esta política

Esta Política de Privacidad puede actualizarse de vez en cuando para reflejar mejoras en el servicio o requisitos reglamentarios.

9. Contacto

Para soporte o preguntas relacionadas con esta política, contacte con:
info@ibiticoin.com""",

    'pt': """Política de Privacidade – DrainShield

Última atualização: 2026

O DrainShield é uma ferramenta de segurança móvel concebida para ajudar os utilizadores a analisar as aprovações de tokens e a identificar potenciais riscos associados às permissões de contratos inteligentes.

1. Informações que não recolhemos

O DrainShield não recolhe nem armazena nada do seguinte:
• Chaves privadas
• Frases semente (seed phrases)
• Palavras-passe de carteira
• Informações de identidade pessoal
• Credenciais de contas financeiras

O DrainShield nunca solicita nem tem acesso às credenciais da sua carteira.

2. Utilização do endereço da carteira

Quando uma carteira é ligada, a aplicação pode processar temporariamente o endereço público da carteira para:
• verificar as aprovações de tokens
• analisar as permissões de contratos inteligentes
• avaliar potenciais riscos de segurança

Os endereços das carteiras são identificadores públicos na blockchain e não são associados à identidade pessoal pela aplicação.
O DrainShield não armazena endereços de carteiras em servidores centralizados.

3. Dados da Blockchain

O DrainShield lê os dados da blockchain disponíveis publicamente através de fornecedores de RPC de terceiros e serviços de indexação. Isto pode incluir:
• informações de aprovação de tokens
• metadados de contratos inteligentes
• dados de transações

Toda esta informação já existe publicamente na blockchain.

4. Armazenamento Local

O DrainShield pode armazenar informações limitadas localmente no seu dispositivo para melhorar a funcionalidade, tais como:
• definições da aplicação
• preferências de idioma
• configuração de monitorização
• endereços de carteiras ligadas (opcional)

Não são armazenadas localmente credenciais de carteira sensíveis.

5. Serviços de Terceiros

A aplicação pode depender de serviços externos para aceder aos dados da blockchain. Estes fornecedores operam ao abrigo das suas próprias políticas de privacidade.
O DrainShield não partilha dados pessoais dos utilizadores com terceiros.

6. Segurança

O DrainShield foi concebido para funcionar sem exigir credenciais de carteira sensíveis. Toda a análise de segurança é efectuada utilizando informações da blockchain disponíveis publicamente.

7. Privacidade das Crianças

O DrainShield não se destina a ser utilizado por indivíduos com idade inferior a 13 anos.

8. Alterações a esta Política

Esta Política de Privacidade pode ser actualizada periodicamente para refletir melhorias no serviço ou requisitos regulamentares.

9. Contacto

Para apoio ou questões relacionadas com esta política, contacte:
info@ibiticoin.com""",

    'tr': """Gizlilik Politikası – DrainShield

Son güncelleme: 2026

DrainShield, kullanıcıların jeton onaylarını analiz etmelerine ve akıllı sözleşme izinleriyle ilişkili potansiyel riskleri belirlemelerine yardımcı olmak için tasarlanmış bir mobil güvenlik aracıdır.

1. Toplamadığımız Bilgiler

DrainShield aşağıdakilerin hiçbirini toplamaz veya saklamaz:
• Özel anahtarlar
• Tohum ifadeler (seed phrases)
• Cüzdan şifreleri
• Kişisel kimlik bilgileri
• Finansal hesap bilgileri

DrainShield hiçbir zaman cüzdan bilgilerinizi talep etmez veya bunlara erişimi yoktur.

2. Cüzdan Adresi Kullanımı

Bir cüzdan bağlandığında, uygulama aşağıdakileri yapmak için genel cüzdan adresini geçici olarak işleyebilir:
• jeton onaylarını taramak
• akıllı sözleşme izinlerini analiz etmek
• potansiyel güvenlik risklerini değerlendirmek

Cüzdan adresleri halka açık blok zinciri tanımlayıcılarıdır ve uygulama tarafından kişisel kimlikle ilişkilendirilmez.
DrainShield cüzdan adreslerini merkezi sunucularda saklamaz.

3. Blok Zinciri Verileri

DrainShield, üçüncü taraf RPC sağlayıcıları ve indeksleme hizmetleri aracılığıyla halka açık blok zinciri verilerini okur. Bu şunları içerebilir:
• jeton onay bilgileri
• akıllı sözleşme meta verileri
• işlem verileri

Tüm bu bilgiler blok zincirinde zaten halka açık olarak bulunmaktadır.

4. Yerel Depolama

DrainShield, işlevselliği artırmak için cihazınızda yerel olarak sınırlı bilgiler saklayabilir, örneğin:
• uygulama ayarları
• dil tercihleri
• izleme yapılandırması
• bağlantılı cüzdan adresleri (isteğe bağlı)

Yerel olarak hassas cüzdan bilgileri saklanmaz.

5. Üçüncü Taraf Hizmetleri

Uygulama, blok zinciri verilerine erişmek için harici hizmetlere güvenebilir. Bu sağlayıcılar kendi gizlilik politikaları altında faaliyet gösterirler.
DrainShield kişisel kullanıcı verilerini üçüncü taraflarla paylaşmaz.

6. Güvenlik

DrainShield, hassas cüzdan bilgileri gerektirmeden çalışacak şekilde tasarlanmıştır. Tüm güvenlik analizi, halka açık blok zinciri bilgileri kullanılarak gerçekleştirilir.

7. Çocukların Gizliliği

DrainShield, 13 yaşın altındaki bireyler tarafından kullanılmak üzere tasarlanmamıştır.

8. Bu Politikadaki Değişiklikler

Bu Gizlilik Politikası, hizmet iyileştirmelerini veya düzenleyici gereklilikleri yansıtmak için zaman zaman güncellenebilir.

9. İletişim

Bu politikayla ilgili destek veya sorularınız için şu adrese ulaşın:
info@ibiticoin.com""",

    'ar': """سياسة الخصوصية – DrainShield

آخر تحديث: 2026

DrainShield هي أداة أمنية للهواتف المحمولة مصممة لمساعدة المستخدمين على تحليل موافقات الرموز المميزة وتحديد المخاطر المحتملة المرتبطة بأذونات العقود الذكية.

1. المعلومات التي لا نجمعها

لا تقوم DrainShield بجمع أو تخزين أي مما يلي:
• المفاتيح الخاصة
• عبارات البذور (seed phrases)
• كلمات مرور المحفظة
• معلومات الهوية الشخصية
• بيانات الاعتماد الخاصة بالحسابات المالية

لا تطلب DrainShield أبدًا بيانات اعتماد محفظتك أو تتمكن من الوصول إليها.

2. استخدام عنوان المحفظة

عند توصيل المحفظة، قد يقوم التطبيق بمعالجة عنوان المحفظة العام مؤقتًا من أجل:
• مسح موافقات الرموز المميزة
• تحليل أذونات العقود الذكية
• تقييم المخاطر الأمنية المحتملة

عناوين المحفظة هي معرفات عامة على البلوكشين ولا يربطها التطبيق بالهوية الشخصية.
لا تقوم DrainShield بتخزين عناوين المحافظ على خوادم مركزية.

3. بيانات البلوكشين

تقوم DrainShield بقراءة بيانات البلوكشين المتاحة للجمهور من خلال موفري RPC والجهات الخارجية وخدمات الفهرسة. قد يشمل ذلك:
• معلومات موافقة الرمز المميز
• البيانات الوصفية للعقود الذكية
• بيانات المعاملات

كل هذه المعلومات موجودة بالفعل بشكل عام على البلوكشين.

4. التخزين المحلي

قد تقوم DrainShield بتخزين معلومات محدودة محليًا على جهازك لتحسين الوظائف، مثل:
• إعدادات التطبيق
• تفضيلات اللغة
• تكوين المراقبة
• عناوين المحفظة المرتبطة (اختياري)

لا يتم تخزين أي بيانات اعتماد حساسة للمحفظة محليًا.

5. خدمات الجهات الخارجية

قد يعتمد التطبيق على خدمات خارجية للوصول إلى بيانات البلوكشين. يعمل هؤلاء المزودون بموجب سياسات الخصوصية الخاصة بهم.
لا تشارك DrainShield بيانات المستخدم الشخصية مع أطراف ثالثة.

6. الأمان

تم تصميم DrainShield للعمل دون الحاجة إلى بيانات اعتماد المحفظة الحساسة. يتم إجراء جميع التحليلات الأمنية باستخدام معلومات البلوكشين المتاحة للجمهور.

7. خصوصية الأطفال

DrainShield غير مخصص للاستخدام من قبل الأفراد الذين تقل أعمارهم عن 13 عامًا.

8. التغييرات على هذه السياسة

قد يتم تحديث سياسة الخصوصية هذه من وقت لآخر لتعكس تحسينات الخدمة أو المتطلبات التنظيمية.

9. الاتصال

للحصول على دعم أو أسئلة بخصوص هذه السياسة، اتصل بـ:
info@ibiticoin.com""",

    'zh': """隐私政策 – DrainShield

最后更新：2026

DrainShield 是一款移动安全工具，旨在帮助用户分析代币授权并识别与智能合约权限相关的潜在风险。

1. 我们不收集的信息

DrainShield 不收集或存储以下任何信息：
• 私钥
• 助记词 (seed phrases)
• 钱包密码
• 个人身份信息
• 财务账户凭据

DrainShield 从不请求也无法访问您的钱包凭据。

2. 钱包地址的使用

当连接钱包时，应用程序可能会临时处理公共钱包地址，以便：
• 扫描代币授权
• 分析智能合约权限
• 评估潜在的安全风险

钱包地址是公共区块链标识符，应用程序不会将其与个人身份相关联。
DrainShield 不会在中央服务器上存储钱包地址。

3. 区块链数据

DrainShield 通过第三方 RPC 提供商和索引服务读取公开可用的区块链数据。这可能包括：
• 代币授权信息
• 智能合约元数据
• 交易数据

所有这些信息已经公开存在于区块链上。

4. 本地存储

DrainShield 可能会在您的设备本地存储有限的信息以改善功能，例如：
• 应用程序设置
• 语言偏好
• 监控配置
• 关联的钱包地址（可选）

本地不会存储任何敏感的钱包凭据。

5. 第三方服务

应用程序可能依赖外部服务来访问区块链数据。这些提供商根据其自身的隐私政策运营。
DrainShield 不与第三方共享个人用户数据。

6. 安全

DrainShield 的设计旨在无需敏感的钱包凭据即可运行。所有安全分析均使用公开可用的区块链信息进行。

7. 儿童隐私

DrainShield 不供 13 岁以下人士使用。

8. 本政策的修订

本隐私政策可能会不时更新，以反映服务的改进或监管要求。

9. 联系方式

如需有关本政策的支持或有任何疑问，请联系：
info@ibiticoin.com""",

    'hi': """गोपनीयता नीति – DrainShield

अंतिम अपडेट: 2026

DrainShield एक मोबाइल सुरक्षा उपकरण है जिसे उपयोगकर्ताओं को टोकन अनुमोदन का विश्लेषण करने और स्मार्ट-कॉन्ट्रैक्ट अनुमतियों से जुड़े संभावित जोखिमों की पहचान करने में मदद करने के लिए डिज़ाइन किया गया है।

1. जानकारी जो हम एकत्र नहीं करते हैं

DrainShield निम्नलिखित में से किसी को भी एकत्र या संग्रहीत नहीं करता है:
• निजी चाबियां (Private keys)
• सीड वाक्यांश (Seed phrases)
• वॉलेट पासवर्ड
• व्यक्तिगत पहचान की जानकारी
• वित्तीय खाता क्रेडेंशियल

DrainShield कभी भी आपके वॉलेट क्रेडेंशियल का अनुरोध नहीं करता है और न ही उसकी उन तक पहुंच होती है।

2. वॉलेट पते का उपयोग

जब कोई वॉलेट कनेक्ट होता है, तो एप्लिकेशन अस्थायी रूप से सार्वजनिक वॉलेट पते को संसाधित कर सकता है ताकि:
• टोकन अनुमोदन को स्कैन किया जा सके
• स्मार्ट-कॉन्ट्रैक्ट अनुमतियों का विश्लेषण किया जा सके
• संभावित सुरक्षा जोखिमों का मूल्यांकन किया जा सके

वॉलेट पते सार्वजनिक ब्लॉकचेन पहचानकर्ता हैं और एप्लिकेशन द्वारा व्यक्तिगत पहचान से जुड़े नहीं हैं।
DrainShield वॉलेट पते को केंद्रीकृत सर्वर पर संग्रहीत नहीं करता है।

3. ब्लॉकचेन डेटा

DrainShield तीसरे पक्ष के RPC प्रदाताओं और अनुक्रमण सेवाओं के माध्यम से सार्वजनिक रूप से उपलब्ध ब्लॉकचेन डेटा को पढ़ता है। इसमें शामिल हो सकते हैं:
• टोकन अनुमोदन की जानकारी
• स्मार्ट कॉन्ट्रैक्ट मेटाडेटा
• लेनदेन डेटा

यह सारी जानकारी ब्लॉकचेन पर पहले से ही सार्वजनिक रूप से मौजूद है।

4. स्थानीय भंडारण

DrainShield कार्यक्षमता में सुधार के लिए आपके डिवाइस पर स्थानीय रूप से सीमित जानकारी संग्रहीत कर सकता है, जैसे:
• एप्लिकेशन सेटिंग्स
• भाषा प्राथमिकताएं
• निगरानी विन्यास
• लिंक किए गए वॉलेट पते (वैकल्पिक)

कोई भी संवेदनशील वॉलेट क्रेडेंशियल स्थानीय रूप से संग्रहीत नहीं किया जाता है।

5. तीसरे पक्ष की सेवाएं

एप्लिकेशन ब्लॉकचेन डेटा तक पहुंचने के लिए बाहरी सेवाओं पर निर्भर हो सकता है। ये प्रदाता अपनी गोपनीयता नीतियों के तहत काम करते हैं।
DrainShield तीसरे पक्ष के साथ व्यक्तिगत उपयोगकर्ता डेटा साझा नहीं करता है।

6. सुरक्षा

DrainShield को संवेदनशील वॉलेट क्रेडेंशियल की आवश्यकता के बिना संचालित करने के लिए डिज़ाइन किया गया है। सभी सुरक्षा विश्लेषण सार्वजनिक रूप से उपलब्ध ब्लॉकचेन जानकारी का उपयोग करके किए जाते हैं।

7. बच्चों की गोपनीयता

DrainShield 13 वर्ष से कम उम्र के व्यक्तियों द्वारा उपयोग के लिए नहीं है।

8. इस नीति में परिवर्तन

सेवा सुधारों या नियामक आवश्यकताओं को प्रतिबिंबित करने के लिए समय-समय पर इस गोपनीयता नीति को अपडेट किया जा सकता है।

9. संपर्क

इस नीति के संबंध में सहायता या प्रश्नों के लिए, संपर्क करें:
info@ibiticoin.com""",

    'ja': """プライバシーポリシー – DrainShield

最終更新日：2026年

DrainShieldは、ユーザーがトークンの承認を分析し、スマートコントラクトの権限に関連する潜在的なリスクを特定できるように設計されたモバイルセキュリティツールです。

1. 収集しない情報

DrainShieldは、以下のいずれの情報も収集または保存しません：
• プライベートキー（秘密鍵）
• シードフレーズ（復元フレーズ）
• ウォレットのパスワード
• 個人識別情報
• 金融口座の認証情報

DrainShieldがウォレットの認証情報を要求したり、アクセスしたりすることはありません。

2. ウォレットアドレスの使用

ウォレットが接続されると、アプリケーションは以下の目的で公開ウォレットアドレスを一時的に処理する場合があります：
• トークン承認のスキャン
• スマートコントラクト権限の分析
• 潜在的なセキュリティリスクの評価

ウォレットアドレスは公開されたブロックチェーン識別子であり、アプリケーションによって個人情報と紐付けられることはありません。
DrainShieldは、中央サーバーにウォレットアドレスを保存しません。

3. ブロックチェーンデータ

DrainShieldは、サードパーティのRPCプロバイダーおよびインデックスサービスを通じて、公開されているブロックチェーンデータを読み取ります。これには以下が含まれます：
• トークン承認情報
• スマートコントラクトのメタデータ
• 取引データ

これらの情報はすべて、ブロックチェーン上に既に公開されています。

4. ローカルストレージ

DrainShieldは、機能を向上させるために、デバイスに限定された情報をローカルに保存する場合があります（例：）：
• アプリケーション設定
• 言語設定
• モニタリング設定
• リンクされたウォレットアドレス（任意）

機密性の高いウォレット認証情報がローカルに保存されることはありません。

5. サードパーティサービス

アプリケーションは、ブロックチェーンデータにアクセスするために外部サービスを利用する場合があります。これらのプロバイダーは、独自のプライバシーポリシーに基づいて運営されています。
DrainShieldが個人のユーザーデータを第三者と共有することはありません。

6. セキュリティ

DrainShieldは、機密性の高いウォレット認証情報を必要とせずに動作するように設計されています。すべてのセキュリティ分析は、公開されているブロックチェーン情報を使用して実行されます。

7. お子様のプライバシー

DrainShieldは、13歳未満の方による使用を意図していません。

8. 本ポリシーの変更

本プライバシーポリシーは、サービスの改善や規制上の要件を反映するために、随時更新される場合があります。

9. お問い合わせ

本ポリシーに関するサポートやご質問については、以下までお問い合わせください：
info@ibiticoin.com""",

    'ko': """개인정보 처리방침 – DrainShield

최종 업데이트: 2026년

DrainShield는 사용자가 토큰 승인을 분석하고 스마트 컨트랙트 권한과 관련된 잠재적 리스크를 식별할 수 있도록 설계된 모바일 보안 도구입니다.

1. 수집하지 않는 정보

DrainShield는 다음 중 어떠한 정보도 수집하거나 저장하지 않습니다:
• 프라이빗 키 (비밀키)
• 시드 구문 (복구 구문)
• 지갑 비밀번호
• 개인 식별 정보
• 금융 계정 인증 정보

DrainShield는 귀하의 지갑 인증 정보를 요청하거나 접근하지 않습니다.

2. 지갑 주소 사용

지갑이 연결되면 애플리케이션은 다음을 위해 공개 지갑 주소를 일시적으로 처리할 수 있습니다:
• 토큰 승인 스캔
• 스마트 컨트랙트 권한 분석
• 잠재적 보안 리스크 평가

지갑 주소는 공개된 블록체인 식별자이며 애플리케이션에 의해 개인 신원과 연결되지 않습니다.
DrainShield는 중앙 서버에 지갑 주소를 저장하지 않습니다.

3. 블록체인 데이터

DrainShield는 제3자 RPC 제공업체 및 인덱싱 서비스를 통해 공개적으로 사용 가능한 블록체인 데이터를 읽습니다. 여기에는 다음이 포함될 수 있습니다:
• 토큰 승인 정보
• 스마트 컨트랙트 메타데이터
• 트랜잭션 데이터

이 모든 정보는 이미 블록체인에 공개적으로 존재합니다.

4. 로컬 저장소

DrainShield는 다음과 같은 기능 향상을 위해 귀하의 기기에 제한된 정보를 로컬로 저장할 수 있습니다:
• 애플리케이션 설정
• 언어 기본 설정
• 모니터링 구성
• 연결된 지갑 주소 (선택 사항)

민감한 지갑 인증 정보는 로컬에 저장되지 않습니다.

5. 제3자 서비스

애플리케이션은 블록체인 데이터에 접근하기 위해 외부 서비스에 의존할 수 있습니다. 이러한 제공업체는 자체 개인정보 처리방침에 따라 운영됩니다.
DrainShield는 개인 사용자 데이터를 제3자와 공유하지 않습니다.

6. 보안

DrainShield는 민감한 지갑 인증 정보 없이 작동하도록 설계되었습니다. 모든 보안 분석은 공개적으로 사용 가능한 블록체인 정보를 사용하여 수행됩니다.

7. 아동의 개인정보 보호

DrainShield는 13세 미만의 아동을 대상으로 하지 않습니다.

8. 본 방침의 변경

본 개인정보 처리방침은 서비스 개선이나 규정 요구 사항을 반영하기 위해 수시로 업데이트될 수 있습니다.

9. 연락처

본 방침에 관한 지원이나 질문이 있는 경우 다음으로 연락하십시오:
info@ibiticoin.com""",

    'it': """Informativa sulla privacy – DrainShield

Ultimo aggiornamento: 2026

DrainShield è uno strumento di sicurezza mobile progettato per aiutare gli utenti ad analizzare le approvazioni dei token e identificare i potenziali rischi associati ai permessi degli smart contract.

1. Informazioni che non raccogliamo

DrainShield non raccoglie né memorizza alcuno dei seguenti dati:
• Chiavi private
• Frasi seed
• Password del portafoglio
• Informazioni di identità personale
• Credenziali del conto finanziario

DrainShield non richiede mai né ha accesso alle credenziali del tuo portafoglio.

2. Utilizzo dell'indirizzo del portafoglio

Quando un portafoglio è collegato, l'applicazione può elaborare temporaneamente l'indirizzo pubblico del portafoglio al fine di:
• scansionare le approvazioni dei token
• analizzare i permessi degli smart contract
• valutare i potenziali rischi per la sicurezza

Gli indirizzi dei portafogli sono identificatori pubblici della blockchain e non sono collegati all'identità personale dall'applicazione.
DrainShield non memorizza gli indirizzi dei portafogli su server centralizzati.

3. Dati della blockchain

DrainShield legge i dati della blockchain disponibili pubblicamente attraverso fornitori RPC di terze parti e servizi di indicizzazione. Ciò può includere:
• informazioni sull'approvazione del token
• metadati dello smart contract
• dati sulle transazioni

Tutte queste informazioni esistono già pubblicamente sulla blockchain.

4. Archiviazione locale

DrainShield può memorizzare informazioni limitate localmente sul tuo dispositivo per migliorare la funzionalità, come ad esempio:
• impostazioni dell'applicazione
• preferenze della lingua
• configurazione del monitoraggio
• indirizzi dei portafogli collegati (opzionale)

Nessuna credenziale sensibile del portafoglio viene memorizzata localmente.

5. Servizi di terze parti

L'applicazione può affidarsi a servizi esterni per accedere ai dati della blockchain. Questi fornitori operano secondo le proprie informative sulla privacy.
DrainShield non condivide i dati personali degli utenti con terze parti.

6. Sicurezza

DrainShield è progettato per funzionare senza richiedere credenziali sensibili del portafoglio. Tutte le analisi di sicurezza vengono eseguite utilizzando informazioni della blockchain pubblicamente disponibili.

7. Privacy dei bambini

DrainShield non è destinato all'uso da parte di individui di età inferiore ai 13 anni.

8. Modifiche a questa informativa

Questa informativa sulla privacy può essere aggiornata di volta in volta per riflettere i miglioramenti del servizio o i requisiti normativi.

9. Contatto

Per supporto o domande riguardanti questa informativa, contattare:
info@ibiticoin.com""",

    'pl': """Polityka prywatności – DrainShield

Ostatnia aktualizacja: 2026

DrainShield to mobilne narzędzie bezpieczeństwa zaprojektowane, aby pomagać użytkownikom analizować zatwierdzenia tokenów i identyfikować potencjalne ryzyka związane z uprawnieniami inteligentnych kontraktów.

1. Informacje, których nie zbieramy

DrainShield nie zbiera ani nie przechowuje żadnych z poniższych:
• Kluczy prywatnych
• Fraz seed (fraz odzyskiwania)
• Haseł do portfeli
• Danych osobowych
• Poświadczeń kont finansowych

DrainShield nigdy nie prosi o poświadczenia portfela ani nie ma do nich dostępu.

2. Wykorzystanie adresu portfela

Po podłączeniu portfela aplikacja może tymczasowo przetwarzać publiczny adres portfela w celu:
• skanowania zatwierdzeń tokenów
• analizy uprawnień inteligentnych kontraktów
• oceny potencjalnych zagrożeń bezpieczeństwa

Adresy portfeli są publicznymi identyfikatorami blockchain i nie są łączone przez aplikację z tożsamością osobistą.
DrainShield nie przechowuje adresów portfeli na scentralizowanych serwerach.

3. Dane Blockchain

DrainShield odczytuje publicznie dostępne dane blockchain za pośrednictwem zewnętrznych dostawców RPC i usług indeksowania. Może to obejmować:
• informacje o zatwierdzeniach tokenów
• metadane inteligentnych kontraktów
• dane transakcyjne

Wszystkie te informacje istnieją już publicznie w sieci blockchain.

4. Przechowywanie lokalne

DrainShield może przechowywać ograniczone informacje lokalnie na Twoim urządzeniu, aby usprawnić funkcjonalność, takie jak:
• ustawienia aplikacji
• preferencje językowe
• konfiguracja monitorowania
• powiązane adresy portfeli (opcjonalnie)

Żadne wrażliwe poświadczenia portfela nie są przechowywane lokalnie.

5. Usługi stron trzecich

Aplikacja może polegać na zewnętrznych usługach w celu uzyskania dostępu do danych blockchain. Dostawcy ci działają zgodnie z własnymi politykami prywatności.
DrainShield nie udostępnia danych osobowych użytkowników stronom trzecim.

6. Bezpieczeństwo

DrainShield został zaprojektowany do działania bez konieczności podawania wrażliwych poświadczeń portfela. Cała analiza bezpieczeństwa jest przeprowadzana na podstawie publicznie dostępnych informacji blockchain.

7. Prywatność dzieci

DrainShield nie jest przeznaczony dla osób poniżej 13 roku życia.

8. Zmiany w niniejszej polityce

Niniejsza Polityka prywatności może być od czasu do czasu aktualizowana w celu odzwierciedlenia ulepszeń usług lub wymogów regulacyjnych.

9. Kontakt

W celu uzyskania wsparcia lub pytań dotyczących niniejszej polityki, prosimy o kontakt pod adresem:
info@ibiticoin.com""",

    'uk': """Політика конфіденційності – DrainShield

Останнє оновлення: 2026

DrainShield — це мобільний інструмент безпеки, розроблений для допомоги користувачам в аналізі дозволів токенів та виявленні потенційних ризиків, пов'язаних з дозволами смарт-контрактів.

1. Інформація, яку ми не збираємо

DrainShield не збирає і не зберігає нічого з наступного:
• Приватні ключі
• Сід-фрази
• Паролі гаманців
• Особисту ідентифікаційну інформацію
• Дані фінансових рахунків

DrainShield ніколи не запитує та не має доступу до облікових даних вашого гаманця.

2. Використання адреси гаманця

Коли гаманець підключено, програма може тимчасово обробляти публічну адресу гаманця для:
• сканування дозволів токенів
• аналізу дозволів смарт-контрактів
• оцінки потенційних ризиків безпеки

Адреси гаманців є загальнодоступними ідентифікаторами блокчейну і не пов'язуються програмою з особистою ідентичністю.
DrainShield не зберігає адреси гаманців на централізованих серверах.

3. Дані блокчейну

DrainShield зчитує загальнодоступні дані блокчейну через сторонніх постачальників RPC та служби індексації. Це може включати:
• інформацію про дозволи токенів
• метадані смарт-контрактів
• дані транзакцій

Уся ця інформація вже публічно існує в блокчейні.

4. Локальне сховище

DrainShield може зберігати обмежену інформацію локально на вашому пристрої для покращення функціональності, таку як:
• налаштування програми
• мовні переваги
• конфігурація моніторингу
• прив'язані адреси гаманців (опціонально)

Жодні конфіденційні облікові дані гаманця не зберігаються локально.

5. Сторонні сервіси

Програма може покладатися на зовнішні сервіси для доступу до даних блокчейну. Ці постачальники діють відповідно до своїх власних політик конфіденційності.
DrainShield не передає особисті дані користувачів третім особам.

6. Безпека

DrainShield розроблений для роботи без необхідності введення конфіденційних облікових даних гаманця. Весь аналіз безпеки виконується з використанням загальнодоступної інформації блокчейну.

7. Конфіденційність дітей

DrainShield не призначений для використання особами віком до 13 років.

8. Зміни до цієї політики

Ця Політика конфіденційності може час від часу оновлюватися для відображення покращень сервісу або нормативних вимог.

9. Контакти

З питань підтримки або запитань щодо цієї політики звертайтеся:
info@ibiticoin.com""",

    'id': """Kebijakan Privasi – DrainShield

Terakhir diperbarui: 2026

DrainShield adalah alat keamanan seluler yang dirancang untuk membantu pengguna menganalisis persetujuan token dan mengidentifikasi potensi risiko yang terkait dengan izin kontrak pintar (smart-contract).

1. Informasi yang Tidak Kami Kumpulkan

DrainShield tidak mengumpulkan atau menyimpan hal-hal berikut:
• Kunci pribadi (Private keys)
• Frasa pemulihan (Seed phrases)
• Kata sandi dompet (Wallet passwords)
• Informasi identitas pribadi
• Kredensial akun keuangan

DrainShield tidak pernah meminta atau memiliki akses ke kredensial dompet Anda.

2. Penggunaan Alamat Dompet

Saat dompet terhubung, aplikasi dapat memproses alamat dompet publik untuk sementara waktu guna:
• memindai persetujuan token
• menganalisis izin kontrak pintar
• mengevaluasi potensi risiko keamanan

Alamat dompet adalah pengidentifikasi blockchain publik dan tidak ditautkan ke identitas pribadi oleh aplikasi.
DrainShield tidak menyimpan alamat dompet di server terpusat.

3. Data Blockchain

DrainShield membaca data blockchain yang tersedia secara publik melalui penyedia RPC pihak ketiga dan layanan pengindeksan. Ini termasuk:
• informasi persetujuan token
• metadata kontrak pintar
• data transaksi

Semua informasi ini sudah tersedia secara publik di blockchain.

4. Penyimpanan Lokal

DrainShield dapat menyimpan informasi terbatas secara lokal di perangkat Anda untuk meningkatkan fungsionalitas, seperti:
• pengaturan aplikasi
• preferensi bahasa
• konfigurasi pemantauan
• alamat dompet yang ditautkan (opsional)

Tidak ada kredensial dompet sensitif yang disimpan secara lokal.

5. Layanan Pihak Ketiga

Aplikasi mungkin bergantung pada layanan eksternal untuk mengakses data blockchain. Penyedia ini beroperasi di bawah kebijakan privasi mereka sendiri.
DrainShield tidak membagikan data pribadi pengguna dengan pihak ketiga.

6. Keamanan

DrainShield dirancang untuk beroperasi tanpa memerlukan kredensial dompet yang sensitif. Semua analisis keamanan dilakukan menggunakan informasi blockchain yang tersedia secara publik.

7. Privasi Anak-anak

DrainShield tidak dimaksudkan untuk digunakan oleh individu di bawah usia 13 tahun.

8. Perubahan pada Kebijakan Ini

Kebijakan Privasi ini dapat diperbarui dari waktu ke waktu untuk mencerminkan peningkatan layanan atau persyaratan peraturan.

9. Kontak

Untuk bantuan atau pertanyaan mengenai kebijakan ini, hubungi:
info@ibiticoin.com""",

    'vi': """Chính sách Bảo mật – DrainShield

Cập nhật lần cuối: 2026

DrainShield là một công cụ bảo mật di động được thiết kế để giúp người dùng phân tích các phê duyệt mã thông báo (token approvals) và xác định các rủi ro tiềm ẩn liên quan đến quyền của hợp đồng thông minh (smart-contract).

1. Thông tin chúng tôi không thu thập

DrainShield không thu thập hoặc lưu trữ bất kỳ thông tin nào sau đây:
• Khóa cá nhân (Private keys)
• Cụm từ hạt giống (Seed phrases)
• Mật khẩu ví
• Thông tin nhận dạng cá nhân
• Thông tin xác thực tài khoản tài chính

DrainShield không bao giờ yêu cầu hoặc có quyền truy cập vào thông tin xác thực ví của bạn.

2. Sử dụng địa chỉ ví

Khi một ví được kết nối, ứng dụng có thể tạm thời xử lý địa chỉ ví công khai để:
• quét các phê duyệt mã thông báo
• phân tích quyền của hợp đồng thông minh
• đánh giá các rủi ro bảo mật tiềm ẩn

Địa chỉ ví là mã định danh blockchain công khai và không được ứng dụng liên kết với danh tính cá nhân.
DrainShield không lưu trữ địa chỉ ví trên các máy chủ tập trung.

3. Dữ liệu Blockchain

DrainShield đọc dữ liệu blockchain có sẵn công khai thông qua các nhà cung cấp RPC của bên thứ ba và dịch vụ lập chỉ mục. Điều này có thể bao gồm:
• thông tin phê duyệt mã thông báo
• siêu dữ liệu hợp đồng thông minh
• dữ liệu giao dịch

Tất cả thông tin này đã tồn tại công khai trên blockchain.

4. Lưu trữ cục bộ

DrainShield có thể lưu trữ thông tin hạn chế cục bộ trên thiết bị của bạn để cải thiện chức năng, chẳng hạn như:
• cài đặt ứng dụng
• tùy chọn ngôn ngữ
• cấu hình giám sát
• địa chỉ ví đã liên kết (tùy chọn)

Không có thông tin xác thực ví nhạy cảm nào được lưu trữ cục bộ.

5. Dịch vụ của bên thứ ba

Ứng dụng có thể dựa vào các dịch vụ bên ngoài để truy cập dữ liệu blockchain. Các nhà cung cấp này hoạt động theo chính sách bảo mật của riêng họ.
DrainShield không chia sẻ dữ liệu cá nhân của người dùng với bên thứ ba.

6. Bảo mật

DrainShield được thiết kế để hoạt động mà không yêu cầu thông tin xác thực ví nhạy cảm. Tất cả các phân tích bảo mật được thực hiện bằng cách sử dụng thông tin blockchain công khai.

7. Quyền riêng tư của trẻ em

DrainShield không dành cho cá nhân dưới 13 tuổi sử dụng.

8. Thay đổi đối với chính sách này

Chính sách Bảo mật này có thể được cập nhật theo thời gian để phản ánh các cải tiến dịch vụ hoặc yêu cầu pháp lý.

9. Liên hệ

Để được hỗ trợ hoặc có thắc mắc liên quan đến chính sách này, hãy liên hệ:
info@ibiticoin.com"""
  };

  translations.forEach((lang, policy) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsPrivacyPolicyContent'] = policy;
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated Privacy Policy in assets/i18n/$lang.json');
    }
  });
}
