import { randomUUID, timingSafeEqual } from 'node:crypto';
import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http';
import type { AddressInfo } from 'node:net';
import { URL } from 'node:url';
import { LocalKnowledgeAdapter } from './adapters/knowledge.js';
import { ManualCodexAdapter, type CodexAdapter } from './adapters/codex.js';
import type { BridgeConfig } from './config.js';
import { JsonStore } from './store.js';
import { PROTOCOL_VERSION, type CodexTask, type InboxItem } from './types.js';
import {
  asRecord,
  optionalId,
  optionalText,
  parseInboxStatus,
  parseInboxType,
  parseTags,
  parseTaskStatus,
  requiredText,
  ValidationError
} from './validation.js';

const MAX_BODY_BYTES = 256 * 1024;

function send(response: ServerResponse, status: number, payload: unknown): void {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(body),
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff'
  });
  response.end(body);
}

function authorized(request: IncomingMessage, expected?: string): boolean {
  if (!expected) return true;
  const received = request.headers['x-the-one-token'];
  if (typeof received !== 'string') return false;
  const left = Buffer.from(received);
  const right = Buffer.from(expected);
  return left.length === right.length && timingSafeEqual(left, right);
}

async function readJson(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of request) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > MAX_BODY_BYTES) throw new ValidationError('Request body is too large.');
    chunks.push(buffer);
  }
  if (chunks.length === 0) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8')) as unknown;
  } catch {
    throw new ValidationError('Request body is not valid JSON.');
  }
}

export class BridgeServer {
  private server: Server | undefined;
  readonly store: JsonStore;
  readonly knowledge: LocalKnowledgeAdapter;
  readonly codex: CodexAdapter;

  constructor(readonly config: BridgeConfig, codex: CodexAdapter = new ManualCodexAdapter()) {
    this.store = new JsonStore(config.dataFile);
    this.knowledge = new LocalKnowledgeAdapter(config.knowledgeRoot);
    this.codex = codex;
  }

  async start(): Promise<{ host: string; port: number; url: string }> {
    await this.store.load();
    this.server = createServer((request, response) => {
      void this.route(request, response).catch((error: unknown) => {
        if (error instanceof ValidationError) {
          send(response, 400, { error: 'validation_error', message: error.message });
          return;
        }
        console.error(error);
        if (!response.headersSent) send(response, 500, { error: 'internal_error' });
        else response.end();
      });
    });
    await new Promise<void>((resolve, reject) => {
      this.server?.once('error', reject);
      this.server?.listen(this.config.port, this.config.host, resolve);
    });
    const address = this.server.address() as AddressInfo;
    const displayHost = address.family === 'IPv6' ? `[${address.address}]` : address.address;
    return { host: address.address, port: address.port, url: `http://${displayHost}:${address.port}` };
  }

  async stop(): Promise<void> {
    if (!this.server) return;
    await new Promise<void>((resolve, reject) => {
      this.server?.close((error) => error ? reject(error) : resolve());
    });
    this.server = undefined;
  }

  private async route(request: IncomingMessage, response: ServerResponse): Promise<void> {
    if (!authorized(request, this.config.token)) {
      send(response, 401, { error: 'unauthorized' });
      return;
    }
    const url = new URL(request.url || '/', 'http://bridge.local');
    const method = request.method || 'GET';

    if (method === 'GET' && url.pathname === '/health') {
      send(response, 200, {
        ok: true,
        service: 'the-one-mobile-bridge',
        protocolVersion: PROTOCOL_VERSION,
        storage: 'local-json',
        knowledge: this.config.knowledgeRoot ? 'local-fixture-root' : 'disabled'
      });
      return;
    }
    if (method === 'GET' && url.pathname === '/api/version') {
      send(response, 200, { protocolVersion: PROTOCOL_VERSION, minimumClientVersion: '1.0.0' });
      return;
    }
    if (method === 'GET' && url.pathname === '/api/inbox') {
      const query = (url.searchParams.get('q') || '').toLocaleLowerCase();
      const status = url.searchParams.get('status');
      const items = this.store.snapshot().inbox.filter((item) =>
        (!query || item.content.toLocaleLowerCase().includes(query) || item.tags.some((tag) => tag.toLocaleLowerCase().includes(query))) &&
        (!status || item.status === status)
      );
      send(response, 200, { items });
      return;
    }
    if (method === 'POST' && url.pathname === '/api/inbox') {
      const body = asRecord(await readJson(request));
      const id = optionalId(body) || randomUUID();
      const existing = this.store.findInbox(id);
      const content = requiredText(body, 'content');
      const type = parseInboxType(body.type || 'note');
      if (existing) {
        if (body.upsert === true) {
          const updated: InboxItem = {
            ...existing,
            content,
            type,
            tags: parseTags(body.tags),
            updatedAt: new Date().toISOString(),
            syncStatus: 'synced'
          };
          await this.store.replaceInbox(updated);
          send(response, 200, { item: updated, duplicate: false, updated: true });
        } else if (existing.content === content && existing.type === type) {
          send(response, 200, { item: existing, duplicate: true });
        } else send(response, 409, { error: 'id_conflict' });
        return;
      }
      const now = new Date().toISOString();
      const item: InboxItem = {
        id, content, type, createdAt: now, updatedAt: now,
        status: 'pending', tags: parseTags(body.tags), syncStatus: 'synced'
      };
      await this.store.addInbox(item);
      send(response, 201, { item, duplicate: false });
      return;
    }
    if (method === 'GET' && url.pathname === '/api/tasks') {
      const query = (url.searchParams.get('q') || '').toLocaleLowerCase();
      const status = url.searchParams.get('status');
      const tasks = this.store.snapshot().tasks.filter((task) =>
        (!query || task.title.toLocaleLowerCase().includes(query) || task.description.toLocaleLowerCase().includes(query)) &&
        (!status || task.status === status)
      );
      send(response, 200, { tasks });
      return;
    }
    if (method === 'POST' && url.pathname === '/api/tasks') {
      const body = asRecord(await readJson(request));
      const id = optionalId(body) || randomUUID();
      const existing = this.store.findTask(id);
      const title = requiredText(body, 'title', 240);
      const description = optionalText(body, 'description');
      if (existing) {
        if (body.upsert === true) {
          const updated: CodexTask = {
            ...existing,
            title,
            description,
            status: body.status === undefined ? existing.status : parseTaskStatus(body.status),
            updatedAt: new Date().toISOString(),
            syncStatus: 'synced'
          };
          await this.store.replaceTask(updated);
          send(response, 200, { task: updated, duplicate: false, updated: true, dispatchMode: 'manual' });
        } else if (existing.title === title && existing.description === description) {
          send(response, 200, { task: existing, duplicate: true, dispatchMode: 'manual' });
        } else send(response, 409, { error: 'id_conflict' });
        return;
      }
      const now = new Date().toISOString();
      const task: CodexTask = {
        id, title, description, createdAt: now, updatedAt: now,
        status: 'pending', syncStatus: 'synced'
      };
      await this.store.addTask(task);
      const dispatch = await this.codex.dispatch(task);
      send(response, 201, { task, duplicate: false, dispatchMode: dispatch.mode, dispatchMessage: dispatch.message });
      return;
    }
    const taskMatch = /^\/api\/tasks\/([A-Za-z0-9_-]{6,100})$/u.exec(url.pathname);
    if (method === 'GET' && taskMatch) {
      const task = this.store.findTask(taskMatch[1] as string);
      if (!task) send(response, 404, { error: 'not_found' });
      else send(response, 200, { task });
      return;
    }
    if (method === 'PATCH' && taskMatch) {
      const id = taskMatch[1] as string;
      const current = this.store.findTask(id);
      if (!current) {
        send(response, 404, { error: 'not_found' });
        return;
      }
      const body = asRecord(await readJson(request));
      const next: CodexTask = {
        ...current,
        title: body.title === undefined ? current.title : requiredText(body, 'title', 240),
        description: body.description === undefined ? current.description : optionalText(body, 'description'),
        status: body.status === undefined ? current.status : parseTaskStatus(body.status),
        updatedAt: new Date().toISOString(),
        syncStatus: 'synced'
      };
      if (body.result !== undefined) next.result = optionalText(body, 'result', 100_000);
      await this.store.replaceTask(next);
      const archivePath = next.status === 'done' ? await this.knowledge.archiveTaskResult(next) : undefined;
      send(response, 200, archivePath ? { task: next, archivePath } : { task: next });
      return;
    }
    if (method === 'POST' && url.pathname === '/api/search') {
      const body = asRecord(await readJson(request));
      const query = requiredText(body, 'query', 500);
      const result = await this.knowledge.search(query);
      const needle = query.toLocaleLowerCase();
      const state = this.store.snapshot();
      for (const item of state.inbox) {
        if (item.content.toLocaleLowerCase().includes(needle) ||
            item.tags.some((tag) => tag.toLocaleLowerCase().includes(needle))) {
          result.hits.unshift({
            path: `bridge://inbox/${item.id}`,
            title: item.type,
            excerpt: item.content.slice(0, 220)
          });
        }
      }
      for (const task of state.tasks) {
        if (task.title.toLocaleLowerCase().includes(needle) || task.description.toLocaleLowerCase().includes(needle)) {
          result.hits.unshift({
            path: `bridge://tasks/${task.id}`,
            title: task.title,
            excerpt: task.description.slice(0, 220)
          });
        }
      }
      result.hits = result.hits.slice(0, 20);
      send(response, 200, result);
      return;
    }
    send(response, 404, { error: 'not_found' });
  }
}
