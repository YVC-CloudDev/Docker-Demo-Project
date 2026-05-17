/* ═══════════════════════════════════════════════════════════
   CloudShip — Interactive Features
   Particles background, terminal animation, and live stats
   ═══════════════════════════════════════════════════════════ */

// ── Particle Background ─────────────────────────────────────
(function initParticles() {
    const canvas = document.getElementById('particles');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    let particles = [];
    let animationId;

    function resize() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }

    function createParticles() {
        particles = [];
        const count = Math.floor((canvas.width * canvas.height) / 15000);
        for (let i = 0; i < count; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                vx: (Math.random() - 0.5) * 0.3,
                vy: (Math.random() - 0.5) * 0.3,
                size: Math.random() * 1.5 + 0.5,
                opacity: Math.random() * 0.5 + 0.1,
            });
        }
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        for (let i = 0; i < particles.length; i++) {
            const p = particles[i];
            p.x += p.vx;
            p.y += p.vy;

            if (p.x < 0) p.x = canvas.width;
            if (p.x > canvas.width) p.x = 0;
            if (p.y < 0) p.y = canvas.height;
            if (p.y > canvas.height) p.y = 0;

            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(6, 182, 212, ${p.opacity})`;
            ctx.fill();

            // Draw connections
            for (let j = i + 1; j < particles.length; j++) {
                const p2 = particles[j];
                const dx = p.x - p2.x;
                const dy = p.y - p2.y;
                const dist = Math.sqrt(dx * dx + dy * dy);
                if (dist < 120) {
                    ctx.beginPath();
                    ctx.moveTo(p.x, p.y);
                    ctx.lineTo(p2.x, p2.y);
                    ctx.strokeStyle = `rgba(6, 182, 212, ${0.08 * (1 - dist / 120)})`;
                    ctx.lineWidth = 0.5;
                    ctx.stroke();
                }
            }
        }

        animationId = requestAnimationFrame(draw);
    }

    resize();
    createParticles();
    draw();

    window.addEventListener('resize', () => {
        resize();
        createParticles();
    });
})();


// ── Terminal Typing Animation ────────────────────────────────
(function initTerminal() {
    const commands = [
        { cmd: 'docker build -t cloudship .', delay: 60 },
        { out: 'Building image... ✓', cls: 'success' },
        { cmd: 'docker push ecr/cloudship:v2', delay: 50 },
        { out: 'Pushing to ECR... ✓', cls: 'success' },
        { cmd: 'aws ecs update-service --force', delay: 45 },
        { out: 'Deploying to ECS...', cls: 'output' },
        { out: '✓ Service updated. New task running!', cls: 'success' },
        { cmd: 'curl http://cloudship.aws', delay: 55 },
        { out: '200 OK — App is live! 🚀', cls: 'success' },
    ];

    const terminalBody = document.querySelector('.terminal-body');
    const typingEl = document.getElementById('typing');
    const cursorEl = document.querySelector('.cursor');
    if (!terminalBody || !typingEl) return;

    let cmdIndex = 0;

    async function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function typeCommand(text, charDelay) {
        typingEl.textContent = '';
        cursorEl.style.display = 'inline';
        for (let i = 0; i < text.length; i++) {
            typingEl.textContent += text[i];
            await sleep(charDelay);
        }
        await sleep(400);
        cursorEl.style.display = 'none';
    }

    function addOutputLine(text, cls) {
        const line = document.createElement('div');
        line.className = 'line ' + (cls || '');
        line.textContent = text;
        terminalBody.insertBefore(line, terminalBody.lastElementChild);
    }

    function addCommandLine(text) {
        const line = document.createElement('div');
        line.className = 'line';
        line.innerHTML = `<span class="prompt">$</span> ${text}`;
        terminalBody.insertBefore(line, terminalBody.lastElementChild);
    }

    async function runSequence() {
        while (true) {
            for (const entry of commands) {
                if (entry.cmd) {
                    await typeCommand(entry.cmd, entry.delay);
                    addCommandLine(entry.cmd);
                    typingEl.textContent = '';
                    await sleep(300);
                } else if (entry.out) {
                    addOutputLine(entry.out, entry.cls);
                    await sleep(600);
                }
            }

            await sleep(3000);

            // Clear and restart
            const lines = terminalBody.querySelectorAll('.line:not(:last-child)');
            lines.forEach(l => l.remove());
            typingEl.textContent = '';
            cursorEl.style.display = 'inline';
            await sleep(1000);
        }
    }

    runSequence();
})();


// ── Live Status / Uptime Counter ─────────────────────────────
(function initStatus() {
    const startTime = Date.now();
    const containerId = 'ctn-' + Math.random().toString(36).substring(2, 10);
    const deployDate = new Date().toLocaleString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric',
        hour: '2-digit', minute: '2-digit'
    });

    const containerEl = document.getElementById('container-id');
    const uptimeEl = document.getElementById('uptime');
    const deployEl = document.getElementById('deploy-time');

    if (containerEl) containerEl.textContent = containerId;
    if (deployEl) deployEl.textContent = deployDate;

    function updateUptime() {
        const elapsed = Math.floor((Date.now() - startTime) / 1000);
        const h = Math.floor(elapsed / 3600);
        const m = Math.floor((elapsed % 3600) / 60);
        const s = elapsed % 60;
        if (uptimeEl) {
            uptimeEl.textContent = h > 0
                ? `${h}h ${m}m ${s}s`
                : m > 0
                    ? `${m}m ${s}s`
                    : `${s}s`;
        }
    }

    setInterval(updateUptime, 1000);
    updateUptime();
})();


// ── Pipeline Step Animation on Scroll ────────────────────────
(function initPipelineAnimation() {
    const steps = document.querySelectorAll('.pipeline-step');
    if (!steps.length) return;

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const allSteps = document.querySelectorAll('.pipeline-step');
                allSteps.forEach((step, i) => {
                    setTimeout(() => {
                        step.style.opacity = '1';
                        step.style.transform = 'translateY(0)';
                    }, i * 150);
                });
                observer.disconnect();
            }
        });
    }, { threshold: 0.3 });

    steps.forEach(step => {
        step.style.opacity = '0';
        step.style.transform = 'translateY(20px)';
        step.style.transition = 'all 0.5s ease';
    });

    observer.observe(steps[0]);
})();


// ── Smooth scroll for nav links ──────────────────────────────
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});
