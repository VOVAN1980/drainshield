document.addEventListener('DOMContentLoaded', () => {
    gsap.registerPlugin(ScrollTrigger);

    // --- HD Smooth Background ---
    const mesh = document.querySelector('.mesh-gradient');
    const ambient = document.querySelector('.ambient-scene');

    // Smooth Mesh Aurora
    window.addEventListener('mousemove', (e) => {
        if (mesh) {
            const dx = (e.clientX - window.innerWidth / 2) / (window.innerWidth / 2);
            const dy = (e.clientY - window.innerHeight / 2) / (window.innerHeight / 2);
            gsap.to(mesh, {
                rotate: 20 * dx,
                x: dx * 30,
                y: dy * 30,
                duration: 2.5,
                ease: 'sine.out'
            });
        }
    });

    // --- Strict Pair Parallax ---
    // Target the CONTAINER only to move the pair together (NO internal collision)
    const isMobile = window.innerWidth < 1024;

    if (!isMobile) {
        window.addEventListener('mousemove', (e) => {
            const cx = window.innerWidth / 2;
            const cy = window.innerHeight / 2;
            const dx = (e.clientX - cx) / cx;
            const dy = (e.clientY - cy) / cy;

            document.querySelectorAll('.visual-scene[data-depth]').forEach(container => {
                const depth = parseFloat(container.getAttribute('data-depth')) || 0.1;
                gsap.to(container, {
                    x: dx * depth * 60,
                    y: dy * depth * 60,
                    duration: 2,
                    ease: 'power1.out',
                    overwrite: 'auto'
                });
            });
        });
    }

    // --- Smooth Reveals ---
    document.querySelectorAll('.reveal').forEach(el => {
        gsap.from(el, {
            scrollTrigger: {
                trigger: el,
                start: 'top 85%',
                toggleActions: 'play none none reverse'
            },
            y: 30,
            opacity: 0,
            duration: 1.2,
            ease: 'power2.out'
        });
    });

    // Mockup Static Glow (No pulse to keep it clean)
    document.querySelectorAll('.phone-mockup').forEach(phone => {
        phone.style.boxShadow = '0 50px 100px rgba(0, 240, 255, 0.15)';
    });
});
