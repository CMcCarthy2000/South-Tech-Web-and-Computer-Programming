(function () {
    'use strict';

    const canvasApi = !!document.createElement('canvas').getContext;
    if (!canvasApi) {
        return;
    }

    const textSelector = 'h1, h2, p, li, a, .panel-header, .footer-bar, .title-bar, .main-body';
    let renderFrame = null;

    function safeText(value) {
        if (!value) {
            return '';
        }
        return String(value).replace(/\s+/g, ' ').trim();
    }

    function getTextColor(element) {
        if (element.closest('.title-bar, .footer-bar, .panel-header')) {
            return '#FFFFFF';
        }
        if (element.matches('h2')) {
            return '#800000';
        }
        if (element.matches('a')) {
            return '#0000FF';
        }
        return '#000000';
    }

    function lineWrap(ctx, text, maxWidth) {
        if (!text) {
            return [''];
        }

        const words = text.split(' ');
        const lines = [];
        let current = '';

        for (let i = 0; i < words.length; i += 1) {
            const candidate = current ? current + ' ' + words[i] : words[i];
            if (ctx.measureText(candidate).width <= maxWidth || current.length === 0) {
                current = candidate;
            } else {
                lines.push(current);
                current = words[i];
            }
        }

        if (current) {
            lines.push(current);
        }

        return lines.length > 0 ? lines : [''];
    }

    function renderCanvasText(element, canvas) {
        try {
            const style = window.getComputedStyle(element);
            const text = safeText(element.textContent);
            if (!text) {
                return;
            }

            const width = Math.max(60, Math.round(element.offsetWidth || element.clientWidth || 100));
            const height = Math.max(18, Math.round(element.offsetHeight || element.clientHeight || 24));

            const baseFontSize = Math.max(10, parseFloat(style.fontSize) || 11);
            const fontFamily = style.fontFamily || 'Courier New, monospace';
            const fontWeight = style.fontWeight || '400';
            const fillColor = getTextColor(element);

            canvas.width = Math.max(80, Math.round(width * 1.7));
            canvas.height = Math.max(24, Math.round(height * 1.7));

            const ctx = canvas.getContext('2d');
            if (!ctx) {
                return;
            }

            const lowCanvas = document.createElement('canvas');
            lowCanvas.width = Math.max(40, Math.round(canvas.width / 2));
            lowCanvas.height = Math.max(20, Math.round(canvas.height / 2));
            const lowCtx = lowCanvas.getContext('2d');

            if (!lowCtx) {
                return;
            }

            lowCtx.imageSmoothingEnabled = false;
            lowCtx.clearRect(0, 0, lowCanvas.width, lowCanvas.height);
            lowCtx.textBaseline = 'top';
            lowCtx.textAlign = 'left';
            lowCtx.font = fontWeight + ' ' + Math.max(10, baseFontSize) + 'px ' + fontFamily;
            lowCtx.fillStyle = fillColor;

            const lines = lineWrap(lowCtx, text, lowCanvas.width - 14);
            const lineHeight = Math.max(12, baseFontSize + 2);
            const totalHeight = lines.length * lineHeight;
            const extraTop = Math.max(2, Math.round((lowCanvas.height - totalHeight) / 2));

            lines.forEach(function (line, lineIndex) {
                lowCtx.fillText(line, 6, extraTop + lineIndex * lineHeight);
            });

            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.imageSmoothingEnabled = false;
            ctx.drawImage(lowCanvas, 0, 0, canvas.width, canvas.height);
        } catch (error) {
            // Fail silently so the original page remains readable.
        }
    }

    function buildRetroText(element) {
        if (!element || !element.isConnected || element.dataset.retroReady === 'true') {
            return;
        }

        const text = safeText(element.textContent);
        if (!text || element.closest('script, style, noscript, svg')) {
            return;
        }

        const existingCanvas = element.querySelector('.retro-text-canvas');
        const canvas = existingCanvas || document.createElement('canvas');

        if (!existingCanvas) {
            canvas.className = 'retro-text-canvas';
            canvas.setAttribute('aria-hidden', 'true');
            element.classList.add('retro-text-target');
            element.style.position = 'relative';
            element.style.color = 'transparent';
            element.style.textShadow = 'none';
            element.style.overflow = 'hidden';
            element.textContent = '';
            element.appendChild(canvas);
        }

        element.dataset.retroReady = 'true';
        renderCanvasText(element, canvas);
    }

    function refreshRetroText() {
        const elements = Array.from(document.querySelectorAll(textSelector));

        elements.forEach(function (element) {
            const text = safeText(element.textContent);
            if (!text) {
                return;
            }

            if (!element.dataset.retroReady) {
                buildRetroText(element);
                return;
            }

            const canvas = element.querySelector('.retro-text-canvas');
            if (canvas) {
                renderCanvasText(element, canvas);
            }
        });
    }

    function scheduleRefresh() {
        if (renderFrame) {
            cancelAnimationFrame(renderFrame);
        }
        renderFrame = requestAnimationFrame(function () {
            refreshRetroText();
            renderFrame = null;
        });
    }

    function initialize() {
        scheduleRefresh();

        if ('ResizeObserver' in window) {
            try {
                const resizeObserver = new ResizeObserver(function () {
                    scheduleRefresh();
                });
                resizeObserver.observe(document.body);
            } catch (error) {
                // Ignore unsupported resize behavior.
            }
        }

        window.addEventListener('resize', scheduleRefresh, { passive: true });

        try {
            const observer = new MutationObserver(function () {
                scheduleRefresh();
            });
            observer.observe(document.body, {
                childList: true,
                subtree: true,
                attributes: true,
                characterData: true
            });
        } catch (error) {
            // Ignore unsupported mutation observers.
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize, { once: true });
    } else {
        initialize();
    }
})();
