/**
 * Live Reload WebSocket Client
 * Include this script in your HTML pages to enable live reload functionality
 * when using the beans CLI development server.
 */

(function () {
    'use strict';

    // Configuration
    const WS_URL = 'ws://localhost:8081';
    const RECONNECT_DELAY = 1000;

    Window.lob_ws = Window.lob_ws || null;
    let reconnectTimer = null;

    // Create connection status indicator
    function createStatusIndicator() {
        const indicator = document.createElement('div');
        indicator.id = 'live-reload-status';
        indicator.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background-color: #dc3545;
            z-index: 9999;
            transition: background-color 0.3s ease;
        `;
        if (document.body !== null) {
            document.body.appendChild(indicator);
        }
        return indicator;
    }

    // Update connection status
    function updateStatus(connected) {
        const indicator = document.getElementById('live-reload-status');
        if (indicator) {
            indicator.style.backgroundColor = connected ? '#28a745' : '#dc3545';
        }
    }

    // Reload stylesheets to force CSS refresh
    function reloadStylesheets() {
        document.querySelectorAll('link[rel="stylesheet"]').forEach(link => {
            try {
                const url = new URL(link.href);
                url.searchParams.set('v', Date.now());
                link.href = url.toString();
            } catch (e) {
                console.error('Failed to reload stylesheet:', link.href, e);
            }
        });
    }

    // Connect to WebSocket server
    function connect() {
        if (Window.lob_ws && Window.lob_ws.readyState === WebSocket.OPEN) {
            updateStatus(true);
            return;
        }

        try {
            Window.lob_ws = Window.lob_ws || new WebSocket(WS_URL);
            if (Window.lob_ws.readyState == 3) {
                Window.lob_ws = new WebSocket(WS_URL);
            }

            Window.lob_ws.onopen = function () {
                updateStatus(true);
            };

            Window.lob_ws.onmessage = async function (event) {
                try {
                    const data = JSON.parse(event.data);
                    if (data.type === 'file_changed') {
                        // Reload page for relevant file changes
                        if (shouldReload(data.path)) {
                            setTimeout(async () => {
                                const isCSS = data.path.toLowerCase().endsWith('.css');
                                if (isCSS) {
                                    // For CSS changes, just reload stylesheets without touching body
                                    reloadStylesheets();
                                } else {
                                    // For other changes, fetch and replace body content
                                    const newPage = await fetch(window.location.href, {
                                        headers: { "X-Requested-With": "fetch-update" }
                                    });
                                    const html = await newPage.text();

                                    // Parse and replace <body> content safely
                                    const parser = new DOMParser();
                                    const doc = parser.parseFromString(html, "text/html");
                                    document.body.innerHTML = doc.body.innerHTML;

                                    // Optionally re-run scripts if needed
                                    const scripts = document.body.querySelectorAll("script");
                                    scripts.forEach(oldScript => {
                                        const newScript = document.createElement("script");
                                        if (oldScript.src) {
                                            newScript.src = oldScript.src;
                                        } else {
                                            newScript.textContent = oldScript.textContent;
                                        }
                                        // Remove the old script node before appending new to avoid duplicates
                                        oldScript.parentNode.removeChild(oldScript);
                                        document.body.appendChild(newScript);
                                    });
                                }
                                // Run any script here
                                try { hljs.highlightAll(); } catch (e) { console.log(e); }
                            }, 1);
                        }
                    }
                } catch (e) {
                    console.log('Received:', event.data);
                }
            };

            Window.lob_ws.onclose = function () {
                updateStatus(false);
                scheduleReconnect();
            };

            Window.lob_ws.onerror = function (error) {
                updateStatus(false);
                scheduleReconnect();
            };

        } catch (error) {
            scheduleReconnect();
        }
    }

    // Determine if page should reload for this file change
    function shouldReload(filePath) {
        const reloadExtensions = ['.html', '.css', '.js', '.lua', '.etlua'];
        const reloadPaths = ['/'];

        // Check file extension
        const hasReloadExtension = reloadExtensions.some(ext =>
            filePath.toLowerCase().endsWith(ext)
        );

        // Check if file is in a reload-worthy directory
        const isInReloadPath = reloadPaths.some(path =>
            filePath.includes(path)
        );

        return hasReloadExtension || isInReloadPath;
    }

    // Schedule reconnection attempt
    function scheduleReconnect() {
        if (reconnectTimer) {
            clearTimeout(reconnectTimer);
        }

        reconnectTimer = setTimeout(() => {
            connect();
        }, RECONNECT_DELAY);
    }

    // Initialize live reload
    function init() {
        // Only run in development mode (when localhost)
        if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
            createStatusIndicator();
            connect();
        }
    }

    // Start when DOM is ready
    init();
})();
