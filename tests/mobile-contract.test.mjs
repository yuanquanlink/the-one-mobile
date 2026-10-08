import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const root = path.resolve(import.meta.dirname, '..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');

test('Inbox V1 contract includes CRUD, search, migration and sync states', () => {
  const model = read('entry/src/main/ets/model/InboxItem.ets');
  const repository = read('entry/src/main/ets/repository/InboxRepository.ets');
  const migration = read('entry/src/main/ets/storage/StorageMigration.ets');
  for (const field of ['id', 'content', 'type', 'tags', 'createdAt', 'updatedAt', 'status', 'syncStatus']) {
    assert.match(model, new RegExp(`\\b${field}\\b`, 'u'));
  }
  for (const operation of ['getById', 'save', 'update', 'remove', 'search', 'updateStatus', 'listUnsynced']) {
    assert.match(repository, new RegExp(`async ${operation}\\(`, 'u'));
  }
  assert.match(migration, /SCHEMA_VERSION: number = 2/u);
  assert.match(repository, /preserveCorruptedValue/u);
});

test('Task queue V1 contract includes failed, detail CRUD and retry sync', () => {
  const model = read('entry/src/main/ets/model/CodexTask.ets');
  const repository = read('entry/src/main/ets/repository/TaskRepository.ets');
  const detail = read('entry/src/main/ets/pages/CodexTaskDetailPage.ets');
  assert.match(model, /FAILED = 'failed'/u);
  for (const operation of ['getById', 'save', 'update', 'remove', 'search', 'updateStatus', 'listUnsynced']) {
    assert.match(repository, new RegExp(`async ${operation}\\(`, 'u'));
  }
  assert.match(detail, /retrySync/u);
  assert.match(detail, /refreshFromBridge/u);
  assert.match(detail, /confirmDelete/u);
  assert.match(repository, /applyRemoteState/u);
});

test('Bridge client is local-first, bounded and uses the agreed protocol', () => {
  const client = read('entry/src/main/ets/services/BridgeClient.ets');
  const sync = read('entry/src/main/ets/services/SyncService.ets');
  const module = read('entry/src/main/module.json5');
  for (const route of ['/health', '/api/inbox', '/api/tasks', '/api/search']) assert.ok(client.includes(route));
  assert.match(client, /connectTimeout: 5000/u);
  assert.match(client, /readTimeout: 5000/u);
  assert.match(client, /x-the-one-token/u);
  assert.match(sync, /SyncStatus\.PENDING/u);
  assert.match(sync, /SyncStatus\.FAILED/u);
  assert.match(module, /ohos\.permission\.INTERNET/u);
});

test('dangerous test cleanup is scoped and requires UI confirmation', () => {
  const settings = read('entry/src/main/ets/pages/SettingsPage.ets');
  const inbox = read('entry/src/main/ets/repository/InboxRepository.ets');
  const tasks = read('entry/src/main/ets/repository/TaskRepository.ets');
  assert.match(settings, /AlertDialog\.show/u);
  assert.match(inbox, /tag\.toLowerCase\(\) === 'test'/u);
  assert.match(tasks, /startsWith\('\[TEST\]'\)/u);
});

test('machine-readable Bridge protocol matches mobile routes and states', () => {
  const protocol = JSON.parse(read('bridge/protocol.json'));
  assert.equal(protocol.version, '1.0.0');
  const endpoints = protocol.endpoints.map((endpoint) => `${endpoint.method} ${endpoint.path}`);
  for (const endpoint of [
    'GET /health', 'POST /api/inbox', 'GET /api/inbox', 'POST /api/tasks',
    'GET /api/tasks/{id}', 'PATCH /api/tasks/{id}', 'POST /api/search'
  ]) assert.ok(endpoints.includes(endpoint), `missing ${endpoint}`);
  assert.deepEqual(protocol.$defs.syncStatus.enum, ['local', 'pending', 'synced', 'failed']);
  assert.deepEqual(protocol.$defs.inboxType.enum, ['idea', 'note', 'material', 'task']);
  assert.equal(protocol.$defs.SearchResponse.properties.obsidianConnected.const, false);
});

test('ArkTS sources avoid high-confidence restricted TypeScript syntax', () => {
  const sourceRoot = path.join(root, 'entry/src/main/ets');
  const files = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(full);
      else if (entry.name.endsWith('.ets')) files.push(full);
    }
  };
  visit(sourceRoot);
  const combined = files.map((file) => fs.readFileSync(file, 'utf8')).join('\n');
  assert.doesNotMatch(combined, /JSON\.stringify\(\s*\{/u);
  assert.doesNotMatch(combined, /(?:replace|match|search|split)\(\s*\//u);
  assert.doesNotMatch(combined, /constructor\s*\(\s*(?:public|private|protected|readonly)\b/u);
  assert.doesNotMatch(combined, /:\s*(?:any|unknown)\b/u);
});

test('Brain page exposes honest Bridge-local search and offline behavior', () => {
  const brain = read('entry/src/main/ets/pages/BrainPage.ets');
  const client = read('entry/src/main/ets/services/BridgeClient.ets');
  const routes = read('entry/src/main/ets/navigation/Routes.ets');
  assert.match(brain, /Bridge 本地索引/u);
  assert.match(brain, /不会伪装成 Obsidian 搜索/u);
  assert.match(brain, /settings\.isConfigured\(\)/u);
  assert.match(client, /BridgeSearchResponse/u);
  assert.match(routes, /BRAIN: string = 'brain'/u);
});

test('API 26 Skill PoC is a thin service adapter with honest boundaries', () => {
  const script = read('entry/skills/the-one-local-control/scripts/TheOneSkill.ets');
  const contract = read('entry/skills/the-one-local-control/SKILL.md');
  const module = read('entry/src/main/module.json5');
  assert.match(module, /"skillProfiles"/u);
  assert.match(module, /"the-one-local-control"/u);
  for (const functionName of ['save_to_brain', 'create_codex_task']) {
    assert.ok(script.includes(`async ${functionName}(`));
    assert.ok(contract.includes(`functionName '${functionName}'`));
  }
  assert.match(script, /AppServiceContainer\.get\(\)\.captureService/u);
  assert.match(script, /AppServiceContainer\.get\(\)\.taskService/u);
  assert.match(script, /completeArkTSScriptInApp/u);
  assert.match(contract, /不直接修改 Obsidian/u);
  assert.match(contract, /manual_codex_adapter/u);
});
