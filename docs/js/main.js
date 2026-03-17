document.addEventListener('DOMContentLoaded', () => {
    gsap.registerPlugin(ScrollTrigger);

    // --- HD Cinematic Background (Alive & Drifting) ---
    const mesh = document.querySelector('.mesh-gradient');
    const ambient = document.querySelector('.ambient-scene');
    const glow = document.querySelector('.glow-follower');

    if (mesh) {
        // Subtle ambient drifting (always alive)
        gsap.to(mesh, {
            duration: 20,
            x: '+=30',
            y: '+=20',
            rotation: 5,
            repeat: -1,
            yoyo: true,
            ease: "sine.inOut"
        });

        // Mouse-responsive atmosphere
        window.addEventListener('mousemove', (e) => {
            const dx = (e.clientX - window.innerWidth / 2) / (window.innerWidth / 2);
            const dy = (e.clientY - window.innerHeight / 2) / (window.innerHeight / 2);

            gsap.to(mesh, {
                rotate: 15 * dx,
                x: dx * 40,
                y: dy * 40,
                duration: 3,
                ease: 'power1.out'
            });

            if (glow) {
                gsap.to(glow, {
                    x: e.clientX,
                    y: e.clientY,
                    duration: 1.5,
                    ease: 'power2.out'
                });
            }
        });
    }

    // --- Premium Entrance Stagger (Hero) ---
    const heroTl = gsap.timeline();

    heroTl.from('.hero-content h1', {
        y: 60,
        opacity: 0,
        duration: 1.5,
        ease: 'power4.out'
    })
        .from('.hero-content .text-label', {
            x: -20,
            opacity: 0,
            duration: 1,
            ease: 'power3.out'
        }, "-=1")
        .from('.hero-content .text-body', {
            y: 20,
            opacity: 0,
            duration: 1.2,
            ease: 'power3.out'
        }, "-=0.8")
        .from('.hero-content .btn', {
            y: 20,
            opacity: 0,
            duration: 0.8,
            stagger: 0.2,
            ease: 'back.out(1.7)'
        }, "-=0.6")
        .from('.hero-content + .visual-scene', {
            scale: 0.95,
            opacity: 0,
            duration: 2,
            ease: 'power2.out'
        }, "-=1.5");

    // --- Rigid Pair Parallax (Restrained) ---
    const isMobile = window.innerWidth < 1024;

    if (!isMobile) {
        window.addEventListener('mousemove', (e) => {
            const cx = window.innerWidth / 2;
            const cy = window.innerHeight / 2;
            const dx = (e.clientX - cx) / cx;
            const dy = (e.clientY - cy) / cy;

            document.querySelectorAll('.visual-scene[data-depth]').forEach(container => {
                const depth = parseFloat(container.getAttribute('data-depth')) || 0.1;

                // Move entire container (Rigid Pair)
                gsap.to(container, {
                    x: dx * depth * 50,
                    y: dy * depth * 50,
                    duration: 2.5,
                    ease: 'power1.out',
                    overwrite: 'auto'
                });

                // Subtle internal depth difference (very light)
                const phone = container.querySelector('.phone-mockup');
                const mascot = container.querySelector('.mascot-companion');

                if (phone) {
                    gsap.to(phone, {
                        x: dx * 10,
                        duration: 3,
                        ease: 'power1.out'
                    });
                }
                if (mascot) {
                    gsap.to(mascot, {
                        x: dx * -5,
                        duration: 3,
                        ease: 'power1.out'
                    });
                }
            });
        });
    }

    // --- Content Reveal (Scroll Triggered) ---
    document.querySelectorAll('.stage:not(:first-child)').forEach(stage => {
        const revealEl = stage.querySelector('.reveal');
        const visualEl = stage.querySelector('.visual-scene');

        if (revealEl) {
            gsap.from(revealEl, {
                scrollTrigger: {
                    trigger: stage,
                    start: 'top 75%',
                },
                y: 50,
                opacity: 0,
                duration: 1.2,
                ease: 'power3.out'
            });
        }

        // PRO Feature Stagger Reveal
        const proFeaturesByStage = stage.querySelectorAll('.pro-feature-item');
        if (proFeaturesByStage.length > 0) {
            gsap.from(proFeaturesByStage, {
                scrollTrigger: {
                    trigger: stage,
                    start: 'top 60%',
                },
                x: -20,
                opacity: 0,
                duration: 0.8,
                stagger: 0.1,
                ease: 'power2.out'
            });
        }

        if (visualEl) {
            gsap.from(visualEl, {
                scrollTrigger: {
                    trigger: stage,
                    start: 'top 80%',
                },
                scale: 0.98,
                opacity: 0,
                duration: 1.5,
                ease: 'power2.out'
            });
        }
    });

    // --- Final Section Polish ---
    gsap.from('.mascot-gold', {
        scrollTrigger: {
            trigger: '.final-stage',
            start: 'top 70%',
        },
        scale: 0.8,
        opacity: 0,
        duration: 2,
        ease: 'elastic.out(1, 0.75)'
    });

    // --- Internationalization (i18n) ---
    const translations = {
        en: {
            nav_labs: "LABS",
            nav_source: "SOURCE CODE",
            nav_privacy: "PRIVACY",
            nav_status: "SECURED BY WALLETCONNECT",
            hero_label: "Active Wallet Security",
            hero_title_1: "SCAN AND SECURE",
            hero_title_2: "WALLET",
            hero_title_3: "APPROVALS.",
            hero_desc: "Proactive protection against risky approvals and dangerous permissions. Detect hidden drains and malicious hooks before they compromise your assets.<br><br><strong data-i18n=\"hero_disclaimer\">No private key storage. Wallet-signed transactions only. Non-custodial.</strong>",
            hero_disclaimer: "No private key storage. Wallet-signed transactions only. Non-custodial.",
            btn_github: "VIEW ON GITHUB",
            btn_code: "BROWSE CODE",
            stage2_label: "SILENT DRAIN PREVENTION",
            stage2_title_1: "Detect Dangerous",
            stage2_title_2: "Permissions.",
            stage2_desc: "Stale or unlimited approvals are the primary attack paths for modern exploits. Our risk engine identifies high-risk protocols and identifies silent connections that could lead to asset drains.",
            stage3_label: "APPROVAL CLASSIFICATION",
            stage3_title_1: "Know exactly",
            stage3_title_2: "What you sign.",
            stage3_desc: "Decode complex smart contract logic into clear security signals. Analyze spender reputation, contract trust signals, and perform one-tap revocations for any unsafe allowance.",
            pro_label: "ADVANCED MONITORING",
            pro_title_1: "Continuous",
            pro_title_2: "Wallet Defense.",
            pro_desc: "Automate your security workflow with 24/7 monitoring and batch remediation tools built for intensive wallet management.",
            pro_feat_1: "24/7 AUTO-MONITORING",
            pro_feat_2: "BATCH RISK REVOKE",
            pro_feat_3: "5+ WALLET SLOTS",
            pro_feat_4: "PRIORITY THREAT ALERTS",
            pro_feat_5: "ADVANCED RISK INTEL",
            pro_feat_6: "ZERO-TRUST GUARD",
            btn_pro: "ACTIVATE PRO PROTECTION",
            stage5_label: "EMERGENCY RESPONSE",
            stage5_title_1: "PANIC MODE:",
            stage5_title_2: "ASSET ISOLATION.",
            stage5_desc: "Instant asset isolation through fast revocation. In the event of a breach, trigger emergency response directly through your connected wallet. Transparent, trustless, and wallet-signed.",
            footer_labs: "A PRODUCT OF IBITI SECURITY LABS.",
            footer_slogan: "Proactive defense for the decentralized era.",
            footer_connect: "CONNECT",
            footer_legal: "LEGAL",
            footer_privacy: "Privacy Policy",
            footer_terms: "Terms of Use",
            footer_copy: "© 2026 IBITI LABS. SECURING YOUR ON-CHAIN JOURNEY."
        },
        ru: {
            nav_labs: "ЛАБОРАТОРИЯ",
            nav_source: "ИСХОДНЫЙ КОД",
            nav_privacy: "ПРИВАТНОСТЬ",
            nav_status: "ЗАЩИЩЕНО WALLETCONNECT",
            hero_label: "Активная безопасность кошелька",
            hero_title_1: "СКАНИРУЙТЕ И ЗАЩИЩАЙТЕ",
            hero_title_2: "КОШЕЛЕК",
            hero_title_3: "АПРУВЫ.",
            hero_desc: "Проактивная защита от рискованных апрувов и опасных разрешений. Обнаруживайте скрытые дрейнеры и вредоносные ловушки до того, как они скомпрометируют ваши активы.<br><br><strong data-i18n=\"hero_disclaimer\">Без хранения приватных ключей. Только транзакции, подписанные кошельком. Некастодиально.</strong>",
            hero_disclaimer: "Без хранения приватных ключей. Только транзакции, подписанные кошельком. Некастодиально.",
            btn_github: "СМОТРЕТЬ НА GITHUB",
            btn_code: "ПОСМОТРЕТЬ КОД",
            stage2_label: "ПРЕДОТВРАЩЕНИЕ СКРЫТЫХ КРАЖ",
            stage2_title_1: "Обнаруживайте опасные",
            stage2_title_2: "Разрешения.",
            stage2_desc: "Устаревшие или неограниченные апрувы — главные пути атак для современных эксплойтов. Наш движок рисков определяет опасные протоколы и выявляет скрытые соединения, ведущие к краже активов.",
            stage3_label: "КЛАССИФИКАЦИЯ АПРУВОВ",
            stage3_title_1: "Знайте точно,",
            stage3_title_2: "Что вы подписываете.",
            stage3_desc: "Декодируйте сложную логику смарт-контрактов в понятные сигналы безопасности. Анализируйте репутацию сервиса, сигналы доверия к контракту и отзывайте доступы одним нажатием.",
            pro_label: "ПРОДВИНУТЫЙ МОНИТОРИНГ",
            pro_title_1: "Непрерывная",
            pro_title_2: "Защита кошелька.",
            pro_desc: "Автоматизируйте свой рабочий процесс безопасности с помощью круглосуточного мониторинга и инструментов массового исправления, созданных для профессионального управления активами.",
            pro_feat_1: "24/7 АВТО-МОНИТОРИНГ",
            pro_feat_2: "МАССОВЫЙ ОТЗЫВ РИСКОВ",
            pro_feat_3: "5+ СЛОТОВ ДЛЯ КОШЕЛЬКОВ",
            pro_feat_4: "ПРИОРИТЕТНЫЕ УВЕДОМЛЕНИЯ",
            pro_feat_5: "ПРЕМИУМ АНАЛИТИКА",
            pro_feat_6: "ЗАЩИТА ZERO-TRUST",
            btn_pro: "АКТИВИРОВАТЬ PRO ЗАЩИТУ",
            stage5_label: "ЭКСТРЕННОЕ РЕАГИРОВАНИЕ",
            stage5_title_1: "ПАНИК МОД:",
            stage5_title_2: "ИЗОЛЯЦИЯ АКТИВОВ.",
            stage5_desc: "Мгновенная изоляция активов через быстрый отзыв апрувов. В случае взлома запустите экстренное реагирование прямо через ваш кошелек. Прозрачно и безопасно.",
            footer_labs: "ПРОДУКТ IBITI SECURITY LABS.",
            footer_slogan: "Проактивная защита для децентрализованной эры.",
            footer_connect: "СВЯЗЬ",
            footer_legal: "ЮРИДИЧЕСКАЯ ИНФОРМАЦИЯ",
            footer_privacy: "Политика конфиденциальности",
            footer_terms: "Условия использования",
            footer_copy: "© 2026 IBITI LABS. ЗАЩИЩАЕМ ВАШ ПУТЬ В ON-CHAIN."
        }
    };

    function updateLanguage(lang) {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (translations[lang] && translations[lang][key]) {
                if (key === 'hero_desc' || key.includes('desc')) {
                    el.innerHTML = translations[lang][key];
                } else {
                    el.textContent = translations[lang][key];
                }
            }
        });

        document.querySelectorAll('.lang-btn').forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-lang') === lang);
        });

        localStorage.setItem('drainshield_lang', lang);
        document.documentElement.lang = lang;
    }

    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            updateLanguage(btn.getAttribute('data-lang'));
        });
    });

    const savedLang = localStorage.getItem('drainshield_lang') || 'en';
    if (savedLang !== 'en') {
        updateLanguage(savedLang);
    }
});
