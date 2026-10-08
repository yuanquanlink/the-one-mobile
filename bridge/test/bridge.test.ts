import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, test } from 'node:test';
import { BridgeServer } from '../src/server.js';
import { JsonStore } from '../src/store.js';

const servers: BridgeServer[] = [];

afterEach(async () => {
  await Promise.all(servers.splice(0).map((server) => server.stop()));
});

async function start(token?: string, knowledgeRoot?: string): Promise<{ bridge: BridgeServer; base: string }> {
  const folder = await mkdtemp(path.join(tmpdir(), 'the-one-bridge-'));
  const config = { host: '127.0.0.1', port: 0, dataFile: path.join(folder, 'state.json') };
  const bridge = new BridgeServer({ ...config, ...(token ? { token } : {}), ...(knowledgeRoot ? { knowledgeRoot } : {}) });
  servers.push(bridge);
  const address = await bridge.start();
  return { bridge, base: address.url };
}

async function json(base: string, route: string, init?: RequestInit): Promise<{ response: Response; body: any }> {
  const response = await fetch(`${base}${route}`, {
    ...init,
    headers: { 'content-type': 'application/json', ...(init?.headers || {}) }
  });
  return { response, body: await response.json() };
}

test('health and version expose real bridge capabilities', async () => {
  const { base } = await start();
  const health = await json(base, '/health');
  assert.equal(health.response.status, 200);
  assert.equal(health.body.ok, true);
  assert.equal(health.body.knowledge, 'disabled');
  const version = await json(base, '/api/version');
  assert.equal(version.body.protocolVersion, '1.0.0');
});

test('phone mock can create inbox and task, retry safely, then complete task', async () => {
  const { base } = await start();
  const inbox = { id: 'phone_item_001', content: 'Capture from phone', type: 'idea', tags: ['mobile'] };
  const firstInbox = await json(base, '/api/inbox', { method: 'POST', body: JSON.stringify(inbox) });
  assert.equal(firstInbox.response.status, 201);
  assert.equal(firstInbox.body.item.syncStatus, 'synced');
  const duplicateInbox = await json(base, '/api/inbox', { method: 'POST', body: JSON.stringify(inbox) });
  assert.equal(duplicateInbox.response.status, 200);
  assert.equal(duplicateInbox.body.duplicate, true);

  const task = { id: 'phone_task_001', title: 'Test the bridge', description: 'Integration path' };
  const created = await json(base, '/api/tasks', { method: 'POST', body: JSON.stringify(task) });
  assert.equal(created.response.status, 201);
  assert.equal(created.body.dispatchMode, 'manual');
  assert.match(created.body.dispatchMessage, /dispatch it manually/u);
  const updated = await json(base, '/api/tasks/phone_task_001', {
    method: 'PATCH', body: JSON.stringify({ status: 'done', result: 'Verified locally.' })
  });
  assert.equal(updated.response.status, 200);
  assert.equal(updated.body.task.status, 'done');
  const detail = await json(base, '/api/tasks/phone_task_001');
  assert.equal(detail.body.task.id, 'phone_task_001');
  const listed = await json(base, '/api/tasks?status=done');
  assert.equal(listed.body.tasks.length, 1);
});

test('mobile upsert synchronizes edits without creating duplicate records', async () => {
  const { base } = await start();
  await json(base, '/api/inbox', {
    method: 'POST',
    body: JSON.stringify({ id: 'editable_item_001', content: 'Before edit', type: 'material', tags: [] })
  });
  const editedInbox = await json(base, '/api/inbox', {
    method: 'POST',
    body: JSON.stringify({
      id: 'editable_item_001', content: 'After edit searchable', type: 'material', tags: ['updated'], upsert: true
    })
  });
  assert.equal(editedInbox.response.status, 200);
  assert.equal(editedInbox.body.updated, true);
  const inboxList = await json(base, '/api/inbox');
  assert.equal(inboxList.body.items.length, 1);
  assert.equal(inboxList.body.items[0].content, 'After edit searchable');

  await json(base, '/api/tasks', {
    method: 'POST',
    body: JSON.stringify({ id: 'editable_task_001', title: 'Before task', description: '' })
  });
  const editedTask = await json(base, '/api/tasks', {
    method: 'POST',
    body: JSON.stringify({
      id: 'editable_task_001', title: 'After task', description: 'New details', status: 'failed', upsert: true
    })
  });
  assert.equal(editedTask.body.task.status, 'failed');
  const taskList = await json(base, '/api/tasks');
  assert.equal(taskList.body.tasks.length, 1);
});

test('search indexes Bridge inbox and task data without claiming Obsidian access', async () => {
  const { base } = await start();
  await json(base, '/api/inbox', {
    method: 'POST',
    body: JSON.stringify({ id: 'search_item_001', content: 'Unique bridge lighthouse', type: 'note' })
  });
  const search = await json(base, '/api/search', {
    method: 'POST', body: JSON.stringify({ query: 'lighthouse' })
  });
  assert.equal(search.body.obsidianConnected, false);
  assert.equal(search.body.hits.length, 1);
  assert.equal(search.body.hits[0].path, 'bridge://inbox/search_item_001');
});

test('offline endpoint produces a bounded network error for the phone mock', async () => {
  await assert.rejects(fetch('http://127.0.0.1:1/health', { signal: AbortSignal.timeout(250) }));
});

test('conflicts and invalid bodies are rejected', async () => {
  const { base } = await start();
  await json(base, '/api/tasks', {
    method: 'POST', body: JSON.stringify({ id: 'conflict_001', title: 'One', description: '' })
  });
  const conflict = await json(base, '/api/tasks', {
    method: 'POST', body: JSON.stringify({ id: 'conflict_001', title: 'Different', description: '' })
  });
  assert.equal(conflict.response.status, 409);
  const invalid = await json(base, '/api/inbox', { method: 'POST', body: JSON.stringify({ content: '' }) });
  assert.equal(invalid.response.status, 400);
});

test('configured token protects every endpoint', async () => {
  const token = 'a-secure-test-token-with-24-characters';
  const { base } = await start(token);
  const denied = await json(base, '/health');
  assert.equal(denied.response.status, 401);
  const allowed = await json(base, '/health', { headers: { 'x-the-one-token': token } });
  assert.equal(allowed.response.status, 200);
});

test('corrupt state is preserved and recovered, never silently discarded', async () => {
  const folder = await mkdtemp(path.join(tmpdir(), 'the-one-store-'));
  const stateFile = path.join(folder, 'state.json');
  await writeFile(stateFile, '{bad json', 'utf8');
  const store = new JsonStore(stateFile);
  await store.load();
  assert.deepEqual(store.snapshot(), { schemaVersion: 1, inbox: [], tasks: [] });
  const names = await readdir(folder);
  const recovery = names.find((name) => name.startsWith('state.json.corrupt-'));
  assert.ok(recovery);
  assert.equal(await readFile(path.join(folder, recovery), 'utf8'), '{bad json');
});

test('knowledge adapter searches and archives only inside an explicit fixture root', async () => {
  const knowledgeRoot = await mkdtemp(path.join(tmpdir(), 'the-one-knowledge-'));
  await writeFile(path.join(knowledgeRoot, 'fixture.md'), '# Fixture\nThe bridge needle is here.', 'utf8');
  const { base } = await start(undefined, knowledgeRoot);
  const search = await json(base, '/api/search', { method: 'POST', body: JSON.stringify({ query: 'needle' }) });
  assert.equal(search.body.capability, 'bridge_local_index');
  assert.equal(search.body.obsidianConnected, false);
  assert.equal(search.body.hits.length, 1);
  await json(base, '/api/tasks', {
    method: 'POST', body: JSON.stringify({ id: 'archive_task_001', title: 'Archive me', description: '' })
  });
  const done = await json(base, '/api/tasks/archive_task_001', {
    method: 'PATCH', body: JSON.stringify({ status: 'done', result: 'Fixture result' })
  });
  assert.equal(done.body.archivePath, path.join('The One Mobile', 'archive_task_001.md'));
  const archived = await readFile(path.join(knowledgeRoot, done.body.archivePath), 'utf8');
  assert.match(archived, /Fixture result/u);
});
