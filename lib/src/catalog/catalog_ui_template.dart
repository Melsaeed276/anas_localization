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
  <style>
    :root {
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
      --radius: 18px;
      --radius-sm: 12px;
      --input-bg: rgba(3, 13, 24, 0.84);
      --surface-gradient:
        radial-gradient(circle at top left, rgba(73, 132, 228, 0.18), transparent 36%),
        radial-gradient(circle at top right, rgba(17, 153, 142, 0.15), transparent 28%),
        linear-gradient(180deg, rgba(8, 18, 33, 0.98), rgba(6, 12, 23, 1));
      --font-sans: "Avenir Next", "Segoe UI", sans-serif;
      --font-mono: "SF Mono", "Menlo", monospace;
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
      background: rgba(5, 14, 27, 0.88);
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
      background: rgba(13, 30, 52, 0.82);
      color: var(--text-soft);
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
      color: #7086a7;
    }

    .search-shell input:focus,
    .modal-input:focus,
    .field-textarea:focus,
    .advanced-json textarea:focus {
      border-color: rgba(104, 169, 255, 0.72);
      box-shadow: 0 0 0 4px rgba(104, 169, 255, 0.12);
    }

    .toolbar-button,
    .primary-button,
    .subtle-button,
    .danger-button,
    .mini-button {
      border-radius: 14px;
      border: 1px solid var(--border);
      background: rgba(12, 28, 49, 0.78);
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
      border-color: rgba(104, 169, 255, 0.48);
      color: #02111f;
      font-weight: 700;
    }

    .subtle-button {
      background: rgba(15, 35, 61, 0.7);
      color: var(--text-soft);
    }

    .danger-button {
      background: rgba(91, 25, 29, 0.54);
      border-color: rgba(223, 87, 87, 0.34);
      color: #ffd7d7;
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
      background: rgba(10, 23, 42, 0.78);
      color: var(--text-soft);
      padding: 0.46rem 0.8rem;
      font-size: 0.83rem;
    }

    .filter-button[aria-pressed="true"] {
      background: rgba(104, 169, 255, 0.18);
      color: var(--text);
      border-color: rgba(104, 169, 255, 0.42);
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
      background: rgba(10, 24, 43, 0.84);
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
      border-color: rgba(104, 169, 255, 0.48);
      background: rgba(15, 35, 61, 0.92);
      box-shadow: inset 0 0 0 1px rgba(104, 169, 255, 0.16);
    }

    .row-key {
      font-family: var(--font-mono);
      font-size: 0.9rem;
      word-break: break-word;
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
      background: rgba(12, 27, 48, 0.82);
      color: var(--text-soft);
    }

    .sync-chip.sync-dirty,
    .sync-chip.sync-saving,
    .sync-chip.sync-save_error {
      border-color: rgba(230, 173, 56, 0.34);
      color: var(--warning-text);
    }

    .sync-chip.sync-save_error {
      border-color: rgba(223, 87, 87, 0.34);
      color: var(--red-text);
    }

    .sync-chip.sync-saved {
      border-color: rgba(37, 184, 112, 0.34);
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
    }

    .locale-tabs {
      display: flex;
      flex-wrap: wrap;
      gap: 0.55rem;
    }

    .tab-button {
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(12, 27, 48, 0.84);
      color: var(--text-soft);
      padding: 0.48rem 0.82rem;
      font-size: 0.86rem;
    }

    .tab-button.is-active {
      background: rgba(104, 169, 255, 0.2);
      color: var(--text);
      border-color: rgba(104, 169, 255, 0.42);
    }

    .source-card {
      background: linear-gradient(180deg, rgba(16, 32, 53, 0.88), rgba(10, 21, 39, 0.92));
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
      background: rgba(6, 14, 25, 0.76);
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
      background: rgba(10, 24, 43, 0.74);
      display: grid;
      gap: 0.3rem;
    }

    .warning-card {
      background: rgba(88, 64, 12, 0.24);
      border-color: rgba(230, 173, 56, 0.28);
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
      background: rgba(7, 18, 33, 0.78);
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
    }

    .danger-link {
      padding: 0;
      border: none;
      background: transparent;
      color: #ff9d9d;
      text-decoration: underline;
      text-underline-offset: 0.18rem;
    }

    .inline-error {
      color: #ffb3b3;
      font-size: 0.88rem;
    }

    .empty-state,
    .error-banner {
      display: grid;
      gap: 0.7rem;
    }

    .error-banner {
      background: rgba(73, 16, 23, 0.78);
      border-color: rgba(223, 87, 87, 0.34);
      color: #ffd1d1;
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
      background: rgba(14, 28, 46, 0.82);
    }

    .skeleton::after {
      content: "";
      position: absolute;
      inset: 0;
      transform: translateX(-100%);
      background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.08), transparent);
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
      background: rgba(9, 22, 40, 0.94);
      box-shadow: var(--shadow);
    }

    .toast.toast-error {
      border-color: rgba(223, 87, 87, 0.34);
      color: #ffd1d1;
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
      background: rgba(7, 17, 31, 0.98);
      color: var(--text);
      box-shadow: var(--shadow);
    }

    dialog::backdrop {
      background: rgba(1, 7, 13, 0.72);
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
            <h1>Anas Localization Catalog</h1>
            <p>Minimal translation workspace with autosave, explicit Done review, and structured editors for plural and gender variants.</p>
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
            <h2>Keys</h2>
            <p>List + editor workflow</p>
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
        <p class="eyebrow">Create New String</p>
        <h2 id="newKeyTitle" class="section-title">Create New String</h2>
        <p class="muted-copy">Source locale goes first. Filled target locales still start as needing review until you mark them Done.</p>
      </div>

      <div class="modal-grid">
        <div class="modal-field">
          <label for="newKeyPath">Key path</label>
          <input class="modal-input mono-note" id="newKeyPath" type="text" placeholder="checkout.summary.title" autocomplete="off">
          <div class="inline-error" id="newKeyPathError"></div>
        </div>
        <div class="modal-locale-grid" id="newKeyLocaleFields"></div>
      </div>

      <div class="modal-actions">
        <button class="subtle-button" type="button" data-action="close-modal">Cancel</button>
        <button class="primary-button" type="button" id="newKeySaveBtn" data-action="create-key">Create</button>
      </div>
    </form>
  </dialog>

  <script>
    const API_URL = __API_URL__;
    const PLURAL_KEYS = ['zero', 'one', 'two', 'few', 'many', 'other', 'more'];
    const GENDER_KEYS = ['male', 'female'];
    const STATUS_COPY = {
      green: 'Ready',
      warning: 'Needs review',
      red: 'Missing',
    };
    const REASON_COPY = {
      source_changed: 'Source changed. Re-check this locale.',
      source_added: 'Source was added. Review the translation.',
      source_deleted: 'Source value was removed.',
      source_deleted_review_required: 'Source value was removed. Review this locale.',
      target_missing: 'Translation is missing.',
      new_key_needs_translation_review: 'New entry needs review.',
      target_updated_needs_review: 'Saved, but still needs review.',
    };

    const state = {
      meta: null,
      rows: [],
      summary: null,
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
      metaBadges: document.getElementById('metaBadges'),
      statusFilters: document.getElementById('statusFilters'),
      summaryCounts: document.getElementById('summaryCounts'),
      activeFilterSummary: document.getElementById('activeFilterSummary'),
      visibleKeyCount: document.getElementById('visibleKeyCount'),
      keyListPanel: document.getElementById('keyListPanel'),
      editorPane: document.getElementById('editorPane'),
      toastHost: document.getElementById('toastHost'),
      srAnnouncer: document.getElementById('srAnnouncer'),
      searchInput: document.getElementById('searchInput'),
      refreshBtn: document.getElementById('refreshBtn'),
      newKeyBtn: document.getElementById('newKeyBtn'),
      newKeyModal: document.getElementById('newKeyModal'),
      newKeyPath: document.getElementById('newKeyPath'),
      newKeyPathError: document.getElementById('newKeyPathError'),
      newKeySaveBtn: document.getElementById('newKeySaveBtn'),
      newKeyLocaleFields: document.getElementById('newKeyLocaleFields'),
    };

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
        return new Date(value).toLocaleString();
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
        blockers.push('Advanced JSON must be valid.');
        return blockers;
      }
      if (draft.syncState === 'dirty' || draft.syncState === 'saving' || draft.syncState === 'save_error') {
        blockers.push('Wait for autosave to finish before marking Done.');
      }
      if (isCatalogValueEmpty(draft.value)) {
        blockers.push('Translation is still empty.');
      }

      const editorMode = draft.editorMode;
      const requiredPaths = requiredPathsForValue(row.valuesByLocale[state.meta.sourceLocale], draft.value, editorMode);
      const missingBranches = requiredPaths.filter((path) => {
        const branchValue = readPath(draft.value, path);
        return typeof branchValue !== 'string' ? branchValue == null : branchValue.trim() === '';
      });
      if (missingBranches.length && editorMode !== 'raw') {
        blockers.push('Fill every visible branch before marking Done.');
      }

      const sourcePlaceholders = collectPlaceholders(row.valuesByLocale[state.meta.sourceLocale], new Set());
      const targetPlaceholders = collectPlaceholders(draft.value, new Set());
      const missingPlaceholders = [...sourcePlaceholders].filter((item) => !targetPlaceholders.has(item));
      if (missingPlaceholders.length) {
        blockers.push('Missing placeholders: ' + missingPlaceholders.map((item) => '{' + item + '}').join(', '));
      }
      return blockers;
    }

    function syncLabelForState(syncState) {
      switch (syncState) {
        case 'dirty':
          return 'Unsaved';
        case 'saving':
          return 'Saving';
        case 'saved':
          return 'Saved';
        case 'save_error':
          return 'Retry needed';
        default:
          return 'Synced';
      }
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
        '<span class="pill">Source ' + escapeHtml(formatLocale(state.meta.sourceLocale)) + '</span>',
        '<span class="pill">' + escapeHtml(state.meta.locales.length) + ' locales</span>',
        '<span class="pill">' + escapeHtml(state.summary ? state.summary.totalKeys : 0) + ' keys</span>',
      ].join('');
    }

    function renderStatusFilters() {
      const counts = state.summary || {totalKeys: 0, greenRows: 0, warningRows: 0, redRows: 0};
      const items = [
        {status: '', label: 'All', count: counts.totalKeys},
        {status: 'green', label: 'Ready', count: counts.greenRows},
        {status: 'warning', label: 'Needs review', count: counts.warningRows},
        {status: 'red', label: 'Missing', count: counts.redRows},
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
      dom.visibleKeyCount.textContent = visibleRows.length + ' visible';

      const counts = state.summary || {greenRows: 0, warningRows: 0, redRows: 0};
      dom.summaryCounts.innerHTML = [
        '<span class="count-chip">Ready ' + counts.greenRows + '</span>',
        '<span class="count-chip">Needs review ' + counts.warningRows + '</span>',
        '<span class="count-chip">Missing ' + counts.redRows + '</span>',
      ].join('');

      if (state.loading) {
        dom.activeFilterSummary.textContent = 'Loading workspace…';
        return;
      }

      if (!visibleRows.length) {
        dom.activeFilterSummary.textContent = 'No keys match the current search or filter.';
        return;
      }

      const activeStatusLabel = state.statusFilter ? STATUS_COPY[state.statusFilter] : 'All';
      dom.activeFilterSummary.textContent = visibleRows.length + ' rows visible · filter: ' + activeStatusLabel + (state.search ? ' · search: ' + state.search : '');
    }

    function renderKeyList() {
      if (state.error) {
        dom.keyListPanel.innerHTML =
          '<div class="error-banner"><strong>Catalog failed to load</strong><p>' + escapeHtml(state.error) + '</p>' +
          '<div><button class="subtle-button" data-action="refresh">Retry</button></div></div>';
        return;
      }

      if (state.loading) {
        dom.keyListPanel.innerHTML = new Array(6).fill(0).map(() => '<div class="skeleton"></div>').join('');
        return;
      }

      const rows = filteredRows();
      if (!rows.length) {
        dom.keyListPanel.innerHTML =
          '<div class="empty-state"><strong>No matching keys</strong><p>Try clearing the search or switching back to all statuses.</p>' +
          '<div><button class="subtle-button" data-action="clear-filters">Clear filters</button></div></div>';
        return;
      }

      dom.keyListPanel.innerHTML = rows.map((row) => {
        const selected = row.keyPath === state.selectedKey;
        const visibleStatus = getVisibleRowStatus(row);
        const syncState = getRowSyncState(row.keyPath);
        const pendingText = row.missingLocales.length
          ? row.missingLocales.length + ' missing · ' + row.missingLocales.join(', ').toUpperCase()
          : row.pendingLocales.length
            ? row.pendingLocales.length + ' pending · ' + row.pendingLocales.join(', ').toUpperCase()
            : 'All target locales done';

        return '<button class="row-button ' + (selected ? 'is-selected' : '') + '" data-action="select-row" data-key-path="' + escapeHtml(row.keyPath) + '">' +
          '<div class="row-topline">' +
            '<span class="row-key">' + escapeHtml(row.keyPath) + '</span>' +
            '<span class="status-chip ' + statusClass(visibleStatus) + '">' + escapeHtml(STATUS_COPY[visibleStatus]) + '</span>' +
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
        return '<div class="source-card"><p class="eyebrow">Source impact</p><div class="source-summary"><p>Editing the source autosaves immediately and marks every target locale as needing review or missing.</p></div></div>';
      }
      return '<div class="source-card"><p class="eyebrow">Source reference · ' + escapeHtml(formatLocale(state.meta.sourceLocale)) + '</p>' +
        renderSourceReferenceValue(row.valuesByLocale[state.meta.sourceLocale], state.meta.sourceLocale) +
      '</div>';
    }

    function renderReasonCard(row, locale, draft) {
      const cell = row.cellStates[locale] || {};
      const doneBlockers = validateDraftForDone(draft, row, locale);
      const lines = [];
      if (cell.reason && REASON_COPY[cell.reason]) {
        lines.push('<div class="reason-card"><strong>' + escapeHtml(REASON_COPY[cell.reason]) + '</strong>' +
          '<p class="status-note">' + escapeHtml(STATUS_COPY[cell.status || 'warning']) + '</p>' +
          (cell.lastEditedAt ? '<p class="status-note">Last edit: ' + escapeHtml(formatTimestamp(cell.lastEditedAt)) + '</p>' : '') +
          (cell.lastReviewedAt ? '<p class="status-note">Last done: ' + escapeHtml(formatTimestamp(cell.lastReviewedAt)) + '</p>' : '') +
        '</div>');
      } else if (cell.lastReviewedAt) {
        lines.push('<div class="reason-card"><strong>Reviewed and ready.</strong><p class="status-note">Last done: ' + escapeHtml(formatTimestamp(cell.lastReviewedAt)) + '</p></div>');
      }
      if (doneBlockers.length) {
        lines.push('<div class="warning-card"><strong>Done is blocked</strong><p>' + escapeHtml(doneBlockers[0]) + '</p></div>');
      }
      if (draft.syncState === 'save_error' && draft.errorMessage) {
        lines.push('<div class="warning-card"><strong>Autosave failed</strong><p>' + escapeHtml(draft.errorMessage) + '</p>' +
          '<div><button class="mini-button" data-action="retry-save" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">Retry save</button></div></div>');
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
        '<textarea class="field-textarea" data-field-kind="branch" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-path="' + escapeHtml(pathKey) + '" dir="' + escapeHtml(getDirection(locale)) + '" data-editor-size="compact" placeholder="Add translation">' + escapeHtml(value) + '</textarea>' +
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
        return '<button class="mini-button" data-action="add-plural" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-category="' + escapeHtml(category) + '">Add ' + escapeHtml(category) + '</button>';
      }).join('') + '</div>';
    }

    function renderGenderAddActions(row, locale, draft, category) {
      const existing = new Set(normalizedGenderKeys(category ? draft.value[category] : draft.value));
      const sourceValue = category ? readPath(row.valuesByLocale[state.meta.sourceLocale], [category]) : row.valuesByLocale[state.meta.sourceLocale];
      const sourceKeys = detectSupportedShape(sourceValue) === 'gender' ? normalizedGenderKeys(sourceValue) : GENDER_KEYS;
      const candidates = [...new Set([...GENDER_KEYS, ...sourceKeys])].filter((key) => !existing.has(key));
      if (!candidates.length) return '';
      return '<div class="add-actions">' + candidates.map((gender) => {
        return '<button class="mini-button" data-action="add-gender" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" data-category="' + escapeHtml(category || '') + '" data-gender="' + escapeHtml(gender) + '">Add ' + escapeHtml(gender) + '</button>';
      }).join('') + '</div>';
    }

    function renderEditorFields(row, locale, draft) {
      if (draft.editorMode === 'raw') {
        return '<div class="warning-card"><strong>Advanced JSON editor</strong><p>This value shape is kept in raw mode because it does not match the guided plural or gender patterns.</p></div>';
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
            return '<div class="branch-card"><div class="branch-label"><strong>' + escapeHtml(pluralKey) + '</strong><span>Plural branch</span></div>' +
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
      return '<div class="field-stack"><div class="branch-card"><div class="branch-label"><strong>Translation</strong>' +
        (locale === state.meta.sourceLocale ? '<span>Source locale</span>' : '<span>Autosaves after 700ms</span>') +
        '</div>' +
        '<textarea class="field-textarea" data-field-kind="plain" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '" dir="' + escapeHtml(getDirection(locale)) + '" placeholder="Enter localized copy">' +
          escapeHtml(textValue) +
        '</textarea>' +
      '</div></div>';
    }

    function renderAdvancedJson(row, locale, draft) {
      const open = draft.rawPinned || Boolean(draft.rawError);
      return '<details class="advanced-json" ' + (open ? 'open' : '') + '>' +
        '<summary>Advanced JSON<span class="muted-copy">Pretty printed raw value</span></summary>' +
        '<div class="advanced-json-body">' +
          '<p class="helper-text">Use this when the translation shape is more complex than the guided editor. Invalid JSON stays local and blocks Done.</p>' +
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
          '<div class="empty-state"><strong>No keys yet</strong><p>Create the first string to start editing localized values.</p>' +
          '<div><button class="primary-button" data-action="open-modal">+ New String</button></div></div>';
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
              '<div><p class="eyebrow">Selected key</p><p class="editor-key">' + escapeHtml(row.keyPath) + '</p></div>' +
              '<div class="editor-actions">' +
                '<span class="status-chip ' + statusClass(getVisibleRowStatus(row)) + '">' + escapeHtml(STATUS_COPY[getVisibleRowStatus(row)]) + '</span>' +
                '<button class="danger-button" data-action="delete-key" data-key-path="' + escapeHtml(row.keyPath) + '">Delete key</button>' +
              '</div>' +
            '</div>' +
            '<p class="editor-subtle">' +
              (row.missingLocales.length
                ? escapeHtml('Missing: ' + row.missingLocales.join(', ').toUpperCase())
                : row.pendingLocales.length
                  ? escapeHtml('Pending: ' + row.pendingLocales.join(', ').toUpperCase())
                  : 'All target locales are ready.') +
            '</p>' +
          '</div>' +

          renderSourceCard(row, locale) +

          '<div class="pane-card">' +
            '<div class="editor-topline">' +
              '<div class="section-heading"><h2>' + escapeHtml(formatLocale(locale)) + ' editor</h2><p class="helper-text">Autosaves after 700ms, on blur, and when switching rows or locales.</p></div>' +
              '<div class="editor-actions">' +
                '<span class="sync-chip sync-' + draft.syncState + '">' + escapeHtml(syncLabelForState(draft.syncState)) + '</span>' +
                (locale === state.meta.sourceLocale
                  ? '<span class="pill">Source stays green</span>'
                  : reviewed
                    ? '<span class="status-chip status-green">Reviewed</span>'
                    : '<button class="primary-button" data-action="mark-done" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '"' + (doneDisabled ? ' disabled' : '') + '>Done</button>') +
              '</div>' +
            '</div>' +

            '<div class="locale-tabs">' + state.meta.locales.map((item) => {
              const isActive = item === locale;
              const status = row.cellStates[item] ? row.cellStates[item].status : 'warning';
              return '<button class="tab-button ' + (isActive ? 'is-active' : '') + '" data-action="select-locale" data-locale="' + escapeHtml(item) + '">' +
                escapeHtml(formatLocale(item)) + ' · ' + escapeHtml(STATUS_COPY[status]) +
              '</button>';
            }).join('') + '</div>' +

            renderReasonCard(row, locale, draft) +
            renderEditorFields(row, locale, draft) +
            renderAdvancedJson(row, locale, draft) +

            '<div class="editor-footer">' +
              '<button class="danger-link" data-action="delete-locale" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">' +
                escapeHtml(locale === state.meta.sourceLocale ? 'Delete source value' : 'Delete ' + formatLocale(locale) + ' value') +
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
        const sourceBadge = locale === state.meta.sourceLocale ? '<span class="pill">Source</span>' : '';
        return '<div class="modal-field"><label for="newKeyValue_' + escapeHtml(locale) + '">' +
          '<span>' + escapeHtml(formatLocale(locale)) + '</span>' + sourceBadge +
        '</label>' +
        '<textarea class="field-textarea" id="newKeyValue_' + escapeHtml(locale) + '" data-modal-locale="' + escapeHtml(locale) + '" dir="' + escapeHtml(getDirection(locale)) + '" data-editor-size="compact" placeholder="Optional initial value"></textarea></div>';
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
        toast('Autosave failed for ' + keyPath + ' (' + formatLocale(locale) + ')', 'error');
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
        dom.newKeyPathError.textContent = 'Use dot-separated segments with letters, numbers, and underscores.';
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
        const shouldContinue = window.confirm('Create "' + keyPath + '" without a source value? Target locales will stay blocked until the source is filled.');
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
        toast('Created ' + keyPath);
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
        toast('Marked ' + keyPath + ' (' + formatLocale(locale) + ') as done');
      } catch (error) {
        toast(error.message || String(error), 'error');
      }
    }

    async function deleteLocaleValue(keyPath, locale) {
      const sourceLocale = state.meta.sourceLocale;
      const prompt = locale === sourceLocale
        ? 'Delete the source value for "' + keyPath + '"? Every target locale will need review.'
        : 'Delete the ' + formatLocale(locale) + ' value for "' + keyPath + '"? This row will become missing.';
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
        toast('Deleted value for ' + keyPath + ' (' + formatLocale(locale) + ')');
      } catch (error) {
        toast(error.message || String(error), 'error');
      }
    }

    async function deleteKey(keyPath) {
      if (!window.confirm('Delete the entire key "' + keyPath + '" across every locale?')) return;
      try {
        await fetchJson('/api/catalog/key', {
          method: 'DELETE',
          body: JSON.stringify({keyPath}),
        });
        removeRow(keyPath);
        await refreshSummary();
        toast('Deleted ' + keyPath);
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
          draft.rawError = error.message || 'Invalid JSON';
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

    loadCatalog();
  </script>
</body>
</html>
''';
