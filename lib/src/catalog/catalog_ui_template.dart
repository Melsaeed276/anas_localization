library;

import 'dart:convert';

String buildCatalogHtml({required String apiUrl}) {
  final escapedApiUrl = const HtmlEscape(HtmlEscapeMode.element).convert(apiUrl);
  return _catalogUiTemplate.replaceAll('__API_URL__', escapedApiUrl);
}

const String _catalogUiTemplate = r'''
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Anas Localization Catalog</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #07111f;
      --bg-glow: radial-gradient(circle at top left, rgba(74, 143, 255, 0.24), transparent 32%),
        radial-gradient(circle at bottom right, rgba(76, 214, 180, 0.14), transparent 28%);
      --surface: rgba(8, 19, 37, 0.94);
      --surface-strong: rgba(11, 26, 48, 0.98);
      --surface-muted: rgba(15, 32, 58, 0.88);
      --surface-soft: rgba(18, 35, 63, 0.72);
      --border: rgba(122, 161, 216, 0.18);
      --border-strong: rgba(122, 161, 216, 0.32);
      --text: #e8f0ff;
      --text-strong: #f7fbff;
      --muted: #99adcc;
      --accent: #6ba7ff;
      --accent-strong: #4e83f3;
      --accent-soft: rgba(107, 167, 255, 0.18);
      --success: #4dd4a7;
      --warning: #ffbf5e;
      --danger: #ff7d7d;
      --shadow: 0 24px 70px rgba(2, 8, 18, 0.42);
      --radius-xl: 28px;
      --radius-lg: 20px;
      --radius-md: 16px;
      --radius-sm: 12px;
      --radius-xs: 10px;
      --content-max: 1600px;
      --space-1: 4px;
      --space-2: 8px;
      --space-3: 12px;
      --space-4: 16px;
      --space-5: 20px;
      --space-6: 24px;
      --space-7: 28px;
      --space-8: 32px;
      --transition: 180ms ease;
      --header-offset: 18px;
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
      font-family: Inter, "Segoe UI", system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
      background:
        linear-gradient(180deg, rgba(7, 17, 31, 0.98), rgba(4, 12, 23, 0.98)),
        var(--bg-glow),
        var(--bg);
      color: var(--text);
    }

    button,
    input,
    textarea {
      font: inherit;
    }

    button {
      border: none;
      background: none;
      color: inherit;
    }

    button:disabled {
      cursor: not-allowed;
      opacity: 0.48;
    }

    .sr-only {
      position: absolute;
      width: 1px;
      height: 1px;
      padding: 0;
      margin: -1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      border: 0;
      white-space: nowrap;
    }

    .catalog-shell {
      width: min(calc(100% - 32px), var(--content-max));
      margin: 18px auto 28px;
    }

    .shell-header {
      position: sticky;
      top: var(--header-offset);
      z-index: 30;
      padding: 22px;
      border: 1px solid var(--border);
      border-radius: var(--radius-xl);
      background:
        linear-gradient(135deg, rgba(12, 30, 56, 0.96), rgba(7, 18, 34, 0.98)),
        var(--surface);
      box-shadow: var(--shadow);
      backdrop-filter: blur(22px);
    }

    .header-top {
      display: flex;
      gap: var(--space-5);
      align-items: flex-start;
      justify-content: space-between;
    }

    .header-brand {
      max-width: 760px;
    }

    .eyebrow {
      display: inline-flex;
      align-items: center;
      gap: var(--space-2);
      margin-bottom: var(--space-2);
      font-size: 11px;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      color: #b9cfff;
    }

    .eyebrow::before {
      content: "";
      width: 10px;
      height: 10px;
      border-radius: 999px;
      background: linear-gradient(135deg, #9fc5ff, #55e6b8);
      box-shadow: 0 0 0 4px rgba(107, 167, 255, 0.14);
    }

    .shell-header h1 {
      margin: 0;
      font-size: clamp(26px, 3vw, 38px);
      line-height: 1.04;
      color: var(--text-strong);
    }

    .shell-header p {
      margin: var(--space-2) 0 0;
      max-width: 68ch;
      color: var(--muted);
      line-height: 1.5;
      font-size: 14px;
    }

    .header-meta {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
      justify-content: flex-end;
    }

    .badge-pill,
    .filter-chip,
    .summary-chip {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      min-height: 36px;
      padding: 0 12px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(12, 27, 48, 0.78);
      color: var(--text);
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.01em;
    }

    .summary-chip strong {
      color: var(--text-strong);
      font-size: 13px;
    }

    .source-pill {
      background: linear-gradient(135deg, rgba(80, 130, 255, 0.22), rgba(70, 210, 180, 0.14));
      border-color: rgba(118, 170, 255, 0.3);
      color: #dbe8ff;
    }

    .mode-pill {
      color: var(--muted);
    }

    .header-controls {
      display: grid;
      grid-template-columns: minmax(260px, 1.6fr) minmax(260px, 1.8fr) auto auto;
      gap: var(--space-3);
      align-items: end;
      margin-top: var(--space-6);
    }

    .search-field,
    .control-cluster {
      display: flex;
      flex-direction: column;
      gap: 7px;
    }

    .search-field label,
    .control-cluster label,
    .modal-stack label,
    .field-header label {
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.02em;
      color: var(--muted);
    }

    .search-input,
    .modal-input,
    .editor-textarea,
    .raw-editor {
      width: 100%;
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      background: rgba(4, 12, 24, 0.92);
      color: var(--text-strong);
      padding: 12px 14px;
      transition: border-color var(--transition), box-shadow var(--transition), transform var(--transition);
      outline: none;
    }

    .search-input:focus,
    .modal-input:focus,
    .editor-textarea:focus,
    .raw-editor:focus,
    .action-btn:focus-visible,
    .filter-btn:focus-visible,
    .matrix-cell:focus-visible,
    .row-card:focus-visible,
    .toggle-btn:focus-visible,
    .branch-btn:focus-visible {
      border-color: rgba(115, 181, 255, 0.72);
      box-shadow: 0 0 0 4px rgba(107, 167, 255, 0.16);
    }

    .search-input::placeholder,
    .editor-textarea::placeholder,
    .raw-editor::placeholder {
      color: rgba(153, 173, 204, 0.76);
    }

    .status-cluster {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
    }

    .filter-btn,
    .action-btn,
    .toggle-btn,
    .branch-btn,
    .ghost-link {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      min-height: 42px;
      padding: 0 14px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: rgba(14, 30, 53, 0.78);
      color: var(--text);
      cursor: pointer;
      transition:
        transform var(--transition),
        border-color var(--transition),
        background var(--transition),
        color var(--transition);
      text-decoration: none;
    }

    .filter-btn:hover,
    .action-btn:hover,
    .toggle-btn:hover,
    .branch-btn:hover,
    .ghost-link:hover {
      transform: translateY(-1px);
      border-color: rgba(122, 161, 216, 0.38);
      background: rgba(18, 40, 72, 0.92);
    }

    .filter-btn.active,
    .toggle-btn.active {
      background: linear-gradient(135deg, rgba(88, 141, 255, 0.28), rgba(45, 193, 166, 0.16));
      border-color: rgba(117, 171, 255, 0.48);
      color: var(--text-strong);
    }

    .action-btn.primary {
      background: linear-gradient(135deg, #4f88ff, #3768df);
      border-color: rgba(143, 189, 255, 0.35);
      color: white;
      box-shadow: 0 14px 34px rgba(55, 104, 223, 0.28);
    }

    .action-btn.danger,
    .branch-btn.danger {
      background: rgba(90, 24, 34, 0.86);
      border-color: rgba(255, 125, 125, 0.34);
      color: #ffd5d5;
    }

    .summary-row {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-3);
      margin-top: var(--space-5);
    }

    .summary-card {
      min-width: 136px;
      padding: 14px 16px;
      border-radius: var(--radius-lg);
      border: 1px solid var(--border);
      background: rgba(10, 24, 44, 0.84);
    }

    .summary-card .label {
      font-size: 12px;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .summary-card strong {
      display: block;
      margin-top: 10px;
      font-size: 28px;
      color: var(--text-strong);
    }

    .summary-card.green strong { color: var(--success); }
    .summary-card.warning strong { color: var(--warning); }
    .summary-card.red strong { color: var(--danger); }

    .filters-row {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: var(--space-2);
      margin-top: var(--space-4);
    }

    .filters-row .hint {
      color: var(--muted);
      font-size: 12px;
      margin-right: 2px;
    }

    .workspace {
      display: grid;
      gap: var(--space-4);
      margin-top: var(--space-4);
      align-items: start;
    }

    .workspace.is-expanded {
      grid-template-columns: minmax(0, 1.5fr) minmax(320px, 0.94fr);
    }

    .workspace.is-medium {
      grid-template-columns: minmax(0, 0.92fr) minmax(320px, 1.08fr);
    }

    .workspace.is-compact {
      grid-template-columns: 1fr;
    }

    .surface {
      border: 1px solid var(--border);
      border-radius: var(--radius-xl);
      background: linear-gradient(180deg, rgba(11, 24, 44, 0.94), rgba(7, 16, 31, 0.98));
      box-shadow: var(--shadow);
      overflow: hidden;
    }

    .master-panel,
    .detail-panel {
      min-height: 460px;
    }

    .panel-header {
      padding: 18px 20px 0;
    }

    .panel-title {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: var(--space-3);
    }

    .panel-title h2,
    .detail-header h2 {
      margin: 0;
      font-size: 18px;
      color: var(--text-strong);
    }

    .panel-title p,
    .detail-header p {
      margin: 6px 0 0;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.4;
    }

    .error-banner {
      display: none;
      gap: var(--space-3);
      align-items: flex-start;
      margin: 18px 20px 0;
      padding: 14px 16px;
      border-radius: var(--radius-md);
      border: 1px solid rgba(255, 125, 125, 0.32);
      background: rgba(62, 18, 28, 0.78);
      color: #ffd8d8;
    }

    .error-banner.show {
      display: flex;
    }

    .panel-body {
      padding: 18px 20px 20px;
    }

    .loading-shell {
      display: grid;
      gap: 12px;
    }

    .skeleton {
      position: relative;
      overflow: hidden;
      border-radius: var(--radius-md);
      background: rgba(17, 35, 62, 0.76);
      min-height: 72px;
    }

    .skeleton::after {
      content: "";
      position: absolute;
      inset: 0;
      transform: translateX(-100%);
      background: linear-gradient(90deg, transparent, rgba(150, 185, 235, 0.14), transparent);
      animation: shimmer 1.2s infinite;
    }

    @keyframes shimmer {
      100% {
        transform: translateX(100%);
      }
    }

    .empty-state {
      padding: 32px 24px;
      text-align: center;
      color: var(--muted);
    }

    .empty-state h3 {
      margin: 0 0 10px;
      color: var(--text-strong);
      font-size: 20px;
    }

    .empty-state p {
      margin: 0 auto 20px;
      max-width: 44ch;
      line-height: 1.5;
    }

    .matrix-wrapper {
      overflow: auto;
      max-height: min(78vh, 980px);
      border-top: 1px solid var(--border);
    }

    .catalog-table {
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
      min-width: 860px;
    }

    .catalog-table thead th {
      position: sticky;
      top: 0;
      z-index: 2;
      text-align: left;
      padding: 14px 16px;
      background: rgba(14, 31, 55, 0.96);
      border-bottom: 1px solid var(--border);
      font-size: 12px;
      color: #bed0ef;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .catalog-table th:first-child,
    .catalog-table td.key-column {
      position: sticky;
      left: 0;
      z-index: 3;
      background: linear-gradient(180deg, rgba(13, 28, 50, 0.98), rgba(9, 21, 39, 0.98));
    }

    .catalog-table td {
      padding: 12px 14px;
      border-bottom: 1px solid rgba(122, 161, 216, 0.08);
      vertical-align: top;
      background: rgba(8, 18, 34, 0.6);
    }

    .catalog-table tr.is-selected td {
      background: rgba(17, 38, 67, 0.66);
    }

    .key-column code,
    .detail-header code,
    .row-card code {
      font-family: "SFMono-Regular", "Roboto Mono", ui-monospace, monospace;
      font-size: 13px;
      line-height: 1.45;
      word-break: break-word;
      color: #eaf2ff;
    }

    .matrix-cell,
    .row-card {
      width: 100%;
      display: flex;
      flex-direction: column;
      gap: 9px;
      padding: 12px;
      border-radius: var(--radius-md);
      border: 1px solid rgba(122, 161, 216, 0.12);
      background: rgba(10, 22, 42, 0.88);
      cursor: pointer;
      text-align: left;
      transition:
        border-color var(--transition),
        transform var(--transition),
        background var(--transition);
    }

    .matrix-cell:hover,
    .row-card:hover {
      transform: translateY(-1px);
      border-color: rgba(122, 161, 216, 0.36);
      background: rgba(14, 30, 56, 0.96);
    }

    .matrix-cell.active,
    .row-card.active {
      border-color: rgba(117, 171, 255, 0.5);
      box-shadow: 0 0 0 1px rgba(117, 171, 255, 0.2);
    }

    .cell-topline,
    .row-card-topline,
    .locale-topline {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: var(--space-2);
    }

    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      min-height: 28px;
      padding: 0 10px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      border: 1px solid transparent;
    }

    .status-badge::before {
      content: "";
      width: 8px;
      height: 8px;
      border-radius: 999px;
      background: currentColor;
      box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.08);
    }

    .status-green {
      color: #9df1cd;
      border-color: rgba(77, 212, 167, 0.24);
      background: rgba(18, 57, 43, 0.72);
    }

    .status-warning {
      color: #ffe2a8;
      border-color: rgba(255, 191, 94, 0.28);
      background: rgba(62, 45, 16, 0.74);
    }

    .status-red {
      color: #ffc7c7;
      border-color: rgba(255, 125, 125, 0.28);
      background: rgba(66, 25, 25, 0.74);
    }

    .shape-badge {
      display: inline-flex;
      align-items: center;
      min-height: 28px;
      padding: 0 10px;
      border-radius: 999px;
      border: 1px solid rgba(122, 161, 216, 0.16);
      background: rgba(12, 28, 47, 0.82);
      color: var(--muted);
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .source-chip {
      background: rgba(88, 141, 255, 0.2);
      border-color: rgba(117, 171, 255, 0.38);
      color: #dbe9ff;
    }

    .preview-text,
    .cell-meta,
    .row-card p,
    .detail-meta {
      color: var(--muted);
      font-size: 12px;
      line-height: 1.45;
    }

    .preview-text {
      display: block;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 3;
      -webkit-box-orient: vertical;
      white-space: pre-wrap;
    }

    .preview-text.structured {
      font-family: "SFMono-Regular", "Roboto Mono", ui-monospace, monospace;
      font-size: 11px;
    }

    .row-list {
      display: grid;
      gap: 12px;
    }

    .row-card {
      padding: 16px;
    }

    .row-card-locales {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
    }

    .row-card .summary-chip {
      min-height: 30px;
      background: rgba(10, 23, 40, 0.88);
    }

    .detail-panel {
      position: sticky;
      top: calc(var(--header-offset) + 196px);
    }

    .detail-scroll {
      max-height: min(78vh, 1080px);
      overflow: auto;
      padding: 20px;
    }

    .detail-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: var(--space-4);
      margin-bottom: var(--space-4);
    }

    .detail-summary {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
      margin-bottom: var(--space-5);
    }

    .locale-stack {
      display: grid;
      gap: 16px;
    }

    .locale-section {
      border: 1px solid rgba(122, 161, 216, 0.16);
      border-radius: var(--radius-lg);
      background: rgba(8, 20, 38, 0.84);
      overflow: hidden;
      transition: border-color var(--transition), box-shadow var(--transition);
    }

    .locale-section.active {
      border-color: rgba(117, 171, 255, 0.46);
      box-shadow: 0 0 0 1px rgba(117, 171, 255, 0.14);
    }

    .locale-header {
      padding: 16px 16px 14px;
      border-bottom: 1px solid rgba(122, 161, 216, 0.12);
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: var(--space-4);
      align-items: start;
    }

    .locale-body {
      padding: 16px;
      display: grid;
      gap: 14px;
    }

    .locale-actions {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
      justify-content: flex-end;
    }

    .toggle-group {
      display: inline-flex;
      gap: 8px;
      padding: 4px;
      border: 1px solid rgba(122, 161, 216, 0.12);
      border-radius: 999px;
      background: rgba(10, 23, 40, 0.84);
    }

    .toggle-btn {
      min-height: 34px;
      padding: 0 12px;
      font-size: 12px;
    }

    .field-grid {
      display: grid;
      gap: 14px;
    }

    .field-grid.two {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .field-grid.single {
      grid-template-columns: 1fr;
    }

    .field-card,
    .branch-row {
      padding: 14px;
      border-radius: var(--radius-md);
      border: 1px solid rgba(122, 161, 216, 0.12);
      background: rgba(5, 14, 28, 0.82);
      display: grid;
      gap: 10px;
    }

    .field-header,
    .branch-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: var(--space-2);
    }

    .field-hint {
      font-size: 12px;
      color: var(--muted);
      line-height: 1.4;
    }

    .editor-textarea,
    .raw-editor {
      min-height: 118px;
      resize: vertical;
      line-height: 1.5;
    }

    .raw-editor {
      font-family: "SFMono-Regular", "Roboto Mono", ui-monospace, monospace;
      font-size: 12px;
      min-height: 220px;
    }

    .structured-table {
      width: 100%;
      border-collapse: collapse;
      border: 1px solid rgba(122, 161, 216, 0.12);
      border-radius: var(--radius-md);
      overflow: hidden;
    }

    .structured-table th,
    .structured-table td {
      padding: 12px;
      border-bottom: 1px solid rgba(122, 161, 216, 0.12);
      vertical-align: top;
    }

    .structured-table th {
      background: rgba(13, 27, 48, 0.9);
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .structured-table td:first-child {
      width: 148px;
      background: rgba(10, 21, 38, 0.9);
    }

    .structured-table .editor-textarea {
      min-height: 94px;
    }

    .branch-toolbar {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
      align-items: center;
    }

    .branch-toolbar .hint {
      color: var(--muted);
      font-size: 12px;
      margin-right: 2px;
    }

    .issue-list {
      display: grid;
      gap: var(--space-2);
      margin: 0;
      padding: 0;
      list-style: none;
    }

    .issue-item {
      display: flex;
      gap: 10px;
      align-items: flex-start;
      padding: 10px 12px;
      border-radius: var(--radius-sm);
      font-size: 12px;
      line-height: 1.45;
    }

    .issue-item.warning {
      background: rgba(62, 45, 16, 0.64);
      border: 1px solid rgba(255, 191, 94, 0.18);
      color: #ffe5b8;
    }

    .issue-item.error {
      background: rgba(66, 25, 25, 0.68);
      border: 1px solid rgba(255, 125, 125, 0.22);
      color: #ffd2d2;
    }

    .issue-item::before {
      content: "!";
      width: 18px;
      height: 18px;
      border-radius: 999px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 11px;
      font-weight: 800;
      background: rgba(255, 255, 255, 0.12);
      flex-shrink: 0;
    }

    .placeholder-strip {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
    }

    .placeholder-chip {
      display: inline-flex;
      align-items: center;
      min-height: 28px;
      padding: 0 10px;
      border-radius: 999px;
      border: 1px dashed rgba(122, 161, 216, 0.28);
      color: var(--muted);
      font-size: 11px;
      font-family: "SFMono-Regular", "Roboto Mono", ui-monospace, monospace;
      background: rgba(8, 19, 34, 0.78);
    }

    .helper-copy {
      font-size: 12px;
      color: var(--muted);
      line-height: 1.45;
    }

    .modal {
      position: fixed;
      inset: 0;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 24px;
      background: rgba(4, 10, 19, 0.72);
      backdrop-filter: blur(14px);
      z-index: 60;
    }

    .modal.show {
      display: flex;
    }

    .modal-card {
      width: min(980px, 100%);
      max-height: min(86vh, 980px);
      overflow: auto;
      padding: 24px;
      border-radius: var(--radius-xl);
      border: 1px solid var(--border-strong);
      background: linear-gradient(180deg, rgba(11, 24, 45, 0.98), rgba(5, 14, 26, 1));
      box-shadow: var(--shadow);
    }

    .modal-card h2 {
      margin: 0;
      font-size: 24px;
      color: var(--text-strong);
    }

    .modal-card p {
      margin: 8px 0 0;
      color: var(--muted);
      line-height: 1.5;
      font-size: 13px;
    }

    .modal-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 14px;
      margin-top: 18px;
    }

    .modal-locale-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 14px;
      margin-top: 8px;
    }

    .modal-stack {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .modal-textarea {
      min-height: 120px;
      resize: vertical;
    }

    .modal-note,
    .validation-note {
      color: var(--muted);
      font-size: 12px;
      line-height: 1.45;
    }

    .validation-note.error {
      color: #ffd7d7;
    }

    .modal-actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 14px;
      margin-top: 20px;
      flex-wrap: wrap;
    }

    .modal-actions .left {
      color: var(--muted);
      font-size: 12px;
    }

    @media (max-width: 1399px) {
      .catalog-shell {
        width: min(calc(100% - 24px), var(--content-max));
      }

      .detail-panel {
        top: calc(var(--header-offset) + 174px);
      }
    }

    @media (max-width: 1080px) {
      .header-controls {
        grid-template-columns: 1fr 1fr;
      }

      .detail-panel {
        position: static;
      }

      .detail-scroll,
      .matrix-wrapper {
        max-height: none;
      }
    }

    @media (max-width: 839px) {
      .catalog-shell {
        width: min(calc(100% - 18px), var(--content-max));
      }

      .shell-header {
        top: 10px;
        padding: 18px;
        border-radius: 24px;
      }

      .header-top,
      .detail-header,
      .locale-header {
        grid-template-columns: 1fr;
        display: grid;
      }

      .header-controls {
        grid-template-columns: 1fr;
      }

      .workspace.is-medium,
      .workspace.is-compact {
        grid-template-columns: 1fr;
      }

      .field-grid.two {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 599px) {
      .catalog-shell {
        margin: 10px auto 18px;
      }

      .shell-header,
      .surface,
      .modal-card {
        border-radius: 22px;
      }

      .summary-card {
        min-width: calc(50% - 6px);
        flex: 1 1 calc(50% - 6px);
      }

      .matrix-wrapper {
        display: none;
      }

      .structured-table,
      .structured-table thead,
      .structured-table tbody,
      .structured-table tr,
      .structured-table th,
      .structured-table td {
        display: block;
        width: 100%;
      }

      .structured-table tr {
        border-bottom: 1px solid rgba(122, 161, 216, 0.12);
      }

      .structured-table td:first-child {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="catalog-shell">
    <header class="shell-header">
      <div class="header-top">
        <div class="header-brand">
          <div class="eyebrow">Translation Workspace</div>
          <h1>Anas Localization Catalog</h1>
          <p>
            Review translation status, edit locale content, and handle structured plural or gender values
            from a single responsive catalog.
          </p>
        </div>
        <div class="header-meta" id="headerMeta"></div>
      </div>
      <div class="header-controls">
        <div class="search-field">
          <label for="searchInput">Search keys or content</label>
          <input
            id="searchInput"
            class="search-input"
            type="text"
            autocomplete="off"
            placeholder="Search key path, translation copy, or structured content"
          />
        </div>
        <div class="control-cluster">
          <label>Status quick filters</label>
          <div class="status-cluster" id="statusFilters"></div>
        </div>
        <button class="action-btn" data-action="refresh">Refresh</button>
        <button class="action-btn primary" data-action="open-new-key">+ New String</button>
      </div>
      <div class="summary-row" id="summaryRow"></div>
      <div class="filters-row" id="activeFilters"></div>
    </header>

    <main class="workspace" id="workspace">
      <section class="surface master-panel">
        <div id="errorBanner" class="error-banner" role="alert"></div>
        <div class="panel-header">
          <div class="panel-title">
            <div>
              <h2 id="masterTitle">Catalog entries</h2>
              <p id="masterSubtitle">Pick a row to inspect, edit, review, or delete locale content.</p>
            </div>
            <div class="summary-chip" id="resultCount">0 results</div>
          </div>
        </div>
        <div class="panel-body" id="masterBody"></div>
      </section>

      <aside class="surface detail-panel" id="detailPanel">
        <div class="detail-scroll" id="detailBody"></div>
      </aside>
    </main>
  </div>

  <div id="statusLive" class="sr-only" aria-live="polite"></div>

  <div class="modal" id="newKeyModal" aria-hidden="true">
    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="newKeyTitle">
      <h2 id="newKeyTitle">Create New String</h2>
      <p>
        Add a dotted key once, provide source copy first, and optionally seed target locales before review.
      </p>
      <div class="modal-grid">
        <div class="modal-stack">
          <label for="newKeyPath">Key path</label>
          <input
            id="newKeyPath"
            class="modal-input"
            type="text"
            autocomplete="off"
            placeholder="home.header.title"
          />
          <div class="validation-note" id="newKeyValidation"></div>
        </div>
        <div class="modal-stack">
          <label>Locale values</label>
          <div class="modal-note">
            Source locale should contain the canonical copy. Empty target values are allowed, but they will stay in review-needed state.
          </div>
          <div class="modal-locale-grid" id="newKeyLocaleGrid"></div>
        </div>
      </div>
      <div class="modal-actions">
        <div class="left" id="newKeyHelper">Keys must use dotted segments with letters, numbers, or underscores.</div>
        <div style="display:flex; gap: 10px; flex-wrap: wrap;">
          <button class="action-btn" data-action="close-new-key">Cancel</button>
          <button class="action-btn primary" data-action="create-new-key" id="createKeyBtn">Create Key</button>
        </div>
      </div>
    </div>
  </div>

  <script>
    const API_BASE = '__API_URL__';
    const STATUS_OPTIONS = ['', 'green', 'warning', 'red'];
    const PLURAL_ORDER = ['zero', 'one', 'two', 'few', 'many', 'other'];
    const GENDER_KEYS = ['male', 'female'];
    const STATUS_COPY = {
      '': 'All statuses',
      green: 'Green',
      warning: 'Warning',
      red: 'Red',
    };
    const STATUS_DESCRIPTIONS = {
      green: 'Ready or explicitly reviewed',
      warning: 'Needs review or follow-up',
      red: 'Missing required translation',
    };
    const SHAPE_COPY = {
      plain: 'Plain text',
      gender: 'Gender',
      plural: 'Plural',
      pluralGender: 'Plural + gender',
      rawObject: 'Raw JSON',
    };
    const REASON_COPY = {
      source_changed: 'Source changed after this locale was reviewed.',
      source_added: 'Source copy was added and targets need attention.',
      source_deleted: 'Source value was deleted. Confirm whether this key should remain.',
      source_deleted_review_required: 'Source value was removed. Review this locale before keeping it.',
      target_missing: 'This locale is missing content for the selected key.',
      new_key_needs_translation_review: 'New key created. Review target locales before considering it complete.',
      target_updated_needs_review: 'Edited locally and waiting for review.',
    };

    const state = {
      meta: null,
      rows: [],
      summary: null,
      loading: true,
      error: null,
      query: '',
      status: '',
      mode: 'expanded',
      selectedKey: null,
      focusedLocale: null,
      drafts: {},
      scrollY: 0,
      focusRestore: null,
      searchTimer: null,
      modalOpen: false,
    };

    function escapeHtml(value) {
      return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }

    function toComparableValue(value) {
      return value === undefined ? null : value;
    }

    function cloneValue(value) {
      if (value === undefined) return '';
      if (value === null) return null;
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        return value;
      }
      return JSON.parse(JSON.stringify(value));
    }

    function stableSortValue(value) {
      if (value === null || value === undefined) return null;
      if (Array.isArray(value)) {
        return value.map(stableSortValue);
      }
      if (typeof value === 'object') {
        return Object.keys(value)
          .sort((a, b) => a.localeCompare(b))
          .reduce((acc, key) => {
            acc[key] = stableSortValue(value[key]);
            return acc;
          }, {});
      }
      return value;
    }

    function stableSerialize(value) {
      return JSON.stringify(stableSortValue(toComparableValue(value)));
    }

    function isPlainObject(value) {
      return value !== null && typeof value === 'object' && !Array.isArray(value);
    }

    function isEmptyValue(value) {
      if (value === null || value === undefined) return true;
      if (typeof value === 'string') return value.trim().length === 0;
      if (Array.isArray(value)) return value.length === 0;
      if (isPlainObject(value)) return Object.keys(value).length === 0;
      return false;
    }

    function orderedLocales() {
      if (!state.meta) return [];
      const source = state.meta.sourceLocale;
      return [source].concat(state.meta.locales.filter((locale) => locale !== source));
    }

    function directionForLocale(locale) {
      return state.meta?.localeDirections?.[locale] || 'ltr';
    }

    function isScalarLeaf(value) {
      return value === null || value === undefined || ['string', 'number', 'boolean'].includes(typeof value);
    }

    function isGenderBranch(value) {
      if (!isPlainObject(value)) return false;
      const keys = Object.keys(value);
      return keys.length > 0 && keys.every((key) => GENDER_KEYS.includes(key) && isScalarLeaf(value[key]));
    }

    function orderBranchKeys(keys) {
      return PLURAL_ORDER
        .filter((key) => keys.includes(key))
        .concat(keys.filter((key) => !PLURAL_ORDER.includes(key)).sort((a, b) => a.localeCompare(b)));
    }

    function detectValueShape(value) {
      if (!isPlainObject(value)) {
        return { kind: 'plain', branchKeys: [] };
      }

      const keys = Object.keys(value);
      if (keys.length === 0) {
        return { kind: 'rawObject', branchKeys: [] };
      }

      const allGender = keys.every((key) => GENDER_KEYS.includes(key) && isScalarLeaf(value[key]));
      if (allGender) {
        return {
          kind: 'gender',
          branchKeys: GENDER_KEYS.filter((key) => keys.includes(key)),
        };
      }

      const pluralLike = keys.some((key) => PLURAL_ORDER.includes(key)) || keys.some((key) => isGenderBranch(value[key]));
      const everyValueSupported = keys.every((key) => isScalarLeaf(value[key]) || isGenderBranch(value[key]));
      if (pluralLike && everyValueSupported) {
        const nestedGender = keys.some((key) => isGenderBranch(value[key]));
        return {
          kind: nestedGender ? 'pluralGender' : 'plural',
          branchKeys: orderBranchKeys(keys),
        };
      }

      return {
        kind: 'rawObject',
        branchKeys: keys.slice().sort((a, b) => a.localeCompare(b)),
      };
    }

    function supportsGuidedEditor(kind) {
      return kind === 'gender' || kind === 'plural' || kind === 'pluralGender';
    }

    function emptyFromShape(value) {
      if (isScalarLeaf(value)) return '';
      if (!isPlainObject(value)) return '';
      return Object.keys(value).reduce((acc, key) => {
        acc[key] = emptyFromShape(value[key]);
        return acc;
      }, {});
    }

    function chooseEditableValue(row, locale) {
      const currentValue = cloneValue(row.valuesByLocale[locale]);
      const currentShape = detectValueShape(currentValue);
      if (supportsGuidedEditor(currentShape.kind) || currentShape.kind === 'rawObject') {
        return {
          value: currentValue,
          shape: currentShape,
        };
      }

      const sourceValue = cloneValue(row.valuesByLocale[state.meta.sourceLocale]);
      const sourceShape = detectValueShape(sourceValue);
      if (isEmptyValue(currentValue) && supportsGuidedEditor(sourceShape.kind)) {
        return {
          value: emptyFromShape(sourceValue),
          shape: sourceShape,
        };
      }

      return {
        value: currentValue,
        shape: currentShape,
      };
    }

    function createDraft(row, locale) {
      const preferred = chooseEditableValue(row, locale);
      const shape = preferred.shape;
      const mode = shape.kind === 'plain' ? 'plain' : (shape.kind === 'rawObject' ? 'raw' : 'guided');
      return {
        keyPath: row.keyPath,
        locale,
        originalValue: cloneValue(row.valuesByLocale[locale]),
        value: cloneValue(preferred.value),
        mode,
        shapeKind: shape.kind,
        rawText: shape.kind === 'plain' ? '' : JSON.stringify(preferred.value ?? '', null, 2),
      };
    }

    function getRow(keyPath) {
      return state.rows.find((row) => row.keyPath === keyPath) || null;
    }

    function draftId(keyPath, locale) {
      return keyPath + '::' + locale;
    }

    function getDraft(keyPath, locale) {
      const id = draftId(keyPath, locale);
      if (!state.drafts[id]) {
        const row = getRow(keyPath);
        if (!row) return null;
        state.drafts[id] = createDraft(row, locale);
      }
      return state.drafts[id];
    }

    function clearLocaleDraft(keyPath, locale) {
      delete state.drafts[draftId(keyPath, locale)];
    }

    function clearRowDrafts(keyPath) {
      Object.keys(state.drafts).forEach((id) => {
        if (id.startsWith(keyPath + '::')) {
          delete state.drafts[id];
        }
      });
    }

    function flattenLeaves(value, prefix = '', acc = {}) {
      if (!isPlainObject(value)) {
        acc[prefix || 'value'] = value === undefined || value === null ? '' : String(value);
        return acc;
      }

      const keys = Object.keys(value);
      if (keys.length === 0) {
        acc[prefix || 'value'] = '';
        return acc;
      }

      keys.forEach((key) => {
        const nextPrefix = prefix ? prefix + '.' + key : key;
        flattenLeaves(value[key], nextPrefix, acc);
      });
      return acc;
    }

    function extractPlaceholders(text) {
      const matches = String(text ?? '').match(/\{[a-zA-Z0-9_]+\}/g) || [];
      return Array.from(new Set(matches)).sort((a, b) => a.localeCompare(b));
    }

    function humanizeReason(reason) {
      return REASON_COPY[reason] || String(reason || 'No review note yet.');
    }

    function formatTimestamp(value) {
      if (!value) return 'Never';
      const date = new Date(value);
      if (Number.isNaN(date.getTime())) return 'Unknown';
      return date.toLocaleString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    }

    function resolveDraftValue(row, locale, draft) {
      if (!draft) {
        return {
          value: row.valuesByLocale[locale],
          error: null,
          shape: detectValueShape(row.valuesByLocale[locale]),
        };
      }

      if (draft.mode === 'plain' || draft.mode === 'guided') {
        const value = cloneValue(draft.value);
        return {
          value,
          error: null,
          shape: detectValueShape(value),
        };
      }

      try {
        const parsed = JSON.parse(draft.rawText || 'null');
        return {
          value: parsed,
          error: null,
          shape: detectValueShape(parsed),
        };
      } catch (error) {
        return {
          value: null,
          error: 'Invalid JSON: ' + (error.message || String(error)),
          shape: { kind: 'rawObject', branchKeys: [] },
        };
      }
    }

    function collectDraftIssues(row, locale, draft, resolved) {
      const issues = [];
      if (resolved.error) {
        issues.push({ level: 'error', message: resolved.error });
        return issues;
      }

      const sourceValue = row.valuesByLocale[state.meta.sourceLocale];
      const sourceLeaves = flattenLeaves(sourceValue);
      const targetLeaves = flattenLeaves(resolved.value);

      const missingBranches = [];
      const emptyBranches = [];
      const placeholderWarnings = [];

      Object.keys(sourceLeaves).forEach((branch) => {
        if (!(branch in targetLeaves)) {
          missingBranches.push(branch);
          return;
        }

        if (String(targetLeaves[branch] ?? '').trim() === '') {
          emptyBranches.push(branch);
        }

        if (locale !== state.meta.sourceLocale) {
          const sourcePlaceholders = extractPlaceholders(sourceLeaves[branch]);
          const targetPlaceholders = extractPlaceholders(targetLeaves[branch]);
          const missingPlaceholders = sourcePlaceholders.filter((item) => !targetPlaceholders.includes(item));
          if (missingPlaceholders.length > 0) {
            placeholderWarnings.push(branch + ' misses ' + missingPlaceholders.join(', '));
          }
        }
      });

      if (missingBranches.length > 0) {
        issues.push({
          level: 'warning',
          message: 'Missing branches: ' + missingBranches.join(', '),
        });
      }

      if (emptyBranches.length > 0) {
        issues.push({
          level: 'warning',
          message: 'Empty branches: ' + emptyBranches.join(', '),
        });
      }

      if (placeholderWarnings.length > 0) {
        issues.push({
          level: 'warning',
          message: 'Placeholder mismatches: ' + placeholderWarnings.join(' • '),
        });
      }

      return issues;
    }

    function draftIsDirty(row, locale, draft, resolved) {
      return stableSerialize(resolved.value) !== stableSerialize(row.valuesByLocale[locale]);
    }

    function summarizeValue(value) {
      const shape = detectValueShape(value);
      if (shape.kind === 'plain') {
        const text = String(value ?? '').trim();
        return {
          kind: shape.kind,
          chips: [SHAPE_COPY.plain],
          preview: text || 'No text',
        };
      }

      if (shape.kind === 'rawObject') {
        const keys = isPlainObject(value) ? Object.keys(value) : [];
        return {
          kind: shape.kind,
          chips: [SHAPE_COPY.rawObject, keys.length + ' branches'],
          preview: JSON.stringify(stableSortValue(value)),
        };
      }

      const leafValues = Object.values(flattenLeaves(value));
      return {
        kind: shape.kind,
        chips: [
          SHAPE_COPY[shape.kind],
          shape.branchKeys.length + ' branches',
        ],
        preview: String(leafValues[0] ?? 'Structured content'),
      };
    }

    function rowStatusCounts(row) {
      return Object.values(row.cellStates).reduce((acc, cell) => {
        acc[cell.status] = (acc[cell.status] || 0) + 1;
        return acc;
      }, { green: 0, warning: 0, red: 0 });
    }

    function highestRowStatus(row) {
      if (Object.values(row.cellStates).some((cell) => cell.status === 'red')) return 'red';
      if (Object.values(row.cellStates).some((cell) => cell.status === 'warning')) return 'warning';
      return 'green';
    }

    function updateMode() {
      const width = window.innerWidth;
      state.mode = width < 600 ? 'compact' : (width < 840 ? 'medium' : 'expanded');
      const workspace = document.getElementById('workspace');
      workspace.className = 'workspace is-' + state.mode;
    }

    function setStatus(message, isError = false) {
      const live = document.getElementById('statusLive');
      live.textContent = message;
      const count = document.getElementById('resultCount');
      if (count) {
        count.textContent = message;
        count.style.borderColor = isError ? 'rgba(255, 125, 125, 0.28)' : 'rgba(122, 161, 216, 0.18)';
      }
    }

    function captureViewState() {
      state.scrollY = window.scrollY;
      const active = document.activeElement;
      if (active && active.dataset && active.dataset.keyPath && active.dataset.locale) {
        state.focusRestore = {
          keyPath: active.dataset.keyPath,
          locale: active.dataset.locale,
          selector: active.dataset.restoreSelector || '',
        };
      }
    }

    function restoreViewState() {
      window.scrollTo({ top: state.scrollY, behavior: 'auto' });
      if (!state.focusRestore) return;
      const selector =
        '[data-key-path="' + CSS.escape(state.focusRestore.keyPath) +
        '"][data-locale="' + CSS.escape(state.focusRestore.locale) + '"]' +
        (state.focusRestore.selector ? '[data-restore-selector="' + CSS.escape(state.focusRestore.selector) + '"]' : '');
      const element = document.querySelector(selector);
      if (element) {
        element.focus({ preventScroll: true });
      }
      state.focusRestore = null;
    }

    async function api(path, options = {}) {
      const response = await fetch(API_BASE + path, {
        headers: {
          'Content-Type': 'application/json',
          ...(options.headers || {}),
        },
        ...options,
      });
      const text = await response.text();
      const payload = text ? JSON.parse(text) : {};
      if (!response.ok) {
        throw new Error(payload.error || ('Request failed with ' + response.status));
      }
      return payload;
    }

    function ensureSelection() {
      if (state.rows.length === 0) {
        state.selectedKey = null;
        state.focusedLocale = null;
        return;
      }

      const current = getRow(state.selectedKey || '');
      if (!current) {
        state.selectedKey = state.rows[0].keyPath;
      }

      if (!state.focusedLocale || !state.meta.locales.includes(state.focusedLocale)) {
        state.focusedLocale = state.meta.sourceLocale;
      }
    }

    async function refreshRows(options = {}) {
      const announceMessage = options.announceMessage !== false;
      captureViewState();
      state.loading = true;
      state.error = null;
      render();
      try {
        const params = new URLSearchParams();
        if (state.query.trim()) params.set('search', state.query.trim());
        if (state.status) params.set('status', state.status);
        const suffix = params.toString() ? '?' + params.toString() : '';
        const [rowsResult, summary] = await Promise.all([
          api('/api/catalog/rows' + suffix),
          api('/api/catalog/summary'),
        ]);
        state.rows = rowsResult.rows || [];
        state.summary = summary;
        ensureSelection();
        if (announceMessage) {
          setStatus('Loaded ' + state.rows.length + ' row' + (state.rows.length === 1 ? '' : 's') + '.');
        }
      } catch (error) {
        state.error = error.message || String(error);
        setStatus(state.error, true);
      } finally {
        state.loading = false;
        render();
        restoreViewState();
      }
    }

    function setSelectedRow(keyPath, locale = null) {
      state.selectedKey = keyPath;
      if (locale) {
        state.focusedLocale = locale;
      }
      render();
    }

    function renderHeaderMeta() {
      const meta = state.meta;
      const header = document.getElementById('headerMeta');
      if (!meta) {
        header.innerHTML = '';
        return;
      }

      header.innerHTML = [
        '<span class="badge-pill source-pill">Source locale: <strong>' + escapeHtml(meta.sourceLocale.toUpperCase()) + '</strong></span>',
        '<span class="badge-pill mode-pill">Layout: <strong>' + escapeHtml(state.mode) + '</strong></span>',
        '<span class="badge-pill mode-pill">Locales: <strong>' + meta.locales.length + '</strong></span>',
      ].join('');
    }

    function renderStatusFilters() {
      const holder = document.getElementById('statusFilters');
      const counts = {
        '': state.summary ? state.summary.totalKeys : 0,
        green: state.summary ? state.summary.greenCount : 0,
        warning: state.summary ? state.summary.warningCount : 0,
        red: state.summary ? state.summary.redCount : 0,
      };
      holder.innerHTML = STATUS_OPTIONS.map((status) => {
        const active = state.status === status ? ' active' : '';
        return (
          '<button class="filter-btn' + active + '" data-action="set-status" data-status="' + status + '">' +
            '<span>' + escapeHtml(STATUS_COPY[status]) + '</span>' +
            '<strong>' + counts[status] + '</strong>' +
          '</button>'
        );
      }).join('');
    }

    function renderSummary() {
      const row = document.getElementById('summaryRow');
      if (!state.summary) {
        row.innerHTML = '';
        return;
      }

      const cards = [
        { label: 'Keys', value: state.summary.totalKeys, tone: '' },
        { label: 'Green', value: state.summary.greenCount, tone: ' green' },
        { label: 'Warning', value: state.summary.warningCount, tone: ' warning' },
        { label: 'Red', value: state.summary.redCount, tone: ' red' },
      ];
      row.innerHTML = cards.map((item) => (
        '<div class="summary-card' + item.tone + '">' +
          '<div class="label">' + escapeHtml(item.label) + '</div>' +
          '<strong>' + item.value + '</strong>' +
        '</div>'
      )).join('');
    }

    function renderActiveFilters() {
      const holder = document.getElementById('activeFilters');
      const filters = [];
      if (state.query.trim()) {
        filters.push('<span class="filter-chip">Query: <strong>' + escapeHtml(state.query.trim()) + '</strong></span>');
      }
      if (state.status) {
        filters.push('<span class="filter-chip">Status: <strong>' + escapeHtml(STATUS_COPY[state.status]) + '</strong></span>');
      }
      if (filters.length === 0) {
        holder.innerHTML = '<span class="hint">No active filters.</span>';
        return;
      }
      holder.innerHTML = '<span class="hint">Active filters:</span>' + filters.join('') +
        '<button class="ghost-link" data-action="clear-filters">Clear filters</button>';
    }

    function renderErrorBanner() {
      const banner = document.getElementById('errorBanner');
      if (!state.error) {
        banner.className = 'error-banner';
        banner.innerHTML = '';
        return;
      }

      banner.className = 'error-banner show';
      banner.innerHTML =
        '<div style="flex:1;">' +
          '<strong>Catalog request failed.</strong>' +
          '<div class="helper-copy" style="color:#ffd8d8; margin-top:4px;">' + escapeHtml(state.error) + '</div>' +
        '</div>' +
        '<button class="action-btn" data-action="refresh">Retry</button>';
    }

    function renderLoadingShell(lines = 4) {
      const items = Array.from({ length: lines }, (_, index) =>
        '<div class="skeleton" style="height:' + (index === 0 ? 96 : 82) + 'px;"></div>'
      );
      return '<div class="loading-shell">' + items.join('') + '</div>';
    }

    function renderMasterBody() {
      const body = document.getElementById('masterBody');

      if (state.loading && state.rows.length === 0) {
        body.innerHTML = renderLoadingShell(state.mode === 'expanded' ? 5 : 4);
        return;
      }

      if (!state.loading && state.rows.length === 0) {
        body.innerHTML =
          '<div class="empty-state">' +
            '<h3>No rows match this filter</h3>' +
            '<p>Try clearing the search or status filters, or create a new key to seed the catalog.</p>' +
            '<div style="display:flex; gap:10px; justify-content:center; flex-wrap:wrap;">' +
              '<button class="action-btn" data-action="clear-filters">Clear filters</button>' +
              '<button class="action-btn primary" data-action="open-new-key">+ New String</button>' +
            '</div>' +
          '</div>';
        return;
      }

      body.innerHTML = state.mode === 'expanded'
        ? renderExpandedTable()
        : renderRowCards();
    }

    function renderExpandedTable() {
      const locales = orderedLocales();
      const headers = locales.map((locale) => {
        const source = locale === state.meta.sourceLocale
          ? ' <span class="shape-badge source-chip">Source</span>'
          : '';
        return '<th>' + escapeHtml(locale.toUpperCase()) + source + '</th>';
      }).join('');

      const rows = state.rows.map((row) => {
        const selected = row.keyPath === state.selectedKey ? ' is-selected' : '';
        const cells = locales.map((locale) => renderMatrixCell(row, locale)).join('');
        return (
          '<tr class="' + selected.trim() + '">' +
            '<td class="key-column">' +
              '<button class="row-card' + (row.keyPath === state.selectedKey ? ' active' : '') + '" ' +
                'data-action="select-row" data-key-path="' + escapeHtml(row.keyPath) + '" style="padding:14px;">' +
                '<div class="row-card-topline">' +
                  renderStatusBadge(highestRowStatus(row)) +
                  '<span class="shape-badge">' + escapeHtml(rowStatusCounts(row).green + ' / ' + rowStatusCounts(row).warning + ' / ' + rowStatusCounts(row).red) + '</span>' +
                '</div>' +
                '<code>' + escapeHtml(row.keyPath) + '</code>' +
              '</button>' +
            '</td>' +
            cells +
            '<td>' +
              '<button class="action-btn danger" data-action="delete-key" data-key-path="' + escapeHtml(row.keyPath) + '">Delete key</button>' +
            '</td>' +
          '</tr>'
        );
      }).join('');

      return (
        '<div class="matrix-wrapper">' +
          '<table class="catalog-table" id="catalogTable">' +
            '<thead>' +
              '<tr>' +
                '<th>Key</th>' +
                headers +
                '<th>Actions</th>' +
              '</tr>' +
            '</thead>' +
            '<tbody>' + rows + '</tbody>' +
          '</table>' +
        '</div>'
      );
    }

    function renderMatrixCell(row, locale) {
      const cellState = row.cellStates[locale] || { status: 'warning' };
      const summary = summarizeValue(row.valuesByLocale[locale]);
      const active = row.keyPath === state.selectedKey && locale === state.focusedLocale ? ' active' : '';
      const direction = directionForLocale(locale);
      const metaBits = [];
      if (cellState.lastReviewedAt) metaBits.push('Reviewed ' + formatTimestamp(cellState.lastReviewedAt));
      else metaBits.push('Not reviewed yet');
      if (cellState.lastEditedAt) metaBits.push('Edited ' + formatTimestamp(cellState.lastEditedAt));

      return (
        '<td>' +
          '<button class="matrix-cell' + active + '" data-action="select-cell" data-key-path="' + escapeHtml(row.keyPath) +
            '" data-locale="' + escapeHtml(locale) + '">' +
            '<div class="cell-topline">' +
              renderStatusBadge(cellState.status) +
              summary.chips.map((chip) => '<span class="shape-badge">' + escapeHtml(chip) + '</span>').join('') +
            '</div>' +
            '<span class="preview-text' + (summary.kind === 'plain' ? '' : ' structured') + '" dir="' + direction + '">' +
              escapeHtml(summary.preview) +
            '</span>' +
            '<span class="cell-meta">' + escapeHtml(humanizeReason(cellState.reason)) + '</span>' +
            '<span class="cell-meta">' + escapeHtml(metaBits.join(' · ')) + '</span>' +
          '</button>' +
        '</td>'
      );
    }

    function renderRowCards() {
      const cards = state.rows.map((row) => {
        const selected = row.keyPath === state.selectedKey ? ' active' : '';
        const counts = rowStatusCounts(row);
        const sourceSummary = summarizeValue(row.valuesByLocale[state.meta.sourceLocale]);
        const localeChips = orderedLocales().map((locale) => {
          const cellState = row.cellStates[locale] || { status: 'warning' };
          return '<span class="summary-chip">' + escapeHtml(locale.toUpperCase()) + ' ' + escapeHtml(STATUS_COPY[cellState.status]) + '</span>';
        }).join('');
        return (
          '<button class="row-card' + selected + '" data-action="select-row" data-key-path="' + escapeHtml(row.keyPath) + '">' +
            '<div class="row-card-topline">' +
              renderStatusBadge(highestRowStatus(row)) +
              '<span class="shape-badge">' + counts.green + ' green</span>' +
              '<span class="shape-badge">' + counts.warning + ' warning</span>' +
              '<span class="shape-badge">' + counts.red + ' red</span>' +
            '</div>' +
            '<code>' + escapeHtml(row.keyPath) + '</code>' +
            '<div class="row-card-locales">' + localeChips + '</div>' +
            '<p class="preview-text' + (sourceSummary.kind === 'plain' ? '' : ' structured') + '" dir="' + directionForLocale(state.meta.sourceLocale) + '">' +
              escapeHtml(sourceSummary.preview) +
            '</p>' +
          '</button>'
        );
      }).join('');
      return '<div class="row-list">' + cards + '</div>';
    }

    function renderDetailBody() {
      const body = document.getElementById('detailBody');
      if (state.loading && !state.selectedKey) {
        body.innerHTML = renderLoadingShell(4);
        return;
      }

      if (!state.selectedKey) {
        body.innerHTML =
          '<div class="empty-state">' +
            '<h3>Select a key</h3>' +
            '<p>Pick a row from the catalog to edit locale values, review status, or inspect structured translation branches.</p>' +
          '</div>';
        return;
      }

      const row = getRow(state.selectedKey);
      if (!row) {
        body.innerHTML =
          '<div class="empty-state">' +
            '<h3>Selected key is hidden</h3>' +
            '<p>The current filters removed this key from the results. Clear filters or select a different row.</p>' +
          '</div>';
        return;
      }

      const counts = rowStatusCounts(row);
      const localeSections = orderedLocales().map((locale) => renderLocaleSection(row, locale)).join('');
      body.innerHTML =
        '<div class="detail-header">' +
          '<div>' +
            '<div class="eyebrow" style="margin-bottom:10px;">Selected key</div>' +
            '<h2><code>' + escapeHtml(row.keyPath) + '</code></h2>' +
            '<p>Source locale: ' + escapeHtml(state.meta.sourceLocale.toUpperCase()) + ' · ' +
              escapeHtml(state.meta.format.toUpperCase()) + ' catalog format</p>' +
          '</div>' +
          '<div style="display:flex; gap:10px; flex-wrap:wrap;">' +
            '<button class="action-btn danger" data-action="delete-key" data-key-path="' + escapeHtml(row.keyPath) + '">Delete key</button>' +
          '</div>' +
        '</div>' +
        '<div class="detail-summary">' +
          '<span class="summary-chip"><strong>' + counts.green + '</strong> green</span>' +
          '<span class="summary-chip"><strong>' + counts.warning + '</strong> warning</span>' +
          '<span class="summary-chip"><strong>' + counts.red + '</strong> red</span>' +
        '</div>' +
        '<div class="locale-stack">' + localeSections + '</div>';
    }

    function renderLocaleSection(row, locale) {
      const cellState = row.cellStates[locale] || { status: 'warning' };
      const draft = getDraft(row.keyPath, locale);
      const resolved = resolveDraftValue(row, locale, draft);
      const issues = collectDraftIssues(row, locale, draft, resolved);
      const dirty = draftIsDirty(row, locale, draft, resolved);
      const placeholders = Array.from(
        new Set(
          Object.values(flattenLeaves(row.valuesByLocale[state.meta.sourceLocale]))
            .flatMap((text) => extractPlaceholders(text))
        )
      ).sort((a, b) => a.localeCompare(b));

      const reviewDisabled =
        locale === state.meta.sourceLocale ||
        dirty ||
        !!resolved.error ||
        isEmptyValue(resolved.value);

      const saveDisabled = !!resolved.error;
      const showToggle = draft.mode !== 'plain';
      const sectionClass = 'locale-section' + (locale === state.focusedLocale ? ' active' : '');
      return (
        '<section class="' + sectionClass + '" dir="' + directionForLocale(locale) + '">' +
          '<div class="locale-header">' +
            '<div>' +
              '<div class="locale-topline">' +
                '<span class="badge-pill' + (locale === state.meta.sourceLocale ? ' source-pill' : '') + '">' +
                  escapeHtml(locale.toUpperCase()) +
                  (locale === state.meta.sourceLocale ? ' Source' : '') +
                '</span>' +
                renderStatusBadge(cellState.status) +
                '<span class="shape-badge">' + escapeHtml(SHAPE_COPY[resolved.shape.kind]) + '</span>' +
              '</div>' +
              '<div class="detail-meta" style="margin-top:10px;">' + escapeHtml(humanizeReason(cellState.reason)) + '</div>' +
              '<div class="detail-meta" style="margin-top:6px;">' +
                'Last reviewed: ' + escapeHtml(formatTimestamp(cellState.lastReviewedAt)) +
                ' · Last edited: ' + escapeHtml(formatTimestamp(cellState.lastEditedAt)) +
              '</div>' +
            '</div>' +
            '<div class="locale-actions">' +
              (showToggle ? renderModeToggle(row.keyPath, locale, draft) : '') +
              '<button class="action-btn" data-action="save-locale" data-key-path="' + escapeHtml(row.keyPath) +
                '" data-locale="' + escapeHtml(locale) + '"' + (saveDisabled ? ' disabled' : '') + '>Save</button>' +
              '<button class="action-btn" data-action="review-locale" data-key-path="' + escapeHtml(row.keyPath) +
                '" data-locale="' + escapeHtml(locale) + '"' + (reviewDisabled ? ' disabled' : '') + '>Review</button>' +
              '<button class="action-btn danger" data-action="delete-locale" data-key-path="' + escapeHtml(row.keyPath) +
                '" data-locale="' + escapeHtml(locale) + '">Delete</button>' +
            '</div>' +
          '</div>' +
          '<div class="locale-body">' +
            '<div class="helper-copy">' +
              (dirty ? 'Unsaved changes are present for this locale.' : 'No unsaved changes for this locale.') +
            '</div>' +
            renderPlaceholderStrip(placeholders) +
            renderIssues(issues) +
            renderLocaleEditor(row, locale, draft, resolved) +
          '</div>' +
        '</section>'
      );
    }

    function renderModeToggle(keyPath, locale, draft) {
      const guidedDisabled = draft.mode === 'raw' && !supportsGuidedEditor(resolveDraftValue(getRow(keyPath), locale, draft).shape.kind);
      const guidedActive = draft.mode === 'guided';
      const rawActive = draft.mode === 'raw';
      return (
        '<div class="toggle-group">' +
          '<button class="toggle-btn' + (guidedActive ? ' active' : '') + '" data-action="toggle-mode" data-mode="guided" ' +
            'data-key-path="' + escapeHtml(keyPath) + '" data-locale="' + escapeHtml(locale) + '"' +
            (guidedDisabled ? ' disabled' : '') + '>Guided</button>' +
          '<button class="toggle-btn' + (rawActive ? ' active' : '') + '" data-action="toggle-mode" data-mode="raw" ' +
            'data-key-path="' + escapeHtml(keyPath) + '" data-locale="' + escapeHtml(locale) + '">Raw JSON</button>' +
        '</div>'
      );
    }

    function renderPlaceholderStrip(placeholders) {
      if (placeholders.length === 0) {
        return '<div class="helper-copy">No source placeholders detected for this key.</div>';
      }
      return (
        '<div>' +
          '<div class="helper-copy" style="margin-bottom:8px;">Source placeholders</div>' +
          '<div class="placeholder-strip">' +
            placeholders.map((item) => '<span class="placeholder-chip">' + escapeHtml(item) + '</span>').join('') +
          '</div>' +
        '</div>'
      );
    }

    function renderIssues(issues) {
      if (issues.length === 0) {
        return '';
      }
      return (
        '<ul class="issue-list">' +
          issues.map((issue) =>
            '<li class="issue-item ' + issue.level + '">' + escapeHtml(issue.message) + '</li>'
          ).join('') +
        '</ul>'
      );
    }

    function renderLocaleEditor(row, locale, draft, resolved) {
      if (draft.mode === 'plain') {
        return renderPlainEditor(row, locale, draft);
      }

      if (draft.mode === 'raw') {
        return renderRawEditor(row, locale, draft, resolved);
      }

      if (resolved.shape.kind === 'gender') {
        return renderGenderEditor(row, locale, draft);
      }

      if (resolved.shape.kind === 'plural') {
        return renderPluralEditor(row, locale, draft);
      }

      if (resolved.shape.kind === 'pluralGender') {
        return renderPluralGenderEditor(row, locale, draft);
      }

      return renderRawEditor(row, locale, draft, resolved);
    }

    function renderPlainEditor(row, locale, draft) {
      return (
        '<div class="field-card">' +
          '<div class="field-header">' +
            '<label for="plain-' + escapeHtml(row.keyPath) + '-' + escapeHtml(locale) + '">Translation text</label>' +
            '<span class="field-hint">Press Cmd/Ctrl + Enter to save</span>' +
          '</div>' +
          '<textarea class="editor-textarea" data-editor="plain" data-key-path="' + escapeHtml(row.keyPath) +
            '" data-locale="' + escapeHtml(locale) + '" data-restore-selector="plain">' +
            escapeHtml(draft.value ?? '') +
          '</textarea>' +
        '</div>'
      );
    }

    function renderRawEditor(row, locale, draft, resolved) {
      const shapeHint = resolved.shape.kind === 'rawObject'
        ? 'Unsupported object shapes stay in raw JSON mode.'
        : 'Switch back to guided mode when the JSON matches a supported plural or gender shape.';
      return (
        '<div class="field-card">' +
          '<div class="field-header">' +
            '<label for="raw-' + escapeHtml(row.keyPath) + '-' + escapeHtml(locale) + '">Advanced JSON editor</label>' +
            '<span class="field-hint">' + escapeHtml(shapeHint) + '</span>' +
          '</div>' +
          '<textarea class="raw-editor" data-editor="raw" data-key-path="' + escapeHtml(row.keyPath) +
            '" data-locale="' + escapeHtml(locale) + '" data-restore-selector="raw">' +
            escapeHtml(draft.rawText) +
          '</textarea>' +
        '</div>'
      );
    }

    function renderGenderEditor(row, locale, draft) {
      const value = isPlainObject(draft.value) ? draft.value : {};
      return (
        '<div class="field-grid two">' +
          GENDER_KEYS.map((gender) => (
            '<div class="field-card">' +
              '<div class="field-header">' +
                '<label>' + escapeHtml(gender) + '</label>' +
                '<span class="shape-badge">Gender</span>' +
              '</div>' +
              '<textarea class="editor-textarea" data-editor="guided" data-field-path="' + escapeHtml(gender) +
                '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) +
                '" data-restore-selector="guided">' + escapeHtml(value[gender] ?? '') + '</textarea>' +
            '</div>'
          )).join('') +
        '</div>'
      );
    }

    function renderPluralEditor(row, locale, draft) {
      const value = isPlainObject(draft.value) ? draft.value : {};
      const keys = orderBranchKeys(Object.keys(value));
      const missing = PLURAL_ORDER.filter((branch) => !keys.includes(branch));
      return (
        '<div class="field-grid single">' +
          '<div class="branch-toolbar">' +
            '<span class="hint">Plural branches</span>' +
            missing.map((branch) =>
              '<button class="branch-btn" data-action="add-branch" data-branch-kind="plural" data-branch="' +
                escapeHtml(branch) + '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' +
                escapeHtml(locale) + '">' + escapeHtml(branch) + '</button>'
            ).join('') +
            '<button class="branch-btn" data-action="add-custom-branch" data-branch-kind="plural" data-key-path="' +
              escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">Custom branch</button>' +
          '</div>' +
          keys.map((branch) => (
            '<div class="branch-row">' +
              '<div class="branch-header">' +
                '<label>' + escapeHtml(branch) + '</label>' +
                (!PLURAL_ORDER.includes(branch)
                  ? '<button class="branch-btn danger" data-action="remove-branch" data-branch="' + escapeHtml(branch) +
                    '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">Remove</button>'
                  : '<span class="shape-badge">Plural</span>') +
              '</div>' +
              '<textarea class="editor-textarea" data-editor="guided" data-field-path="' + escapeHtml(branch) +
                '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) +
                '" data-restore-selector="guided">' + escapeHtml(value[branch] ?? '') + '</textarea>' +
            '</div>'
          )).join('') +
        '</div>'
      );
    }

    function renderPluralGenderEditor(row, locale, draft) {
      const value = isPlainObject(draft.value) ? draft.value : {};
      const keys = orderBranchKeys(Object.keys(value));
      const missing = PLURAL_ORDER.filter((branch) => !keys.includes(branch));
      const rows = keys.map((branch) => {
        const branchValue = isPlainObject(value[branch]) ? value[branch] : {};
        return (
          '<tr>' +
            '<td>' +
              '<div class="branch-header">' +
                '<label>' + escapeHtml(branch) + '</label>' +
                (!PLURAL_ORDER.includes(branch)
                  ? '<button class="branch-btn danger" data-action="remove-branch" data-branch="' + escapeHtml(branch) +
                    '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">Remove</button>'
                  : '<span class="shape-badge">Plural</span>') +
              '</div>' +
            '</td>' +
            GENDER_KEYS.map((gender) => (
              '<td>' +
                '<textarea class="editor-textarea" data-editor="guided" data-field-path="' + escapeHtml(branch + '.' + gender) +
                  '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) +
                  '" data-restore-selector="guided">' + escapeHtml(branchValue[gender] ?? '') + '</textarea>' +
              '</td>'
            )).join('') +
          '</tr>'
        );
      }).join('');

      return (
        '<div class="field-grid single">' +
          '<div class="branch-toolbar">' +
            '<span class="hint">Plural and gender branches</span>' +
            missing.map((branch) =>
              '<button class="branch-btn" data-action="add-branch" data-branch-kind="pluralGender" data-branch="' +
                escapeHtml(branch) + '" data-key-path="' + escapeHtml(row.keyPath) + '" data-locale="' +
                escapeHtml(locale) + '">' + escapeHtml(branch) + '</button>'
            ).join('') +
            '<button class="branch-btn" data-action="add-custom-branch" data-branch-kind="pluralGender" data-key-path="' +
              escapeHtml(row.keyPath) + '" data-locale="' + escapeHtml(locale) + '">Custom branch</button>' +
          '</div>' +
          '<table class="structured-table">' +
            '<thead><tr><th>Branch</th><th>Male</th><th>Female</th></tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
          '</table>' +
        '</div>'
      );
    }

    function renderStatusBadge(status) {
      return '<span class="status-badge status-' + escapeHtml(status) + '">' + escapeHtml(STATUS_COPY[status] || status) + '</span>';
    }

    function renderNewKeyLocaleInputs() {
      const grid = document.getElementById('newKeyLocaleGrid');
      grid.innerHTML = orderedLocales().map((locale) => (
        '<div class="modal-stack" dir="' + directionForLocale(locale) + '">' +
          '<label for="newKeyValue_' + escapeHtml(locale) + '">' +
            escapeHtml(locale.toUpperCase()) +
            (locale === state.meta.sourceLocale ? ' (source)' : '') +
          '</label>' +
          '<textarea class="modal-input modal-textarea" id="newKeyValue_' + escapeHtml(locale) + '" ' +
            'placeholder="' + escapeHtml(locale === state.meta.sourceLocale ? 'Canonical source copy' : 'Optional at creation') + '"></textarea>' +
        '</div>'
      )).join('');
    }

    function validateKeyPath(value) {
      const trimmed = String(value || '').trim();
      if (!trimmed || trimmed.startsWith('.') || trimmed.endsWith('.') || trimmed.includes('..')) {
        return 'Use dot-separated segments without leading, trailing, or double dots.';
      }
      if (!trimmed.split('.').every((segment) => /^[a-zA-Z0-9_]+$/.test(segment))) {
        return 'Each segment may contain only letters, numbers, or underscores.';
      }
      return '';
    }

    function updateNewKeyValidation() {
      const keyPath = document.getElementById('newKeyPath').value.trim();
      const error = validateKeyPath(keyPath);
      const sourceValue = document.getElementById('newKeyValue_' + state.meta.sourceLocale)?.value.trim() || '';
      const note = document.getElementById('newKeyValidation');
      const helper = document.getElementById('newKeyHelper');
      const button = document.getElementById('createKeyBtn');

      if (error) {
        note.textContent = error;
        note.className = 'validation-note error';
        button.disabled = true;
        return false;
      }

      if (!sourceValue) {
        note.textContent = 'Source locale is empty. You can still create the key, but the row will need review immediately.';
        note.className = 'validation-note';
      } else {
        note.textContent = 'Key path is valid and ready to create.';
        note.className = 'validation-note';
      }

      helper.textContent = 'Source locale: ' + state.meta.sourceLocale.toUpperCase() + ' · Empty targets will stay review-needed until updated.';
      button.disabled = false;
      return true;
    }

    function openNewKeyModal() {
      state.modalOpen = true;
      const modal = document.getElementById('newKeyModal');
      modal.classList.add('show');
      modal.setAttribute('aria-hidden', 'false');
      document.getElementById('newKeyPath').value = '';
      orderedLocales().forEach((locale) => {
        const input = document.getElementById('newKeyValue_' + locale);
        if (input) input.value = '';
      });
      updateNewKeyValidation();
      window.setTimeout(() => document.getElementById('newKeyPath').focus(), 0);
    }

    function closeNewKeyModal() {
      state.modalOpen = false;
      const modal = document.getElementById('newKeyModal');
      modal.classList.remove('show');
      modal.setAttribute('aria-hidden', 'true');
    }

    async function createNewKey() {
      const keyPath = document.getElementById('newKeyPath').value.trim();
      if (!updateNewKeyValidation()) {
        return;
      }

      const valuesByLocale = {};
      orderedLocales().forEach((locale) => {
        valuesByLocale[locale] = document.getElementById('newKeyValue_' + locale)?.value || '';
      });

      if (String(valuesByLocale[state.meta.sourceLocale] || '').trim() === '') {
        const accepted = window.confirm(
          'The source locale is empty. The key will be created in review-needed state. Continue?'
        );
        if (!accepted) return;
      }

      await api('/api/catalog/key', {
        method: 'POST',
        body: JSON.stringify({
          keyPath,
          valuesByLocale,
          markGreenIfComplete: true,
        }),
      });
      closeNewKeyModal();
      clearRowDrafts(keyPath);
      await refreshRows({ announceMessage: false });
      state.selectedKey = keyPath;
      state.focusedLocale = state.meta.sourceLocale;
      render();
      setStatus('Added key ' + keyPath + '.');
    }

    function updateDraftFromInput(target) {
      const keyPath = target.dataset.keyPath;
      const locale = target.dataset.locale;
      if (!keyPath || !locale) return;
      const draft = getDraft(keyPath, locale);
      if (!draft) return;

      if (target.dataset.editor === 'plain') {
        draft.value = target.value;
      } else if (target.dataset.editor === 'raw') {
        draft.rawText = target.value;
      } else if (target.dataset.editor === 'guided') {
        const path = (target.dataset.fieldPath || '').split('.').filter(Boolean);
        if (!isPlainObject(draft.value)) {
          draft.value = {};
        }
        let current = draft.value;
        for (let index = 0; index < path.length - 1; index++) {
          const part = path[index];
          if (!isPlainObject(current[part])) {
            current[part] = {};
          }
          current = current[part];
        }
        current[path[path.length - 1]] = target.value;
      }

    }

    function addBranch(keyPath, locale, branchKind, branchName) {
      const draft = getDraft(keyPath, locale);
      if (!draft) return;
      if (!isPlainObject(draft.value)) {
        draft.value = {};
      }
      if (branchKind === 'pluralGender') {
        draft.value[branchName] = { male: '', female: '' };
      } else {
        draft.value[branchName] = '';
      }
      renderDetailBody();
    }

    function removeBranch(keyPath, locale, branchName) {
      const draft = getDraft(keyPath, locale);
      if (!draft || !isPlainObject(draft.value)) return;
      delete draft.value[branchName];
      renderDetailBody();
    }

    function switchDraftMode(keyPath, locale, nextMode) {
      const row = getRow(keyPath);
      const draft = getDraft(keyPath, locale);
      if (!row || !draft || draft.mode === nextMode) return;

      const resolved = resolveDraftValue(row, locale, draft);
      if (nextMode === 'raw') {
        draft.rawText = JSON.stringify(resolved.value ?? '', null, 2);
        draft.mode = 'raw';
        renderDetailBody();
        return;
      }

      if (nextMode === 'guided') {
        if (resolved.error) {
          setStatus(resolved.error, true);
          renderDetailBody();
          return;
        }
        if (!supportsGuidedEditor(resolved.shape.kind)) {
          setStatus('Guided mode is available only for plural or gender structures.', true);
          return;
        }
        draft.value = cloneValue(resolved.value);
        draft.mode = 'guided';
        renderDetailBody();
      }
    }

    async function saveLocale(keyPath, locale) {
      const row = getRow(keyPath);
      const draft = getDraft(keyPath, locale);
      if (!row || !draft) return;
      const resolved = resolveDraftValue(row, locale, draft);
      if (resolved.error) {
        setStatus(resolved.error, true);
        renderDetailBody();
        return;
      }

      await api('/api/catalog/cell', {
        method: 'PATCH',
        body: JSON.stringify({
          keyPath,
          locale,
          value: resolved.value,
        }),
      });

      if (locale === state.meta.sourceLocale) {
        clearRowDrafts(keyPath);
      } else {
        clearLocaleDraft(keyPath, locale);
      }
      await refreshRows({ announceMessage: false });
      state.selectedKey = keyPath;
      state.focusedLocale = locale;
      render();
      setStatus('Saved ' + keyPath + ' (' + locale + ').');
    }

    async function reviewLocale(keyPath, locale) {
      const row = getRow(keyPath);
      const draft = getDraft(keyPath, locale);
      if (!row || !draft) return;
      const resolved = resolveDraftValue(row, locale, draft);
      if (resolved.error) {
        throw new Error(resolved.error);
      }
      if (draftIsDirty(row, locale, draft, resolved)) {
        throw new Error('Save changes before marking this locale as reviewed.');
      }
      if (isEmptyValue(resolved.value)) {
        throw new Error('Cannot review an empty locale value.');
      }

      await api('/api/catalog/review', {
        method: 'POST',
        body: JSON.stringify({ keyPath, locale }),
      });
      clearLocaleDraft(keyPath, locale);
      await refreshRows({ announceMessage: false });
      state.selectedKey = keyPath;
      state.focusedLocale = locale;
      render();
      setStatus('Reviewed ' + keyPath + ' (' + locale + ').');
    }

    async function deleteLocaleValue(keyPath, locale) {
      const isSource = locale === state.meta.sourceLocale;
      const message = isSource
        ? 'Delete the source locale value? This will mark every target locale as requiring review.'
        : 'Delete only the ' + locale.toUpperCase() + ' value for "' + keyPath + '"?';
      if (!window.confirm(message)) return;

      await api('/api/catalog/cell', {
        method: 'DELETE',
        body: JSON.stringify({ keyPath, locale }),
      });
      clearLocaleDraft(keyPath, locale);
      await refreshRows({ announceMessage: false });
      state.selectedKey = keyPath;
      state.focusedLocale = locale;
      render();
      setStatus('Deleted value for ' + keyPath + ' (' + locale + ').');
    }

    async function deleteKey(keyPath) {
      if (!window.confirm('Delete "' + keyPath + '" from every locale and remove saved review state?')) {
        return;
      }

      await api('/api/catalog/key', {
        method: 'DELETE',
        body: JSON.stringify({ keyPath }),
      });
      clearRowDrafts(keyPath);
      await refreshRows({ announceMessage: false });
      render();
      setStatus('Deleted key ' + keyPath + '.');
    }

    function clearFilters() {
      state.query = '';
      state.status = '';
      document.getElementById('searchInput').value = '';
      refreshRows();
    }

    function render() {
      updateMode();
      renderHeaderMeta();
      renderStatusFilters();
      renderSummary();
      renderActiveFilters();
      renderErrorBanner();
      renderMasterBody();
      renderDetailBody();
    }

    async function bootstrap() {
      try {
        updateMode();
        setStatus('Loading catalog metadata...');
        state.meta = await api('/api/catalog/meta');
        renderNewKeyLocaleInputs();
        render();
        await refreshRows({ announceMessage: false });
        setStatus('Catalog ready.');
      } catch (error) {
        state.error = error.message || String(error);
        render();
        setStatus(state.error, true);
      }
    }

    document.addEventListener('click', async (event) => {
      const actionTarget = event.target.closest('[data-action]');
      if (!actionTarget) return;

      const action = actionTarget.dataset.action;
      const keyPath = actionTarget.dataset.keyPath || '';
      const locale = actionTarget.dataset.locale || '';

      try {
        if (action === 'refresh') {
          await refreshRows();
        } else if (action === 'set-status') {
          state.status = actionTarget.dataset.status || '';
          await refreshRows();
        } else if (action === 'clear-filters') {
          clearFilters();
        } else if (action === 'select-row') {
          setSelectedRow(keyPath);
        } else if (action === 'select-cell') {
          setSelectedRow(keyPath, locale);
        } else if (action === 'save-locale') {
          await saveLocale(keyPath, locale);
        } else if (action === 'review-locale') {
          await reviewLocale(keyPath, locale);
        } else if (action === 'delete-locale') {
          await deleteLocaleValue(keyPath, locale);
        } else if (action === 'delete-key') {
          await deleteKey(keyPath);
        } else if (action === 'toggle-mode') {
          switchDraftMode(keyPath, locale, actionTarget.dataset.mode);
        } else if (action === 'add-branch') {
          addBranch(keyPath, locale, actionTarget.dataset.branchKind, actionTarget.dataset.branch);
        } else if (action === 'add-custom-branch') {
          const branchName = window.prompt('Enter a branch name (for example "other" or "more").');
          if (branchName && branchName.trim()) {
            addBranch(keyPath, locale, actionTarget.dataset.branchKind, branchName.trim());
          }
        } else if (action === 'remove-branch') {
          removeBranch(keyPath, locale, actionTarget.dataset.branch);
        } else if (action === 'open-new-key') {
          openNewKeyModal();
        } else if (action === 'close-new-key') {
          closeNewKeyModal();
        } else if (action === 'create-new-key') {
          await createNewKey();
        }
      } catch (error) {
        setStatus(error.message || String(error), true);
      }
    });

    document.addEventListener('input', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLElement)) return;

      if (target.id === 'searchInput') {
        state.query = target.value;
        window.clearTimeout(state.searchTimer);
        state.searchTimer = window.setTimeout(() => {
          refreshRows();
        }, 220);
        return;
      }

      if (target.id === 'newKeyPath' || String(target.id || '').startsWith('newKeyValue_')) {
        updateNewKeyValidation();
        return;
      }

      if (target.dataset && target.dataset.editor) {
        updateDraftFromInput(target);
      }
    });

    document.addEventListener('change', (event) => {
      const target = event.target;
      if (!(target instanceof HTMLElement)) return;
      if (target.dataset && target.dataset.editor) {
        renderDetailBody();
      }
    });

    document.addEventListener('keydown', (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
        const target = event.target;
        if (!(target instanceof HTMLElement)) return;
        if (target.dataset && target.dataset.keyPath && target.dataset.locale) {
          event.preventDefault();
          saveLocale(target.dataset.keyPath, target.dataset.locale).catch((error) => {
            setStatus(error.message || String(error), true);
          });
        }
      }

      if (event.key === 'Escape' && state.modalOpen) {
        closeNewKeyModal();
      }
    });

    document.getElementById('newKeyModal').addEventListener('click', (event) => {
      if (event.target.id === 'newKeyModal') {
        closeNewKeyModal();
      }
    });

    window.addEventListener('resize', () => {
      updateMode();
      render();
    });

    bootstrap();
  </script>
</body>
</html>
''';
