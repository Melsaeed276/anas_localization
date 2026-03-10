library;

import 'dart:convert';

String buildCatalogHtml({required String apiUrl}) {
  return _catalogUiTemplate.replaceFirst('__API_URL__', jsonEncode(apiUrl));
}

const String _catalogUiTemplate = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Anas Localization Catalog</title>
  <script>
    (function() {
      const themeStorageKey = 'anasCatalog.themeMode';
      const displayLanguageStorageKey = 'anasCatalog.displayLanguage';
      let themeMode = 'system';
      let displayLanguage = 'en';

      function normalizeDisplayLanguage(value) {
        const normalized = String(value || '').trim().toLowerCase();
        if (!normalized) return '';
        if (normalized === 'zh-cn' || normalized.startsWith('zh-') || normalized === 'zh') {
          return 'zh-CN';
        }
        if (normalized === 'en' || normalized.startsWith('en-')) return 'en';
        if (normalized === 'ar' || normalized.startsWith('ar-')) return 'ar';
        if (normalized === 'tr' || normalized.startsWith('tr-')) return 'tr';
        if (normalized === 'es' || normalized.startsWith('es-')) return 'es';
        if (normalized === 'hi' || normalized.startsWith('hi-')) return 'hi';
        return '';
      }

      try {
        const stored = window.localStorage.getItem(themeStorageKey);
        if (stored === 'light' || stored === 'dark' || stored === 'system') {
          themeMode = stored;
        }
      } catch (_) {}

      try {
        const storedDisplayLanguage = normalizeDisplayLanguage(window.localStorage.getItem(displayLanguageStorageKey));
        if (storedDisplayLanguage) {
          displayLanguage = storedDisplayLanguage;
        } else {
          const browserLocales = [];
          if (Array.isArray(window.navigator.languages)) {
            browserLocales.push(...window.navigator.languages);
          }
          if (window.navigator.language) {
            browserLocales.push(window.navigator.language);
          }
          for (const locale of browserLocales) {
            const normalized = normalizeDisplayLanguage(locale);
            if (normalized) {
              displayLanguage = normalized;
              break;
            }
          }
        }
      } catch (_) {}

      document.documentElement.setAttribute('data-theme', themeMode);
      document.documentElement.setAttribute('lang', displayLanguage);
      document.documentElement.setAttribute('dir', displayLanguage === 'ar' ? 'rtl' : 'ltr');
    })();
  </script>
  <style>
    :root {
      color-scheme: light;
      --bg: #eef4ff;
      --panel: rgba(255, 255, 255, 0.9);
      --panel-soft: rgba(232, 240, 252, 0.9);
      --panel-muted: rgba(222, 232, 247, 0.84);
      --border: rgba(63, 91, 126, 0.16);
      --border-strong: rgba(63, 91, 126, 0.28);
      --text: #122033;
      --text-muted: #56677f;
      --text-soft: #34465c;
      --accent: #2f74e4;
      --accent-strong: #1859c1;
      --green-bg: rgba(37, 184, 112, 0.14);
      --green-border: rgba(37, 184, 112, 0.34);
      --green-text: #0e6d40;
      --warning-bg: rgba(230, 173, 56, 0.16);
      --warning-border: rgba(230, 173, 56, 0.34);
      --warning-text: #7b5600;
      --red-bg: rgba(223, 87, 87, 0.14);
      --red-border: rgba(223, 87, 87, 0.32);
      --red-text: #8f2730;
      --shadow: 0 22px 56px rgba(15, 31, 54, 0.12);
      --radius: 18px;
      --radius-sm: 12px;
      --input-bg: rgba(248, 251, 255, 0.94);
      --chrome-bg: rgba(239, 245, 255, 0.88);
      --pill-bg: rgba(226, 235, 249, 0.92);
      --placeholder: #70809a;
      --focus-border: rgba(47, 116, 228, 0.72);
      --focus-ring: rgba(47, 116, 228, 0.12);
      --button-bg: rgba(228, 237, 249, 0.92);
      --button-subtle-bg: rgba(220, 231, 246, 0.92);
      --button-danger-bg: rgba(255, 230, 232, 0.95);
      --button-danger-border: rgba(223, 87, 87, 0.28);
      --button-danger-text: #8f2730;
      --button-on-accent: #f7fbff;
      --filter-bg: rgba(226, 235, 249, 0.94);
      --filter-active-bg: rgba(47, 116, 228, 0.14);
      --filter-active-border: rgba(47, 116, 228, 0.32);
      --count-bg: rgba(228, 237, 249, 0.92);
      --selected-row-bg: rgba(216, 229, 248, 0.98);
      --selected-row-border: rgba(47, 116, 228, 0.42);
      --selected-row-outline: rgba(47, 116, 228, 0.12);
      --sync-bg: rgba(228, 237, 249, 0.92);
      --sync-warning-border: rgba(230, 173, 56, 0.28);
      --sync-red-border: rgba(223, 87, 87, 0.28);
      --sync-green-border: rgba(37, 184, 112, 0.28);
      --tab-bg: rgba(228, 237, 249, 0.92);
      --tab-active-bg: rgba(47, 116, 228, 0.12);
      --tab-active-border: rgba(47, 116, 228, 0.34);
      --source-card-bg: linear-gradient(180deg, rgba(233, 242, 255, 0.96), rgba(218, 230, 247, 0.98));
      --source-preview-bg: rgba(247, 250, 255, 0.96);
      --reason-bg: rgba(228, 237, 249, 0.9);
      --warning-card-bg: rgba(255, 241, 212, 0.84);
      --warning-card-border: rgba(230, 173, 56, 0.24);
      --advanced-bg: rgba(232, 240, 252, 0.92);
      --danger-link: #b13944;
      --inline-error: #b13944;
      --error-bg: rgba(255, 236, 238, 0.96);
      --error-border: rgba(223, 87, 87, 0.28);
      --error-text: #8f2730;
      --skeleton-bg: rgba(224, 234, 247, 0.95);
      --skeleton-highlight: rgba(255, 255, 255, 0.45);
      --toast-bg: rgba(247, 250, 255, 0.98);
      --toast-error-border: rgba(223, 87, 87, 0.28);
      --dialog-bg: rgba(246, 250, 255, 0.98);
      --backdrop-bg: rgba(138, 156, 181, 0.3);
      --surface-gradient:
        radial-gradient(circle at top left, rgba(47, 116, 228, 0.16), transparent 36%),
        radial-gradient(circle at top right, rgba(21, 152, 136, 0.12), transparent 28%),
        linear-gradient(180deg, rgba(245, 249, 255, 1), rgba(232, 240, 252, 1));
      --font-sans: "Avenir Next", "Segoe UI", sans-serif;
      --font-mono: "SF Mono", "Menlo", monospace;
    }

    :root[data-theme="dark"] {
      color-scheme: dark;
      --bg: #07111f;
      --panel: rgba(8, 21, 39, 0.92);
      --panel-soft: rgba(10, 27, 48, 0.78);
      --panel-muted: rgba(11, 32, 57, 0.62);
      --border: rgba(132, 167, 214, 0.16);
      --border-strong: rgba(132, 167, 214, 0.26);
      --text: #edf3ff;
      --text-muted: #8ea6c7;
      --text-soft: #a8bdd7;
      --accent: #68a9ff;
      --accent-strong: #3278e5;
      --green-bg: rgba(37, 184, 112, 0.16);
      --green-border: rgba(37, 184, 112, 0.44);
      --green-text: #9cf0c4;
      --warning-bg: rgba(230, 173, 56, 0.18);
      --warning-border: rgba(230, 173, 56, 0.42);
      --warning-text: #ffe19a;
      --red-bg: rgba(223, 87, 87, 0.18);
      --red-border: rgba(223, 87, 87, 0.42);
      --red-text: #ffb3b3;
      --shadow: 0 22px 56px rgba(0, 0, 0, 0.34);
      --input-bg: rgba(3, 13, 24, 0.84);
      --chrome-bg: rgba(5, 14, 27, 0.88);
      --pill-bg: rgba(13, 30, 52, 0.82);
      --placeholder: #7086a7;
      --focus-border: rgba(104, 169, 255, 0.72);
      --focus-ring: rgba(104, 169, 255, 0.12);
      --button-bg: rgba(12, 28, 49, 0.78);
      --button-subtle-bg: rgba(15, 35, 61, 0.7);
      --button-danger-bg: rgba(91, 25, 29, 0.54);
      --button-danger-border: rgba(223, 87, 87, 0.34);
      --button-danger-text: #ffd7d7;
      --button-on-accent: #02111f;
      --filter-bg: rgba(10, 23, 42, 0.78);
      --filter-active-bg: rgba(104, 169, 255, 0.18);
      --filter-active-border: rgba(104, 169, 255, 0.42);
      --count-bg: rgba(10, 24, 43, 0.84);
      --selected-row-bg: rgba(15, 35, 61, 0.92);
      --selected-row-border: rgba(104, 169, 255, 0.48);
      --selected-row-outline: rgba(104, 169, 255, 0.16);
      --sync-bg: rgba(12, 27, 48, 0.82);
      --sync-warning-border: rgba(230, 173, 56, 0.34);
      --sync-red-border: rgba(223, 87, 87, 0.34);
      --sync-green-border: rgba(37, 184, 112, 0.34);
      --tab-bg: rgba(12, 27, 48, 0.84);
      --tab-active-bg: rgba(104, 169, 255, 0.2);
      --tab-active-border: rgba(104, 169, 255, 0.42);
      --source-card-bg: linear-gradient(180deg, rgba(16, 32, 53, 0.88), rgba(10, 21, 39, 0.92));
      --source-preview-bg: rgba(6, 14, 25, 0.76);
      --reason-bg: rgba(10, 24, 43, 0.74);
      --warning-card-bg: rgba(88, 64, 12, 0.24);
      --warning-card-border: rgba(230, 173, 56, 0.28);
      --advanced-bg: rgba(7, 18, 33, 0.78);
      --danger-link: #ff9d9d;
      --inline-error: #ffb3b3;
      --error-bg: rgba(73, 16, 23, 0.78);
      --error-border: rgba(223, 87, 87, 0.34);
      --error-text: #ffd1d1;
      --skeleton-bg: rgba(14, 28, 46, 0.82);
      --skeleton-highlight: rgba(255, 255, 255, 0.08);
      --toast-bg: rgba(9, 22, 40, 0.94);
      --toast-error-border: rgba(223, 87, 87, 0.34);
      --dialog-bg: rgba(7, 17, 31, 0.98);
      --backdrop-bg: rgba(1, 7, 13, 0.72);
      --surface-gradient:
        radial-gradient(circle at top left, rgba(73, 132, 228, 0.18), transparent 36%),
        radial-gradient(circle at top right, rgba(17, 153, 142, 0.15), transparent 28%),
        linear-gradient(180deg, rgba(8, 18, 33, 0.98), rgba(6, 12, 23, 1));
    }

    @media (prefers-color-scheme: dark) {
      :root[data-theme="system"] {
        color-scheme: dark;
        --bg: #07111f;
        --panel: rgba(8, 21, 39, 0.92);
        --panel-soft: rgba(10, 27, 48, 0.78);
        --panel-muted: rgba(11, 32, 57, 0.62);
        --border: rgba(132, 167, 214, 0.16);
        --border-strong: rgba(132, 167, 214, 0.26);
        --text: #edf3ff;
        --text-muted: #8ea6c7;
        --text-soft: #a8bdd7;
        --accent: #68a9ff;
        --accent-strong: #3278e5;
        --green-bg: rgba(37, 184, 112, 0.16);
        --green-border: rgba(37, 184, 112, 0.44);
        --green-text: #9cf0c4;
        --warning-bg: rgba(230, 173, 56, 0.18);
        --warning-border: rgba(230, 173, 56, 0.42);
        --warning-text: #ffe19a;
        --red-bg: rgba(223, 87, 87, 0.18);
        --red-border: rgba(223, 87, 87, 0.42);
        --red-text: #ffb3b3;
        --shadow: 0 22px 56px rgba(0, 0, 0, 0.34);
        --input-bg: rgba(3, 13, 24, 0.84);
        --chrome-bg: rgba(5, 14, 27, 0.88);
        --pill-bg: rgba(13, 30, 52, 0.82);
        --placeholder: #7086a7;
        --focus-border: rgba(104, 169, 255, 0.72);
        --focus-ring: rgba(104, 169, 255, 0.12);
        --button-bg: rgba(12, 28, 49, 0.78);
        --button-subtle-bg: rgba(15, 35, 61, 0.7);
        --button-danger-bg: rgba(91, 25, 29, 0.54);
        --button-danger-border: rgba(223, 87, 87, 0.34);
        --button-danger-text: #ffd7d7;
        --button-on-accent: #02111f;
        --filter-bg: rgba(10, 23, 42, 0.78);
        --filter-active-bg: rgba(104, 169, 255, 0.18);
        --filter-active-border: rgba(104, 169, 255, 0.42);
        --count-bg: rgba(10, 24, 43, 0.84);
        --selected-row-bg: rgba(15, 35, 61, 0.92);
        --selected-row-border: rgba(104, 169, 255, 0.48);
        --selected-row-outline: rgba(104, 169, 255, 0.16);
        --sync-bg: rgba(12, 27, 48, 0.82);
        --sync-warning-border: rgba(230, 173, 56, 0.34);
        --sync-red-border: rgba(223, 87, 87, 0.34);
        --sync-green-border: rgba(37, 184, 112, 0.34);
        --tab-bg: rgba(12, 27, 48, 0.84);
        --tab-active-bg: rgba(104, 169, 255, 0.2);
        --tab-active-border: rgba(104, 169, 255, 0.42);
        --source-card-bg: linear-gradient(180deg, rgba(16, 32, 53, 0.88), rgba(10, 21, 39, 0.92));
        --source-preview-bg: rgba(6, 14, 25, 0.76);
        --reason-bg: rgba(10, 24, 43, 0.74);
        --warning-card-bg: rgba(88, 64, 12, 0.24);
        --warning-card-border: rgba(230, 173, 56, 0.28);
        --advanced-bg: rgba(7, 18, 33, 0.78);
        --danger-link: #ff9d9d;
        --inline-error: #ffb3b3;
        --error-bg: rgba(73, 16, 23, 0.78);
        --error-border: rgba(223, 87, 87, 0.34);
        --error-text: #ffd1d1;
        --skeleton-bg: rgba(14, 28, 46, 0.82);
        --skeleton-highlight: rgba(255, 255, 255, 0.08);
        --toast-bg: rgba(9, 22, 40, 0.94);
        --toast-error-border: rgba(223, 87, 87, 0.34);
        --dialog-bg: rgba(7, 17, 31, 0.98);
        --backdrop-bg: rgba(1, 7, 13, 0.72);
        --surface-gradient:
          radial-gradient(circle at top left, rgba(73, 132, 228, 0.18), transparent 36%),
          radial-gradient(circle at top right, rgba(17, 153, 142, 0.15), transparent 28%),
          linear-gradient(180deg, rgba(8, 18, 33, 0.98), rgba(6, 12, 23, 1));
      }
    }

    * {
      box-sizing: border-box;
    }

    html,
    body {
      min-height: 100%;
    }

    body {
      margin: 0;
      background: var(--surface-gradient);
      color: var(--text);
      font-family: var(--font-sans);
      line-height: 1.45;
    }

    button,
    input,
    select,
    textarea {
      font: inherit;
    }

    button {
      cursor: pointer;
    }

    button:disabled {
      cursor: not-allowed;
      opacity: 0.62;
    }

    .app-shell {
      min-height: 100vh;
      display: grid;
      grid-template-rows: auto 1fr;
    }

    .topbar {
      position: sticky;
      top: 0;
      z-index: 10;
      backdrop-filter: blur(18px);
      background: var(--chrome-bg);
      border-bottom: 1px solid var(--border);
    }

    .topbar-inner {
      max-width: 1600px;
      margin: 0 auto;
      padding: 1.25rem 1.35rem 1rem;
      display: grid;
      gap: 0.85rem;
    }

    .brand-row {
      display: flex;
      justify-content: space-between;
      gap: 1rem;
      align-items: flex-start;
    }

    .brand-copy h1 {
      margin: 0;
      font-size: clamp(1.4rem, 2.4vw, 2rem);
      letter-spacing: -0.04em;
    }

    .brand-copy p {
      margin: 0.3rem 0 0;
      color: var(--text-muted);
      max-width: 64ch;
    }

    .meta-badges {
      display: flex;
      gap: 0.55rem;
      flex-wrap: wrap;
      align-items: center;
      justify-content: flex-end;
    }

    .pill,
    .status-chip,
    .sync-chip,
    .count-chip {
      display: inline-flex;
      align-items: center;
      gap: 0.35rem;
      border-radius: 999px;
      border: 1px solid var(--border);
      padding: 0.36rem 0.72rem;
      font-size: 0.84rem;
      white-space: nowrap;
    }

    .pill {
      background: var(--pill-bg);
      color: var(--text-soft);
    }

    .meta-badge-button {
      appearance: none;
      background: var(--pill-bg);
      color: var(--text-soft);
    }

    .meta-badge-button:hover {
      border-color: var(--border-strong);
      transform: translateY(-1px);
    }

    .toolbar {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      align-items: center;
      justify-content: space-between;
    }

    .toolbar-left,
    .toolbar-right {
      display: flex;
      flex-wrap: wrap;
      gap: 0.65rem;
      align-items: center;
    }

    .theme-select-shell {
      display: inline-flex;
      align-items: center;
      gap: 0.55rem;
      border-radius: 14px;
      border: 1px solid var(--border);
      background: var(--button-bg);
      color: var(--text-soft);
      padding: 0.2rem 0.35rem 0.2rem 0.7rem;
      min-height: 3rem;
    }

    .theme-select-label {
      font-size: 0.84rem;
      font-weight: 600;
      color: var(--text-soft);
    }

    .theme-select {
      border: 0;
      background: transparent;
      color: var(--text);
      min-width: 7rem;
      outline: none;
      cursor: pointer;
      padding: 0.45rem 1.6rem 0.45rem 0.2rem;
    }

    .search-shell {
      position: relative;
      min-width: min(100%, 20rem);
      flex: 1 1 19rem;
    }

    .search-shell input,
    .modal-input,
    .field-textarea,
    .advanced-json textarea {
      width: 100%;
      border-radius: 14px;
      border: 1px solid var(--border);
      background: var(--input-bg);
      color: var(--text);
      padding: 0.85rem 0.95rem;
      outline: none;
      transition: border-color 140ms ease, box-shadow 140ms ease, transform 140ms ease;
    }

    .search-shell input::placeholder,
    .modal-input::placeholder,
    .field-textarea::placeholder,
    .advanced-json textarea::placeholder {
      color: var(--placeholder);
    }

    .search-shell input:focus,
    .modal-input:focus,
    .field-textarea:focus,
    .advanced-json textarea:focus {
      border-color: var(--focus-border);
      box-shadow: 0 0 0 4px var(--focus-ring);
    }

    .toolbar-button,
    .primary-button,
    .subtle-button,
    .danger-button,
    .mini-button {
      border-radius: 14px;
      border: 1px solid var(--border);
      background: var(--button-bg);
      color: var(--text);
      padding: 0.78rem 0.95rem;
      transition: border-color 140ms ease, background 140ms ease, transform 140ms ease;
    }

    .toolbar-button:hover,
    .primary-button:hover,
    .subtle-button:hover,
    .danger-button:hover,
    .mini-button:hover {
      border-color: var(--border-strong);
      transform: translateY(-1px);
    }

    .primary-button {
      background: linear-gradient(135deg, var(--accent), var(--accent-strong));
      border-color: var(--filter-active-border);
      color: var(--button-on-accent);
      font-weight: 700;
    }

    .subtle-button {
      background: var(--button-subtle-bg);
      color: var(--text-soft);
    }

    .danger-button {
      background: var(--button-danger-bg);
      border-color: var(--button-danger-border);
      color: var(--button-danger-text);
    }

    .mini-button {
      padding: 0.44rem 0.64rem;
      border-radius: 999px;
      font-size: 0.78rem;
      color: var(--text-soft);
    }

    .filter-strip {
      display: flex;
      flex-wrap: wrap;
      gap: 0.48rem;
      align-items: center;
    }

    .filter-button {
      border-radius: 999px;
      border: 1px solid var(--border);
      background: var(--filter-bg);
      color: var(--text-soft);
      padding: 0.46rem 0.8rem;
      font-size: 0.83rem;
    }

    .filter-button[aria-pressed="true"] {
      background: var(--filter-active-bg);
      color: var(--text);
      border-color: var(--filter-active-border);
    }

    .topbar-footer {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      gap: 0.7rem;
      align-items: center;
      color: var(--text-muted);
      font-size: 0.9rem;
    }

    .inline-counts {
      display: flex;
      gap: 0.45rem;
      flex-wrap: wrap;
    }

    .count-chip {
      background: var(--count-bg);
      color: var(--text-muted);
    }

    .workspace {
      width: min(1600px, 100%);
      margin: 0 auto;
      padding: 1.1rem 1.35rem 1.35rem;
      display: grid;
      gap: 1rem;
      grid-template-columns: minmax(280px, 350px) minmax(0, 1fr);
      align-items: start;
    }

    .panel {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
    }

    .list-shell,
    .editor-shell {
      min-width: 0;
    }

    .list-shell {
      position: sticky;
      top: 10.5rem;
      overflow: hidden;
    }

    .list-header {
      padding: 1rem 1rem 0.75rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.8rem;
      border-bottom: 1px solid var(--border);
    }

    .list-header h2,
    .editor-header h2,
    .section-title {
      margin: 0;
      font-size: 1rem;
      letter-spacing: -0.02em;
    }

    .list-header p,
    .editor-subtle,
    .helper-text,
    .muted-copy,
    .status-note,
    .source-summary p,
    .empty-state p {
      margin: 0;
      color: var(--text-muted);
      font-size: 0.9rem;
    }

    .key-list {
      max-height: calc(100vh - 13rem);
      overflow: auto;
      padding: 0.75rem;
      display: grid;
      gap: 0.65rem;
    }

    .row-button {
      width: 100%;
      text-align: left;
      border-radius: 16px;
      border: 1px solid transparent;
      background: var(--panel-soft);
      color: var(--text);
      padding: 0.9rem 0.95rem;
      display: grid;
      gap: 0.55rem;
      transition: border-color 140ms ease, transform 140ms ease, background 140ms ease;
    }

    .row-button:hover {
      border-color: var(--border-strong);
      transform: translateY(-1px);
    }

    .row-button.is-selected {
      border-color: var(--selected-row-border);
      background: var(--selected-row-bg);
      box-shadow: inset 0 0 0 1px var(--selected-row-outline);
    }

    .row-key {
      font-family: var(--font-mono);
      font-size: 0.9rem;
      word-break: break-word;
      direction: ltr;
      unicode-bidi: plaintext;
    }

    .row-topline,
    .row-meta,
    .editor-topline,
    .editor-actions,
    .status-bar,
    .editor-footer,
    .detail-grid,
    .add-actions,
    .branch-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 0.55rem;
      align-items: center;
      justify-content: space-between;
    }

    .row-meta {
      gap: 0.45rem;
      justify-content: flex-start;
    }

    .status-chip {
      font-weight: 600;
      letter-spacing: 0.01em;
      text-transform: capitalize;
    }

    .status-green,
    .status-chip.status-green {
      background: var(--green-bg);
      color: var(--green-text);
      border-color: var(--green-border);
    }

    .status-warning,
    .status-chip.status-warning {
      background: var(--warning-bg);
      color: var(--warning-text);
      border-color: var(--warning-border);
    }

    .status-red,
    .status-chip.status-red {
      background: var(--red-bg);
      color: var(--red-text);
      border-color: var(--red-border);
    }

    .sync-chip {
      background: var(--sync-bg);
      color: var(--text-soft);
    }

    .sync-chip.sync-dirty,
    .sync-chip.sync-saving,
    .sync-chip.sync-save_error {
      border-color: var(--sync-warning-border);
      color: var(--warning-text);
    }

    .sync-chip.sync-save_error {
      border-color: var(--sync-red-border);
      color: var(--red-text);
    }

    .sync-chip.sync-saved {
      border-color: var(--sync-green-border);
      color: var(--green-text);
    }

    .editor-shell {
      display: grid;
      gap: 1rem;
    }

    .editor-card,
    .source-card,
    .pane-card,
    .empty-state,
    .error-banner {
      padding: 1rem 1.05rem;
      border-radius: var(--radius);
      border: 1px solid var(--border);
      background: var(--panel);
      box-shadow: var(--shadow);
    }

    .editor-card {
      display: grid;
      gap: 0.95rem;
    }

    .editor-header {
      display: grid;
      gap: 0.75rem;
    }

    .editor-keyline {
      display: flex;
      justify-content: space-between;
      gap: 0.8rem;
      align-items: flex-start;
      flex-wrap: wrap;
    }

    .editor-key {
      margin: 0.25rem 0 0;
      font-family: var(--font-mono);
      font-size: 1rem;
      word-break: break-word;
      direction: ltr;
      unicode-bidi: plaintext;
    }

    .locale-tabs {
      display: flex;
      flex-wrap: wrap;
      gap: 0.55rem;
    }

    .tab-button {
      border-radius: 999px;
      border: 1px solid var(--border);
      background: var(--tab-bg);
      color: var(--text-soft);
      padding: 0.48rem 0.82rem;
      font-size: 0.86rem;
    }

    .tab-button.is-active {
      background: var(--tab-active-bg);
      color: var(--text);
      border-color: var(--tab-active-border);
    }

    .source-card {
      background: var(--source-card-bg);
      display: grid;
      gap: 0.8rem;
    }

    .eyebrow {
      font-size: 0.76rem;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--text-muted);
      margin: 0;
    }

    .source-preview,
    .source-branch-preview {
      border-radius: 14px;
      border: 1px solid var(--border);
      background: var(--source-preview-bg);
      padding: 0.78rem 0.88rem;
      color: var(--text-soft);
      min-height: 3rem;
      white-space: pre-wrap;
      word-break: break-word;
    }

    .pane-card {
      display: grid;
      gap: 0.95rem;
    }

    .section-heading {
      display: grid;
      gap: 0.3rem;
    }

    .reason-card,
    .warning-card {
      border-radius: 14px;
      padding: 0.8rem 0.88rem;
      border: 1px solid var(--border);
      background: var(--reason-bg);
      display: grid;
      gap: 0.3rem;
    }

    .warning-card {
      background: var(--warning-card-bg);
      border-color: var(--warning-card-border);
      color: var(--warning-text);
    }

    .field-stack {
      display: grid;
      gap: 0.95rem;
    }

    .branch-card {
      display: grid;
      gap: 0.55rem;
      border-radius: 16px;
      border: 1px solid var(--border);
      background: var(--panel-muted);
      padding: 0.85rem;
    }

    .branch-label {
      display: flex;
      justify-content: space-between;
      gap: 0.5rem;
      align-items: center;
      flex-wrap: wrap;
      font-size: 0.86rem;
      color: var(--text-soft);
    }

    .branch-label strong {
      color: var(--text);
      font-weight: 600;
      text-transform: capitalize;
    }

    .field-textarea,
    .advanced-json textarea {
      min-height: 7.8rem;
      resize: vertical;
    }

    .field-textarea[data-editor-size="compact"] {
      min-height: 5.4rem;
    }

    .branch-grid {
      align-items: stretch;
    }

    .branch-grid > * {
      flex: 1 1 16rem;
      min-width: min(100%, 16rem);
    }

    .advanced-json {
      border-radius: 16px;
      border: 1px solid var(--border);
      background: var(--advanced-bg);
      overflow: hidden;
    }

    .advanced-json summary {
      cursor: pointer;
      list-style: none;
      padding: 0.92rem 0.95rem;
      font-weight: 600;
      color: var(--text-soft);
      display: flex;
      justify-content: space-between;
      gap: 0.7rem;
    }

    .advanced-json summary::-webkit-details-marker {
      display: none;
    }

    .advanced-json-body {
      padding: 0 0.95rem 0.95rem;
      display: grid;
      gap: 0.7rem;
    }

    .mono-note {
      font-family: var(--font-mono);
      font-size: 0.83rem;
      direction: ltr;
      unicode-bidi: plaintext;
    }

    .danger-link {
      padding: 0;
      border: none;
      background: transparent;
      color: var(--danger-link);
      text-decoration: underline;
      text-underline-offset: 0.18rem;
    }

    .inline-error {
      color: var(--inline-error);
      font-size: 0.88rem;
    }

    .empty-state,
    .error-banner {
      display: grid;
      gap: 0.7rem;
    }

    .error-banner {
      background: var(--error-bg);
      border-color: var(--error-border);
      color: var(--error-text);
    }

    .empty-state strong,
    .error-banner strong {
      font-size: 1rem;
    }

    .skeleton {
      position: relative;
      overflow: hidden;
      min-height: 4.4rem;
      border-radius: 16px;
      background: var(--skeleton-bg);
    }

    .skeleton::after {
      content: "";
      position: absolute;
      inset: 0;
      transform: translateX(-100%);
      background: linear-gradient(90deg, transparent, var(--skeleton-highlight), transparent);
      animation: shimmer 1.15s infinite;
    }

    @keyframes shimmer {
      100% {
        transform: translateX(100%);
      }
    }

    .toast-host {
      position: fixed;
      right: 1rem;
      bottom: 1rem;
      display: grid;
      gap: 0.55rem;
      z-index: 20;
      max-width: min(92vw, 24rem);
    }

    .toast {
      padding: 0.85rem 0.95rem;
      border-radius: 16px;
      border: 1px solid var(--border);
      background: var(--toast-bg);
      box-shadow: var(--shadow);
    }

    .toast.toast-error {
      border-color: var(--toast-error-border);
      color: var(--error-text);
    }

    .sr-only {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border: 0;
    }

    dialog {
      width: min(38rem, calc(100vw - 2rem));
      border: 1px solid var(--border);
      border-radius: 22px;
      padding: 0;
      background: var(--dialog-bg);
      color: var(--text);
      box-shadow: var(--shadow);
    }

    dialog::backdrop {
      background: var(--backdrop-bg);
      backdrop-filter: blur(3px);
    }

    .modal-shell {
      padding: 1rem;
      display: grid;
      gap: 0.95rem;
    }

    .modal-grid {
      display: grid;
      gap: 0.8rem;
    }

    .modal-locale-grid {
      display: grid;
      gap: 0.75rem;
    }

    .modal-field {
      display: grid;
      gap: 0.4rem;
    }

    .modal-field label,
    .field-label {
      font-size: 0.84rem;
      color: var(--text-soft);
      font-weight: 600;
      display: flex;
      justify-content: space-between;
      gap: 0.6rem;
      align-items: center;
    }

    .modal-actions {
      display: flex;
      justify-content: flex-end;
      gap: 0.7rem;
      flex-wrap: wrap;
    }

    .list-editor-layout {
      container-type: inline-size;
    }

    @media (max-width: 1024px) {
      .topbar-inner {
        padding-left: 1rem;
        padding-right: 1rem;
      }

      .workspace {
        padding-left: 1rem;
        padding-right: 1rem;
        grid-template-columns: minmax(260px, 320px) minmax(0, 1fr);
      }
    }

    @media (max-width: 839px) {
      .workspace {
        grid-template-columns: 1fr;
      }

      .list-shell {
        position: static;
      }

      .key-list {
        max-height: none;
      }
    }

    @media (max-width: 599px) {
      .topbar-inner {
        padding: 1rem 0.9rem 0.9rem;
      }

      .workspace {
        padding: 0.9rem;
      }

      .brand-row,
      .toolbar,
      .topbar-footer,
      .editor-keyline,
      .editor-topline {
        align-items: stretch;
      }

      .brand-row,
      .editor-keyline,
      .editor-topline,
      .toolbar {
        flex-direction: column;
      }

      .toolbar-left,
      .toolbar-right {
        width: 100%;
      }

      .toolbar-left > *,
      .toolbar-right > * {
        flex: 1 1 auto;
      }

      .search-shell {
        min-width: 0;
      }
    }
  </style>
</head>
<body>
  <div class="app-shell">
    <header class="topbar">
      <div class="topbar-inner">
        <div class="brand-row">
          <div class="brand-copy">
            <h1 id="catalogTitle">Anas Localization Catalog</h1>
            <p id="catalogSubtitle">Minimal translation workspace with autosave, explicit Done review, and structured editors for plural and gender variants.</p>
          </div>
          <div class="meta-badges" id="metaBadges"></div>
        </div>

        <div class="toolbar">
          <div class="toolbar-left">
            <label class="search-shell" for="searchInput">
              <input id="searchInput" type="search" placeholder="Search keys or values">
            </label>
            <div class="filter-strip" id="statusFilters"></div>
          </div>

          <div class="toolbar-right">
            <label class="theme-select-shell" for="themeModeSelect">
              <span class="theme-select-label" id="themeModeLabel">Theme</span>
              <select class="theme-select" id="themeModeSelect" aria-label="Theme mode">
                <option value="system" id="themeModeOptionSystem">System</option>
                <option value="light" id="themeModeOptionLight">Light</option>
                <option value="dark" id="themeModeOptionDark">Dark</option>
              </select>
            </label>
            <button class="toolbar-button" id="refreshBtn" data-action="refresh">Refresh</button>
            <button class="primary-button" id="newKeyBtn" data-action="open-modal">+ New String</button>
          </div>
        </div>

        <div class="topbar-footer">
          <div id="activeFilterSummary">Loading workspace…</div>
          <div class="inline-counts" id="summaryCounts"></div>
        </div>
      </div>
    </header>

    <main class="workspace list-editor-layout">
      <aside class="panel list-shell">
        <div class="list-header">
          <div>
            <h2 id="keyListTitle">Keys</h2>
            <p id="keyListSubtitle">List + editor workflow</p>
          </div>
          <span class="pill" id="visibleKeyCount">0 visible</span>
        </div>
        <div class="key-list" id="keyListPanel"></div>
      </aside>

      <section class="editor-shell" id="editorPane"></section>
    </main>
  </div>

  <div class="toast-host" id="toastHost"></div>
  <div class="sr-only" aria-live="polite" id="srAnnouncer"></div>

  <dialog id="newKeyModal" aria-labelledby="newKeyTitle">
    <form method="dialog" class="modal-shell" id="newKeyForm">
      <div>
        <p class="eyebrow" id="newKeyEyebrow">Create New String</p>
        <h2 id="newKeyTitle" class="section-title">Create New String</h2>
        <p class="muted-copy" id="newKeySubtitle">Source locale goes first. Filled target locales still start as needing review until you mark them Done.</p>
      </div>

      <div class="modal-grid">
        <div class="modal-field">
          <label for="newKeyPath" id="newKeyPathLabel">Key path</label>
          <input class="modal-input mono-note" id="newKeyPath" type="text" placeholder="checkout.summary.title" autocomplete="off">
          <div class="inline-error" id="newKeyPathError"></div>
        </div>
        <div class="modal-locale-grid" id="newKeyLocaleFields"></div>
      </div>

      <div class="modal-actions">
        <button class="subtle-button" type="button" data-action="close-modal" id="newKeyCancelBtn">Cancel</button>
        <button class="primary-button" type="button" id="newKeySaveBtn" data-action="create-key">Create</button>
      </div>
    </form>
  </dialog>

  <dialog id="displayLanguageModal" aria-labelledby="displayLanguageTitle">
    <form method="dialog" class="modal-shell" id="displayLanguageForm">
      <div>
        <p class="eyebrow" id="displayLanguageEyebrow">Catalog Language</p>
        <h2 id="displayLanguageTitle" class="section-title">Choose display language</h2>
        <p class="muted-copy" id="displayLanguageSubtitle">This changes only the catalog interface text.</p>
      </div>

      <div class="modal-grid">
        <div class="modal-field">
          <label for="displayLanguageSelect" id="displayLanguageSelectLabel">Language</label>
          <select class="modal-input" id="displayLanguageSelect">
            <option value="en">English</option>
            <option value="ar">العربية</option>
            <option value="tr">Türkçe</option>
            <option value="es">Español</option>
            <option value="hi">हिन्दी</option>
            <option value="zh-CN">简体中文</option>
          </select>
        </div>
      </div>

      <div class="modal-actions">
        <button class="subtle-button" type="button" data-action="close-display-language-modal" id="displayLanguageCancelBtn">Cancel</button>
        <button class="primary-button" type="button" data-action="confirm-display-language" id="displayLanguageConfirmBtn">Confirm</button>
      </div>
    </form>
  </dialog>

  <script>
    const API_URL = __API_URL__;
    const DISPLAY_LANGUAGE_STORAGE_KEY = 'anasCatalog.displayLanguage';
    const DISPLAY_LANGUAGES = ['en', 'ar', 'tr', 'es', 'hi', 'zh-CN'];
    const DISPLAY_LANGUAGE_DIRECTIONS = {
      en: 'ltr',
      ar: 'rtl',
      tr: 'ltr',
      es: 'ltr',
      hi: 'ltr',
      'zh-CN': 'ltr',
    };
    const THEME_STORAGE_KEY = 'anasCatalog.themeMode';
    const THEME_MODES = ['system', 'light', 'dark'];
    const PLURAL_KEYS = ['zero', 'one', 'two', 'few', 'many', 'other', 'more'];
    const GENDER_KEYS = ['male', 'female'];
    const CATALOG_COPY = {
      en: {
        pageTitle: 'Anas Localization Catalog',
        catalogTitle: 'Anas Localization Catalog',
        catalogSubtitle: 'Minimal translation workspace with autosave, explicit Done review, and structured editors for plural and gender variants.',
        searchPlaceholder: 'Search keys or values',
        themeLabel: 'Theme',
        themeModes: {system: 'System', light: 'Light', dark: 'Dark'},
        refresh: 'Refresh',
        newString: '+ New String',
        keysTitle: 'Keys',
        keysSubtitle: 'List + editor workflow',
        meta: {
          catalogLanguage: 'Catalog Language',
          source: 'Source',
          locales: '{count} locales',
          keys: '{count} keys',
          sourceLabel: 'Source: {locale}',
          catalogLanguageButton: 'Catalog Language: {language}',
        },
        filters: {all: 'All'},
        statuses: {green: 'Ready', warning: 'Needs review', red: 'Missing'},
        reasons: {
          source_changed: 'Source changed. Re-check this locale.',
          source_added: 'Source was added. Review the translation.',
          source_deleted: 'Source value was removed.',
          source_deleted_review_required: 'Source value was removed. Review this locale.',
          target_missing: 'Translation is missing.',
          new_key_needs_translation_review: 'New entry needs review.',
          target_updated_needs_review: 'Saved, but still needs review.',
        },
        summary: {
          visible: '{count} visible',
          ready: 'Ready {count}',
          needsReview: 'Needs review {count}',
          missing: 'Missing {count}',
          loading: 'Loading workspace…',
          noMatches: 'No keys match the current search or filter.',
          rowsVisible: '{count} rows visible · filter: {filter}{searchSuffix}',
          searchSuffix: ' · search: {query}',
        },
        errors: {
          catalogFailedToLoad: 'Catalog failed to load',
        },
        emptyStates: {
          noMatchingKeysTitle: 'No matching keys',
          noMatchingKeysBody: 'Try clearing the search or switching back to all statuses.',
          noKeysYetTitle: 'No keys yet',
          noKeysYetBody: 'Create the first string to start editing localized values.',
        },
        actions: {
          retry: 'Retry',
          clearFilters: 'Clear filters',
          cancel: 'Cancel',
          confirm: 'Confirm',
          create: 'Create',
          deleteKey: 'Delete key',
          done: 'Done',
          retrySave: 'Retry save',
        },
        list: {
          allTargetsDone: 'All target locales done',
          allTargetsReady: 'All target locales are ready.',
          missingCount: '{count} missing · {locales}',
          pendingCount: '{count} pending · {locales}',
          missingSummary: 'Missing: {locales}',
          pendingSummary: 'Pending: {locales}',
        },
        newKey: {
          eyebrow: 'Create New String',
          title: 'Create New String',
          subtitle: 'Source locale goes first. Filled target locales still start as needing review until you mark them Done.',
          keyPathLabel: 'Key path',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: 'Optional initial value',
          sourceBadge: 'Source',
          invalidKeyPath: 'Use dot-separated segments with letters, numbers, and underscores.',
          confirmMissingSource: 'Create "{keyPath}" without a source value? Target locales will stay blocked until the source is filled.',
        },
        displayLanguage: {
          eyebrow: 'Catalog Language',
          title: 'Choose display language',
          subtitle: 'This changes only the catalog interface text.',
          label: 'Language',
        },
        editor: {
          selectedKey: 'Selected key',
          sourceImpact: 'Source impact',
          sourceImpactBody: 'Editing the source autosaves immediately and marks every target locale as needing review or missing.',
          sourceReference: 'Source reference · {locale}',
          editorTitle: '{locale} editor',
          editorHelp: 'Autosaves after 700ms, on blur, and when switching rows or locales.',
          sourceStaysGreen: 'Source stays green',
          reviewed: 'Reviewed',
          reviewedAndReady: 'Reviewed and ready.',
          doneBlocked: 'Done is blocked',
          autosaveFailed: 'Autosave failed',
          lastEdit: 'Last edit: {value}',
          lastDone: 'Last done: {value}',
          deleteSourceValue: 'Delete source value',
          deleteLocaleValue: 'Delete {locale} value',
          translation: 'Translation',
          sourceLocale: 'Source locale',
          autosavesAfter: 'Autosaves after 700ms',
          enterLocalizedCopy: 'Enter localized copy',
          advancedJson: 'Advanced JSON',
          advancedJsonSubtitle: 'Pretty printed raw value',
          advancedJsonHelp: 'Use this when the translation shape is more complex than the guided editor. Invalid JSON stays local and blocks Done.',
          advancedJsonEditor: 'Advanced JSON editor',
          advancedJsonEditorBody: 'This value shape is kept in raw mode because it does not match the guided plural or gender patterns.',
          pluralBranch: 'Plural branch',
          addAction: 'Add {item}',
        },
        sync: {
          dirty: 'Unsaved',
          saving: 'Saving',
          saved: 'Saved',
          save_error: 'Retry needed',
          clean: 'Synced',
        },
        blockers: {
          advancedJsonInvalid: 'Advanced JSON must be valid.',
          waitAutosave: 'Wait for autosave to finish before marking Done.',
          translationEmpty: 'Translation is still empty.',
          fillVisibleBranches: 'Fill every visible branch before marking Done.',
          missingPlaceholders: 'Missing placeholders: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: 'Delete the source value for "{keyPath}"? Every target locale will need review.',
          deleteLocaleValue: 'Delete the {locale} value for "{keyPath}"? This row will become missing.',
          deleteKey: 'Delete the entire key "{keyPath}" across every locale?',
        },
        toasts: {
          autosaveFailed: 'Autosave failed for {keyPath} ({locale})',
          created: 'Created {keyPath}',
          markedDone: 'Marked {keyPath} ({locale}) as done',
          deletedValue: 'Deleted value for {keyPath} ({locale})',
          deletedKey: 'Deleted {keyPath}',
        },
      },
      ar: {
        pageTitle: 'فهرس Anas للترجمة',
        catalogTitle: 'فهرس Anas للترجمة',
        catalogSubtitle: 'مساحة عمل بسيطة للترجمة مع حفظ تلقائي ومراجعة صريحة عبر تم، ومحررات منظّمة لصيغ الجمع والنوع.',
        searchPlaceholder: 'ابحث في المفاتيح أو القيم',
        themeLabel: 'السمة',
        themeModes: {system: 'النظام', light: 'فاتح', dark: 'داكن'},
        refresh: 'تحديث',
        newString: '+ نص جديد',
        keysTitle: 'المفاتيح',
        keysSubtitle: 'سير عمل القائمة + المحرر',
        meta: {
          catalogLanguage: 'لغة الفهرس',
          source: 'المصدر',
          locales: '{count} لغات',
          keys: '{count} مفتاح',
          sourceLabel: 'المصدر: {locale}',
          catalogLanguageButton: 'لغة الفهرس: {language}',
        },
        filters: {all: 'الكل'},
        statuses: {green: 'جاهز', warning: 'بحاجة إلى مراجعة', red: 'مفقود'},
        reasons: {
          source_changed: 'تم تغيير المصدر. أعد التحقق من هذه اللغة.',
          source_added: 'تمت إضافة المصدر. راجع الترجمة.',
          source_deleted: 'تمت إزالة قيمة المصدر.',
          source_deleted_review_required: 'تمت إزالة قيمة المصدر. راجع هذه اللغة.',
          target_missing: 'الترجمة مفقودة.',
          new_key_needs_translation_review: 'الإدخال الجديد يحتاج إلى مراجعة.',
          target_updated_needs_review: 'تم الحفظ، لكنه ما يزال يحتاج إلى مراجعة.',
        },
        summary: {
          visible: '{count} ظاهر',
          ready: 'جاهز {count}',
          needsReview: 'بحاجة إلى مراجعة {count}',
          missing: 'مفقود {count}',
          loading: 'جارٍ تحميل مساحة العمل…',
          noMatches: 'لا توجد مفاتيح تطابق البحث أو الفلتر الحالي.',
          rowsVisible: '{count} صفوف ظاهرة · الفلتر: {filter}{searchSuffix}',
          searchSuffix: ' · البحث: {query}',
        },
        errors: {catalogFailedToLoad: 'تعذر تحميل الفهرس'},
        emptyStates: {
          noMatchingKeysTitle: 'لا توجد مفاتيح مطابقة',
          noMatchingKeysBody: 'جرّب مسح البحث أو العودة إلى جميع الحالات.',
          noKeysYetTitle: 'لا توجد مفاتيح بعد',
          noKeysYetBody: 'أنشئ أول نص لبدء تعديل القيم المترجمة.',
        },
        actions: {
          retry: 'إعادة المحاولة',
          clearFilters: 'مسح الفلاتر',
          cancel: 'إلغاء',
          confirm: 'تأكيد',
          create: 'إنشاء',
          deleteKey: 'حذف المفتاح',
          done: 'تم',
          retrySave: 'إعادة الحفظ',
        },
        list: {
          allTargetsDone: 'اكتملت كل اللغات الهدف',
          allTargetsReady: 'جميع اللغات الهدف جاهزة.',
          missingCount: '{count} مفقود · {locales}',
          pendingCount: '{count} قيد الانتظار · {locales}',
          missingSummary: 'مفقود: {locales}',
          pendingSummary: 'قيد الانتظار: {locales}',
        },
        newKey: {
          eyebrow: 'إنشاء نص جديد',
          title: 'إنشاء نص جديد',
          subtitle: 'تبدأ لغة المصدر أولاً. حتى اللغات الهدف المعبأة تبدأ بحالة تحتاج إلى مراجعة إلى أن تضغط تم.',
          keyPathLabel: 'مسار المفتاح',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: 'قيمة أولية اختيارية',
          sourceBadge: 'المصدر',
          invalidKeyPath: 'استخدم أجزاء مفصولة بنقاط مع أحرف وأرقام وشرطات سفلية.',
          confirmMissingSource: 'إنشاء "{keyPath}" بدون قيمة مصدر؟ ستبقى اللغات الهدف محجوبة حتى تتم تعبئة المصدر.',
        },
        displayLanguage: {
          eyebrow: 'لغة الفهرس',
          title: 'اختر لغة العرض',
          subtitle: 'هذا يغيّر نص واجهة الفهرس فقط.',
          label: 'اللغة',
        },
        editor: {
          selectedKey: 'المفتاح المحدد',
          sourceImpact: 'تأثير المصدر',
          sourceImpactBody: 'تعديل المصدر يحفظ تلقائياً فوراً ويجعل كل لغة هدف بحاجة إلى مراجعة أو مفقودة.',
          sourceReference: 'مرجع المصدر · {locale}',
          editorTitle: 'محرر {locale}',
          editorHelp: 'يحفظ تلقائياً بعد 700 مللي ثانية، وعند فقدان التركيز، وعند تبديل الصفوف أو اللغات.',
          sourceStaysGreen: 'يبقى المصدر أخضر',
          reviewed: 'تمت المراجعة',
          reviewedAndReady: 'تمت المراجعة وهو جاهز.',
          doneBlocked: 'زر تم معطّل',
          autosaveFailed: 'فشل الحفظ التلقائي',
          lastEdit: 'آخر تعديل: {value}',
          lastDone: 'آخر تم: {value}',
          deleteSourceValue: 'حذف قيمة المصدر',
          deleteLocaleValue: 'حذف قيمة {locale}',
          translation: 'الترجمة',
          sourceLocale: 'لغة المصدر',
          autosavesAfter: 'يحفظ تلقائياً بعد 700 مللي ثانية',
          enterLocalizedCopy: 'أدخل النص المترجم',
          advancedJson: 'JSON متقدم',
          advancedJsonSubtitle: 'قيمة خام منسقة',
          advancedJsonHelp: 'استخدم هذا عندما يكون شكل الترجمة أعقد من المحرر الموجّه. يبقى JSON غير الصالح محلياً ويمنع الضغط على تم.',
          advancedJsonEditor: 'محرر JSON متقدم',
          advancedJsonEditorBody: 'تم الاحتفاظ بهذا الشكل في وضع الخام لأنه لا يطابق أنماط الجمع أو النوع الموجّهة.',
          pluralBranch: 'فرع الجمع',
          addAction: 'إضافة {item}',
        },
        sync: {
          dirty: 'غير محفوظ',
          saving: 'جارٍ الحفظ',
          saved: 'تم الحفظ',
          save_error: 'تحتاج إلى إعادة المحاولة',
          clean: 'متزامن',
        },
        blockers: {
          advancedJsonInvalid: 'يجب أن يكون JSON المتقدم صالحاً.',
          waitAutosave: 'انتظر حتى يكتمل الحفظ التلقائي قبل الضغط على تم.',
          translationEmpty: 'الترجمة ما تزال فارغة.',
          fillVisibleBranches: 'املأ كل الفروع الظاهرة قبل الضغط على تم.',
          missingPlaceholders: 'العناصر النائبة المفقودة: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: 'حذف قيمة المصدر لـ "{keyPath}"؟ ستحتاج كل اللغات الهدف إلى مراجعة.',
          deleteLocaleValue: 'حذف قيمة {locale} لـ "{keyPath}"؟ سيصبح هذا الصف مفقوداً.',
          deleteKey: 'حذف المفتاح بالكامل "{keyPath}" من جميع اللغات؟',
        },
        toasts: {
          autosaveFailed: 'فشل الحفظ التلقائي لـ {keyPath} ({locale})',
          created: 'تم إنشاء {keyPath}',
          markedDone: 'تم وضع {keyPath} ({locale}) كمنجز',
          deletedValue: 'تم حذف قيمة {keyPath} ({locale})',
          deletedKey: 'تم حذف {keyPath}',
        },
      },
      tr: {
        pageTitle: 'Anas Yerelleştirme Kataloğu',
        catalogTitle: 'Anas Yerelleştirme Kataloğu',
        catalogSubtitle: 'Otomatik kaydetme, açık Tamam incelemesi ve çoğul/cinsiyet varyantları için yapılandırılmış düzenleyiciler içeren sade çeviri çalışma alanı.',
        searchPlaceholder: 'Anahtar veya değer ara',
        themeLabel: 'Tema',
        themeModes: {system: 'Sistem', light: 'Açık', dark: 'Koyu'},
        refresh: 'Yenile',
        newString: '+ Yeni Metin',
        keysTitle: 'Anahtarlar',
        keysSubtitle: 'Liste + düzenleyici akışı',
        meta: {
          catalogLanguage: 'Katalog Dili',
          source: 'Kaynak',
          locales: '{count} dil',
          keys: '{count} anahtar',
          sourceLabel: 'Kaynak: {locale}',
          catalogLanguageButton: 'Katalog Dili: {language}',
        },
        filters: {all: 'Tümü'},
        statuses: {green: 'Hazır', warning: 'İnceleme gerekli', red: 'Eksik'},
        reasons: {
          source_changed: 'Kaynak değişti. Bu dili yeniden kontrol edin.',
          source_added: 'Kaynak eklendi. Çeviriyi gözden geçirin.',
          source_deleted: 'Kaynak değeri kaldırıldı.',
          source_deleted_review_required: 'Kaynak değeri kaldırıldı. Bu dili gözden geçirin.',
          target_missing: 'Çeviri eksik.',
          new_key_needs_translation_review: 'Yeni kayıt inceleme gerektiriyor.',
          target_updated_needs_review: 'Kaydedildi, ancak hâlâ inceleme gerekiyor.',
        },
        summary: {
          visible: '{count} görünür',
          ready: 'Hazır {count}',
          needsReview: 'İnceleme gerekli {count}',
          missing: 'Eksik {count}',
          loading: 'Çalışma alanı yükleniyor…',
          noMatches: 'Geçerli arama veya filtreyle eşleşen anahtar yok.',
          rowsVisible: '{count} satır görünür · filtre: {filter}{searchSuffix}',
          searchSuffix: ' · arama: {query}',
        },
        errors: {catalogFailedToLoad: 'Katalog yüklenemedi'},
        emptyStates: {
          noMatchingKeysTitle: 'Eşleşen anahtar yok',
          noMatchingKeysBody: 'Aramayı temizlemeyi veya tüm durumlara dönmeyi deneyin.',
          noKeysYetTitle: 'Henüz anahtar yok',
          noKeysYetBody: 'Yerelleştirilmiş değerleri düzenlemeye başlamak için ilk metni oluşturun.',
        },
        actions: {
          retry: 'Tekrar dene',
          clearFilters: 'Filtreleri temizle',
          cancel: 'İptal',
          confirm: 'Onayla',
          create: 'Oluştur',
          deleteKey: 'Anahtarı sil',
          done: 'Tamam',
          retrySave: 'Kaydetmeyi yeniden dene',
        },
        list: {
          allTargetsDone: 'Tüm hedef diller tamam',
          allTargetsReady: 'Tüm hedef diller hazır.',
          missingCount: '{count} eksik · {locales}',
          pendingCount: '{count} bekliyor · {locales}',
          missingSummary: 'Eksik: {locales}',
          pendingSummary: 'Bekliyor: {locales}',
        },
        newKey: {
          eyebrow: 'Yeni Metin Oluştur',
          title: 'Yeni Metin Oluştur',
          subtitle: 'Önce kaynak dil gelir. Dolu hedef diller bile Tamam diyene kadar inceleme bekliyor olarak başlar.',
          keyPathLabel: 'Anahtar yolu',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: 'İsteğe bağlı başlangıç değeri',
          sourceBadge: 'Kaynak',
          invalidKeyPath: 'Harf, rakam ve alt çizgi içeren nokta ayrımlı segmentler kullanın.',
          confirmMissingSource: '"{keyPath}" kaynak değer olmadan oluşturulsun mu? Kaynak doldurulana kadar hedef diller bloklu kalır.',
        },
        displayLanguage: {
          eyebrow: 'Katalog Dili',
          title: 'Görüntüleme dilini seçin',
          subtitle: 'Bu yalnızca katalog arayüzü metnini değiştirir.',
          label: 'Dil',
        },
        editor: {
          selectedKey: 'Seçili anahtar',
          sourceImpact: 'Kaynak etkisi',
          sourceImpactBody: 'Kaynağı düzenlemek anında otomatik kaydeder ve tüm hedef dilleri inceleme gerekli veya eksik olarak işaretler.',
          sourceReference: 'Kaynak referansı · {locale}',
          editorTitle: '{locale} düzenleyicisi',
          editorHelp: '700 ms sonra, odak kaybolduğunda ve satır veya dil değiştirildiğinde otomatik kaydeder.',
          sourceStaysGreen: 'Kaynak yeşil kalır',
          reviewed: 'İncelendi',
          reviewedAndReady: 'İncelendi ve hazır.',
          doneBlocked: 'Tamam engellendi',
          autosaveFailed: 'Otomatik kaydetme başarısız',
          lastEdit: 'Son düzenleme: {value}',
          lastDone: 'Son tamam: {value}',
          deleteSourceValue: 'Kaynak değeri sil',
          deleteLocaleValue: '{locale} değerini sil',
          translation: 'Çeviri',
          sourceLocale: 'Kaynak dili',
          autosavesAfter: '700 ms sonra otomatik kaydeder',
          enterLocalizedCopy: 'Yerelleştirilmiş metni girin',
          advancedJson: 'Gelişmiş JSON',
          advancedJsonSubtitle: 'Biçimlendirilmiş ham değer',
          advancedJsonHelp: 'Çeviri yapısı yönlendirilmiş düzenleyiciden daha karmaşıksa bunu kullanın. Geçersiz JSON yerelde kalır ve Tamam\'ı engeller.',
          advancedJsonEditor: 'Gelişmiş JSON düzenleyicisi',
          advancedJsonEditorBody: 'Bu değer biçimi, yönlendirilmiş çoğul veya cinsiyet kalıplarıyla eşleşmediği için ham modda tutulur.',
          pluralBranch: 'Çoğul dalı',
          addAction: '{item} ekle',
        },
        sync: {
          dirty: 'Kaydedilmedi',
          saving: 'Kaydediliyor',
          saved: 'Kaydedildi',
          save_error: 'Yeniden dene',
          clean: 'Senkronize',
        },
        blockers: {
          advancedJsonInvalid: 'Gelişmiş JSON geçerli olmalıdır.',
          waitAutosave: 'Tamam demeden önce otomatik kaydetmenin bitmesini bekleyin.',
          translationEmpty: 'Çeviri hâlâ boş.',
          fillVisibleBranches: 'Tamam demeden önce görünen tüm dalları doldurun.',
          missingPlaceholders: 'Eksik yer tutucular: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: '"{keyPath}" için kaynak değeri silinsin mi? Tüm hedef diller inceleme gerektirecek.',
          deleteLocaleValue: '"{keyPath}" için {locale} değeri silinsin mi? Bu satır eksik durumuna düşecek.',
          deleteKey: '"{keyPath}" anahtarı tüm dillerde tamamen silinsin mi?',
        },
        toasts: {
          autosaveFailed: '{keyPath} ({locale}) için otomatik kaydetme başarısız oldu',
          created: '{keyPath} oluşturuldu',
          markedDone: '{keyPath} ({locale}) tamamlandı olarak işaretlendi',
          deletedValue: '{keyPath} ({locale}) için değer silindi',
          deletedKey: '{keyPath} silindi',
        },
      },
      es: {
        pageTitle: 'Catálogo de Localización Anas',
        catalogTitle: 'Catálogo de Localización Anas',
        catalogSubtitle: 'Espacio de trabajo de traducción minimalista con autoguardado, revisión explícita con Hecho y editores estructurados para variantes de plural y género.',
        searchPlaceholder: 'Buscar claves o valores',
        themeLabel: 'Tema',
        themeModes: {system: 'Sistema', light: 'Claro', dark: 'Oscuro'},
        refresh: 'Actualizar',
        newString: '+ Nueva Cadena',
        keysTitle: 'Claves',
        keysSubtitle: 'Flujo de lista + editor',
        meta: {
          catalogLanguage: 'Idioma del Catálogo',
          source: 'Origen',
          locales: '{count} idiomas',
          keys: '{count} claves',
          sourceLabel: 'Origen: {locale}',
          catalogLanguageButton: 'Idioma del Catálogo: {language}',
        },
        filters: {all: 'Todo'},
        statuses: {green: 'Listo', warning: 'Necesita revisión', red: 'Falta'},
        reasons: {
          source_changed: 'La fuente cambió. Vuelve a revisar este idioma.',
          source_added: 'Se agregó la fuente. Revisa la traducción.',
          source_deleted: 'Se eliminó el valor de origen.',
          source_deleted_review_required: 'Se eliminó el valor de origen. Revisa este idioma.',
          target_missing: 'Falta la traducción.',
          new_key_needs_translation_review: 'La nueva entrada necesita revisión.',
          target_updated_needs_review: 'Se guardó, pero aún necesita revisión.',
        },
        summary: {
          visible: '{count} visibles',
          ready: 'Listo {count}',
          needsReview: 'Necesita revisión {count}',
          missing: 'Falta {count}',
          loading: 'Cargando espacio de trabajo…',
          noMatches: 'No hay claves que coincidan con la búsqueda o el filtro actual.',
          rowsVisible: '{count} filas visibles · filtro: {filter}{searchSuffix}',
          searchSuffix: ' · búsqueda: {query}',
        },
        errors: {catalogFailedToLoad: 'No se pudo cargar el catálogo'},
        emptyStates: {
          noMatchingKeysTitle: 'No hay claves coincidentes',
          noMatchingKeysBody: 'Prueba limpiando la búsqueda o volviendo a todos los estados.',
          noKeysYetTitle: 'Aún no hay claves',
          noKeysYetBody: 'Crea la primera cadena para empezar a editar valores localizados.',
        },
        actions: {
          retry: 'Reintentar',
          clearFilters: 'Limpiar filtros',
          cancel: 'Cancelar',
          confirm: 'Confirmar',
          create: 'Crear',
          deleteKey: 'Eliminar clave',
          done: 'Hecho',
          retrySave: 'Reintentar guardado',
        },
        list: {
          allTargetsDone: 'Todos los idiomas de destino están listos',
          allTargetsReady: 'Todos los idiomas de destino están listos.',
          missingCount: '{count} faltan · {locales}',
          pendingCount: '{count} pendientes · {locales}',
          missingSummary: 'Faltan: {locales}',
          pendingSummary: 'Pendientes: {locales}',
        },
        newKey: {
          eyebrow: 'Crear Nueva Cadena',
          title: 'Crear Nueva Cadena',
          subtitle: 'Primero va el idioma de origen. Incluso los idiomas de destino rellenados empiezan como pendientes de revisión hasta que pulses Hecho.',
          keyPathLabel: 'Ruta de la clave',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: 'Valor inicial opcional',
          sourceBadge: 'Origen',
          invalidKeyPath: 'Usa segmentos separados por puntos con letras, números y guiones bajos.',
          confirmMissingSource: '¿Crear "{keyPath}" sin un valor de origen? Los idiomas de destino seguirán bloqueados hasta que se complete el origen.',
        },
        displayLanguage: {
          eyebrow: 'Idioma del Catálogo',
          title: 'Elige el idioma de visualización',
          subtitle: 'Esto solo cambia el texto de la interfaz del catálogo.',
          label: 'Idioma',
        },
        editor: {
          selectedKey: 'Clave seleccionada',
          sourceImpact: 'Impacto en origen',
          sourceImpactBody: 'Editar el origen guarda automáticamente de inmediato y marca todos los idiomas de destino como pendientes de revisión o faltantes.',
          sourceReference: 'Referencia de origen · {locale}',
          editorTitle: 'Editor de {locale}',
          editorHelp: 'Guarda automáticamente después de 700 ms, al perder el foco y al cambiar filas o idiomas.',
          sourceStaysGreen: 'El origen permanece en verde',
          reviewed: 'Revisado',
          reviewedAndReady: 'Revisado y listo.',
          doneBlocked: 'Hecho está bloqueado',
          autosaveFailed: 'Falló el autoguardado',
          lastEdit: 'Última edición: {value}',
          lastDone: 'Último hecho: {value}',
          deleteSourceValue: 'Eliminar valor de origen',
          deleteLocaleValue: 'Eliminar valor de {locale}',
          translation: 'Traducción',
          sourceLocale: 'Idioma de origen',
          autosavesAfter: 'Guarda automáticamente después de 700 ms',
          enterLocalizedCopy: 'Introduce el texto localizado',
          advancedJson: 'JSON avanzado',
          advancedJsonSubtitle: 'Valor bruto con formato',
          advancedJsonHelp: 'Úsalo cuando la forma de la traducción sea más compleja que la del editor guiado. Un JSON no válido se mantiene local y bloquea Hecho.',
          advancedJsonEditor: 'Editor JSON avanzado',
          advancedJsonEditorBody: 'Esta forma de valor se mantiene en modo bruto porque no coincide con los patrones guiados de plural o género.',
          pluralBranch: 'Rama plural',
          addAction: 'Agregar {item}',
        },
        sync: {
          dirty: 'Sin guardar',
          saving: 'Guardando',
          saved: 'Guardado',
          save_error: 'Requiere reintento',
          clean: 'Sincronizado',
        },
        blockers: {
          advancedJsonInvalid: 'El JSON avanzado debe ser válido.',
          waitAutosave: 'Espera a que termine el autoguardado antes de marcar como Hecho.',
          translationEmpty: 'La traducción sigue vacía.',
          fillVisibleBranches: 'Completa cada rama visible antes de marcar como Hecho.',
          missingPlaceholders: 'Marcadores faltantes: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: '¿Eliminar el valor de origen de "{keyPath}"? Todos los idiomas de destino requerirán revisión.',
          deleteLocaleValue: '¿Eliminar el valor de {locale} de "{keyPath}"? Esta fila pasará a estar faltante.',
          deleteKey: '¿Eliminar por completo la clave "{keyPath}" en todos los idiomas?',
        },
        toasts: {
          autosaveFailed: 'Falló el autoguardado para {keyPath} ({locale})',
          created: 'Se creó {keyPath}',
          markedDone: 'Se marcó {keyPath} ({locale}) como hecho',
          deletedValue: 'Se eliminó el valor de {keyPath} ({locale})',
          deletedKey: 'Se eliminó {keyPath}',
        },
      },
      hi: {
        pageTitle: 'Anas लोकलाइज़ेशन कैटलॉग',
        catalogTitle: 'Anas लोकलाइज़ेशन कैटलॉग',
        catalogSubtitle: 'ऑटोसेव, स्पष्ट Done समीक्षा, और बहुवचन व जेंडर वैरिएंट्स के लिए संरचित एडिटर्स वाला सरल अनुवाद कार्यक्षेत्र।',
        searchPlaceholder: 'कुंजियाँ या मान खोजें',
        themeLabel: 'थीम',
        themeModes: {system: 'सिस्टम', light: 'लाइट', dark: 'डार्क'},
        refresh: 'रिफ्रेश',
        newString: '+ नया टेक्स्ट',
        keysTitle: 'कुंजियाँ',
        keysSubtitle: 'सूची + एडिटर प्रवाह',
        meta: {
          catalogLanguage: 'कैटलॉग भाषा',
          source: 'स्रोत',
          locales: '{count} भाषाएँ',
          keys: '{count} कुंजियाँ',
          sourceLabel: 'स्रोत: {locale}',
          catalogLanguageButton: 'कैटलॉग भाषा: {language}',
        },
        filters: {all: 'सभी'},
        statuses: {green: 'तैयार', warning: 'समीक्षा आवश्यक', red: 'अनुपस्थित'},
        reasons: {
          source_changed: 'स्रोत बदल गया है। इस भाषा को फिर से जाँचें।',
          source_added: 'स्रोत जोड़ा गया है। अनुवाद की समीक्षा करें।',
          source_deleted: 'स्रोत मान हटा दिया गया है।',
          source_deleted_review_required: 'स्रोत मान हटा दिया गया है। इस भाषा की समीक्षा करें।',
          target_missing: 'अनुवाद अनुपस्थित है।',
          new_key_needs_translation_review: 'नई प्रविष्टि की समीक्षा आवश्यक है।',
          target_updated_needs_review: 'सहेजा गया, लेकिन अभी भी समीक्षा आवश्यक है।',
        },
        summary: {
          visible: '{count} दिखाई दे रहे हैं',
          ready: 'तैयार {count}',
          needsReview: 'समीक्षा आवश्यक {count}',
          missing: 'अनुपस्थित {count}',
          loading: 'कार्यस्थान लोड हो रहा है…',
          noMatches: 'मौजूदा खोज या फ़िल्टर से कोई कुंजी मेल नहीं खाती।',
          rowsVisible: '{count} पंक्तियाँ दिखाई दे रही हैं · फ़िल्टर: {filter}{searchSuffix}',
          searchSuffix: ' · खोज: {query}',
        },
        errors: {catalogFailedToLoad: 'कैटलॉग लोड नहीं हो सका'},
        emptyStates: {
          noMatchingKeysTitle: 'कोई मेल खाती कुंजी नहीं',
          noMatchingKeysBody: 'खोज साफ़ करें या सभी स्थितियों पर वापस जाएँ।',
          noKeysYetTitle: 'अभी तक कोई कुंजी नहीं',
          noKeysYetBody: 'स्थानीयकृत मान संपादित करना शुरू करने के लिए पहला टेक्स्ट बनाएं।',
        },
        actions: {
          retry: 'फिर प्रयास करें',
          clearFilters: 'फ़िल्टर साफ़ करें',
          cancel: 'रद्द करें',
          confirm: 'पुष्टि करें',
          create: 'बनाएँ',
          deleteKey: 'कुंजी हटाएँ',
          done: 'हो गया',
          retrySave: 'सेव फिर करें',
        },
        list: {
          allTargetsDone: 'सभी लक्ष्य भाषाएँ पूरी हैं',
          allTargetsReady: 'सभी लक्ष्य भाषाएँ तैयार हैं।',
          missingCount: '{count} अनुपस्थित · {locales}',
          pendingCount: '{count} लंबित · {locales}',
          missingSummary: 'अनुपस्थित: {locales}',
          pendingSummary: 'लंबित: {locales}',
        },
        newKey: {
          eyebrow: 'नया टेक्स्ट बनाएँ',
          title: 'नया टेक्स्ट बनाएँ',
          subtitle: 'स्रोत भाषा पहले आती है। भरी हुई लक्ष्य भाषाएँ भी तब तक समीक्षा लंबित रहती हैं जब तक आप Done नहीं दबाते।',
          keyPathLabel: 'कुंजी पथ',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: 'वैकल्पिक प्रारंभिक मान',
          sourceBadge: 'स्रोत',
          invalidKeyPath: 'अक्षरों, संख्याओं और अंडरस्कोर के साथ डॉट-सेपरेटेड सेगमेंट उपयोग करें।',
          confirmMissingSource: 'क्या "{keyPath}" को बिना स्रोत मान के बनाना है? स्रोत भरने तक लक्ष्य भाषाएँ अवरुद्ध रहेंगी।',
        },
        displayLanguage: {
          eyebrow: 'कैटलॉग भाषा',
          title: 'प्रदर्शन भाषा चुनें',
          subtitle: 'यह केवल कैटलॉग इंटरफ़ेस का पाठ बदलता है।',
          label: 'भाषा',
        },
        editor: {
          selectedKey: 'चयनित कुंजी',
          sourceImpact: 'स्रोत प्रभाव',
          sourceImpactBody: 'स्रोत संपादित करने पर तुरंत ऑटोसेव होता है और सभी लक्ष्य भाषाएँ समीक्षा आवश्यक या अनुपस्थित हो जाती हैं।',
          sourceReference: 'स्रोत संदर्भ · {locale}',
          editorTitle: '{locale} एडिटर',
          editorHelp: '700ms बाद, ब्लर पर, और पंक्ति या भाषा बदलने पर ऑटोसेव करता है।',
          sourceStaysGreen: 'स्रोत हरा रहता है',
          reviewed: 'समीक्षित',
          reviewedAndReady: 'समीक्षित और तैयार।',
          doneBlocked: 'Done अवरुद्ध है',
          autosaveFailed: 'ऑटोसेव विफल हुआ',
          lastEdit: 'अंतिम संपादन: {value}',
          lastDone: 'अंतिम Done: {value}',
          deleteSourceValue: 'स्रोत मान हटाएँ',
          deleteLocaleValue: '{locale} मान हटाएँ',
          translation: 'अनुवाद',
          sourceLocale: 'स्रोत भाषा',
          autosavesAfter: '700ms बाद ऑटोसेव',
          enterLocalizedCopy: 'स्थानीयकृत पाठ दर्ज करें',
          advancedJson: 'उन्नत JSON',
          advancedJsonSubtitle: 'सुंदर ढंग से स्वरूपित कच्चा मान',
          advancedJsonHelp: 'जब अनुवाद संरचना निर्देशित एडिटर से अधिक जटिल हो तब इसका उपयोग करें। अमान्य JSON स्थानीय रहता है और Done को रोकता है।',
          advancedJsonEditor: 'उन्नत JSON एडिटर',
          advancedJsonEditorBody: 'यह मान संरचना रॉ मोड में रखी गई है क्योंकि यह निर्देशित बहुवचन या जेंडर पैटर्न से मेल नहीं खाती।',
          pluralBranch: 'बहुवचन शाखा',
          addAction: '{item} जोड़ें',
        },
        sync: {
          dirty: 'असहेजा',
          saving: 'सेव हो रहा है',
          saved: 'सहेजा गया',
          save_error: 'फिर प्रयास आवश्यक',
          clean: 'सिंक्ड',
        },
        blockers: {
          advancedJsonInvalid: 'उन्नत JSON मान्य होना चाहिए।',
          waitAutosave: 'Done चिह्नित करने से पहले ऑटोसेव पूरा होने दें।',
          translationEmpty: 'अनुवाद अभी भी खाली है।',
          fillVisibleBranches: 'Done चिह्नित करने से पहले हर दिखाई देने वाली शाखा भरें।',
          missingPlaceholders: 'अनुपस्थित प्लेसहोल्डर्स: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: '"{keyPath}" के लिए स्रोत मान हटाएँ? सभी लक्ष्य भाषाओं को समीक्षा की आवश्यकता होगी।',
          deleteLocaleValue: '"{keyPath}" के लिए {locale} मान हटाएँ? यह पंक्ति अनुपस्थित हो जाएगी।',
          deleteKey: 'क्या "{keyPath}" कुंजी को सभी भाषाओं में पूरी तरह हटाना है?',
        },
        toasts: {
          autosaveFailed: '{keyPath} ({locale}) के लिए ऑटोसेव विफल हुआ',
          created: '{keyPath} बनाया गया',
          markedDone: '{keyPath} ({locale}) को Done के रूप में चिह्नित किया गया',
          deletedValue: '{keyPath} ({locale}) का मान हटाया गया',
          deletedKey: '{keyPath} हटाया गया',
        },
      },
      'zh-CN': {
        pageTitle: 'Anas 本地化目录',
        catalogTitle: 'Anas 本地化目录',
        catalogSubtitle: '一个简洁的翻译工作区，支持自动保存、显式“完成”审核，以及用于复数和性别变体的结构化编辑器。',
        searchPlaceholder: '搜索键或值',
        themeLabel: '主题',
        themeModes: {system: '系统', light: '浅色', dark: '深色'},
        refresh: '刷新',
        newString: '+ 新建文案',
        keysTitle: '键',
        keysSubtitle: '列表 + 编辑器流程',
        meta: {
          catalogLanguage: '目录语言',
          source: '源语言',
          locales: '{count} 种语言',
          keys: '{count} 个键',
          sourceLabel: '源语言: {locale}',
          catalogLanguageButton: '目录语言: {language}',
        },
        filters: {all: '全部'},
        statuses: {green: '已就绪', warning: '需要审核', red: '缺失'},
        reasons: {
          source_changed: '源内容已更改。请重新检查此语言。',
          source_added: '已添加源内容。请审核翻译。',
          source_deleted: '源值已被删除。',
          source_deleted_review_required: '源值已被删除。请审核此语言。',
          target_missing: '缺少翻译。',
          new_key_needs_translation_review: '新条目需要审核。',
          target_updated_needs_review: '已保存，但仍需要审核。',
        },
        summary: {
          visible: '可见 {count}',
          ready: '已就绪 {count}',
          needsReview: '需要审核 {count}',
          missing: '缺失 {count}',
          loading: '正在加载工作区…',
          noMatches: '没有键匹配当前搜索或筛选条件。',
          rowsVisible: '可见 {count} 行 · 筛选: {filter}{searchSuffix}',
          searchSuffix: ' · 搜索: {query}',
        },
        errors: {catalogFailedToLoad: '目录加载失败'},
        emptyStates: {
          noMatchingKeysTitle: '没有匹配的键',
          noMatchingKeysBody: '请尝试清除搜索或切换回所有状态。',
          noKeysYetTitle: '还没有键',
          noKeysYetBody: '先创建第一条文案以开始编辑本地化内容。',
        },
        actions: {
          retry: '重试',
          clearFilters: '清除筛选',
          cancel: '取消',
          confirm: '确认',
          create: '创建',
          deleteKey: '删除键',
          done: '完成',
          retrySave: '重试保存',
        },
        list: {
          allTargetsDone: '所有目标语言均已完成',
          allTargetsReady: '所有目标语言均已就绪。',
          missingCount: '{count} 缺失 · {locales}',
          pendingCount: '{count} 待处理 · {locales}',
          missingSummary: '缺失: {locales}',
          pendingSummary: '待处理: {locales}',
        },
        newKey: {
          eyebrow: '创建新文案',
          title: '创建新文案',
          subtitle: '源语言优先填写。即使目标语言已有内容，在你点击“完成”前仍会保持需要审核状态。',
          keyPathLabel: '键路径',
          keyPathPlaceholder: 'checkout.summary.title',
          optionalInitialValue: '可选初始值',
          sourceBadge: '源语言',
          invalidKeyPath: '请使用由字母、数字和下划线组成的点分段路径。',
          confirmMissingSource: '要在没有源值的情况下创建 “{keyPath}” 吗？在填写源值之前，目标语言将保持阻塞。',
        },
        displayLanguage: {
          eyebrow: '目录语言',
          title: '选择显示语言',
          subtitle: '这只会改变目录界面文本。',
          label: '语言',
        },
        editor: {
          selectedKey: '已选键',
          sourceImpact: '源内容影响',
          sourceImpactBody: '编辑源内容会立即自动保存，并将所有目标语言标记为需要审核或缺失。',
          sourceReference: '源内容参考 · {locale}',
          editorTitle: '{locale} 编辑器',
          editorHelp: '在 700ms 后、失焦时以及切换行或语言时自动保存。',
          sourceStaysGreen: '源语言保持绿色',
          reviewed: '已审核',
          reviewedAndReady: '已审核并就绪。',
          doneBlocked: '“完成”已被阻止',
          autosaveFailed: '自动保存失败',
          lastEdit: '最后编辑: {value}',
          lastDone: '最后完成: {value}',
          deleteSourceValue: '删除源值',
          deleteLocaleValue: '删除 {locale} 的值',
          translation: '翻译',
          sourceLocale: '源语言',
          autosavesAfter: '700ms 后自动保存',
          enterLocalizedCopy: '输入本地化文案',
          advancedJson: '高级 JSON',
          advancedJsonSubtitle: '格式化后的原始值',
          advancedJsonHelp: '当翻译结构比引导式编辑器更复杂时使用。无效 JSON 会保留在本地并阻止“完成”。',
          advancedJsonEditor: '高级 JSON 编辑器',
          advancedJsonEditorBody: '该值结构保持为原始模式，因为它不匹配引导式复数或性别模式。',
          pluralBranch: '复数分支',
          addAction: '添加 {item}',
        },
        sync: {
          dirty: '未保存',
          saving: '保存中',
          saved: '已保存',
          save_error: '需要重试',
          clean: '已同步',
        },
        blockers: {
          advancedJsonInvalid: '高级 JSON 必须有效。',
          waitAutosave: '请等待自动保存完成后再标记为“完成”。',
          translationEmpty: '翻译仍为空。',
          fillVisibleBranches: '请先填写所有可见分支，再标记为“完成”。',
          missingPlaceholders: '缺少占位符: {placeholders}',
        },
        confirmations: {
          deleteSourceValue: '删除 “{keyPath}” 的源值？所有目标语言都将需要重新审核。',
          deleteLocaleValue: '删除 “{keyPath}” 的 {locale} 值？此行将变为缺失。',
          deleteKey: '要在所有语言中彻底删除键 “{keyPath}” 吗？',
        },
        toasts: {
          autosaveFailed: '{keyPath} ({locale}) 自动保存失败',
          created: '已创建 {keyPath}',
          markedDone: '已将 {keyPath} ({locale}) 标记为完成',
          deletedValue: '已删除 {keyPath} ({locale}) 的值',
          deletedKey: '已删除 {keyPath}',
        },
      },
    };

    const state = {
      meta: null,
      rows: [],
      summary: null,
      displayLanguage: resolveInitialDisplayLanguage(),
      pendingDisplayLanguage: resolveInitialDisplayLanguage(),
      themeMode: getStoredThemeMode(),
      search: '',
      statusFilter: '',
      selectedKey: '',
      selectedLocale: '',
      drafts: {},
      loading: true,
      error: '',
      toasts: [],
    };

    const dom = {
      catalogTitle: document.getElementById('catalogTitle'),
      catalogSubtitle: document.getElementById('catalogSubtitle'),
      metaBadges: document.getElementById('metaBadges'),
      statusFilters: document.getElementById('statusFilters'),
      summaryCounts: document.getElementById('summaryCounts'),
      themeModeSelect: document.getElementById('themeModeSelect'),
      themeModeLabel: document.getElementById('themeModeLabel'),
      themeModeOptionSystem: document.getElementById('themeModeOptionSystem'),
      themeModeOptionLight: document.getElementById('themeModeOptionLight'),
      themeModeOptionDark: document.getElementById('themeModeOptionDark'),
      activeFilterSummary: document.getElementById('activeFilterSummary'),
      keyListTitle: document.getElementById('keyListTitle'),
      keyListSubtitle: document.getElementById('keyListSubtitle'),
      visibleKeyCount: document.getElementById('visibleKeyCount'),
      keyListPanel: document.getElementById('keyListPanel'),
      editorPane: document.getElementById('editorPane'),
      toastHost: document.getElementById('toastHost'),
      srAnnouncer: document.getElementById('srAnnouncer'),
      searchInput: document.getElementById('searchInput'),
      refreshBtn: document.getElementById('refreshBtn'),
      newKeyBtn: document.getElementById('newKeyBtn'),
      newKeyModal: document.getElementById('newKeyModal'),
      newKeyEyebrow: document.getElementById('newKeyEyebrow'),
      newKeyTitle: document.getElementById('newKeyTitle'),
      newKeySubtitle: document.getElementById('newKeySubtitle'),
      newKeyPathLabel: document.getElementById('newKeyPathLabel'),
      newKeyCancelBtn: document.getElementById('newKeyCancelBtn'),
      newKeyPath: document.getElementById('newKeyPath'),
      newKeyPathError: document.getElementById('newKeyPathError'),
      newKeySaveBtn: document.getElementById('newKeySaveBtn'),
      newKeyLocaleFields: document.getElementById('newKeyLocaleFields'),
      displayLanguageModal: document.getElementById('displayLanguageModal'),
      displayLanguageEyebrow: document.getElementById('displayLanguageEyebrow'),
      displayLanguageTitle: document.getElementById('displayLanguageTitle'),
      displayLanguageSubtitle: document.getElementById('displayLanguageSubtitle'),
      displayLanguageSelectLabel: document.getElementById('displayLanguageSelectLabel'),
      displayLanguageSelect: document.getElementById('displayLanguageSelect'),
      displayLanguageCancelBtn: document.getElementById('displayLanguageCancelBtn'),
      displayLanguageConfirmBtn: document.getElementById('displayLanguageConfirmBtn'),
    };

    const systemThemeQuery = typeof window.matchMedia === 'function'
      ? window.matchMedia('(prefers-color-scheme: dark)')
      : null;

    function normalizeDisplayLanguage(value) {
      const normalized = String(value || '').trim().toLowerCase();
      if (!normalized) return '';
      if (normalized === 'zh-cn' || normalized.startsWith('zh-') || normalized === 'zh') {
        return 'zh-CN';
      }
      if (normalized === 'en' || normalized.startsWith('en-')) return 'en';
      if (normalized === 'ar' || normalized.startsWith('ar-')) return 'ar';
      if (normalized === 'tr' || normalized.startsWith('tr-')) return 'tr';
      if (normalized === 'es' || normalized.startsWith('es-')) return 'es';
      if (normalized === 'hi' || normalized.startsWith('hi-')) return 'hi';
      return '';
    }

    function getStoredDisplayLanguage() {
      try {
        const stored = window.localStorage.getItem(DISPLAY_LANGUAGE_STORAGE_KEY);
        const normalized = normalizeDisplayLanguage(stored);
        if (DISPLAY_LANGUAGES.includes(normalized)) {
          return normalized;
        }
      } catch (_) {}
      return '';
    }

    function persistDisplayLanguage(language) {
      try {
        window.localStorage.setItem(DISPLAY_LANGUAGE_STORAGE_KEY, language);
      } catch (_) {}
    }

    function resolveInitialDisplayLanguage() {
      const stored = getStoredDisplayLanguage();
      if (stored) {
        return stored;
      }

      const browserLocales = [];
      if (Array.isArray(window.navigator.languages)) {
        browserLocales.push(...window.navigator.languages);
      }
      if (window.navigator.language) {
        browserLocales.push(window.navigator.language);
      }

      for (const locale of browserLocales) {
        const normalized = normalizeDisplayLanguage(locale);
        if (DISPLAY_LANGUAGES.includes(normalized)) {
          return normalized;
        }
      }

      return 'en';
    }

    function getDisplayLanguageDirection(language) {
      return DISPLAY_LANGUAGE_DIRECTIONS[language] || 'ltr';
    }

    function copyValueForPath(source, keyPath) {
      return keyPath.split('.').reduce((current, segment) => {
        if (current && typeof current === 'object' && segment in current) {
          return current[segment];
        }
        return undefined;
      }, source);
    }

    function t(keyPath, replacements) {
      const activeCopy = CATALOG_COPY[state.displayLanguage] || CATALOG_COPY.en;
      const fallbackValue = copyValueForPath(CATALOG_COPY.en, keyPath);
      const value = copyValueForPath(activeCopy, keyPath);
      const raw = value == null ? fallbackValue : value;
      if (typeof raw !== 'string') {
        return '';
      }

      return raw.replace(/\{([a-zA-Z0-9_]+)\}/g, (_, token) => {
        const replacement = replacements && token in replacements ? replacements[token] : '';
        return String(replacement);
      });
    }

    function localizedStatus(status) {
      return t('statuses.' + (status || 'warning'));
    }

    function localizedReason(reason) {
      return t('reasons.' + reason);
    }

    function getStoredThemeMode() {
      try {
        const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
        if (THEME_MODES.includes(stored)) {
          return stored;
        }
      } catch (_) {}
      return 'system';
    }

    function persistThemeMode(mode) {
      try {
        window.localStorage.setItem(THEME_STORAGE_KEY, mode);
      } catch (_) {}
    }

    function resolveThemeMode(mode) {
      if (mode === 'dark') return 'dark';
      if (mode === 'light') return 'light';
      return systemThemeQuery && systemThemeQuery.matches ? 'dark' : 'light';
    }

    function applyThemeMode(mode) {
      const nextMode = THEME_MODES.includes(mode) ? mode : 'system';
      state.themeMode = nextMode;
      document.documentElement.setAttribute('data-theme', nextMode);
      document.documentElement.style.colorScheme = resolveThemeMode(nextMode);
      if (dom.themeModeSelect && dom.themeModeSelect.value !== nextMode) {
        dom.themeModeSelect.value = nextMode;
      }
    }

    function updateThemeMode(mode) {
      applyThemeMode(mode);
      persistThemeMode(state.themeMode);
    }

    function renderStaticText() {
      document.title = t('pageTitle');
      document.documentElement.lang = state.displayLanguage;
      document.documentElement.dir = getDisplayLanguageDirection(state.displayLanguage);

      dom.catalogTitle.textContent = t('catalogTitle');
      dom.catalogSubtitle.textContent = t('catalogSubtitle');
      dom.searchInput.placeholder = t('searchPlaceholder');
      dom.themeModeLabel.textContent = t('themeLabel');
      dom.themeModeSelect.setAttribute('aria-label', t('themeLabel'));
      dom.themeModeOptionSystem.textContent = t('themeModes.system');
      dom.themeModeOptionLight.textContent = t('themeModes.light');
      dom.themeModeOptionDark.textContent = t('themeModes.dark');
      dom.refreshBtn.textContent = t('refresh');
      dom.newKeyBtn.textContent = t('newString');
      dom.keyListTitle.textContent = t('keysTitle');
      dom.keyListSubtitle.textContent = t('keysSubtitle');

      dom.newKeyEyebrow.textContent = t('newKey.eyebrow');
      dom.newKeyTitle.textContent = t('newKey.title');
      dom.newKeySubtitle.textContent = t('newKey.subtitle');
      dom.newKeyPathLabel.textContent = t('newKey.keyPathLabel');
      dom.newKeyPath.placeholder = t('newKey.keyPathPlaceholder');
      dom.newKeyCancelBtn.textContent = t('actions.cancel');
      dom.newKeySaveBtn.textContent = t('actions.create');

      dom.displayLanguageEyebrow.textContent = t('displayLanguage.eyebrow');
      dom.displayLanguageTitle.textContent = t('displayLanguage.title');
      dom.displayLanguageSubtitle.textContent = t('displayLanguage.subtitle');
      dom.displayLanguageSelectLabel.textContent = t('displayLanguage.label');
      dom.displayLanguageCancelBtn.textContent = t('actions.cancel');
      dom.displayLanguageConfirmBtn.textContent = t('actions.confirm');
      dom.displayLanguageSelect.value = state.pendingDisplayLanguage || state.displayLanguage;
      if (state.meta) {
        renderNewKeyLocaleFields();
      }
    }

    function applyDisplayLanguage(language, options) {
      const nextLanguage = DISPLAY_LANGUAGES.includes(language) ? language : 'en';
      state.displayLanguage = nextLanguage;
      state.pendingDisplayLanguage = nextLanguage;
      renderStaticText();
      if (!options || options.render !== false) {
        render();
      }
    }

    function updateDisplayLanguage(language) {
      applyDisplayLanguage(language);
      persistDisplayLanguage(state.displayLanguage);
    }

    function escapeHtml(value) {
      return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    }

    function cloneValue(value) {
      if (value === undefined) return undefined;
      return JSON.parse(JSON.stringify(value));
    }

    function sortKeys(value) {
      if (Array.isArray(value)) {
        return value.map(sortKeys);
      }
      if (value && typeof value === 'object') {
        const sorted = {};
        Object.keys(value).sort().forEach((key) => {
          sorted[key] = sortKeys(value[key]);
        });
        return sorted;
      }
      return value;
    }

    function canonicalize(value) {
      if (value == null) return 'null';
      if (typeof value === 'string') return JSON.stringify(value);
      if (typeof value === 'number' || typeof value === 'boolean') return String(value);
      if (Array.isArray(value)) return '[' + value.map(canonicalize).join(',') + ']';
      if (typeof value === 'object') {
        const sorted = sortKeys(value);
        return '{' + Object.keys(sorted).map((key) => JSON.stringify(key) + ':' + canonicalize(sorted[key])).join(',') + '}';
      }
      return JSON.stringify(String(value));
    }

    function isCatalogValueEmpty(value) {
      if (value == null) return true;
      if (typeof value === 'string') return value.trim() === '';
      if (Array.isArray(value)) return value.length === 0;
      if (typeof value === 'object') return Object.keys(value).length === 0;
      return false;
    }

    function isPlainObject(value) {
      return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
    }

    function isPrimitiveLeaf(value) {
      return value == null || typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean';
    }

    function formatLocale(locale) {
      return String(locale || '').toUpperCase();
    }

    function getDirection(locale) {
      if (!state.meta) return 'ltr';
      return state.meta.localeDirections[locale] || 'ltr';
    }

    function formatTimestamp(value) {
      if (!value) return '';
      try {
        return new Date(value).toLocaleString(state.displayLanguage);
      } catch (_) {
        return '';
      }
    }

    function prettyJson(value) {
      return JSON.stringify(value, null, 2);
    }

    function getDefaultEditorLocale() {
      if (!state.meta) return '';
      const target = state.meta.locales.find((locale) => locale !== state.meta.sourceLocale);
      return target || state.meta.sourceLocale;
    }

    function getRowByKey(keyPath) {
      return state.rows.find((row) => row.keyPath === keyPath) || null;
    }

    function draftId(keyPath, locale) {
      return keyPath + '::' + locale;
    }

    function normalizedPluralKeys(value) {
      if (!isPlainObject(value)) return [];
      const existing = Object.keys(value);
      const canonical = PLURAL_KEYS.filter((key) => existing.includes(key));
      const extra = existing.filter((key) => !canonical.includes(key)).sort();
      return [...canonical, ...extra];
    }

    function normalizedGenderKeys(value) {
      if (!isPlainObject(value)) return [];
      const existing = Object.keys(value);
      const canonical = GENDER_KEYS.filter((key) => existing.includes(key));
      const extra = existing.filter((key) => !canonical.includes(key)).sort();
      return [...canonical, ...extra];
    }

    function detectSupportedShape(value) {
      if (!isPlainObject(value)) return 'plain';
      const keys = Object.keys(value);
      if (!keys.length) return 'raw';
      if (keys.every((key) => GENDER_KEYS.includes(key)) && keys.every((key) => isPrimitiveLeaf(value[key]))) {
        return 'gender';
      }
      if (keys.every((key) => PLURAL_KEYS.includes(key)) && keys.every((key) => isPrimitiveLeaf(value[key]))) {
        return 'plural';
      }
      if (
        keys.every((key) => PLURAL_KEYS.includes(key)) &&
        keys.every((key) => isPlainObject(value[key])) &&
        keys.every((key) => Object.keys(value[key]).every((genderKey) => GENDER_KEYS.includes(genderKey))) &&
        keys.every((key) => Object.keys(value[key]).every((genderKey) => isPrimitiveLeaf(value[key][genderKey])))
      ) {
        return 'pluralGender';
      }
      return 'raw';
    }

    function detectEditorMode(serverValue, sourceValue, rawPinned) {
      if (rawPinned) return 'raw';
      const candidate = !isCatalogValueEmpty(serverValue) ? serverValue : sourceValue;
      const mode = detectSupportedShape(candidate);
      return mode === 'raw' ? 'raw' : mode;
    }

    function emptyTemplateFromShape(sourceShape) {
      const mode = detectSupportedShape(sourceShape);
      if (mode === 'gender') {
        const result = {};
        normalizedGenderKeys(sourceShape).forEach((key) => {
          result[key] = '';
        });
        return result;
      }
      if (mode === 'plural') {
        const result = {};
        normalizedPluralKeys(sourceShape).forEach((key) => {
          result[key] = '';
        });
        return result;
      }
      if (mode === 'pluralGender') {
        const result = {};
        normalizedPluralKeys(sourceShape).forEach((pluralKey) => {
          result[pluralKey] = {};
          normalizedGenderKeys(sourceShape[pluralKey]).forEach((genderKey) => {
            result[pluralKey][genderKey] = '';
          });
        });
        return result;
      }
      return '';
    }

    function buildInitialValue(serverValue, sourceValue, editorMode) {
      if (!isCatalogValueEmpty(serverValue)) {
        return cloneValue(serverValue);
      }
      if (editorMode === 'gender' || editorMode === 'plural' || editorMode === 'pluralGender') {
        return emptyTemplateFromShape(sourceValue);
      }
      if (typeof serverValue === 'number' || typeof serverValue === 'boolean') {
        return serverValue;
      }
      return typeof serverValue === 'string' ? serverValue : '';
    }

    function getOrCreateDraft(row, locale) {
      const id = draftId(row.keyPath, locale);
      let draft = state.drafts[id];
      const sourceValue = row.valuesByLocale[state.meta.sourceLocale];

      if (!draft) {
        const editorMode = detectEditorMode(row.valuesByLocale[locale], sourceValue, false);
        const initialValue = buildInitialValue(row.valuesByLocale[locale], sourceValue, editorMode);
        draft = {
          keyPath: row.keyPath,
          locale,
          baseValue: cloneValue(row.valuesByLocale[locale]),
          value: cloneValue(initialValue),
          editorMode,
          rawPinned: editorMode === 'raw',
          rawText: prettyJson(initialValue),
          rawError: '',
          syncState: 'clean',
          errorMessage: '',
          touched: false,
          timerId: 0,
          savedResetId: 0,
        };
        state.drafts[id] = draft;
      }

      if (draft.syncState === 'clean' || draft.syncState === 'saved') {
        const editorMode = detectEditorMode(row.valuesByLocale[locale], sourceValue, draft.rawPinned);
        const initialValue = buildInitialValue(row.valuesByLocale[locale], sourceValue, editorMode);
        draft.baseValue = cloneValue(row.valuesByLocale[locale]);
        draft.value = cloneValue(initialValue);
        draft.editorMode = editorMode;
        draft.rawPinned = editorMode === 'raw';
        draft.rawText = prettyJson(initialValue);
        draft.rawError = '';
        draft.errorMessage = '';
        draft.touched = false;
      }

      return draft;
    }

    function getCurrentDraft() {
      const row = getRowByKey(state.selectedKey);
      if (!row || !state.selectedLocale) return null;
      return getOrCreateDraft(row, state.selectedLocale);
    }

    function isDraftDirty(draft) {
      if (!draft) return false;
      if (!draft.touched && isCatalogValueEmpty(draft.baseValue) && canonicalize(draft.value) !== canonicalize(draft.baseValue)) {
        return false;
      }
      return canonicalize(draft.value) !== canonicalize(draft.baseValue);
    }

    function setDraftSyncState(draft, syncState, errorMessage) {
      draft.syncState = syncState;
      draft.errorMessage = errorMessage || '';
    }

    function scheduleSavedReset(draft) {
      if (draft.savedResetId) {
        clearTimeout(draft.savedResetId);
      }
      draft.savedResetId = setTimeout(() => {
        if (draft.syncState === 'saved') {
          draft.syncState = 'clean';
          render();
        }
      }, 1200);
    }

    function collectPlaceholders(value, output) {
      if (!output) output = new Set();
      if (typeof value === 'string') {
        const matches = value.matchAll(/\{([a-zA-Z0-9_]+)\}/g);
        for (const match of matches) {
          output.add(match[1]);
        }
        return output;
      }
      if (Array.isArray(value)) {
        value.forEach((item) => collectPlaceholders(item, output));
        return output;
      }
      if (isPlainObject(value)) {
        Object.values(value).forEach((item) => collectPlaceholders(item, output));
      }
      return output;
    }

    function readPath(value, path) {
      if (!path.length) return value;
      let current = value;
      for (const key of path) {
        if (!isPlainObject(current) || !(key in current)) {
          return '';
        }
        current = current[key];
      }
      return current;
    }

    function requiredPathsForValue(sourceValue, currentValue, editorMode) {
      const basis = !isCatalogValueEmpty(sourceValue) ? sourceValue : currentValue;
      if (editorMode === 'gender') {
        return normalizedGenderKeys(basis).map((key) => [key]);
      }
      if (editorMode === 'plural') {
        return normalizedPluralKeys(basis).map((key) => [key]);
      }
      if (editorMode === 'pluralGender') {
        return normalizedPluralKeys(basis).flatMap((pluralKey) => {
          const nestedBasis = (basis && basis[pluralKey]) || {};
          return normalizedGenderKeys(nestedBasis).map((genderKey) => [pluralKey, genderKey]);
        });
      }
      return [[]];
    }

    function validateDraftForDone(draft, row, locale) {
      const blockers = [];
      if (!draft || !row) return blockers;
      if (locale === state.meta.sourceLocale) return blockers;
      if (draft.rawError) {
        blockers.push(t('blockers.advancedJsonInvalid'));
        return blockers;
      }
      if (draft.syncState === 'dirty' || draft.syncState === 'saving' || draft.syncState === 'save_error') {
        blockers.push(t('blockers.waitAutosave'));
      }
      if (isCatalogValueEmpty(draft.value)) {
        blockers.push(t('blockers.translationEmpty'));
      }

      const editorMode = draft.editorMode;
      const requiredPaths = requiredPathsForValue(row.valuesByLocale[state.meta.sourceLocale], draft.value, editorMode);
      const missingBranches = requiredPaths.filter((path) => {
        const branchValue = readPath(draft.value, path);
        return typeof branchValue !== 'string' ? branchValue == null : branchValue.trim() === '';
      });
      if (missingBranches.length && editorMode !== 'raw') {
        blockers.push(t('blockers.fillVisibleBranches'));
      }

      const sourcePlaceholders = collectPlaceholders(row.valuesByLocale[state.meta.sourceLocale], new Set());
      const targetPlaceholders = collectPlaceholders(draft.value, new Set());
      const missingPlaceholders = [...sourcePlaceholders].filter((item) => !targetPlaceholders.has(item));
      if (missingPlaceholders.length) {
        blockers.push(t('blockers.missingPlaceholders', {
          placeholders: missingPlaceholders.map((item) => '{' + item + '}').join(', '),
        }));
      }
      return blockers;
    }

    function syncLabelForState(syncState) {
      return t('sync.' + (syncState || 'clean'));
    }

    function statusClass(status) {
      return 'status-' + (status || 'warning');
    }

    function getVisibleRowStatus(row) {
      const syncState = getRowSyncState(row.keyPath);
      if (syncState === 'dirty' || syncState === 'saving' || syncState === 'save_error') {
        return 'warning';
      }
      return row.rowStatus || 'warning';
    }

    function getRowSyncState(keyPath) {
      const drafts = Object.values(state.drafts).filter((draft) => draft.keyPath === keyPath);
      if (drafts.some((draft) => draft.syncState === 'save_error')) return 'save_error';
      if (drafts.some((draft) => draft.syncState === 'saving')) return 'saving';
      if (drafts.some((draft) => draft.syncState === 'dirty')) return 'dirty';
      if (drafts.some((draft) => draft.syncState === 'saved')) return 'saved';
      return 'clean';
    }

    function filteredRows() {
      const query = state.search.trim().toLowerCase();
      return state.rows.filter((row) => {
        if (state.statusFilter && getVisibleRowStatus(row) !== state.statusFilter) {
          return false;
        }
        if (!query) {
          return true;
        }
        if (row.keyPath.toLowerCase().includes(query)) {
          return true;
        }
        return Object.values(row.valuesByLocale).some((value) => {
          const haystack = typeof value === 'object' ? JSON.stringify(value) : String(value ?? '');
          return haystack.toLowerCase().includes(query);
        });
      });
    }

    function ensureSelection() {
      if (!state.rows.length) {
        state.selectedKey = '';
        return;
      }
      if (!getRowByKey(state.selectedKey)) {
        state.selectedKey = state.rows[0].keyPath;
      }
      if (!state.selectedLocale || !state.meta.locales.includes(state.selectedLocale)) {
        state.selectedLocale = getDefaultEditorLocale();
      }
    }

    function toast(message, kind) {
      const id = Math.random().toString(36).slice(2);
      state.toasts = [...state.toasts, {id, message, kind: kind || 'info'}];
      renderToasts();
      dom.srAnnouncer.textContent = message;
      setTimeout(() => {
        state.toasts = state.toasts.filter((item) => item.id !== id);
        renderToasts();
      }, 2800);
    }

    function renderToasts() {
      dom.toastHost.innerHTML = state.toasts.map((item) => {
        return '<div class="toast ' + (item.kind === 'error' ? 'toast-error' : '') + '">' + escapeHtml(item.message) + '</div>';
      }).join('');
    }

    function renderMeta() {
      if (!state.meta) {
        dom.metaBadges.innerHTML = '';
        return;
      }
      dom.metaBadges.innerHTML = [
        '<button class="pill meta-badge-button" type="button" data-action="open-display-language-modal">' +
          escapeHtml(t('meta.catalogLanguageButton', {language: formatLocale(state.displayLanguage)})) +
        '</button>',
        '<span class="pill">' + escapeHtml(t('meta.locales', {count: state.meta.locales.length})) + '</span>',
        '<span class="pill">' + escapeHtml(t('meta.keys', {count: state.summary ? state.summary.totalKeys : 0})) + '</span>',
      ].join('');
    }

    function renderStatusFilters() {
      const counts = state.summary || {totalKeys: 0, greenRows: 0, warningRows: 0, redRows: 0};
      const items = [
        {status: '', label: t('filters.all'), count: counts.totalKeys},
        {status: 'green', label: localizedStatus('green'), count: counts.greenRows},
        {status: 'warning', label: localizedStatus('warning'), count: counts.warningRows},
        {status: 'red', label: localizedStatus('red'), count: counts.redRows},
      ];
      dom.statusFilters.innerHTML = items.map((item) => {
        const pressed = state.statusFilter === item.status;
        return '<button class="filter-button" aria-pressed="' + pressed + '" data-action="filter-status" data-status="' + item.status + '">' +
          escapeHtml(item.label + ' (' + item.count + ')') +
        '</button>';
      }).join('');
    }

    function renderSummary() {
      const visibleRows = filteredRows();
      dom.visibleKeyCount.textContent = t('summary.visible', {count: visibleRows.length});

      const counts = state.summary || {greenRows: 0, warningRows: 0, redRows: 0};
      dom.summaryCounts.innerHTML = [
        '<span class="count-chip">' + escapeHtml(t('summary.ready', {count: counts.greenRows})) + '</span>',
        '<span class="count-chip">' + escapeHtml(t('summary.needsReview', {count: counts.warningRows})) + '</span>',
        '<span class="count-chip">' + escapeHtml(t('summary.missing', {count: counts.redRows})) + '</span>',
      ].join('');

      if (state.loading) {
        dom.activeFilterSummary.textContent = t('summary.loading');
        return;
      }

      if (!visibleRows.length) {
        dom.activeFilterSummary.textContent = t('summary.noMatches');
        return;
      }

      const activeStatusLabel = state.statusFilter ? localizedStatus(state.statusFilter) : t('filters.all');
      const searchSuffix = state.search ? t('summary.searchSuffix', {query: state.search}) : '';
      dom.activeFilterSummary.textContent = t('summary.rowsVisible', {
        count: visibleRows.length,
        filter: activeStatusLabel,
        searchSuffix,
      });
    }

    function renderKeyList() {
      if (state.error) {
        dom.keyListPanel.innerHTML =
          '<div class="error-banner"><strong>' + escapeHtml(t('errors.catalogFailedToLoad')) + '</strong><p>' + escapeHtml(state.error) + '</p>' +
          '<div><button class="subtle-button" data-action="refresh">' + escapeHtml(t('actions.retry')) + '</button></div></div>';
        return;
      }

      if (state.loading) {
        dom.keyListPanel.innerHTML = new Array(6).fill(0).map(() => '<div class="skeleton"></div>').join('');
        return;
      }

      const rows = filteredRows();
      if (!rows.length) {
        dom.keyListPanel.innerHTML =
          '<div class="empty-state"><strong>' + escapeHtml(t('emptyStates.noMatchingKeysTitle')) + '</strong><p>' + escapeHtml(t('emptyStates.noMatchingKeysBody')) + '</p>' +
          '<div><button class="subtle-button" data-action="clear-filters">' + escapeHtml(t('actions.clearFilters')) + '</button></div></div>';
        return;
      }

      dom.keyListPanel.innerHTML = rows.map((row) => {
        const selected = row.keyPath === state.selectedKey;
        const visibleStatus = getVisibleRowStatus(row);
        const syncState = getRowSyncState(row.keyPath);
        const pendingText = row.missingLocales.length
          ? t('list.missingCount', {count: row.missingLocales.length, locales: row.missingLocales.join(', ').toUpperCase()})
          : row.pendingLocales.length
            ? t('list.pendingCount', {count: row.pendingLocales.length, locales: row.pendingLocales.join(', ').toUpperCase()})
            : t('list.allTargetsDone');

        return '<button class="row-button ' + (selected ? 'is-selected' : '') + '" data-action="select-row" data-key-path="' + escapeHtml(row.keyPath) + '">' +
          '<div class="row-topline">' +
            '<span class="row-key">' + escapeHtml(row.keyPath) + '</span>' +
            '<span class="status-chip ' + statusClass(visibleStatus) + '">' + escapeHtml(localizedStatus(visibleStatus)) + '</span>' +
          '</div>' +
          '<div class="row-meta">' +
            '<span class="pill">' + escapeHtml(pendingText) + '</span>' +
            '<span class="sync-chip sync-' + syncState + '">' + escapeHtml(syncLabelForState(syncState)) + '</span>' +
          '</div>' +
        '</button>';
      }).join('');
    }

    function renderSourceReferenceValue(value, locale) {
      const mode = detectSupportedShape(value);
      if (mode === 'gender') {
        return '<div class="field-stack">' + normalizedGenderKeys(value).map((key) => {
          return '<div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(key) + '</strong></div><div class="source-branch-preview" dir="' + escapeHtml(getDirection(locale)) + '">' +
            escapeHtml(value[key] ?? '') + '</div></div>';
        }).join('') + '</div>';
      }
      if (mode === 'plural') {
        return '<div class="field-stack">' + normalizedPluralKeys(value).map((key) => {
          return '<div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(key) + '</strong></div><div class="source-branch-preview" dir="' + escapeHtml(getDirection(locale)) + '">' +
            escapeHtml(value[key] ?? '') + '</div></div>';
        }).join('') + '</div>';
      }
      if (mode === 'pluralGender') {
        return '<div class="field-stack">' + normalizedPluralKeys(value).map((pluralKey) => {
          return '<div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(pluralKey) + '</strong></div><div class="branch-grid">' +
            normalizedGenderKeys(value[pluralKey]).map((genderKey) => {
              return '<div><div class="field-label"><span>' + escapeHtml(genderKey) + '</span></div><div class="source-branch-preview" dir="' + escapeHtml(getDirection(locale)) + '">' +
                escapeHtml(value[pluralKey][genderKey] ?? '') + '</div></div>';
            }).join('') +
          '</div></div>';
        }).join('') + '</div>';
      }
      const preview = typeof value === 'object' ? prettyJson(value) : String(value ?? '');
      return '<div class="source-preview mono-note" dir="' + escapeHtml(getDirection(locale)) + '">' + escapeHtml(preview) + '</div>';
    }

    function renderSourceCard(row, activeLocale) {
      if (activeLocale === state.meta.sourceLocale) {
        return '<div class="source-card"><p class="eyebrow">' + escapeHtml(t('editor.sourceImpact')) + '</p><div class="source-summary"><p>' + escapeHtml(t('editor.sourceImpactBody')) + '</p></div></div>';
      }
      return '<div class="source-card"><p class="eyebrow">' + escapeHtml(t('editor.sourceReference', {locale: formatLocale(state.meta.sourceLocale)})) + '</p>' +
        renderSourceReferenceValue(row.valuesByLocale[state.meta.sourceLocale], state.meta.sourceLocale) +
      '</div>';
    }

    function renderReasonCard(row, locale, draft) {
      const cell = row.cellStates[locale] || {};
      const doneBlockers = validateDraftForDone(draft, row, locale);
      const lines = [];
      if (cell.reason && localizedReason(cell.reason)) {
        lines.push('<div class="reason-card"><strong>' + escapeHtml(localizedReason(cell.reason)) + '</strong>' +
          '<p class="status-note">' + escapeHtml(localizedStatus(cell.status || 'warning')) + '</p>' +
          (cell.lastEditedAt ? '<p class="status-note">' + escapeHtml(t('editor.lastEdit', {value: formatTimestamp(cell.lastEditedAt)})) + '</p>' : '') +
          (cell.lastReviewedAt ? '<p class="status-note">' + escapeHtml(t('editor.lastDone', {value: formatTimestamp(cell.lastReviewedAt)})) + '</p>' : '') +
        '</div>');
      } else if (cell.lastReviewedAt) {
        lines.push('<div class="reason-card"><strong>' + escapeHtml(t('editor.reviewedAndReady')) + '</strong><p class="status-note">' + escapeHtml(t('editor.lastDone', {value: formatTimestamp(cell.lastReviewedAt)})) + '</p></div>');
      }
      if (doneBlockers.length) {
        lines.push('<div class="warning-card"><strong>' + escapeHtml(t('editor.doneBlocked')) + '</strong><p>' + escapeHtml(doneBlockers[0]) + '</p></div>');
      }
      if (draft.syncState === 'save_error' && draft.errorMessage) {
        lines.push('<div class="warning-card"><strong>' + escapeHtml(t('editor.autosaveFailed')) + '</strong><p>' + escapeHtml(draft.errorMessage) + '</p>' +
          '<div><button class="mini-button" data-action="retry-save" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">' + escapeHtml(t('actions.retrySave')) + '</button></div></div>');
      }
      return lines.join('');
    }

    function renderBranchField(row, locale, path, label, draftValue) {
      const sourceValue = readPath(row.valuesByLocale[state.meta.sourceLocale], path);
      const pathKey = path.join('.');
      const value = typeof draftValue === 'string' || typeof draftValue === 'number' || typeof draftValue === 'boolean'
        ? String(draftValue ?? '')
        : '';
      return '<div class="branch-card">' +
        '<div class="branch-label"><strong>' + escapeHtml(label) + '</strong><span>' + escapeHtml(pathKey) + '</span></div>' +
        (locale === state.meta.sourceLocale ? '' : '<div class="source-branch-preview" dir="' + escapeHtml(getDirection(state.meta.sourceLocale)) + '">' + escapeHtml(sourceValue ?? '') + '</div>') +
        '<textarea class="field-textarea" data-field-kind="branch" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-path="' + escapeHtml(pathKey) + '" dir="' + escapeHtml(getDirection(locale)) + '" data-editor-size="compact" placeholder="' + escapeHtml(t('editor.enterLocalizedCopy')) + '">' + escapeHtml(value) + '</textarea>' +
      '</div>';
    }

    function renderPluralAddActions(row, locale, draft) {
      const existing = new Set(normalizedPluralKeys(draft.value));
      const source = row.valuesByLocale[state.meta.sourceLocale];
      const sourceKeys = detectSupportedShape(source) === 'plural' || detectSupportedShape(source) === 'pluralGender'
        ? normalizedPluralKeys(source)
        : [];
      const candidates = [...new Set([...PLURAL_KEYS, ...sourceKeys])].filter((key) => !existing.has(key));
      if (!candidates.length) return '';
      return '<div class="add-actions">' + candidates.map((category) => {
        return '<button class="mini-button" data-action="add-plural" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-category="' + escapeHtml(category) + '">' + escapeHtml(t('editor.addAction', {item: category})) + '</button>';
      }).join('') + '</div>';
    }

    function renderGenderAddActions(row, locale, draft, category) {
      const existing = new Set(normalizedGenderKeys(category ? draft.value[category] : draft.value));
      const sourceValue = category ? readPath(row.valuesByLocale[state.meta.sourceLocale], [category]) : row.valuesByLocale[state.meta.sourceLocale];
      const sourceKeys = detectSupportedShape(sourceValue) === 'gender' ? normalizedGenderKeys(sourceValue) : GENDER_KEYS;
      const candidates = [...new Set([...GENDER_KEYS, ...sourceKeys])].filter((key) => !existing.has(key));
      if (!candidates.length) return '';
      return '<div class="add-actions">' + candidates.map((gender) => {
        return '<button class="mini-button" data-action="add-gender" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-category="' + escapeHtml(category || '') + '" data-gender="' + escapeHtml(gender) + '">' + escapeHtml(t('editor.addAction', {item: gender})) + '</button>';
      }).join('') + '</div>';
    }

    function renderEditorFields(row, locale, draft) {
      if (draft.editorMode === 'raw') {
        return '<div class="warning-card"><strong>' + escapeHtml(t('editor.advancedJsonEditor')) + '</strong><p>' + escapeHtml(t('editor.advancedJsonEditorBody')) + '</p></div>';
      }

      if (draft.editorMode === 'gender') {
        return '<div class="field-stack">' +
          normalizedGenderKeys(draft.value).map((key) => renderBranchField(row, locale, [key], key, draft.value[key])).join('') +
          renderGenderAddActions(row, locale, draft, '') +
        '</div>';
      }

      if (draft.editorMode === 'plural') {
        return '<div class="field-stack">' +
          normalizedPluralKeys(draft.value).map((key) => renderBranchField(row, locale, [key], key, draft.value[key])).join('') +
          renderPluralAddActions(row, locale, draft) +
        '</div>';
      }

      if (draft.editorMode === 'pluralGender') {
        return '<div class="field-stack">' +
          normalizedPluralKeys(draft.value).map((pluralKey) => {
            return '<div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(pluralKey) + '</strong><span>' + escapeHtml(t('editor.pluralBranch')) + '</span></div>' +
              '<div class="branch-grid">' +
                normalizedGenderKeys(draft.value[pluralKey]).map((genderKey) => {
                  return renderBranchField(row, locale, [pluralKey, genderKey], genderKey, draft.value[pluralKey][genderKey]);
                }).join('') +
              '</div>' +
              renderGenderAddActions(row, locale, draft, pluralKey) +
            '</div>';
          }).join('') +
          renderPluralAddActions(row, locale, draft) +
        '</div>';
      }

      const textValue = draft.value == null ? '' : String(draft.value);
      return '<div class="field-stack"><div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(t('editor.translation')) + '</strong>' +
        (locale === state.meta.sourceLocale ? '<span>' + escapeHtml(t('editor.sourceLocale')) + '</span>' : '<span>' + escapeHtml(t('editor.autosavesAfter')) + '</span>') +
        '</div>' +
        '<textarea class="field-textarea" data-field-kind="plain" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" dir="' + escapeHtml(getDirection(locale)) + '" placeholder="' + escapeHtml(t('editor.enterLocalizedCopy')) + '">' +
          escapeHtml(textValue) +
        '</textarea>' +
      '</div></div>';
    }

    function renderAdvancedJson(row, locale, draft) {
      const open = draft.rawPinned || Boolean(draft.rawError);
      return '<details class="advanced-json" ' + (open ? 'open' : '') + '>' +
        '<summary>' + escapeHtml(t('editor.advancedJson')) + '<span class="muted-copy">' + escapeHtml(t('editor.advancedJsonSubtitle')) + '</span></summary>' +
        '<div class="advanced-json-body">' +
          '<p class="helper-text">' + escapeHtml(t('editor.advancedJsonHelp')) + '</p>' +
          '<textarea class="mono-note" data-field-kind="advanced-json" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" dir="ltr" placeholder="{}">' + escapeHtml(draft.rawText) + '</textarea>' +
          (draft.rawError ? '<div class="inline-error">' + escapeHtml(draft.rawError) + '</div>' : '') +
        '</div>' +
      '</details>';
    }

    function renderEditor() {
      if (state.error) {
        dom.editorPane.innerHTML = '';
        return;
      }

      if (state.loading) {
        dom.editorPane.innerHTML = '<div class="skeleton" style="min-height: 34rem;"></div>';
        return;
      }

      if (!state.rows.length) {
        dom.editorPane.innerHTML =
          '<div class="empty-state"><strong>' + escapeHtml(t('emptyStates.noKeysYetTitle')) + '</strong><p>' + escapeHtml(t('emptyStates.noKeysYetBody')) + '</p>' +
          '<div><button class="primary-button" data-action="open-modal">' + escapeHtml(t('newString')) + '</button></div></div>';
        return;
      }

      const row = getRowByKey(state.selectedKey) || state.rows[0];
      if (!row) {
        dom.editorPane.innerHTML = '';
        return;
      }

      const locale = state.selectedLocale || getDefaultEditorLocale();
      const draft = getOrCreateDraft(row, locale);
      const currentCell = row.cellStates[locale] || {status: 'warning'};
      const doneBlockers = validateDraftForDone(draft, row, locale);
      const doneDisabled = locale === state.meta.sourceLocale || doneBlockers.length > 0;
      const reviewed = locale !== state.meta.sourceLocale && currentCell.status === 'green' && !doneBlockers.length;

      dom.editorPane.innerHTML =
        '<div class="editor-card" id="detailPanel">' +
          '<div class="editor-header">' +
            '<div class="editor-keyline">' +
              '<div><p class="eyebrow">' + escapeHtml(t('editor.selectedKey')) + '</p><p class="editor-key">' + escapeHtml(row.keyPath) + '</p></div>' +
              '<div class="editor-actions">' +
                '<span class="status-chip ' + statusClass(getVisibleRowStatus(row)) + '">' + escapeHtml(localizedStatus(getVisibleRowStatus(row))) + '</span>' +
                '<button class="danger-button" data-action="delete-key" data-key-path="' + escapeHtml(row.keyPath) + '">' + escapeHtml(t('actions.deleteKey')) + '</button>' +
              '</div>' +
            '</div>' +
            '<p class="editor-subtle">' +
              (row.missingLocales.length
                ? escapeHtml(t('list.missingSummary', {locales: row.missingLocales.join(', ').toUpperCase()}))
                : row.pendingLocales.length
                  ? escapeHtml(t('list.pendingSummary', {locales: row.pendingLocales.join(', ').toUpperCase()}))
                  : escapeHtml(t('list.allTargetsReady'))) +
            '</p>' +
          '</div>' +

          renderSourceCard(row, locale) +

          '<div class="pane-card">' +
            '<div class="editor-topline">' +
              '<div class="section-heading"><h2>' + escapeHtml(t('editor.editorTitle', {locale: formatLocale(locale)})) + '</h2><p class="helper-text">' + escapeHtml(t('editor.editorHelp')) + '</p></div>' +
              '<div class="editor-actions">' +
                '<span class="sync-chip sync-' + draft.syncState + '">' + escapeHtml(syncLabelForState(draft.syncState)) + '</span>' +
                (locale === state.meta.sourceLocale
                  ? '<span class="pill">' + escapeHtml(t('editor.sourceStaysGreen')) + '</span>'
                  : reviewed
                    ? '<span class="status-chip status-green">' + escapeHtml(t('editor.reviewed')) + '</span>'
                    : '<button class="primary-button" data-action="mark-done" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '"' + (doneDisabled ? ' disabled' : '') + '>' + escapeHtml(t('actions.done')) + '</button>') +
              '</div>' +
            '</div>' +

            '<div class="locale-tabs">' + state.meta.locales.map((item) => {
              const isActive = item === locale;
              const status = row.cellStates[item] ? row.cellStates[item].status : 'warning';
              return '<button class="tab-button ' + (isActive ? 'is-active' : '') + '" data-action="select-locale" data-locale="' + escapeHtml(item) + '">' +
                escapeHtml(formatLocale(item)) + ' · ' + escapeHtml(localizedStatus(status)) +
              '</button>';
            }).join('') + '</div>' +

            renderReasonCard(row, locale, draft) +
            renderEditorFields(row, locale, draft) +
            renderAdvancedJson(row, locale, draft) +

            '<div class="editor-footer">' +
              '<button class="danger-link" data-action="delete-locale" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">' +
                escapeHtml(locale === state.meta.sourceLocale ? t('editor.deleteSourceValue') : t('editor.deleteLocaleValue', {locale: formatLocale(locale)})) +
              '</button>' +
            '</div>' +
          '</div>' +
        '</div>';
    }

    function renderNewKeyLocaleFields() {
      if (!state.meta) {
        dom.newKeyLocaleFields.innerHTML = '';
        return;
      }
      const orderedLocales = [state.meta.sourceLocale, ...state.meta.locales.filter((locale) => locale !== state.meta.sourceLocale)];
      dom.newKeyLocaleFields.innerHTML = orderedLocales.map((locale) => {
        const sourceBadge = locale === state.meta.sourceLocale ? '<span class="pill">' + escapeHtml(t('newKey.sourceBadge')) + '</span>' : '';
        return '<div class="modal-field"><label for="newKeyValue_' + escapeHtml(locale) + '">' +
          '<span>' + escapeHtml(formatLocale(locale)) + '</span>' + sourceBadge +
        '</label>' +
        '<textarea class="field-textarea" id="newKeyValue_' + escapeHtml(locale) + '" data-modal-locale="' + escapeHtml(locale) + '" dir="' + escapeHtml(getDirection(locale)) + '" data-editor-size="compact" placeholder="' + escapeHtml(t('newKey.optionalInitialValue')) + '"></textarea></div>';
      }).join('');
    }

    function render() {
      renderMeta();
      renderStatusFilters();
      renderSummary();
      renderKeyList();
      renderEditor();
    }

    async function fetchJson(path, options) {
      const response = await fetch(API_URL + path, {
        headers: {'Content-Type': 'application/json'},
        ...options,
      });
      const text = await response.text();
      const payload = text ? JSON.parse(text) : {};
      if (!response.ok) {
        throw new Error(payload.error || ('HTTP ' + response.status));
      }
      return payload;
    }

    async function refreshSummary() {
      state.summary = await fetchJson('/api/catalog/summary');
    }

    function sortRows(rows) {
      rows.sort((a, b) => a.keyPath.localeCompare(b.keyPath));
      return rows;
    }

    async function loadCatalog() {
      state.loading = true;
      state.error = '';
      render();
      try {
        const requests = state.meta
          ? [fetchJson('/api/catalog/rows'), fetchJson('/api/catalog/summary')]
          : [fetchJson('/api/catalog/meta'), fetchJson('/api/catalog/rows'), fetchJson('/api/catalog/summary')];

        const results = await Promise.all(requests);
        if (!state.meta) {
          state.meta = results[0];
          state.rows = sortRows(results[1].rows || []);
          state.summary = results[2];
          renderNewKeyLocaleFields();
        } else {
          state.rows = sortRows(results[0].rows || []);
          state.summary = results[1];
        }
        ensureSelection();
      } catch (error) {
        state.error = error.message || String(error);
      } finally {
        state.loading = false;
        render();
      }
    }

    function upsertRow(row) {
      const existingIndex = state.rows.findIndex((item) => item.keyPath === row.keyPath);
      if (existingIndex >= 0) {
        state.rows.splice(existingIndex, 1, row);
      } else {
        state.rows.push(row);
      }
      sortRows(state.rows);
      ensureSelection();
      render();
    }

    function removeRow(keyPath) {
      state.rows = state.rows.filter((row) => row.keyPath !== keyPath);
      Object.keys(state.drafts).forEach((id) => {
        if (id.startsWith(keyPath + '::')) {
          delete state.drafts[id];
        }
      });
      ensureSelection();
      render();
    }

    function updateDraftFromValue(row, locale, nextValue, options) {
      const draft = getOrCreateDraft(row, locale);
      draft.value = cloneValue(nextValue);
      draft.rawText = prettyJson(nextValue);
      draft.rawError = '';
      draft.editorMode = detectEditorMode(nextValue, row.valuesByLocale[state.meta.sourceLocale], false);
      draft.rawPinned = draft.editorMode === 'raw';
      draft.touched = true;
      if (draft.savedResetId) {
        clearTimeout(draft.savedResetId);
      }
      setDraftSyncState(draft, 'dirty', '');
      if (draft.timerId) {
        clearTimeout(draft.timerId);
      }
      draft.timerId = setTimeout(() => {
        flushDraft(row.keyPath, locale).catch(() => {});
      }, 700);
      if (!options || options.render !== false) {
        render();
      }
      return draft;
    }

    function parsePlainValue(text, draft) {
      if (typeof draft.baseValue === 'number') {
        const parsed = Number(text);
        return Number.isFinite(parsed) && text.trim() !== '' ? parsed : text;
      }
      if (typeof draft.baseValue === 'boolean') {
        if (text.trim() === 'true') return true;
        if (text.trim() === 'false') return false;
      }
      return text;
    }

    function setNestedValue(root, path, value) {
      if (!path.length) {
        return value;
      }
      const next = cloneValue(root) || {};
      let current = next;
      for (let index = 0; index < path.length - 1; index += 1) {
        const key = path[index];
        if (!isPlainObject(current[key])) {
          current[key] = {};
        }
        current = current[key];
      }
      current[path[path.length - 1]] = value;
      return next;
    }

    async function flushDraft(keyPath, locale) {
      const row = getRowByKey(keyPath);
      if (!row) return;
      const draft = getOrCreateDraft(row, locale);
      if (draft.timerId) {
        clearTimeout(draft.timerId);
        draft.timerId = 0;
      }
      if (!isDraftDirty(draft) || draft.rawError) {
        render();
        return;
      }
      setDraftSyncState(draft, 'saving', '');
      render();
      try {
        const updatedRow = await fetchJson('/api/catalog/cell', {
          method: 'PATCH',
          body: JSON.stringify({
            keyPath,
            locale,
            value: draft.value,
          }),
        });
        draft.baseValue = cloneValue(updatedRow.valuesByLocale[locale]);
        draft.value = buildInitialValue(updatedRow.valuesByLocale[locale], updatedRow.valuesByLocale[state.meta.sourceLocale], detectEditorMode(updatedRow.valuesByLocale[locale], updatedRow.valuesByLocale[state.meta.sourceLocale], draft.rawPinned));
        draft.rawText = prettyJson(draft.value);
        draft.rawError = '';
        draft.touched = false;
        setDraftSyncState(draft, 'saved', '');
        upsertRow(updatedRow);
        await refreshSummary();
        scheduleSavedReset(draft);
        render();
      } catch (error) {
        setDraftSyncState(draft, 'save_error', error.message || String(error));
        render();
        toast(t('toasts.autosaveFailed', {keyPath, locale: formatLocale(locale)}), 'error');
      }
    }

    async function flushActiveDraft() {
      const row = getRowByKey(state.selectedKey);
      if (!row || !state.selectedLocale) return;
      await flushDraft(row.keyPath, state.selectedLocale);
    }

    function isValidKeyPath(value) {
      const trimmed = value.trim();
      if (!trimmed || trimmed.startsWith('.') || trimmed.endsWith('.') || trimmed.includes('..')) {
        return false;
      }
      return trimmed.split('.').every((segment) => /^[a-zA-Z0-9_]+$/.test(segment));
    }

    function openDisplayLanguageModal() {
      state.pendingDisplayLanguage = state.displayLanguage;
      dom.displayLanguageSelect.value = state.pendingDisplayLanguage;
      if (typeof dom.displayLanguageModal.showModal === 'function') {
        dom.displayLanguageModal.showModal();
      } else {
        dom.displayLanguageModal.setAttribute('open', 'open');
      }
      dom.displayLanguageSelect.focus();
    }

    function closeDisplayLanguageModal() {
      state.pendingDisplayLanguage = state.displayLanguage;
      if (typeof dom.displayLanguageModal.close === 'function') {
        dom.displayLanguageModal.close();
      } else {
        dom.displayLanguageModal.removeAttribute('open');
      }
    }

    function confirmDisplayLanguage() {
      const nextLanguage = normalizeDisplayLanguage(dom.displayLanguageSelect.value) || 'en';
      updateDisplayLanguage(nextLanguage);
      closeDisplayLanguageModal();
    }

    function openNewKeyModal() {
      flushActiveDraft().catch(() => {});
      dom.newKeyPath.value = '';
      dom.newKeyPathError.textContent = '';
      if (state.meta) {
        state.meta.locales.forEach((locale) => {
          const input = document.getElementById('newKeyValue_' + locale);
          if (input) input.value = '';
        });
      }
      if (typeof dom.newKeyModal.showModal === 'function') {
        dom.newKeyModal.showModal();
      } else {
        dom.newKeyModal.setAttribute('open', 'open');
      }
      dom.newKeyPath.focus();
    }

    function closeNewKeyModal() {
      flushActiveDraft().catch(() => {});
      if (typeof dom.newKeyModal.close === 'function') {
        dom.newKeyModal.close();
      } else {
        dom.newKeyModal.removeAttribute('open');
      }
    }

    async function createNewKey() {
      const keyPath = dom.newKeyPath.value.trim();
      if (!isValidKeyPath(keyPath)) {
        dom.newKeyPathError.textContent = t('newKey.invalidKeyPath');
        return;
      }
      dom.newKeyPathError.textContent = '';

      const valuesByLocale = {};
      const orderedLocales = [state.meta.sourceLocale, ...state.meta.locales.filter((locale) => locale !== state.meta.sourceLocale)];
      orderedLocales.forEach((locale) => {
        const field = document.getElementById('newKeyValue_' + locale);
        valuesByLocale[locale] = field ? field.value : '';
      });

      if (!String(valuesByLocale[state.meta.sourceLocale] || '').trim()) {
        const shouldContinue = window.confirm(t('newKey.confirmMissingSource', {keyPath}));
        if (!shouldContinue) {
          return;
        }
      }

      dom.newKeySaveBtn.disabled = true;
      try {
        const row = await fetchJson('/api/catalog/key', {
          method: 'POST',
          body: JSON.stringify({
            keyPath,
            valuesByLocale,
            markGreenIfComplete: true,
          }),
        });
        upsertRow(row);
        state.selectedKey = keyPath;
        state.selectedLocale = getDefaultEditorLocale();
        await refreshSummary();
        closeNewKeyModal();
        toast(t('toasts.created', {keyPath}));
        render();
      } catch (error) {
        dom.newKeyPathError.textContent = error.message || String(error);
      } finally {
        dom.newKeySaveBtn.disabled = false;
      }
    }

    async function handleRowSelection(keyPath) {
      if (keyPath === state.selectedKey) return;
      await flushActiveDraft();
      state.selectedKey = keyPath;
      render();
    }

    async function handleLocaleSelection(locale) {
      if (locale === state.selectedLocale) return;
      await flushActiveDraft();
      state.selectedLocale = locale;
      render();
    }

    async function markDone(keyPath, locale) {
      const row = getRowByKey(keyPath);
      if (!row) return;
      const draft = getOrCreateDraft(row, locale);
      const blockers = validateDraftForDone(draft, row, locale);
      if (blockers.length) {
        toast(blockers[0], 'error');
        render();
        return;
      }
      try {
        await fetchJson('/api/catalog/review', {
          method: 'POST',
          body: JSON.stringify({keyPath, locale}),
        });
        await loadCatalog();
        toast(t('toasts.markedDone', {keyPath, locale: formatLocale(locale)}));
      } catch (error) {
        toast(error.message || String(error), 'error');
      }
    }

    async function deleteLocaleValue(keyPath, locale) {
      const sourceLocale = state.meta.sourceLocale;
      const prompt = locale === sourceLocale
        ? t('confirmations.deleteSourceValue', {keyPath})
        : t('confirmations.deleteLocaleValue', {keyPath, locale: formatLocale(locale)});
      if (!window.confirm(prompt)) return;
      try {
        const row = await fetchJson('/api/catalog/cell', {
          method: 'DELETE',
          body: JSON.stringify({keyPath, locale}),
        });
        const id = draftId(keyPath, locale);
        delete state.drafts[id];
        upsertRow(row);
        await refreshSummary();
        toast(t('toasts.deletedValue', {keyPath, locale: formatLocale(locale)}));
      } catch (error) {
        toast(error.message || String(error), 'error');
      }
    }

    async function deleteKey(keyPath) {
      if (!window.confirm(t('confirmations.deleteKey', {keyPath}))) return;
      try {
        await fetchJson('/api/catalog/key', {
          method: 'DELETE',
          body: JSON.stringify({keyPath}),
        });
        removeRow(keyPath);
        await refreshSummary();
        toast(t('toasts.deletedKey', {keyPath}));
      } catch (error) {
        toast(error.message || String(error), 'error');
      }
    }

    function addPluralBranch(keyPath, locale, category) {
      const row = getRowByKey(keyPath);
      if (!row) return;
      const draft = getOrCreateDraft(row, locale);
      const nextValue = cloneValue(draft.value) || {};
      if (draft.editorMode === 'pluralGender') {
        const sourceBranch = readPath(row.valuesByLocale[state.meta.sourceLocale], [category]);
        const nextBranch = {};
        const genderKeys = detectSupportedShape(sourceBranch) === 'gender' ? normalizedGenderKeys(sourceBranch) : GENDER_KEYS;
        genderKeys.forEach((genderKey) => {
          nextBranch[genderKey] = '';
        });
        nextValue[category] = nextBranch;
      } else {
        nextValue[category] = '';
      }
      updateDraftFromValue(row, locale, nextValue);
    }

    function addGenderBranch(keyPath, locale, category, gender) {
      const row = getRowByKey(keyPath);
      if (!row) return;
      const draft = getOrCreateDraft(row, locale);
      let nextValue = cloneValue(draft.value) || {};
      if (category) {
        if (!isPlainObject(nextValue[category])) {
          nextValue[category] = {};
        }
        nextValue[category][gender] = '';
      } else {
        nextValue[gender] = '';
      }
      updateDraftFromValue(row, locale, nextValue);
    }

    dom.searchInput.addEventListener('input', (event) => {
      state.search = event.target.value;
      render();
    });

    document.addEventListener('click', async (event) => {
      const target = event.target.closest('[data-action]');
      if (!target) return;
      const action = target.dataset.action;

      if (action === 'refresh') {
        await loadCatalog();
        return;
      }
      if (action === 'filter-status') {
        state.statusFilter = target.dataset.status || '';
        render();
        return;
      }
      if (action === 'clear-filters') {
        state.search = '';
        state.statusFilter = '';
        dom.searchInput.value = '';
        render();
        return;
      }
      if (action === 'open-display-language-modal') {
        openDisplayLanguageModal();
        return;
      }
      if (action === 'close-display-language-modal') {
        closeDisplayLanguageModal();
        return;
      }
      if (action === 'confirm-display-language') {
        confirmDisplayLanguage();
        return;
      }
      if (action === 'select-row') {
        await handleRowSelection(target.dataset.keyPath);
        return;
      }
      if (action === 'select-locale') {
        await handleLocaleSelection(target.dataset.locale);
        return;
      }
      if (action === 'open-modal') {
        openNewKeyModal();
        return;
      }
      if (action === 'close-modal') {
        closeNewKeyModal();
        return;
      }
      if (action === 'create-key') {
        await createNewKey();
        return;
      }
      if (action === 'mark-done') {
        await markDone(target.dataset.keyPath, target.dataset.locale);
        return;
      }
      if (action === 'delete-locale') {
        await deleteLocaleValue(target.dataset.keyPath, target.dataset.locale);
        return;
      }
      if (action === 'delete-key') {
        await deleteKey(target.dataset.keyPath);
        return;
      }
      if (action === 'add-plural') {
        addPluralBranch(target.dataset.keyPath, target.dataset.locale, target.dataset.category);
        return;
      }
      if (action === 'add-gender') {
        addGenderBranch(target.dataset.keyPath, target.dataset.locale, target.dataset.category, target.dataset.gender);
        return;
      }
      if (action === 'retry-save') {
        await flushDraft(target.dataset.keyPath, target.dataset.locale);
      }
    });

    document.addEventListener('input', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLElement)) return;
      if (target === dom.themeModeSelect) {
        updateThemeMode(target.value);
        return;
      }
      if (target === dom.displayLanguageSelect) {
        state.pendingDisplayLanguage = normalizeDisplayLanguage(target.value) || state.displayLanguage;
        return;
      }
      const keyPath = target.dataset.keyPath;
      const locale = target.dataset.locale;
      const fieldKind = target.dataset.fieldKind;
      if (!keyPath || !locale || !fieldKind) return;
      const row = getRowByKey(keyPath);
      if (!row) return;
      const draft = getOrCreateDraft(row, locale);

      if (fieldKind === 'plain') {
        updateDraftFromValue(row, locale, parsePlainValue(target.value, draft));
        return;
      }
      if (fieldKind === 'branch') {
        const path = (target.dataset.path || '').split('.').filter(Boolean);
        const nextValue = setNestedValue(draft.value, path, target.value);
        updateDraftFromValue(row, locale, nextValue);
        return;
      }
      if (fieldKind === 'advanced-json') {
        draft.rawText = target.value;
        try {
          const parsed = JSON.parse(target.value);
          draft.rawError = '';
          draft.rawPinned = detectSupportedShape(parsed) === 'raw';
          updateDraftFromValue(row, locale, parsed, {render: false});
        } catch (error) {
          draft.rawError = t('blockers.advancedJsonInvalid');
          draft.touched = true;
          setDraftSyncState(draft, 'dirty', '');
        }
        render();
      }
    });

    document.addEventListener('focusout', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLElement)) return;
      const keyPath = target.dataset.keyPath;
      const locale = target.dataset.locale;
      const fieldKind = target.dataset.fieldKind;
      if (!keyPath || !locale || !fieldKind) return;
      flushDraft(keyPath, locale).catch(() => {});
    }, true);

    document.addEventListener('keydown', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLElement)) return;
      const keyPath = target.dataset.keyPath;
      const locale = target.dataset.locale;
      const fieldKind = target.dataset.fieldKind;
      if (!keyPath || !locale || !fieldKind) return;
      if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
        event.preventDefault();
        flushDraft(keyPath, locale).catch(() => {});
      }
    });

    window.addEventListener('beforeunload', () => {
      Object.values(state.drafts).forEach((draft) => {
        if (draft.timerId) {
          clearTimeout(draft.timerId);
        }
      });
    });

    if (systemThemeQuery) {
      const syncSystemTheme = () => {
        if (state.themeMode === 'system') {
          applyThemeMode('system');
        }
      };
      if (typeof systemThemeQuery.addEventListener === 'function') {
        systemThemeQuery.addEventListener('change', syncSystemTheme);
      } else if (typeof systemThemeQuery.addListener === 'function') {
        systemThemeQuery.addListener(syncSystemTheme);
      }
    }

    applyDisplayLanguage(state.displayLanguage, {render: false});
    applyThemeMode(state.themeMode);
    loadCatalog();
  </script>
</body>
</html>
''';
