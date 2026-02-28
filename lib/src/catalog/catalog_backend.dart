library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'catalog_config.dart';
import 'catalog_models.dart';
import 'catalog_service.dart';

class CatalogApiServer {
  CatalogApiServer({
    required this.service,
    this.host = '127.0.0.1',
    required this.port,
  });

  final CatalogService service;
  final String host;
  final int port;

  HttpServer? _server;

  bool get isRunning => _server != null;
  String get url => 'http://$host:$port';

  Future<void> start() async {
    if (_server != null) {
      return;
    }
    _server = await HttpServer.bind(host, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) {
      return;
    }
    _server = null;
    await server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final method = request.method.toUpperCase();
      final path = request.uri.path;

      if (method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.noContent
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set('Access-Control-Allow-Headers', 'Content-Type')
          ..headers.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
        await request.response.close();
        return;
      }

      if (path == '/api/catalog/meta' && method == 'GET') {
        final meta = await service.loadMeta();
        return _respondJson(request, HttpStatus.ok, meta.toJson());
      }

      if (path == '/api/catalog/rows' && method == 'GET') {
        final status = request.uri.queryParameters['status'];
        final statusFilter = (status == null || status.isEmpty) ? null : catalogCellStatusFromString(status);
        final rows = await service.loadRows(
          search: request.uri.queryParameters['search'],
          status: statusFilter,
        );
        return _respondJson(
          request,
          HttpStatus.ok,
          {
            'rows': rows.map((row) => row.toJson()).toList(),
          },
        );
      }

      if (path == '/api/catalog/summary' && method == 'GET') {
        final summary = await service.loadSummary();
        return _respondJson(request, HttpStatus.ok, summary.toJson());
      }

      if (path == '/api/catalog/key' && method == 'POST') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final valuesRaw = body['valuesByLocale'];
        final values = <String, dynamic>{};
        if (valuesRaw is Map) {
          for (final entry in valuesRaw.entries) {
            values[entry.key.toString()] = entry.value;
          }
        }
        final markGreenIfComplete = body['markGreenIfComplete'] != false;
        final row = await service.addKey(
          keyPath: keyPath,
          valuesByLocale: values,
          markGreenIfComplete: markGreenIfComplete,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/cell' && method == 'PATCH') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        final value = body['value'];
        final row = await service.updateCell(
          keyPath: keyPath,
          locale: locale,
          value: value,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/cell' && method == 'DELETE') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        final row = await service.deleteCell(
          keyPath: keyPath,
          locale: locale,
        );
        return _respondJson(request, HttpStatus.ok, row.toJson());
      }

      if (path == '/api/catalog/review' && method == 'POST') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        final locale = body['locale']?.toString() ?? '';
        await service.markReviewed(
          keyPath: keyPath,
          locale: locale,
        );
        return _respondJson(request, HttpStatus.ok, {'ok': true});
      }

      if (path == '/api/catalog/key' && method == 'DELETE') {
        final body = await _readJsonBody(request);
        final keyPath = body['keyPath']?.toString() ?? '';
        await service.deleteKey(keyPath);
        return _respondJson(request, HttpStatus.ok, {'ok': true});
      }

      _respondJson(
        request,
        HttpStatus.notFound,
        {'error': 'Route not found: ${request.method} ${request.uri.path}'},
      );
    } on CatalogOperationException catch (error) {
      _respondJson(
        request,
        HttpStatus.badRequest,
        {'error': error.message},
      );
    } catch (error) {
      _respondJson(
        request,
        HttpStatus.internalServerError,
        {'error': error.toString()},
      );
    }
  }

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _respondJson(
    HttpRequest request,
    int statusCode,
    Map<String, dynamic> payload,
  ) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..headers.set('Access-Control-Allow-Origin', '*')
      ..headers.set('Access-Control-Allow-Headers', 'Content-Type')
      ..headers.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS')
      ..write(const JsonEncoder.withIndent('  ').convert(payload));
    request.response.close();
  }
}

class CatalogUiServer {
  CatalogUiServer({
    this.host = '127.0.0.1',
    required this.port,
    required this.apiUrl,
  });

  final String host;
  final int port;
  final String apiUrl;

  HttpServer? _server;

  bool get isRunning => _server != null;
  String get url => 'http://$host:$port';

  Future<void> start() async {
    if (_server != null) {
      return;
    }
    _server = await HttpServer.bind(host, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) {
      return;
    }
    _server = null;
    await server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (request.method.toUpperCase() != 'GET') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Method Not Allowed');
      await request.response.close();
      return;
    }

    if (path == '/' || path == '/index.html') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_buildCatalogHtml(apiUrl: apiUrl));
      await request.response.close();
      return;
    }

    if (path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('ok');
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not Found');
    await request.response.close();
  }
}

class CatalogRuntime {
  CatalogRuntime({
    required CatalogService service,
    required CatalogConfig config,
    this.host = '127.0.0.1',
  })  : _service = service,
        _config = config;

  final CatalogService _service;
  final CatalogConfig _config;
  final String host;

  late final CatalogApiServer _apiServer = CatalogApiServer(
    service: _service,
    host: host,
    port: _config.apiPort,
  );
  late final CatalogUiServer _uiServer = CatalogUiServer(
    host: host,
    port: _config.uiPort,
    apiUrl: _apiServer.url,
  );

  bool get isRunning => _apiServer.isRunning || _uiServer.isRunning;
  String get apiUrl => _apiServer.url;
  String get uiUrl => _uiServer.url;

  Future<void> start() async {
    await _apiServer.start();
    try {
      await _uiServer.start();
    } on Object {
      await _apiServer.stop();
      rethrow;
    }

    if (_config.openBrowser) {
      unawaited(_openBrowser(uiUrl));
    }
  }

  Future<void> stop() async {
    await _uiServer.stop();
    await _apiServer.stop();
  }
}

Future<void> _openBrowser(String url) async {
  try {
    if (Platform.isMacOS) {
      await Process.start('open', [url], runInShell: true);
      return;
    }
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url], runInShell: true);
      return;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], runInShell: true);
    }
  } on Object {
    // Ignore browser launch errors; server is still usable via printed URL.
  }
}

String _buildCatalogHtml({required String apiUrl}) {
  final escapedApiUrl = const HtmlEscape(HtmlEscapeMode.element).convert(apiUrl);
  return r'''
<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Anas Localization Catalog</title>
  <style>
    :root {
      --bg: #0b1220;
      --panel: #111a2b;
      --border: #22314d;
      --text: #e5ecf9;
      --muted: #9aa9c6;
      --green: #1f9d62;
      --warning: #d6a227;
      --red: #c24141;
      --accent: #4f8cff;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--text);
    }
    header {
      padding: 16px 20px 8px;
      border-bottom: 1px solid var(--border);
      background: #0f1728;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    h1 {
      margin: 0;
      font-size: 20px;
      font-weight: 700;
      letter-spacing: 0.2px;
    }
    .sub {
      margin-top: 4px;
      color: var(--muted);
      font-size: 13px;
    }
    .container {
      padding: 16px 20px 24px;
    }
    .toolbar {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      align-items: center;
      margin-bottom: 12px;
    }
    .toolbar input, .toolbar select, .toolbar button, .modal-content input, .modal-content textarea {
      background: #0b1323;
      color: var(--text);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 8px 10px;
      font-size: 13px;
    }
    .toolbar button {
      cursor: pointer;
    }
    .toolbar button.primary {
      border-color: #3a74ea;
      background: #2f65d7;
      color: white;
    }
    .toolbar .spacer {
      flex: 1;
    }
    .summary {
      display: flex;
      gap: 8px;
      margin-bottom: 12px;
      flex-wrap: wrap;
    }
    .pill {
      border: 1px solid var(--border);
      padding: 6px 10px;
      border-radius: 999px;
      font-size: 12px;
      color: var(--muted);
      background: #0d1628;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      border: 1px solid var(--border);
      background: var(--panel);
      table-layout: fixed;
    }
    th, td {
      border: 1px solid var(--border);
      padding: 8px;
      vertical-align: top;
    }
    th {
      background: #101a2f;
      text-align: left;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.4px;
      color: #b8c6e0;
    }
    td.key-col {
      width: 260px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 12px;
      color: #d2def5;
      word-break: break-word;
    }
    td.cell-col {
      min-width: 240px;
    }
    .cell-input {
      width: 100%;
      min-height: 56px;
      resize: vertical;
      border-radius: 8px;
      border: 1px solid var(--border);
      background: #0b1323;
      color: var(--text);
      padding: 8px;
      font-size: 13px;
      margin-bottom: 6px;
    }
    .cell-actions {
      display: flex;
      align-items: center;
      gap: 6px;
      flex-wrap: wrap;
    }
    .cell-actions button {
      border: 1px solid var(--border);
      background: #0e1728;
      color: var(--text);
      font-size: 12px;
      border-radius: 6px;
      padding: 4px 8px;
      cursor: pointer;
    }
    .badge {
      font-size: 11px;
      border-radius: 999px;
      padding: 3px 8px;
      border: 1px solid transparent;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }
    .badge-green { color: #9ff0cb; border-color: #24744f; background: #113123; }
    .badge-warning { color: #ffe7aa; border-color: #86651d; background: #32270e; }
    .badge-red { color: #ffb9b9; border-color: #8b2f2f; background: #351212; }
    .reason {
      color: var(--muted);
      font-size: 11px;
    }
    .row-actions button {
      border: 1px solid #81363d;
      background: #3a171b;
      color: #ffcdd2;
      font-size: 12px;
      border-radius: 6px;
      padding: 5px 8px;
      cursor: pointer;
    }
    .status {
      margin-bottom: 8px;
      color: var(--muted);
      font-size: 12px;
      min-height: 18px;
    }
    .modal {
      position: fixed;
      inset: 0;
      background: rgba(8, 12, 20, 0.75);
      display: none;
      align-items: center;
      justify-content: center;
      padding: 24px;
      z-index: 20;
    }
    .modal.show {
      display: flex;
    }
    .modal-content {
      width: min(900px, 100%);
      max-height: 85vh;
      overflow: auto;
      background: #111a2b;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
    }
    .modal-header {
      margin: 0 0 12px;
      font-size: 18px;
    }
    .locale-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 10px;
    }
    .locale-grid label {
      display: block;
      margin-bottom: 6px;
      font-size: 12px;
      color: var(--muted);
    }
    .modal-actions {
      margin-top: 14px;
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }
  </style>
</head>
<body>
  <header>
    <h1>Anas Localization Catalog</h1>
    <div class="sub">Swift String Catalog-style editor for translation keys with review statuses.</div>
  </header>
  <div class="container">
    <div class="status" id="statusLine">Loading...</div>
    <div class="toolbar">
      <input id="searchInput" type="text" placeholder="Search key or value..." />
      <select id="statusFilter">
        <option value="">All statuses</option>
        <option value="green">Green</option>
        <option value="warning">Warning</option>
        <option value="red">Red</option>
      </select>
      <button id="refreshBtn">Refresh</button>
      <div class="spacer"></div>
      <button id="newKeyBtn" class="primary">+ New String</button>
    </div>
    <div class="summary" id="summary"></div>
    <table id="catalogTable">
      <thead id="catalogHead"></thead>
      <tbody id="catalogBody"></tbody>
    </table>
  </div>

  <div class="modal" id="newKeyModal">
    <div class="modal-content">
      <h2 class="modal-header">Create New String</h2>
      <label for="newKeyPath">Key Path (dotted, e.g. home.header.title)</label>
      <input id="newKeyPath" type="text" placeholder="home.header.title" style="width: 100%; margin-bottom: 12px;" />
      <div class="locale-grid" id="newKeyLocaleGrid"></div>
      <div class="modal-actions">
        <button id="newKeyCancelBtn">Cancel</button>
        <button id="newKeySaveBtn" class="primary">Create</button>
      </div>
    </div>
  </div>

  <script>
    const API_BASE = '__API_URL__';
    const state = {
      meta: null,
      rows: [],
      summary: null,
      query: '',
      status: '',
    };

    async function api(path, options = {}) {
      const response = await fetch(`${API_BASE}${path}`, {
        headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
        ...options,
      });
      const text = await response.text();
      const json = text ? JSON.parse(text) : {};
      if (!response.ok) {
        const message = json.error || `Request failed with ${response.status}`;
        throw new Error(message);
      }
      return json;
    }

    function setStatus(message, isError = false) {
      const line = document.getElementById('statusLine');
      line.textContent = message;
      line.style.color = isError ? '#ffb9b9' : '#9aa9c6';
    }

    function statusBadge(status) {
      const span = document.createElement('span');
      span.className = `badge badge-${status}`;
      span.textContent = status;
      return span;
    }

    function renderSummary() {
      const holder = document.getElementById('summary');
      holder.innerHTML = '';
      if (!state.summary) {
        return;
      }
      const items = [
        ['Keys', String(state.summary.totalKeys)],
        ['Green', String(state.summary.greenCount)],
        ['Warning', String(state.summary.warningCount)],
        ['Red', String(state.summary.redCount)],
      ];
      for (const [label, value] of items) {
        const pill = document.createElement('div');
        pill.className = 'pill';
        pill.textContent = `${label}: ${value}`;
        holder.appendChild(pill);
      }
    }

    function renderHead() {
      const head = document.getElementById('catalogHead');
      head.innerHTML = '';
      const row = document.createElement('tr');

      const keyHeader = document.createElement('th');
      keyHeader.textContent = 'Key';
      row.appendChild(keyHeader);

      for (const locale of state.meta.locales) {
        const cell = document.createElement('th');
        const sourceFlag = locale === state.meta.sourceLocale ? ' (source)' : '';
        cell.textContent = `${locale}${sourceFlag}`;
        row.appendChild(cell);
      }

      const actionHeader = document.createElement('th');
      actionHeader.textContent = 'Actions';
      row.appendChild(actionHeader);
      head.appendChild(row);
    }

    async function refreshRows() {
      const query = new URLSearchParams();
      if (state.query) {
        query.set('search', state.query);
      }
      if (state.status) {
        query.set('status', state.status);
      }
      const suffix = query.toString() ? `?${query.toString()}` : '';
      const rowsResult = await api(`/api/catalog/rows${suffix}`);
      state.rows = rowsResult.rows || [];
      state.summary = await api('/api/catalog/summary');
      renderSummary();
      renderRows();
    }

    function renderRows() {
      const body = document.getElementById('catalogBody');
      body.innerHTML = '';

      for (const rowData of state.rows) {
        const row = document.createElement('tr');

        const keyCell = document.createElement('td');
        keyCell.className = 'key-col';
        keyCell.textContent = rowData.keyPath;
        row.appendChild(keyCell);

        for (const locale of state.meta.locales) {
          const cellData = rowData.cellStates[locale] || { status: 'warning' };
          const value = rowData.valuesByLocale[locale] ?? '';

          const cell = document.createElement('td');
          cell.className = 'cell-col';

          const input = document.createElement('textarea');
          input.className = 'cell-input';
          input.value = typeof value === 'string' ? value : JSON.stringify(value);
          input.setAttribute('data-locale', locale);
          input.setAttribute('data-key', rowData.keyPath);
          cell.appendChild(input);

          const actions = document.createElement('div');
          actions.className = 'cell-actions';

          actions.appendChild(statusBadge(cellData.status || 'warning'));

          if (cellData.reason) {
            const reason = document.createElement('span');
            reason.className = 'reason';
            reason.textContent = cellData.reason;
            actions.appendChild(reason);
          }

          const save = document.createElement('button');
          save.textContent = 'Save';
          save.onclick = async () => {
            await api('/api/catalog/cell', {
              method: 'PATCH',
              body: JSON.stringify({
                keyPath: rowData.keyPath,
                locale,
                value: input.value,
              }),
            });
            setStatus(`Saved ${rowData.keyPath} (${locale})`);
            await refreshRows();
          };
          actions.appendChild(save);

          if (locale !== state.meta.sourceLocale) {
            const review = document.createElement('button');
            review.textContent = 'Review';
            review.onclick = async () => {
              await api('/api/catalog/review', {
                method: 'POST',
                body: JSON.stringify({
                  keyPath: rowData.keyPath,
                  locale,
                }),
              });
              setStatus(`Reviewed ${rowData.keyPath} (${locale})`);
              await refreshRows();
            };
            actions.appendChild(review);
          }

          const remove = document.createElement('button');
          remove.textContent = 'Delete';
          remove.onclick = async () => {
            await api('/api/catalog/cell', {
              method: 'DELETE',
              body: JSON.stringify({
                keyPath: rowData.keyPath,
                locale,
              }),
            });
            setStatus(`Deleted value ${rowData.keyPath} (${locale})`);
            await refreshRows();
          };
          actions.appendChild(remove);

          cell.appendChild(actions);
          row.appendChild(cell);
        }

        const rowActions = document.createElement('td');
        rowActions.className = 'row-actions';
        const deleteKey = document.createElement('button');
        deleteKey.textContent = 'Delete Key';
        deleteKey.onclick = async () => {
          const accepted = window.confirm(`Delete key "${rowData.keyPath}" from all locales?`);
          if (!accepted) return;
          await api('/api/catalog/key', {
            method: 'DELETE',
            body: JSON.stringify({ keyPath: rowData.keyPath }),
          });
          setStatus(`Deleted key ${rowData.keyPath}`);
          await refreshRows();
        };
        rowActions.appendChild(deleteKey);
        row.appendChild(rowActions);

        body.appendChild(row);
      }

      if (state.rows.length === 0) {
        const row = document.createElement('tr');
        const empty = document.createElement('td');
        empty.colSpan = state.meta.locales.length + 2;
        empty.style.color = '#9aa9c6';
        empty.textContent = 'No rows found for current filter.';
        row.appendChild(empty);
        body.appendChild(row);
      }
    }

    function renderNewKeyLocaleInputs() {
      const grid = document.getElementById('newKeyLocaleGrid');
      grid.innerHTML = '';
      for (const locale of state.meta.locales) {
        const holder = document.createElement('div');
        const label = document.createElement('label');
        label.textContent = locale;
        const input = document.createElement('textarea');
        input.id = `newKeyValue_${locale}`;
        input.rows = 3;
        input.placeholder = locale === state.meta.sourceLocale
          ? 'Recommended: provide source text'
          : 'Optional at creation';
        input.style.width = '100%';
        holder.appendChild(label);
        holder.appendChild(input);
        grid.appendChild(holder);
      }
    }

    function openNewKeyModal() {
      document.getElementById('newKeyPath').value = '';
      for (const locale of state.meta.locales) {
        const input = document.getElementById(`newKeyValue_${locale}`);
        if (input) input.value = '';
      }
      document.getElementById('newKeyModal').classList.add('show');
    }

    function closeNewKeyModal() {
      document.getElementById('newKeyModal').classList.remove('show');
    }

    async function createNewKey() {
      const keyPath = document.getElementById('newKeyPath').value.trim();
      const valuesByLocale = {};
      for (const locale of state.meta.locales) {
        const input = document.getElementById(`newKeyValue_${locale}`);
        valuesByLocale[locale] = input ? input.value : '';
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
      setStatus(`Added key ${keyPath}`);
      await refreshRows();
    }

    async function bootstrap() {
      try {
        setStatus('Loading catalog metadata...');
        state.meta = await api('/api/catalog/meta');
        renderHead();
        renderNewKeyLocaleInputs();
        await refreshRows();
        setStatus(`Loaded ${state.rows.length} rows.`);
      } catch (error) {
        setStatus(error.message || String(error), true);
      }
    }

    document.getElementById('refreshBtn').addEventListener('click', async () => {
      state.query = document.getElementById('searchInput').value.trim();
      state.status = document.getElementById('statusFilter').value;
      try {
        await refreshRows();
        setStatus(`Loaded ${state.rows.length} rows.`);
      } catch (error) {
        setStatus(error.message || String(error), true);
      }
    });
    document.getElementById('newKeyBtn').addEventListener('click', openNewKeyModal);
    document.getElementById('newKeyCancelBtn').addEventListener('click', closeNewKeyModal);
    document.getElementById('newKeySaveBtn').addEventListener('click', async () => {
      try {
        await createNewKey();
      } catch (error) {
        setStatus(error.message || String(error), true);
      }
    });
    document.getElementById('newKeyModal').addEventListener('click', (event) => {
      if (event.target.id === 'newKeyModal') {
        closeNewKeyModal();
      }
    });

    bootstrap();
  </script>
</body>
</html>
'''
      .replaceAll('__API_URL__', escapedApiUrl);
}
