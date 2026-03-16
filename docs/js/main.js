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
});
