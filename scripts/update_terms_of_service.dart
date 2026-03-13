import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, String> translations = {
    'en': """Terms of Service – DrainShield

Last updated: 2026

By using the DrainShield application, you agree to the following terms and conditions.

1. Description of the Service
DrainShield is a blockchain security analysis tool designed to help users:
• scan token approvals
• identify potentially risky smart-contract permissions
• review wallet exposure
• revoke permissions through the user's connected wallet

DrainShield is not a cryptocurrency wallet, not a custodian, and does not hold or control user funds.

2. User Responsibility
Users are fully responsible for:
• protecting their private keys and seed phrases
• verifying transactions before signing them
• ensuring the accuracy of wallet addresses they connect

DrainShield cannot reverse blockchain transactions.

3. No Financial Advice
Information provided by DrainShield is for security analysis purposes only and should not be interpreted as financial, investment, or legal advice.

4. Blockchain Risks
Using blockchain technology involves inherent risks, including but not limited to:
• smart contract vulnerabilities
• malicious protocols
• phishing attacks
• irreversible transactions

DrainShield attempts to identify potential risks but cannot guarantee complete protection.

5. Third-Party Services
DrainShield may rely on third-party blockchain infrastructure providers (such as RPC nodes or indexing services). DrainShield is not responsible for the availability or reliability of these services.

6. Limitation of Liability
To the maximum extent permitted by law, DrainShield and its developers are not liable for any financial loss, asset theft, or damages resulting from the use of the application.
Users interact with blockchain networks at their own risk.

7. Changes to the Service
DrainShield may update, modify, or discontinue features of the application at any time without prior notice.

8. Changes to These Terms
These Terms of Service may be updated periodically. Continued use of the application constitutes acceptance of the updated terms.

9. Contact
For questions regarding these Terms of Service, contact:
info@ibiticoin.com""",

    'ru': """Условия использования – DrainShield

Последнее обновление: 2026

Используя приложение DrainShield, вы соглашаетесь со следующими условиями.

1. Описание услуги
DrainShield — это инструмент анализа безопасности блокчейна, предназначенный для помощи пользователям:
• сканировать разрешения токенов
• выявлять потенциально рискованные разрешения смарт-контрактов
• проверять риски кошелька
• отзывать разрешения через подключенный кошелек пользователя

DrainShield не является криптовалютным кошельком, не является кастодианом и не хранит и не контролирует средства пользователей.

2. Ответственность пользователя
Пользователи несут полную ответственность за:
• защиту своих приватных ключей и сид-фраз
• проверку транзакций перед их подписанием
• обеспечение точности адресов кошельков, которые они подключают

DrainShield не может отменить транзакции в блокчейне.

3. Отказ от финансовых рекомендаций
Информация, предоставляемая DrainShield, предназначена только для целей анализа безопасности и не должна рассматриваться как финансовая, инвестиционная или юридическая консультация.

4. Риски блокчейна
Использование технологии блокчейн сопряжено с неотъемлемыми рисками, включая, помимо прочего:
• уязвимости смарт-контрактов
• вредоносные протоколы
• фишинговые атаки
• необратимые транзакции

DrainShield пытается выявить потенциальные риски, но не может гарантировать полную защиту.

5. Сторонние услуги
DrainShield может полагаться на сторонних поставщиков инфраструктуры блокчейна (таких как RPC-узлы или службы индексации). DrainShield не несет ответственности за доступность или надежность этих услуг.

6. Ограничение ответственности
В максимальной степени, разрешенной законом, DrainShield и его разработчики не несут ответственности за любые финансовые потери, кражу активов или ущерб, возникшие в результате использования приложения.
Пользователи взаимодействуют ссетями блокчейн на свой страх и риск.

7. Изменения в услуге
DrainShield может обновлять, изменять или прекращать работу функций приложения в любое время без предварительного уведомления.

8. Изменения в настоящих условиях
Настоящие Условия использования могут периодически обновляться. Продолжение использования приложения означает принятие обновленных условий.

9. Контакты
По вопросам, касающимся настоящих Условий использования, обращайтесь:
info@ibiticoin.com""",

    'de': """Nutzungsbedingungen – DrainShield

Zuletzt aktualisiert: 2026

Durch die Nutzung der DrainShield-Anwendung erklären Sie sich mit den folgenden Geschäftsbedingungen einverstanden.

1. Beschreibung des Dienstes
DrainShield ist ein Tool zur Analyse der Blockchain-Sicherheit, das Benutzern hilft:
• Token-Genehmigungen zu scannen
• potenziell riskante Smart-Contract-Berechtigungen zu identifizieren
• das Wallet-Risiko zu überprüfen
• Berechtigungen über die verbundene Wallet des Benutzers zu widerrufen

DrainShield ist keine Kryptowährungs-Wallet, kein Verwahrer und behält oder kontrolliert keine Benutzergelder.

2. Verantwortung des Benutzers
Benutzer sind voll verantwortlich für:
• den Schutz ihrer privaten Schlüssel und Seed-Phrasen
• die Überprüfung von Transaktionen vor der Unterzeichnung
• die Sicherstellung der Richtigkeit der von ihnen verbundenen Wallet-Adressen

DrainShield kann Blockchain-Transaktionen nicht rückgängig machen.

3. Keine Finanzberatung
Die von DrainShield bereitgestellten Informationen dienen ausschließlich Sicherheitsanalysezwecken und sollten nicht als Finanz-, Investitions- oder Rechtsberatung ausgelegt werden.

4. Blockchain-Risiken
Die Nutzung der Blockchain-Technologie ist mit inhärenten Risiken verbunden, einschließlich, aber nicht beschränkt auf:
• Schwachstellen in Smart Contracts
• böswillige Protokolle
• Phishing-Angriffe
• irreversible Transaktionen

DrainShield versucht, potenzielle Risiken zu identifizieren, kann aber keinen vollständigen Schutz garantieren.

5. Dienste von Drittanbietern
DrainShield kann auf Blockchain-Infrastrukturanbieter von Drittanbietern (wie RPC-Knoten oder Indexierungsdienste) angewiesen sein. DrainShield ist nicht verantwortlich für die Verfügbarkeit oder Zuverlässigkeit dieser Dienste.

6. Haftungsbeschränkung
Soweit gesetzlich zulässig, haften DrainShield und seine Entwickler nicht für finanzielle Verluste, Diebstahl von Vermögenswerten oder Schäden, die aus der Nutzung der Anwendung resultieren.
Benutzer interagieren mit Blockchain-Netzwerken auf eigene Gefahr.

7. Änderungen am Dienst
DrainShield kann Funktionen der Anwendung jederzeit ohne vorherige Ankündigung aktualisieren, ändern oder einstellen.

8. Änderungen an diesen Bedingungen
Diese Nutzungsbedingungen können regelmäßig aktualisiert werden. Die fortgesetzte Nutzung der Anwendung stellt die Annahme der aktualisierten Bedingungen dar.

9. Kontakt
Bei Fragen zu diesen Nutzungsbedingungen wenden Sie sich bitte an:
info@ibiticoin.com""",

    'fr': """Conditions de service – DrainShield

Dernière mise à jour : 2026

En utilisant l'application DrainShield, vous acceptez les conditions générales suivantes.

1. Description du service
DrainShield est un outil d'analyse de la sécurité de la blockchain conçu pour aider les utilisateurs à :
• scanner les approbations de jetons
• identifier les autorisations de contrats intelligents potentiellement risquées
• examiner l'exposition du portefeuille
• révoquer les autorisations via le portefeuille connecté de l'utilisateur

DrainShield n'est pas un portefeuille de crypto-monnaie, n'est pas un dépositaire et ne détient ni ne contrôle les fonds des utilisateurs.

2. Responsabilité de l'utilisateur
Les utilisateurs sont entièrement responsables de :
• la protection de leurs clés privées et de leurs phrases de récupération
• la vérification des transactions avant de les signer
• s'assurer de l'exactitude des adresses de portefeuille qu'ils connectent

DrainShield ne peut pas annuler les transactions sur la blockchain.

3. Pas de conseil financier
Les informations fournies par DrainShield sont uniquement destinées à l'analyse de la sécurité et ne doivent pas être interprétées comme des conseils financiers, d'investissement ou juridiques.

4. Risques liés à la blockchain
L'utilisation de la technologie blockchain comporte des risques inhérents, y compris, mais sans s'y limiter :
• les vulnérabilités des contrats intelligents
• les protocoles malveillants
• les attaques de phishing
• les transactions irréversibles

DrainShield tente d'identifier les risques potentiels mais ne peut garantir une protection complète.

5. Services tiers
DrainShield peut s'appuyer sur des fournisseurs d'infrastructure de blockchain tiers (tels que des nœuds RPC ou des services d'indexation). DrainShield n'est pas responsable de la disponibilité ou de la fiabilité de ces services.

6. Limitation de responsabilité
Dans la mesure maximale permise par la loi, DrainShield et ses développeurs ne sont pas responsables de toute perte financière, vol d'actifs ou dommages résultant de l'utilisation de l'application.
Les utilisateurs interagissent avec les réseaux de blockchain à leurs propres risques.

7. Modifications du service
DrainShield peut mettre à jour, modifier ou interrompre les fonctionnalités de l'application à tout moment sans préavis.

8. Modifications de ces conditions
Ces conditions de service peuvent être mises à jour périodiquement. L'utilisation continue de l'application constitue l'acceptation des conditions mises à jour.

9. Contact
Pour toute question concernant ces conditions de service, contactez :
info@ibiticoin.com""",

    'es': """Términos de servicio – DrainShield

Última actualización: 2026

Al utilizar la aplicación DrainShield, usted acepta los siguientes términos y condiciones.

1. Descripción del servicio
DrainShield es una herramienta de análisis de seguridad de blockchain diseñada para ayudar a los usuarios a:
• escanear aprobaciones de tokens
• identificar permisos de contratos inteligentes potencialmente riesgosos
• revisar la exposición del monedero
• revocar permisos a través del monedero conectado del usuario

DrainShield no es un monedero de criptomonedas, no es un custodio y no posee ni controla los fondos de los usuarios.

2. Responsabilidad del usuario
Los usuarios son totalmente responsables de:
• proteger sus claves privadas y frases semilla
• verificar las transacciones antes de firmarlas
• asegurar la precisión de las direcciones de los monederos que conectan

DrainShield no puede revertir las transacciones de la blockchain.

3. Sin asesoramiento financiero
La información proporcionada por DrainShield es solo para fines de análisis de seguridad y no debe interpretarse como asesoramiento financiero, de inversión o legal.

4. Riesgos de la blockchain
El uso de la tecnología blockchain implica riesgos inherentes, incluidos, entre otros:
• vulnerabilidades de los contratos inteligentes
• protocolos maliciosos
• ataques de phishing
• transacciones irreversibles

DrainShield intenta identificar riesgos potenciales, pero no puede garantizar una protección completa.

5. Servicios de terceros
DrainShield puede depender de proveedores de infraestructura de blockchain de terceros (como nodos RPC o servicios de indexación). DrainShield no es responsable de la disponibilidad o fiabilidad de estos servicios.

6. Limitación de responsabilidad
En la medida máxima permitida por la ley, DrainShield y sus desarrolladores no son responsables de ninguna pérdida financiera, robo de activos o daños resultantes del uso de la aplicación.
Los usuarios interactúan con las redes blockchain bajo su propio riesgo.

7. Cambios en el servicio
DrainShield puede actualizar, modificar o descontinuar funciones de la aplicación en cualquier momento sin previo aviso.

8. Cambios en estos términos
Estos Términos de servicio pueden actualizarse periódicamente. El uso continuado de la aplicación constituye la aceptación de los términos actualizados.

9. Contacto
Para preguntas relacionadas con estos Términos de servicio, contacte con:
info@ibiticoin.com""",

    'pt': """Termos de Serviço – DrainShield

Última atualização: 2026

Ao utilizar a aplicação DrainShield, concorda com os seguintes termos e condições.

1. Descrição do Serviço
O DrainShield é uma ferramenta de análise de segurança blockchain concebida para ajudar os utilizadores a:
• digitalizar aprovações de tokens
• identificar permissões de contratos inteligentes potencialmente arriscadas
• rever a exposição da carteira
• revogar permissões através da carteira ligada do utilizador

O DrainShield não é uma carteira de criptomoedas, não é um custodiante e não detém nem controla fundos de utilizadores.

2. Responsabilidade do Utilizador
Os utilizadores são totalmente responsáveis por:
• proteger as suas chaves privadas e frases-semente
• verificar as transações antes de as assinar
• garantir a exatidão dos endereços de carteira que ligam

O DrainShield não pode reverter transações na blockchain.

3. Sem Aconselhamento Financeiro
As informações fornecidas pelo DrainShield destinam-se apenas a fins de análise de segurança e não devem ser interpretadas como aconselhamento financeiro, de investimento ou jurídico.

4. Riscos da Blockchain
A utilização da tecnologia blockchain envolve riscos inerentes, incluindo, mas não se limitando a:
• vulnerabilidades de contratos inteligentes
• protocolos maliciosos
• ataques de phishing
• transações irreversíveis

O DrainShield tenta identificar potenciais riscos, mas não pode garantir uma proteção completa.

5. Serviços de Terceiros
O DrainShield pode depender de fornecedores de infraestrutura blockchain de terceiros (como nós RPC ou serviços de indexação). O DrainShield não é responsável pela disponibilidade ou fiabilidade destes serviços.

6. Limitação de Responsabilidade
Até ao limite máximo permitido por lei, o DrainShield e os seus programadores não são responsáveis por qualquer perda financeira, roubo de ativos ou danos resultantes da utilização da aplicação.
Os utilizadores interagem com as redes blockchain por sua conta e risco.

7. Alterações ao Serviço
O DrainShield pode atualizar, modificar ou descontinuar funcionalidades da aplicação a qualquer momento, sem aviso prévio.

8. Alterações a estes Termos
Estes Termos de Serviço podem ser atualizados periodicamente. A utilização continuada da aplicação constitui a aceitação dos termos atualizados.

9. Contacto
Para questões relativas a estes Termos de Serviço, contacte:
info@ibiticoin.com""",

    'tr': """Hizmet Şartları – DrainShield

Son güncelleme: 2026

DrainShield uygulamasını kullanarak aşağıdaki hüküm ve koşulları kabul etmiş olursunuz.

1. Hizmetin Açıklaması
DrainShield, kullanıcılara yardımcı olmak için tasarlanmış bir blok zinciri güvenlik analizi aracıdır:
• jeton onaylarını taramak
• potansiyel olarak riskli akıllı sözleşme izinlerini belirlemek
• cüzdan maruziyetini incelemek
• kullanıcının bağlı cüzdanı aracılığıyla izinleri iptal etmek

DrainShield bir kripto para cüzdanı değildir, saklamacı değildir ve kullanıcı fonlarını tutmaz veya kontrol etmez.

2. Kullanıcı Sorumluluğu
Kullanıcılar aşağıdakilerden tamamen sorumludur:
• özel anahtarlarını ve tohum ifadelerini korumak
• işlemleri imzalamadan önce doğrulamak
• bağladıkları cüzdan adreslerinin doğruluğunu sağlamak

DrainShield blok zinciri işlemlerini tersine çeviremez.

3. Finansal Tavsiye Değildir
DrainShield tarafından sağlanan bilgiler yalnızca güvenlik analizi amaçlıdır ve finansal, yatırım veya hukuki tavsiye olarak yorumlanmamalıdır.

4. Blok Zinciri Riskleri
Blok zinciri teknolojisini kullanmak, aşağıdakiler dahil ancak bunlarla sınırlı olmamak üzere doğal riskler içerir:
• akıllı sözleşme güvenlik açıkları
• kötü niyetli protokoller
• kimlik avı saldırıları
• geri alınamaz işlemler

DrainShield potansiyel riskleri belirlemeye çalışır ancak tam koruma garanti edemez.

5. Üçüncü Taraf Hizmetleri
DrainShield, üçüncü taraf blok zinciri altyapı sağlayıcılarına (RPC düğümleri veya indeksleme hizmetleri gibi) güvenebilir. DrainShield, bu hizmetlerin kullanılabilirliğinden veya güvenilirliğinden sorumlu değildir.

6. Sorumluluğun Sınırlandırılması
Yasaların izin verdiği azami ölçüde, DrainShield ve geliştiricileri, uygulamanın kullanımından kaynaklanan herhangi bir finansal kayıp, varlık hırsızlığı veya zarardan sorumlu değildir.
Kullanıcılar blok zinciri ağlarıyla kendi riskleri altında etkileşime girerler.

7. Hizmette Yapılan Değişiklikler
DrainShield, uygulamanın özelliklerini herhangi bir zamanda önceden bildirimde bulunmaksızın güncelleyebilir, değiştirebilir veya durdurabilir.

8. Bu Şartlarda Yapılan Değişiklikler
Bu Hizmet Şartları periyodik olarak güncellenebilir. Uygulamanın kullanımına devam edilmesi, güncellenmiş şartların kabul edildiği anlamına gelir.

9. İletişim
Bu Hizmet Şartları ile ilgili sorularınız için şu adrese ulaşın:
info@ibiticoin.com""",

    'ar': """شروط الخدمة – DrainShield

آخر تحديث: 2026

باستخدام تطبيق DrainShield، فإنك توافق على الشروط والأحكام التالية.

1. وصف الخدمة
DrainShield هي أداة لتحليل أمان البلوكشين مصممة لمساعدة المستخدمين على:
• مسح موافقات الرموز المميزة
• تحديد أذونات العقود الذكية التي قد تنطوي على مخاطر
• مراجعة تعرض المحفظة
• إلغاء الأذونات من خلال محفظة المستخدم المتصلة

DrainShield ليست محفظة عملات مشفرة، وليست وصيًا، ولا تحتفظ بأموال المستخدمين أو تتحكم فيها.

2. مسؤولية المستخدم
يتحمل المستخدمون المسؤولية الكاملة عن:
• حماية مفاتيحهم الخاصة وعباراتهم السرية
• التحقق من المعاملات قبل التوقيع عليها
• ضمان دقة عناوين المحفظة التي يربطونها

لا يمكن لـ DrainShield إلغاء معاملات البلوكشين.

3. ليست نصيحة مالية
المعلومات التي تقدمها DrainShield هي لأغراض تحليل الأمان فقط ولا ينبغي تفسيرها على أنها نصيحة مالية أو استثمارية أو قانونية.

4. مخاطر البلوكشين
ينطوي استخدام تقنية البلوكشين على مخاطر متأصلة، بما في ذلك على سبيل المثال لا الحصر:
• نقاط الضعف في العقود الذكية
• البروتوكولات الضارة
• هجمات التصيد الاحتيالي
• المعاملات غير القابلة للإلغاء

تحاول DrainShield تحديد المخاطر المحتملة ولكنها لا تستطيع ضمان الحماية الكاملة.

5. خدمات الجهات الخارجية
قد تعتمد DrainShield على موفري البنية التحتية للبلوكشين من جهات خارجية (مثل عقد RPC أو خدمات الفهرسة). DrainShield ليست مسؤولة عن توفر هذه الخدمات أو موثوقيتها.

6. تحديد المسؤولية
إلى أقصى حد يسمح به القانون، لا تتحمل DrainShield ومطوروها المسؤولية عن أي خسارة مالية أو سرقة أصول أو أضرار ناتجة عن استخدام التطبيق.
يتفاعل المستخدمون مع شبكات البلوكشين على مسؤوليتهم الخاصة.

7. تغييرات الخدمة
يجوز لـ DrainShield تحديث ميزات التطبيق أو تعديلها أو إيقافها في أي وقت دون إشعار مسبق.

8. تغييرات هذه الشروط
قد يتم تحديث شروط الخدمة هذه بشكل دوري. إن الاستمرار في استخدام التطبيق يشكل قبولًا للشروط المحدثة.

9. الاتصال
للأسئلة المتعلقة بشروط الخدمة هذه، اتصل بـ:
info@ibiticoin.com""",

    'zh': """服务条款 – DrainShield

最后更新：2026

使用 DrainShield 应用程序，即表示您同意以下条款和条件。

1. 服务说明
DrainShield 是一款区块链安全分析工具，旨在帮助用户：
• 扫描代币授权
• 识别潜在风险的智能合约权限
• 检查钱包曝光情况
• 通过用户连接的钱包撤销权限

DrainShield 不是加密货币钱包，不是托管人，也不持有或控制用户资金。

2. 用户责任
用户全权负责：
• 保护其私钥和助记词
• 在签署交易前核实交易
• 确保所连接钱包地址的准确性

DrainShield 无法撤销区块链交易。

3. 非财务建议
DrainShield 提供的信息仅用于安全分析目的，不应被视为财务、投资或法律建议。

4. 区块链风险
使用区块链技术涉及固有风险，包括但不限于：
• 智能合约漏洞
• 恶意协议
• 网络钓鱼攻击
• 不可逆转的交易

DrainShield 尝试识别潜在风险，但不能保证完全保护。

5. 第三方服务
DrainShield 可能依赖第三方区块链基础设施提供商（如 RPC 节点或索引服务）。DrainShield 不对这些服务的可用性或可靠性负责。

6. 责任限制
在法律允许的最大范围内，DrainShield 及其开发人员不对因使用本应用程序而导致的任何财务损失、资产失窃或损害承担责任。
用户自行承担与区块链网络互动的风险。

7. 服务变更
DrainShield 可随时更新、修改或终止应用程序的功能，恕不另行通知。

8. 条款修订
本服务条款可能会定期更新。继续使用本应用程序即表示接受更新后的条款。

9. 联系方式
有关本服务条款的问题，请联系：
info@ibiticoin.com""",

    'hi': """सेवा की शर्तें – DrainShield

अंतिम अपडेट: 2026

DrainShield एप्लिकेशन का उपयोग करके, आप निम्नलिखित नियमों और शर्तों से सहमत होते हैं।

1. सेवा का विवरण
DrainShield एक ब्लॉकचेन सुरक्षा विश्लेषण उपकरण है जिसे उपयोगकर्ताओं की मदद करने के लिए डिज़ाइन किया गया है:
• टोकन अनुमोदन को स्कैन करना
• संभावित रूप से जोखिम भरी स्मार्ट-कॉन्ट्रैक्ट अनुमतियों की पहचान करना
• वॉलेट जोखिम की समीक्षा करना
• उपयोगकर्ता के कनेक्टेड वॉलेट के माध्यम से अनुमतियों को रद्द करना

DrainShield एक क्रिप्टोकरेंसी वॉलेट नहीं है, कोई कस्टोडियन नहीं है, और उपयोगकर्ता के धन को नहीं रखता या नियंत्रित नहीं करता है।

2. उपयोगकर्ता की जिम्मेदारी
उपयोगकर्ता पूरी तरह से इसके लिए जिम्मेदार हैं:
• अपनी निजी चाबियों और सीड वाक्यांशों की रक्षा करना
• हस्ताक्षर करने से पहले लेनदेन की पुष्टि करना
• उनके द्वारा कनेक्ट किए गए वॉलेट पतों की सटीकता सुनिश्चित करना

DrainShield ब्लॉकचेन लेनदेन को उलट नहीं सकता है।

3. कोई वित्तीय सलाह नहीं
DrainShield द्वारा प्रदान की गई जानकारी केवल सुरक्षा विश्लेषण उद्देश्यों के लिए है और इसे वित्तीय, निवेश या कानूनी सलाह के रूप में नहीं लिया जाना चाहिए।

4. ब्लॉकचेन जोखिम
ब्लॉकचेन तकनीक का उपयोग करने में अंतर्निहित जोखिम शामिल हैं, जिनमें शामिल हैं लेकिन सीमित नहीं हैं:
• स्मार्ट कॉन्ट्रैक्ट कमजोरियां
• दुर्भावनापूर्ण प्रोटोकॉल
• फ़िशिंग हमले
• अपरिवर्तनीय लेनदेन

DrainShield संभावित जोखिमों की पहचान करने का प्रयास करता है लेकिन पूर्ण सुरक्षा की गारंटी नहीं दे सकता है।

5. तीसरे पक्ष की सेवाएं
DrainShield तीसरे पक्ष के ब्लॉकचेन बुनियादी ढांचा प्रदाताओं (जैसे RPC नोड्स या अनुक्रमण सेवाओं) पर निर्भर हो सकता है। DrainShield इन सेवाओं की उपलब्धता या विश्वसनीयता के लिए जिम्मेदार नहीं है।

6. देयता की सीमा
कानून द्वारा अनुमत अधिकतम सीमा तक, DrainShield और इसके डेवलपर एप्लिकेशन के उपयोग से होने वाले किसी भी वित्तीय नुकसान, संपत्ति की चोरी या क्षति के लिए उत्तरदायी नहीं हैं।
उपयोगकर्ता अपने जोखिम पर ब्लॉकचेन नेटवर्क के साथ बातचीत करते हैं।

7. सेवा में परिवर्तन
DrainShield बिना किसी पूर्व सूचना के किसी भी समय एप्लिकेशन की सुविधाओं को अपडेट, संशोधित या बंद कर सकता है।

8. इन शर्तों में बदलाव
सेवा की इन शर्तों को समय-समय पर अपडेट किया जा सकता है। एप्लिकेशन का निरंतर उपयोग अपडेट की गई शर्तों की स्वीकृति माना जाएगा।

9. संपर्क
सेवा की इन शर्तों के संबंध में प्रश्नों के लिए, संपर्क करें:
info@ibiticoin.com""",

    'ja': """利用規約 – DrainShield

最終更新日：2026年

DrainShieldアプリケーションを使用することにより、以下の利用規約に同意したものとみなされます。

1. サービスの説明
DrainShieldは、ユーザーを支援するために設計されたブロックチェーンセキュリティ分析ツールです：
• トークン承認のスキャン
• リスクのある可能性のあるスマートコントラクト権限の特定
• ウォレットの露出状況の確認
• 接続されたユーザーのウォレットを介した権限の取り消し

DrainShieldは暗号資産ウォレットではなく、カストディアンでもありません。また、ユーザーの資金を保持または管理することもありません。

2. ユーザーの責任
ユーザーは、以下の事項について全責任を負います：
• プライベートキー（秘密鍵）およびシードフレーズの保護
• 署名前の取引の確認
• 接続するウォレットアドレスの正確性の確保

DrainShieldはブロックチェーン上の取引を取り消すことはできません。

3. 財務上の助言の否定
DrainShieldが提供する情報はセキュリティ分析のみを目的としており、財務、投資、または法律上の助言として解釈されるべきではありません。

4. ブロックチェーンのリスク
ブロックチェーン技術の使用には、以下を含むがこれらに限定されない固有のリスクが伴います：
• スマートコントラクトの脆弱性
• 悪意のあるプロトコル
• フィッシング攻撃
• 取り消し不能な取引

DrainShieldは潜在的なリスクの特定を試みますが、完全な保護を保証することはできません。

5. サードパーティサービス
DrainShieldは、サードパーティのブロックチェーンインフラストラクチャプロバイダー（RPCノードやインデックスサービスなど）に依存する場合があります。DrainShieldは、これらのサービスの可用性や信頼性について責任を負いません。

6. 責任の制限
法律で認められる最大限の範囲において、DrainShieldおよびその開発者は、本アプリケーションの使用に起因するいかなる金銭的損失、資産の盗難、または損害についても責任を負いません。
ユーザーは自己責任でブロックチェーンネットワークとやり取りするものとします。

7. サービスの変更
DrainShieldは、事前の通知なくいつでもアプリケーションの機能を更新、変更、または中止することができます。

8. 本規約の変更
本利用規約は定期的に更新される場合があります。アプリケーションの使用を継続することにより、更新された規約に同意したものとみなされます。

9. お問い合わせ
本利用規約に関するご質問は、以下までお問い合わせください：
info@ibiticoin.com""",

    'ko': """서비스 이용약관 – DrainShield

최종 업데이트: 2026년

DrainShield 애플리케이션을 사용함으로써 귀하는 다음의 이용약관에 동의하게 됩니다.

1. 서비스 설명
DrainShield는 다음을 통해 사용자를 돕기 위해 설계된 블록체인 보안 분석 도구입니다:
• 토큰 승인 스캔
• 잠재적으로 위험한 스마트 컨트랙트 권한 식별
• 지갑 노출 검토
• 연결된 사용자의 지갑을 통한 권한 취소

DrainShield는 암호화폐 지갑이 아니며, 수탁 기관도 아니며, 사용자의 자금을 보유하거나 통제하지 않습니다.

2. 사용자의 책임
사용자는 다음에 대해 전적인 책임을 집니다:
• 프라이빗 키 및 시드 구문 보호
• 서명 전 트랜잭션 확인
• 연결된 지갑 주소의 정확성 확인

DrainShield는 블록체인 트랜잭션을 취소할 수 없습니다.

3. 금융 조언 아님
DrainShield가 제공하는 정보는 보안 분석 목적으로만 제공되며 금융, 투자 또는 법적 조언으로 해석되어서는 안 됩니다.

4. 블록체인 리스크
블록체인 기술을 사용하는 데는 다음을 포함하되 이에 국한되지 않는 고유한 리스크가 수반됩니다:
• 스마트 컨트랙트 취약점
• 악성 프로토콜
• 피싱 공격
• 되돌릴 수 없는 트랜잭션

DrainShield는 잠재적인 리스크를 식별하려고 노력하지만 완전한 보호를 보장할 수는 없습니다.

5. 제3자 서비스
DrainShield는 제3자 블록체인 인프라 제공업체(RPC 노드 또는 인덱싱 서비스 등)에 의존할 수 있습니다. DrainShield는 이러한 서비스의 가용성이나 신뢰성에 대해 책임을 지지 않습니다.

6. 책임의 제한
법이 허용하는 최대 범위 내에서, DrainShield와 그 개발자는 본 애플리케이션의 사용으로 인해 발생하는 어떠한 재정적 손실, 자산 도난 또는 손해에 대해서도 책임을 지지 않습니다.
사용자는 본인의 책임하에 블록체인 네트워크와 상호작용합니다.

7. 서비스의 변경
DrainShield는 사전 고지 없이 언제든지 애플리케이션의 기능을 업데이트, 수정 또는 중단할 수 있습니다.

8. 본 약관의 변경
본 서비스 이용약관은 정기적으로 업데이트될 수 있습니다. 애플리케이션을 계속 사용하면 업데이트된 약관에 동의하는 것으로 간주됩니다.

9. 문의처
본 이용약관에 관한 질문이 있는 경우 다음으로 문의하십시오:
info@ibiticoin.com""",

    'it': """Termini di servizio – DrainShield

Ultimo aggiornamento: 2026

Utilizzando l'applicazione DrainShield, l'utente accetta i seguenti termini e condizioni.

1. Descrizione del servizio
DrainShield è uno strumento di analisi della sicurezza blockchain progettato per aiutare gli utenti a:
• scansionare le approvazioni dei token
• identificare i permessi degli smart contract potenzialmente rischiosi
• rivedere l'esposizione del portafoglio
• revocare i permessi attraverso il portafoglio collegato dell'utente

DrainShield non è un portafoglio di criptovalute, non è un custode e non detiene né controlla i fondi degli utenti.

2. Responsabilità dell'utente
Gli utenti sono pienamente responsabili di:
• proteggere le proprie chiavi private e frasi seed
• verificare le transazioni prima di firmarle
• garantire l'accuratezza degli indirizzi dei portafogli che collegano

DrainShield non può annullare le transazioni blockchain.

3. Nessuna consulenza finanziaria
Le informazioni fornite da DrainShield sono solo a scopo di analisi della sicurezza e non devono essere interpretate come consulenza finanziaria, di investimento o legale.

4. Rischi della blockchain
L'uso della tecnologia blockchain comporta rischi intrinseci, inclusi ma non limitati a:
• vulnerabilità degli smart contract
• protocolli malevoli
• attacchi di phishing
• transazioni irreversibili

DrainShield tenta di identificare i potenziali rischi ma non può garantire una protezione completa.

5. Servizi di terze parti
DrainShield può affidarsi a fornitori di infrastrutture blockchain di terze parti (come nodi RPC o servizi di indicizzazione). DrainShield non è responsabile della disponibilità o dell'affidabilità di questi servizi.

6. Limitazione di responsabilità
Nella misura massima consentita dalla legge, DrainShield e i suoi sviluppatori non sono responsabili per eventuali perdite finanziarie, furti di asset o danni derivanti dall'uso dell'applicazione.
Gli utenti interagiscono con le reti blockchain a proprio rischio.

7. Modifiche al servizio
DrainShield può aggiornare, modificare o interrompere le funzionalità dell'applicazione in qualsiasi momento senza preavviso.

8. Modifiche a questi termini
Questi Termini di servizio possono essere aggiornati periodicamente. L'uso continuato dell'applicazione costituisce l'accettazione dei termini aggiornati.

9. Contatto
Per domande riguardanti questi Termini di servizio, contattare:
info@ibiticoin.com""",

    'pl': """Regulamin świadczenia usług – DrainShield

Ostatnia aktualizacja: 2026

Korzystając z aplikacji DrainShield, akceptujesz poniższe warunki i postanowienia.

1. Opis usługi
DrainShield to narzędzie do analizy bezpieczeństwa blockchain, zaprojektowane, aby pomagać użytkownikom:
• skanować zatwierdzenia tokenów
• identyfikować potencjalnie ryzykowne uprawnienia inteligentnych kontraktów
• sprawdzać ekspozycję portfela
• cofać uprawnienia za pośrednictwem podłączonego portfela użytkownika

DrainShield nie jest portfelem kryptowalutowym, nie jest powiernikiem i nie przechowuje ani nie kontroluje środków użytkowników.

2. Odpowiedzialność użytkownika
Użytkownicy ponoszą pełną odpowiedzialność za:
• ochronę swoich kluczy prywatnych i fraz seed
• weryfikację transakcji przed ich podpisaniem
• zapewnienie dokładności adresów portfeli, które łączą

DrainShield nie może cofnąć transakcji w łańcuchu bloków.

3. Brak porad finansowych
Informacje dostarczane przez DrainShield służą wyłącznie do celów analizy bezpieczeństwa i nie powinny być interpretowane jako porady finansowe, inwestycyjne ani prawne.

4. Ryzyko Blockchain
Korzystanie z technologii blockchain wiąże się z nieodłącznym ryzykiem, w tym m.in.:
• lukami w inteligentnych kontraktach
• złośliwymi protokołami
• atakami phishingowymi
• nieodwracalnymi transakcjami

DrainShield stara się identyfikować potencjalne zagrożenia, ale nie może zagwarantować pełnej ochrony.

5. Usługi stron trzecich
DrainShield może polegać na zewnętrznych dostawcach infrastruktury blockchain (takich jak węzły RPC lub usługi indeksowania). DrainShield nie ponosi odpowiedzialności за dostępność lub niezawodność tych usług.

6. Ograniczenie odpowiedzialności
W maksymalnym zakresie dozwolonym przez prawo, DrainShield i jego twórcy nie ponoszą odpowiedzialności za jakiekolwiek straty finansowe, kradzież aktywów lub szkody wynikające z korzystania z aplikacji.
Użytkownicy wchodzą w interakcję z sieciami blockchain na własne ryzyko.

7. Zmiany w usłudze
DrainShield może aktualizować, modyfikować lub zaprzestawać udostępniania funkcji aplikacji w dowolnym momencie bez uprzedniego powiadomienia.

8. Zmiany w niniejszym regulaminie
Niniejszy Regulamin może być okresowo aktualizowany. Dalsze korzystanie z aplikacji oznacza akceptację zaktualizowanych warunków.

9. Kontakt
W przypadku pytań dotyczących niniejszego Regulaminu, prosimy o kontakt pod adresem:
info@ibiticoin.com""",

    'uk': """Умови надання послуг – DrainShield

Останнє оновлення: 2026

Використовуючи додаток DrainShield, ви погоджуєтеся з наступними умовами.

1. Опис послуги
DrainShield — це інструмент аналізу безпеки блокчейну, розроблений для допомоги користувачам:
• сканувати дозволи токенів
• виявляти потенційно ризиковані дозволи смарт-контрактів
• перевіряти ризики гаманця
• відкликати дозволи через підключений гаманець користувача

DrainShield не є криптовалютним гаманцем, не є кастодіаном і не зберігає та не контролює кошти користувачів.

2. Відповідальність користувача
Користувачі несуть повну відповідальність за:
• захист своїх приватних ключів та сід-фраз
• перевірку транзакцій перед їх підписанням
• забезпечення точності адрес гаманців, які вони підключають

DrainShield не може скасувати транзакції в блокчейні.

3. Відмова від фінансових рекомендацій
Інформація, що надається DrainShield, призначена лише для цілей аналізу безпеки і не повинна розглядатися як фінансова, інвестиційна або юридична консультація.

4. Ризики блокчейну
Використання технології блокчейн пов'язане з невід'ємними ризиками, включаючи, крім іншого:
• уразливості смарт-контрактів
• шкідливі протоколи
• фішингові атаки
• незворотні транзакції

DrainShield намагається виявити потенційні ризики, але не може гарантувати повний захист.

5. Сторонні послуги
DrainShield може покладатися на сторонніх постачальників інфраструктури блокчейну (таких як RPC-вузли або служби індексації). DrainShield не несе відповідальності за доступність або надійність цих послуг.

6. Обмеження відповідальності
У максимальній мірі, дозволеній законом, DrainShield та його розробники не несуть відповідальності за будь-які фінансові втрати, крадіжку активів або збитки, що виникли в результаті використання додатка.
Користувачі взаємодіють з мережами блокчейн на свій страх і ризик.

7. Зміни в послузі
DrainShield може оновлювати, змінювати або припиняти роботу функцій додатка в будь-який час без попереднього повідомлення.

8. Зміни в цих умовах
Ці Умови надання послуг можуть періодично оновлюватися. Продовження використання додатка означає прийняття оновлених умов.

9. Контакти
З питань щодо цих Умов надання послуг звертайтеся:
info@ibiticoin.com""",

    'id': """Ketentuan Layanan – DrainShield

Terakhir diperbarui: 2026

Dengan menggunakan aplikasi DrainShield, Anda menyetujui syarat dan ketentuan berikut.

1. Deskripsi Layanan
DrainShield adalah alat analisis keamanan blockchain yang dirancang untuk membantu pengguna:
• memindai persetujuan token
• mengidentifikasi izin kontrak pintar yang berpotensi berisiko
• meninjau eksposur dompet
• membatalkan izin melalui dompet pengguna yang terhubung

DrainShield bukan dompet mata uang kripto, bukan kustodian, dan tidak memegang atau mengendalikan dana pengguna.

2. Tanggung Jawab Pengguna
Pengguna bertanggung jawab penuh atas:
• melindungi kunci pribadi dan frasa pemulihan mereka
• memverifikasi transaksi sebelum menandatanganinya
• memastikan keakuratan alamat dompet yang mereka hubungkan

DrainShield tidak dapat membatalkan transaksi blockchain.

3. Bukan Saran Keuangan
Informasi yang disediakan oleh DrainShield hanya untuk tujuan analisis keamanan dan tidak boleh ditafsirkan sebagai saran keuangan, investasi, atau hukum.

4. Risiko Blockchain
Menggunakan teknologi blockchain melibatkan risiko yang melekat, termasuk namun tidak terbatas pada:
• kerentanan kontrak pintar
• protokol berbahaya
• serangan phishing
• transaksi yang tidak dapat dibatalkan

DrainShield mencoba mengidentifikasi risiko potensial tetapi tidak dapat menjamin perlindungan lengkap.

5. Layanan Pihak Ketiga
DrainShield mungkin mengandalkan penyedia infrastruktur blockchain pihak ketiga (seperti node RPC atau layanan pengindeksan). DrainShield tidak bertanggung jawab atas ketersediaan atau keandalan layanan ini.

6. Batasan Tanggung Jawab
Sejauh diizinkan oleh hukum, DrainShield dan pengembangnya tidak bertanggung jawab atas kerugian finansial, pencurian aset, atau kerusakan yang diakibatkan oleh penggunaan aplikasi.
Pengguna berinteraksi dengan jaringan blockchain atas risiko mereka sendiri.

7. Perubahan pada Layanan
DrainShield dapat memperbarui, mengubah, atau menghentikan fitur aplikasi kapan saja tanpa pemberitahuan sebelumnya.

8. Perubahan pada Ketentuan Ini
Ketentuan Layanan ini dapat diperbarui secara berkala. Penggunaan aplikasi yang berkelanjutan merupakan penerimaan atas ketentuan yang diperbarui.

9. Kontak
Untuk pertanyaan mengenai Ketentuan Layanan ini, hubungi:
info@ibiticoin.com""",

    'vi': """Điều khoản Dịch vụ – DrainShield

Cập nhật lần cuối: 2026

Bằng cách sử dụng ứng dụng DrainShield, bạn đồng ý với các điều khoản và điều kiện sau đây.

1. Mô tả Dịch vụ
DrainShield là một công cụ phân tích bảo mật blockchain được thiết kế để giúp người dùng:
• quét các phê duyệt mã thông báo
• xác định các quyền của hợp đồng thông minh có tiềm ẩn rủi ro
• xem xét mức độ tiếp xúc của ví
• thu hồi quyền thông qua ví đã kết nối của người dùng

DrainShield không phải là ví tiền điện tử, không phải là bên lưu ký và không nắm giữ hoặc kiểm soát tiền của người dùng.

2. Trách nhiệm của Người dùng
Người dùng hoàn toàn chịu trách nhiệm về:
• bảo vệ khóa cá nhân và cụm từ hạt giống của họ
• xác minh các giao dịch trước khi ký
• đảm bảo tính chính xác của địa chỉ ví mà họ kết nối

DrainShield không thể đảo ngược các giao dịch blockchain.

3. Không phải Lời khuyên Tài chính
Thông tin do DrainShield cung cấp chỉ nhằm mục đích phân tích bảo mật và không được hiểu là lời khuyên về tài chính, đầu tư hoặc pháp lý.

4. Rủi ro Blockchain
Việc sử dụng công nghệ blockchain tiềm ẩn những rủi ro cố hữu, bao gồm nhưng không giới hạn ở:
• lỗ hổng hợp đồng thông minh
• các giao thức độc hại
• tấn công giả mạo
• các giao dịch không thể đảo ngược

DrainShield cố gắng xác định các rủi ro tiềm ẩn nhưng không thể đảm bảo sự bảo vệ hoàn toàn.

5. Dịch vụ của Bên thứ ba
DrainShield có thể dựa vào các nhà cung cấp cơ sở hạ tầng blockchain bên thứ ba (chẳng hạn như các nút RPC hoặc dịch vụ lập chỉ mục). DrainShield không chịu trách nhiệm về tính khả dụng hoặc độ tin cậy của các dịch vụ này.

6. Giới hạn Trách nhiệm pháp lý
Trong phạm vi tối đa được pháp luật cho phép, DrainShield và các nhà phát triển của nó không chịu trách nhiệm về bất kỳ tổn thất tài chính, mất cắp tài sản hoặc thiệt hại nào phát sinh từ việc sử dụng ứng dụng.
Người dùng tương tác với mạng blockchain và tự chịu rủi ro.

7. Thay đổi đối với Dịch vụ
DrainShield có thể cập nhật, sửa đổi hoặc ngừng các tính năng của ứng dụng bất kỳ lúc nào mà không cần thông báo trước.

8. Thay đổi đối với các Điều khoản này
Các Điều khoản Dịch vụ này có thể được cập nhật định kỳ. Việc tiếp tục sử dụng ứng dụng đồng nghĩa với việc chấp nhận các điều khoản đã được cập nhật.

9. Liên hệ
Đối với các câu hỏi liên quan đến Điều khoản Dịch vụ này, hãy liên hệ:
info@ibiticoin.com"""
  };

  translations.forEach((lang, policy) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsTermsOfServiceContent'] = policy;
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated Terms of Service in assets/i18n/$lang.json');
    }
  });
}
