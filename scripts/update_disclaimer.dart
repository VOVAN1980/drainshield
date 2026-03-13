import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, String> translations = {
    'en': """Disclaimer – DrainShield

Last updated: 2026

DrainShield is a blockchain security analysis tool designed to help users review token approvals and identify potential smart-contract risks.

DrainShield analyzes token approvals and provides risk signals based on on-chain data and threat intelligence.

1. No Custody of Funds
DrainShield does not hold, store, or control user funds. All blockchain transactions are executed directly through the user’s connected wallet.

2. No Access to Private Keys
DrainShield never requests or stores private keys, seed phrases, or wallet passwords. Users remain solely responsible for the security of their wallet credentials.

3. Informational Purposes Only
All information provided by DrainShield is for security and informational purposes only. It should not be considered financial, investment, or legal advice.

4. Blockchain Risks
Blockchain networks involve inherent risks including malicious contracts, compromised protocols, and irreversible transactions. DrainShield attempts to detect potential risks but cannot guarantee complete protection against all threats.

5. Third-Party Protocols
DrainShield does not control or operate third-party smart contracts, decentralized applications, or blockchain networks. Users interact with external protocols entirely at their own discretion and risk.

6. Irreversible Transactions
All blockchain transactions are final and irreversible once confirmed on the network. Users should carefully review any transaction before signing it.

7. Limitation of Liability
DrainShield and its developers are not responsible for any financial losses, damages, or asset theft resulting from blockchain interactions or user actions.

8. Contact
For questions regarding this disclaimer, contact:
info@ibiticoin.com""",

    'ru': """Отказ от ответственности – DrainShield

Последнее обновление: 2026

DrainShield — это инструмент анализа безопасности блокчейна, предназначенный для того, чтобы помочь пользователям проверять разрешения токенов и выявлять потенциальные риски смарт-контрактов.

DrainShield анализирует разрешения токенов и предоставляет сигналы о рисках на основе данных в сети и анализа угроз.

1. Отсутствие хранения средств
DrainShield не хранит, не сберегает и не контролирует средства пользователей. Все транзакции в блокчейне выполняются напрямую через подключенный кошелек пользователя.

2. Нет доступа к закрытым ключам
DrainShield никогда не запрашивает и не хранит закрытые ключи, сид-фразы или пароли кошельков. Пользователи несут прямую ответственность за безопасность учетных данных своего кошелька.

3. Только в информационных целях
Вся информация, предоставляемая DrainShield, предназначена только для безопасности и ознакомления. Ее не следует рассматривать как финансовую, инвестиционную или юридическую консультацию.

4. Риски блокчейна
Сети блокчейн сопряжены с неотъемлемыми рисками, включая вредоносные контракты, взломанные протоколы и необратимые транзакции. DrainShield пытается обнаружить потенциальные риски, но не может гарантировать полную защиту от всех угроз.

5. Сторонние протоколы
DrainShield не контролирует и не управляет сторонними смарт-контрактами, децентрализованными приложениями или сетями блокчейн. Пользователи взаимодействуют с внешними протоколами исключительно по своему усмотрению и на свой страх и риск.

6. Необратимые транзакции
Все транзакции в блокчейне являются окончательными и необратимыми после подтверждения в сети. Пользователи должны внимательно проверять любую транзакцию перед ее подписанием.

7. Ограничение ответственности
DrainShield и его разработчики не несут ответственности за любые финансовые потери, ущерб или кражу активов, возникшие в результате взаимодействия с блокчейном или действий пользователя.

8. Контакты
По вопросам, касающимся этого отказа от ответственности, обращайтесь:
info@ibiticoin.com""",

    'de': """Haftungsausschluss – DrainShield

Zuletzt aktualisiert: 2026

DrainShield ist ein Tool zur Analyse der Blockchain-Sicherheit, das Benutzern helfen soll, Token-Genehmigungen zu überprüfen und potenzielle Smart-Contract-Risiken zu identifizieren.

DrainShield analysiert Token-Genehmigungen und liefert Risikosignale auf der Grundlage von On-Chain-Daten und Bedrohungsinformationen.

1. Keine Verwahrung von Geldern
DrainShield hält, speichert oder kontrolliert keine Benutzergelder. Alle Blockchain-Transaktionen werden direkt über die verbundene Wallet des Benutzers ausgeführt.

2. Kein Zugriff auf private Schlüssel
DrainShield fordert niemals private Schlüssel, Seed-Phrasen oder Wallet-Passwörter an oder speichert diese. Die Benutzer bleiben allein verantwortlich für die Sicherheit ihrer Wallet-Zugangsdaten.

3. Nur zu Informationszwecken
Alle von DrainShield bereitgestellten Informationen dienen ausschließlich Sicherheits- und Informationszwecken. Sie sollten nicht als Finanz-, Investitions- oder Rechtsberatung betrachtet werden.

4. Blockchain-Risiken
Blockchain-Netzwerke beinhalten inhärente Risiken, einschließlich böswilliger Verträge, kompromittierter Protokolle und unumkehrbarer Transaktionen. DrainShield versucht, potenzielle Risiken zu erkennen, kann aber keinen vollständigen Schutz gegen alle Bedrohungen garantieren.

5. Drittanbieter-Protokolle
DrainShield kontrolliert oder betreibt keine Smart Contracts, dezentralen Anwendungen oder Blockchain-Netzwerke von Drittanbietern. Benutzer interagieren mit externen Protokollen vollständig nach eigenem Ermessen und auf eigenes Risiko.

6. Unumkehrbare Transaktionen
Alle Blockchain-Transaktionen sind endgültig und unumkehrbar, sobald sie im Netzwerk bestätigt wurden. Benutzer sollten jede Transaktion sorgfältig prüfen, bevor sie sie unterzeichnen.

7. Haftungsbeschränkung
DrainShield und seine Entwickler sind nicht verantwortlich für finanzielle Verluste, Schäden oder Diebstahl von Vermögenswerten, die aus Blockchain-Interaktionen oder Benutzeraktionen resultieren.

8. Kontakt
Bei Fragen zu diesem Haftungsausschluss wenden Sie sich bitte an:
info@ibiticoin.com""",

    'fr': """Clause de non-responsabilité – DrainShield

Dernière mise à jour : 2026

DrainShield est un outil d'analyse de la sécurité de la blockchain conçu pour aider les utilisateurs à examiner les approbations de jetons et à identifier les risques potentiels liés aux contrats intelligents.

DrainShield analyse les approbations de jetons et fournit des signaux de risque basés sur les données on-chain et le renseignement sur les menaces.

1. Pas de garde de fonds
DrainShield ne détient, ne stocke ni ne contrôle les fonds des utilisateurs. Toutes les transactions sur la blockchain sont exécutées directement via le portefeuille connecté de l'utilisateur.

2. Pas d'accès aux clés privées
DrainShield ne demande ni ne stocke jamais de clés privées, de phrases de récupération ou de mots de passe de portefeuille. Les utilisateurs restent seuls responsables de la sécurité de leurs identifiants de portefeuille.

3. À des fins d'information uniquement
Toutes les informations fournies par DrainShield sont destinées uniquement à des fins de sécurité et d'information. Elles ne doivent pas être considérées comme des conseils financiers, d'investissement ou juridiques.

4. Risques liés à la blockchain
Les réseaux blockchain comportent des risques inhérents, notamment des contrats malveillants, des protocoles compromis et des transactions irréversibles. DrainShield tente de détecter les risques potentiels mais ne peut garantir une protection complète contre toutes les menaces.

5. Protocoles tiers
DrainShield ne contrôle ni n'exploite de contrats intelligents, d'applications décentralisées ou de réseaux blockchain tiers. Les utilisateurs interagissent avec des protocoles externes entièrement à leur discrétion et à leurs propres risques.

6. Transactions irréversibles
Toutes les transactions sur la blockchain sont définitives et irréversibles une fois confirmées sur le réseau. Les utilisateurs doivent examiner attentivement toute transaction avant de la signer.

7. Limitation de responsabilité
DrainShield et ses développeurs ne sont pas responsables des pertes financières, des dommages ou du vol d'actifs résultant des interactions avec la blockchain ou des actions des utilisateurs.

8. Contact
Pour toute question concernant cette clause de non-responsabilité, contactez :
info@ibiticoin.com""",

    'es': """Descargo de responsabilidad – DrainShield

Última actualización: 2026

DrainShield es una herramienta de análisis de seguridad de blockchain diseñada para ayudar a los usuarios a revisar las aprobaciones de tokens e identificar posibles riesgos de contratos inteligentes.

DrainShield analiza las aprobaciones de tokens y proporciona señales de riesgo basadas en datos on-chain e inteligencia de amenazas.

1. Sin custodia de fondos
DrainShield no posee, almacena ni controla los fondos de los usuarios. Todas las transacciones de blockchain se ejecutan directamente a través del monedero conectado del usuario.

2. Sin acceso a claves privadas
DrainShield nunca solicita ni almacena claves privadas, frases semilla o contraseñas de monederos. Los usuarios siguen siendo los únicos responsables de la seguridad de las credenciales de su monedero.

3. Solo con fines informativos
Toda la información proporcionada por DrainShield es solo para fines de seguridad e información. No debe considerarse asesoramiento financiero, de inversión o legal.

4. Riesgos de la blockchain
Las redes blockchain implican riesgos inherentes, incluidos contratos maliciosos, protocolos comprometidos y transacciones irreversibles. DrainShield intenta detectar riesgos potenciales, pero no puede garantizar una protección completa contra todas las amenazas.

5. Protocolos de terceros
DrainShield no controla ni opera contratos inteligentes, aplicaciones descentralizadas o redes blockchain de terceros. Los usuarios interactúan con protocolos externos bajo su entera discreción y riesgo.

6. Transacciones irreversibles
Todas las transacciones de blockchain son finales e irreversibles una vez confirmadas en la red. Los usuarios deben revisar cuidadosamente cualquier transacción antes de firmarla.

7. Limitación de responsabilidad
DrainShield y sus desarrolladores no son responsables de ninguna pérdida financiera, daño o robo de activos que resulte de las interacciones con la blockchain o las acciones del usuario.

8. Contacto
Para preguntas relacionadas con este descargo de responsabilidad, contacte con:
info@ibiticoin.com""",

    'pt': """Aviso Legal – DrainShield

Última atualização: 2026

O DrainShield é uma ferramenta de análise de segurança blockchain concebida para ajudar os utilizadores a rever as aprovações de tokens e a identificar potenciais riscos de contratos inteligentes.

O DrainShield analisa as aprovações de tokens e fornece sinais de risco baseados em dados on-chain e inteligência de ameaças.

1. Sem Custódia de Fundos
O DrainShield não detém, armazena ou controla fundos de utilizadores. Todas as transações na blockchain são executadas diretamente através da carteira ligada do utilizador.

2. Sem Acesso a Chaves Privadas
O DrainShield nunca solicita ou armazena chaves privadas, frases-semente ou palavras-passe de carteira. Os utilizadores continuam a ser os únicos responsáveis pela segurança das credenciais da sua carteira.

3. Apenas para Fins Informativos
Todas as informações fornecidas pelo DrainShield destinam-se apenas a fins de segurança e informativos. Não devem ser consideradas aconselhamento financeiro, de investimento ou jurídico.

4. Riscos da Blockchain
As redes blockchain envolvem riscos inerentes, incluindo contratos maliciosos, protocolos comprometidos e transações irreversíveis. O DrainShield tenta detetar potenciais riscos, mas não pode garantir uma proteção completa contra todas as ameaças.

5. Protocolos de Terceiros
O DrainShield não controla ou opera contratos inteligentes de terceiros, aplicações descentralizadas ou redes blockchain. Os utilizadores interagem com protocolos externos inteiramente ao seu critério e risco.

6. Transações Irreversíveis
Todas as transações na blockchain são finais e irreversíveis uma vez confirmadas na rede. Os utilizadores devem rever cuidadosamente qualquer transação antes de a assinar.

7. Limitação de Responsabilidade
O DrainShield e os seus programadores não são responsáveis por quaisquer perdas financeiras, danos ou roubo de ativos resultantes de interações na blockchain ou ações do utilizador.

8. Contacto
Para questões relativas a este aviso legal, contacte:
info@ibiticoin.com""",

    'tr': """Sorumluluk Reddi – DrainShield

Son güncelleme: 2026

DrainShield, kullanıcıların jeton onaylarını incelemelerine ve potansiyel akıllı sözleşme risklerini belirlemelerine yardımcı olmak için tasarlanmış bir blok zinciri güvenlik analizi aracıdır.

DrainShield jeton onaylarını analiz eder ve zincir içi verilere ve tehdit istihbaratına dayalı risk sinyalleri sağlar.

1. Fonların Saklanmaması
DrainShield kullanıcı fonlarını tutmaz, saklamaz veya kontrol etmez. Tüm blok zinciri işlemleri doğrudan kullanıcının bağlı cüzdanı aracılığıyla gerçekleştirilir.

2. Özel Anahtarlara Erişim Yok
DrainShield hiçbir zaman özel anahtarları, tohum ifadeleri veya cüzdan şifrelerini talep etmez veya saklamaz. Kullanıcılar, cüzdan bilgilerinin güvenliğinden tek başlarına sorumludur.

3. Yalnızca Bilgilendirme Amaçlıdır
DrainShield tarafından sağlanan tüm bilgiler yalnızca güvenlik ve bilgilendirme amaçlıdır. Finansal, yatırım veya hukuki tavsiye olarak değerlendirilmemelidir.

4. Blok Zinciri Riskleri
Blok zinciri ağları, kötü niyetli sözleşmeler, güvenliği ihlal edilmiş protokoller ve geri alınamaz işlemler dahil olmak üzere doğal riskler içerir. DrainShield potansiyel riskleri tespit etmeye çalışır ancak tüm tehditlere karşı tam koruma garanti edemez.

5. Üçüncü Taraf Protokolleri
DrainShield, üçüncü taraf akıllı sözleşmeleri, merkeziyetsiz uygulamaları veya blok zinciri ağlarını kontrol etmez veya işletmez. Kullanıcılar harici protokollerle tamamen kendi takdirleri ve riskleri altında etkileşime girerler.

6. Geri Alınamaz İşlemler
Tüm blok zinciri işlemleri, ağda onaylandıktan sonra kesin ve geri alınamazdır. Kullanıcılar herhangi bir işlemi imzalamadan önce dikkatlice incelemelidir.

7. Sorumluluğun Sınırlandırılması
DrainShield ve geliştiricileri, blok zinciri etkileşimlerinden veya kullanıcı eylemlerinden kaynaklanan herhangi bir finansal kayıp, zarar veya varlık hırsızlığından sorumlu değildir.

8. İletişim
Bu sorumluluk reddi beyanıyla ilgili sorularınız için şu adrese ulaşın:
info@ibiticoin.com""",

    'ar': """إخلاء المسؤولية – DrainShield

آخر تحديث: 2026

DrainShield هي أداة لتحليل أمان البلوكشين مصممة لمساعدة المستخدمين على مراجعة موافقات الرموز المميزة وتحديد مخاطر العقود الذكية المحتملة.

تقوم DrainShield بتحليل موافقات الرموز المميزة وتوفر إشارات المخاطر بناءً على البيانات الموجودة على السلسلة واستخبارات التهديدات.

1. لا توجد حضانة للأموال
لا تقوم DrainShield باحتجاز أو تخزين أو التحكم في أموال المستخدمين. يتم تنفيذ جميع معاملات البلوكشين مباشرة من خلال محفظة المستخدم المتصلة.

2. لا يوجد وصول إلى المفاتيح الخاصة
لا تطلب DrainShield أبدًا المفاتيح الخاصة أو عبارات البذور أو كلمات مرور المحفظة ولا تقوم بتخزينها. يظل المستخدمون مسؤولين بمفردهم عن أمن بيانات اعتماد محفظتهم.

3. للأغراض المعلوماتية فقط
جميع المعلومات التي تقدمها DrainShield هي للأغراض الأمنية والمعلوماتية فقط. ولا ينبغي اعتبارها نصيحة مالية أو استثمارية أو قانونية.

4. مخاطر البلوكشين
تنطوي شبكات البلوكشين على مخاطر متأصلة بما في ذلك العقود الضارة والبروتوكولات المخترقة والمعاملات غير القابلة للإلغاء. تحاول DrainShield اكتشاف المخاطر المحتملة ولكنها لا تستطيع ضمان الحماية الكاملة ضد جميع التهديدات.

5. بروتوكولات الجهات الخارجية
لا تتحكم DrainShield في العقود الذكية أو التطبيقات اللامركزية أو شبكات البلوكشين الخاصة بجهات خارجية ولا تقوم بتشغيلها. يتفاعل المستخدمون مع البروتوكولات الخارجية تمامًا وفقًا لتقديرهم ومسؤوليتهم الخاصة.

6. المعاملات غير القابلة للإلغاء
تعد جميع معاملات البلوكشين نهائية وغير قابلة للإلغاء بمجرد تأكيدها على الشبكة. يجب على المستخدمين مراجعة أي معاملة بعناية قبل التوقيع عليها.

7. تحديد المسؤولية
لا تتحمل DrainShield ومطوروها المسؤولية عن أي خسائر مالية أو أضرار أو سرقة أصول ناتجة عن تفاعلات البلوكشين أو إجراءات المستخدم.

8. الاتصال
للأسئلة المتعلقة بإخلاء المسؤولية هذا، اتصل بـ:
info@ibiticoin.com""",

    'zh': """免责声明 – DrainShield

最后更新：2026

DrainShield 是一款区块链安全分析工具，旨在帮助用户审查代币授权并识别潜在的智能合约风险。

DrainShield 分析代币授权，并根据链上数据和威胁情报提供风险信号。

1. 无资金托管
DrainShield 不持有、存储或控制用户资金。所有区块链交易均通过用户连接的钱包直接执行。

2. 无私钥访问权
DrainShield 从不请求或存储私钥、助记词或钱包密码。用户仍对自己的钱包凭据安全负全部责任。

3. 仅供参考
DrainShield 提供的所有信息仅用于安全和参考目的。不应被视为财务、投资或法律建议。

4. 区块链风险
区块链网络涉及固有风险，包括恶意合约、受损协议和不可逆交易。DrainShield 尝试检测潜在风险，但不能保证完全抵御所有威胁。

5. 第三方协议
DrainShield 不控制或运行第三方智能合约、去中心化应用程序或区块链网络。用户与外部协议的互动完全由其自行决定并承担风险。

6. 不可逆交易
所有区块链交易在网络确认后均具有最终性和不可逆性。用户在签署任何交易前应仔细审查。

7. 责任限制
DrainShield 及其开发人员不对因区块链互动或用户行为而导致的任何财务损失、损害或资产失窃负责。

8. 联系方式
有关本免责声明的问题，请联系：
info@ibiticoin.com""",

    'hi': """अस्वीकरण – DrainShield

अंतिम अपडेट: 2026

DrainShield एक ब्लॉकचेन सुरक्षा विश्लेषण उपकरण है जिसे उपयोगकर्ताओं को टोकन अनुमोदन की समीक्षा करने और संभावित स्मार्ट-कॉन्ट्रैक्ट जोखिमों की पहचान करने में मदद करने के लिए डिज़ाइन किया गया है।

DrainShield टोकन अनुमोदन का分析 करता है और ऑन-चैन डेटा और खतरे की खुफिया जानकारी के आधार पर जोखिम संकेत प्रदान करता है।

1. धन की कोई कस्टडी नहीं
DrainShield उपयोगकर्ता के धन को नहीं रखता, संग्रहीत या नियंत्रित नहीं करता है। सभी ब्लॉकचेन लेनदेन सीधे उपयोगकर्ता के कनेक्टेड वॉलेट के माध्यम से निष्पादित किए जाते हैं।

2. निजी चाबियों तक कोई पहुंच नहीं
DrainShield कभी भी निजी चाबियों, सीड वाक्यांशों या वॉलेट पासवर्ड का अनुरोध या भंडारण नहीं करता है। उपयोगकर्ता अपने वॉलेट क्रेडेंशियल की सुरक्षा के लिए पूरी तरह जिम्मेदार रहते हैं।

3. केवल सूचनात्मक उद्देश्यों के लिए
DrainShield द्वारा प्रदान की गई सभी जानकारी केवल सुरक्षा और सूचनात्मक उद्देश्यों के लिए है। इसे वित्तीय, निवेश या कानूनी सलाह नहीं माना जाना चाहिए।

4. ब्लॉकचेन जोखिम
ब्लॉकचेन नेटवर्क में दुर्भावनापूर्ण अनुबंध, समझौता किए गए प्रोटोकॉल और अपरिवर्तनीय लेनदेन सहित अंतर्निहित जोखिम शामिल हैं। DrainShield संभावित जोखिमों का पता लगाने का प्रयास करता है लेकिन सभी खतरों के खिलाफ पूर्ण सुरक्षा की गारंटी नहीं दे सकता है।

5. तीसरे पक्ष के प्रोटोकॉल
DrainShield तीसरे पक्ष के स्मार्ट अनुबंधों, विकेंद्रीकृत अनुप्रयोगों या ब्लॉकचेन नेटवर्क को नियंत्रित या संचालित नहीं करता है। उपयोगकर्ता बाहरी प्रोटोकॉल के साथ पूरी तरह से अपने विवेक और जोखिम पर बातचीत करते हैं।

6. अपरिवर्तनीय लेनदेन
नेटवर्क पर पुष्टि होने के बाद सभी ब्लॉकचेन लेनदेन अंतिम और अपरिवर्तनीय होते हैं। उपयोगकर्ताओं को हस्ताक्षर करने से पहले किसी भी लेनदेन की सावधानीपूर्वक समीक्षा करनी चाहिए।

7. देयता की सीमा
DrainShield और इसके डेवलपर ब्लॉकचेन इंटरैक्शन या उपयोगकर्ता कार्यों के परिणामस्वरूप होने वाले किसी भी वित्तीय नुकसान, क्षति या संपत्ति की चोरी के लिए जिम्मेदार नहीं हैं।

8. संपर्क
इस अस्वीकरण के संबंध में प्रश्नों के लिए, संपर्क करें:
info@ibiticoin.com""",

    'ja': """免責事項 – DrainShield

最終更新日：2026年

DrainShieldは、ユーザーがトークンの承認を確認し、潜在的なスマートコントラクトのリスクを特定できるように設計されたブロックチェーンセキュリティ分析ツールです。

DrainShieldはトークンの承認を分析し、オンチェーンデータと脅威インテリジェンスに基づいてリスクシグナルを提供します。

1. 資金の非預託
DrainShieldはユーザーの資金を保持、保存、または管理しません。すべてのブロックチェーン取引は、接続されたユーザーのウォレットを介して直接実行されます。

2. プライベートキーへのアクセスの否定
DrainShieldがプライベートキー、シードフレーズ、またはウォレットのパスワードを要求したり保存したりすることはありません。ユーザーは、自身のウォレット認証情報のセキュリティについて単独で責任を負います。

3. 情報提供のみを目的とする
DrainShieldが提供するすべての情報は、セキュリティおよび情報提供のみを目的としています。財務、投資、または法律上の助言と見なされるべきではありません。

4. ブロックチェーンのリスク
ブロックチェーンネットワークには、悪意のあるコントラクト、侵害されたプロトコル、取り消し不能な取引などの固有のリスクが伴います。DrainShieldは潜在的なリスクの検出を試みますが、すべての脅威に対する完全な保護を保証することはできません。

5. サードパーティプロトコル
DrainShieldは、サードパーティのスマートコントラクト、分散型アプリケーション、またはブロックチェーンネットワークを管理または運営していません。ユーザーは、自身の裁量と責任において、外部プロトコルとやり取りするものとします。

6. 取り消し不能な取引
すべてのブロックチェーン取引は、ネットワークで確認された後は最終的であり、取り消し不可能です。ユーザーは、署名する前に取引を注意深く確認する必要があります。

7. 責任の制限
DrainShieldおよびその開発者は、ブロックチェーンとのやり取りまたはユーザーの行動に起因する金銭的損失、損害、または資産の盗難について責任を負いません。

8. お問い合わせ
本免責事項に関するご質問は、以下までお問い合わせください：
info@ibiticoin.com""",

    'ko': """면책 조항 – DrainShield

최종 업데이트: 2026년

DrainShield는 사용자가 토큰 승인을 검토하고 잠재적인 스마트 컨트랙트 리스크를 식별할 수 있도록 설계된 블록체인 보안 분석 도구입니다.

DrainShield는 토큰 승인을 분석하고 온체인 데이터 및 위협 인텔리전스를 기반으로 리스크 신호를 제공합니다.

1. 자금 수탁 조항 없음
DrainShield는 사용자의 자금을 보유, 저장 또는 통제하지 않습니다. 모든 블록체인 트랜잭션은 사용자의 연결된 지갑을 통해 직접 실행됩니다.

2. 프라이빗 키 접근 권한 없음
DrainShield는 프라이빗 키, 시드 구문 또는 지갑 비밀번호를 요청하거나 저장하지 않습니다. 사용자는 지갑 인증 정보의 보안을 유지할 전적인 책임이 있습니다.

3. 정보 제공 목적 전용
DrainShield가 제공하는 모든 정보는 보안 및 정보 제공 목적으로만 제공됩니다. 이는 금융, 투자 또는 법률 자문으로 간주되어서는 안 됩니다.

4. 블록체인 리스크
블록체인 네트워크에는 악성 컨트랙트, 손상된 프로토콜, 되돌릴 수 없는 트랜잭션 등 고유한 리스크가 수반됩니다. DrainShield는 잠재적인 리스크를 탐지하려고 노력하지만 모든 위협에 대한 완전한 보호를 보장할 수는 없습니다.

5. 제3자 프로토콜
DrainShield는 제3자 스마트 컨트랙트, 탈중앙화 애플리케이션 또는 블록체인 네트워크를 제어하거나 운영하지 않습니다. 사용자는 전적으로 본인의 판단과 책임하에 외부 프로토콜과 상호작용합니다.

6. 되돌릴 수 없는 트랜잭션
모든 블록체인 트랜잭션은 네트워크에서 확인되면 최종적이며 취소할 수 없습니다. 사용자는 서명하기 전에 모든 트랜잭션을 주의 깊게 검토해야 합니다.

7. 책임의 한계
DrainShield와 그 개발자는 블록체인 상호작용 또는 사용자의 행동으로 인해 발생하는 어떠한 재정적 손실, 피해 또는 자산 도난에 대해서도 책임을 지지 않습니다.

8. 문의처
본 면책 조항에 관한 질문이 있는 경우 다음으로 연락하십시오:
info@ibiticoin.com""",

    'it': """Dichiarazione di non responsabilità – DrainShield

Ultimo aggiornamento: 2026

DrainShield è uno strumento di analisi della sicurezza blockchain progettato per aiutare gli utenti a rivedere le approvazioni dei token e identificare i potenziali rischi degli smart contract.

DrainShield analizza le approvazioni dei token e fornisce segnali di rischio basati sui dati on-chain e sull'intelligence delle minacce.

1. Nessuna custodia di fondi
DrainShield non detiene, memorizza o controlla i fondi degli utenti. Tutte le transazioni blockchain vengono eseguite direttamente attraverso il portafoglio collegato dell'utente.

2. Nessun accesso alle chiavi private
DrainShield non richiede né memorizza mai chiavi private, frasi seed o password del portafoglio. Gli utenti rimangono gli unici responsabili della sicurezza delle proprie credenziali del portafoglio.

3. Solo a scopo informativo
Tutte le informazioni fornite da DrainShield sono solo a scopo informativo e di sicurezza. Non devono essere considerate consulenza finanziaria, d'investimento o legale.

4. Rischi della blockchain
Le reti blockchain comportano rischi intrinseci, tra cui contratti malevoli, protocolli compromessi e transazioni irreversibili. DrainShield tenta di rilevare potenziali rischi ma non può garantire una protezione completa contro tutte le minacce.

5. Protocolli di terze parti
DrainShield non controlla né gestisce smart contract, applicazioni decentralizzate o reti blockchain di terze parti. Gli utenti interagiscono con i protocolli esterni a loro completa discrezione e rischio.

6. Transazioni irreversibili
Tutte le transazioni blockchain sono definitive e irreversibili una volta confermate sulla rete. Gli utenti devono controllare attentamente ogni transazione prima di firmarla.

7. Limitazione di responsabilità
DrainShield e i suoi sviluppatori non sono responsabili per eventuali perdite finanziarie, danni o furti di asset derivanti dalle interazioni con la blockchain o dalle azioni degli utenti.

8. Contatto
Per domande relative a questa dichiarazione di non responsabilità, contattare:
info@ibiticoin.com""",

    'pl': """Zastrzeżenie prawne – DrainShield

Ostatnia aktualizacja: 2026

DrainShield to narzędzie do analizy bezpieczeństwa blockchain zaprojektowane, aby pomagać użytkownikom przeglądać zatwierdzenia tokenów i identyfikować potencjalne ryzyka związane z inteligentnymi kontraktami.

DrainShield analizuje zatwierdzenia tokenów i dostarcza sygnały o ryzyku w oparciu o dane on-chain i analizę zagrożeń.

1. Brak powiernictwa nad środkami
DrainShield nie posiada, nie przechowuje ani nie kontroluje środków użytkowników. Wszystkie transakcje blockchain są wykonywane bezpośrednio przez połączony portfel użytkownika.

2. Brak dostępu do kluczy prywatnych
DrainShield nigdy nie prosi o klucze prywatne, frazy seed ani hasła do portfela, ani ich nie przechowuje. Użytkownicy pozostają wyłącznie odpowiedzialni za bezpieczeństwo swoich danych uwierzytelniających portfel.

3. Wyłącznie w celach informacyjnych
Wszystkie informacje dostarczane przez DrainShield służą wyłącznie celom bezpieczeństwa i informacyjnym. Nie powinny być traktowane jako porady finansowe, inwestycyjne ani prawne.

4. Ryzyko Blockchain
Sieci blockchain wiążą się z nieodłącznym ryzykiem, w tym złośliwymi kontraktami, naruszonymi protokołami i nieodwracalnymi transakcjami. DrainShield stara się wykrywać potencjalne zagrożenia, ale nie może zagwarantować pełnej ochrony przed wszystkimi zagrożeniami.

5. Protokoły stron trzecich
DrainShield nie kontroluje ani nie obsługuje inteligentnych kontraktów, zdecentralizowanych aplikacji ani sieci blockchain innych firm. Użytkownicy wchodzą w interakcję z zewnętrznymi protokołami wyłącznie według własnego uznania i na własne ryzyko.

6. Nieodwracalne transakcje
Wszystkie transakcje blockchain są ostateczne i nieodwracalne po potwierdzeniu w sieci. Użytkownicy powinni dokładnie sprawdzić każdą transakcję przed jej podpisaniem.

7. Ograniczenie odpowiedzialności
DrainShield i jego twórcy nie ponoszą odpowiedzialności za jakiekolwiek straty finansowe, szkody lub kradzież aktywów wynikające z interakcji z blockchainem lub działań użytkownika.

8. Kontakt
W przypadku pytań dotyczących niniejszego zastrzeżenia, prosimy o kontakt:
info@ibiticoin.com""",

    'uk': """Відмова від відповідальності – DrainShield

Останнє оновлення: 2026

DrainShield — це інструмент аналізу безпеки блокчейну, розроблений для допомоги користувачам у перевірці дозволів токенів та виявленні потенційних ризиків смарт-контрактів.

DrainShield аналізує дозволи токенів та надає сигнали про ризики на основі даних у мережі та аналізу загроз.

1. Відсутність зберігання коштів
DrainShield не володіє, не зберігає і не контролює кошти користувачів. Усі транзакції в блокчейні виконуються безпосередньо через підключений гаманець користувача.

2. Відсутність доступу до приватних ключів
DrainShield ніколи не запитує і не зберігає приватні ключі, сід-фрази або паролі гаманців. Користувачі несуть повну відповідальність за безпеку облікових даних свого гаманця.

3. Тільки в інформаційних цілях
Уся інформація, що надається DrainShield, призначена лише для цілей безпеки та ознайомлення. Її не слід розглядати як фінансову, інвестиційну або юридичну консультацію.

4. Ризики блокчейну
Мережі блокчейн пов'язані з невід'ємними ризиками, включаючи шкідливі контракти, скомпрометовані протоколи та незворотні транзакції. DrainShield намагається виявити потенційні ризики, але не може гарантувати повний захист від усіх загроз.

5. Сторонні протоколи
DrainShield не контролює і не керує сторонніми смарт-контрактами, децентралізованими додатками або мережами блокчейн. Користувачі взаємодіють із зовнішніми протоколами виключно на власний розсуд і ризик.

6. Незворотні транзакції
Усі транзакції в блокчейні є остаточними та незворотними після підтвердження в мережі. Користувачі повинні уважно перевіряти будь-яку транзакцію перед її підписанням.

7. Обмеження відповідальності
DrainShield та його розробники не несуть відповідальності за будь-які фінансові втрати, збитки або крадіжку активів, що виникли в результаті взаємодії з блокчейном або дій користувача.

8. Контакти
З питань щодо цієї відмови від відповідальності звертайтеся:
info@ibiticoin.com""",

    'id': """Penafian – DrainShield

Terakhir diperbarui: 2026

DrainShield adalah alat analisis keamanan blockchain yang dirancang untuk membantu pengguna meninjau persetujuan token dan mengidentifikasi potensi risiko kontrak pintar.

DrainShield menganalisis persetujuan token dan memberikan sinyal risiko berdasarkan data on-chain dan intelijen ancaman.

1. Tidak Ada Penitipan Dana
DrainShield tidak memegang, menyimpan, atau mengendalikan dana pengguna. Semua transaksi blockchain dieksekusi secara langsung melalui dompet pengguna yang terhubung.

2. Tidak Ada Akses ke Kunci Pribadi
DrainShield tidak pernah meminta atau menyimpan kunci pribadi, frasa pemulihan, atau kata sandi dompet. Pengguna tetap bertanggung jawab sepenuhnya atas keamanan kredensial dompet mereka.

3. Hanya untuk Tujuan Informasi
Semua informasi yang disediakan oleh DrainShield hanya untuk tujuan keamanan dan informasi. Hal ini tidak boleh dianggap sebagai saran keuangan, investasi, atau hukum.

4. Risiko Blockchain
Jaringan blockchain melibatkan risiko yang melekat termasuk kontrak berbahaya, protokol yang disusupi, dan transaksi yang tidak dapat dibatalkan. DrainShield mencoba mendeteksi potensi risiko tetapi tidak dapat menjamin perlindungan lengkap terhadap semua ancaman.

5. Protokol Pihak Ketiga
DrainShield tidak mengontrol atau mengoperasikan kontrak pintar, aplikasi terdesentralisasi, atau jaringan blockchain pihak ketiga. Pengguna berinteraksi dengan protokol eksternal sepenuhnya atas kebijakan dan risiko mereka sendiri.

6. Transaksi yang Tidak Dapat Dibatalkan
Semua transaksi blockchain bersifat final dan tidak dapat dibatalkan setelah dikonfirmasi di jaringan. Pengguna harus meninjau transaksi apa pun dengan cermat sebelum menandatanganinya.

7. Batasan Tanggung Jawab
DrainShield dan pengembangnya tidak bertanggung jawab atas kerugian finansial, kerusakan, atau pencurian aset yang diakibatkan oleh interaksi blockchain atau tindakan pengguna.

8. Kontak
Untuk pertanyaan mengenai penafian ini, hubungi:
info@ibiticoin.com""",

    'vi': """Tuyên bố miễn trừ trách nhiệm – DrainShield

Cập nhật lần cuối: 2026

DrainShield là một công cụ phân tích bảo mật blockchain được thiết kế để giúp người dùng xem xét các phê duyệt mã thông báo và xác định các rủi ro tiềm ẩn của hợp đồng thông minh.

DrainShield phân tích các phê duyệt mã thông báo và cung cấp các tín hiệu rủi ro dựa trên dữ liệu on-chain và thông tin tình báo về mối đe dọa.

1. Không lưu ký tiền
DrainShield không nắm giữ, lưu trữ hoặc kiểm soát tiền của người dùng. Tất cả các giao dịch blockchain đều được thực hiện trực tiếp thông qua ví đã kết nối của người dùng.

2. Không có quyền truy cập vào Khóa cá nhân
DrainShield không bao giờ yêu cầu hoặc lưu trữ mã khóa cá nhân, cụm từ hạt giống hoặc mật khẩu ví. Người dùng hoàn toàn chịu trách nhiệm về tính bảo mật cho thông tin xác thực ví của họ.

3. Chỉ nhằm mục đích thông tin
Tất cả thông tin do DrainShield cung cấp chỉ nhằm mục đích bảo mật và thông tin. Nó không nên được coi là lời khuyên về tài chính, đầu tư hoặc pháp lý.

4. Rủi ro Blockchain
Mạng lưới blockchain tiềm ẩn những rủi ro cố hữu bao gồm các hợp đồng độc hại, các giao thức bị xâm nhập và các giao dịch không thể đảo ngược. DrainShield cố gắng phát hiện các rủi ro tiềm ẩn nhưng không thể đảm bảo sự bảo vệ hoàn toàn trước mọi mối đe dọa.

5. Giao thức của bên thứ ba
DrainShield không kiểm soát hoặc vận hành các hợp đồng thông minh, ứng dụng phi tập trung hoặc mạng lưới blockchain của bên thứ ba. Người dùng tương tác với các giao thức bên ngoài hoàn toàn theo ý muốn và rủi ro của riêng họ.

6. Giao dịch không thể đảo ngược
Tất cả các giao dịch blockchain là cuối cùng và không thể đảo ngược sau khi được xác nhận trên mạng lưới. Người dùng nên xem xét cẩn thận bất kỳ giao dịch nào trước khi ký.

7. Giới hạn Trách nhiệm pháp lý
DrainShield và các nhà phát triển của nó không chịu trách nhiệm về bất kỳ tổn thất tài chính, thiệt hại hoặc mất cắp tài sản nào phát sinh từ các tương tác blockchain hoặc hành động của người dùng.

8. Liên hệ
Đối với các câu hỏi liên quan đến tuyên bố miễn trừ trách nhiệm này, hãy liên hệ:
info@ibiticoin.com"""
  };

  translations.forEach((lang, policy) {
    final file = File('assets/i18n/$lang.json');
    if (file.existsSync()) {
      final content = json.decode(file.readAsStringSync());
      content['settingsDisclaimerContent'] = policy;
      
      const encoder = JsonEncoder.withIndent('    ');
      file.writeAsStringSync(encoder.convert(content));
      print('Updated Disclaimer in assets/i18n/$lang.json');
    }
  });
}
