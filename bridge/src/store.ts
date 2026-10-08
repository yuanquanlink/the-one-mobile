import { copyFile, mkdir, readFile, rename, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { BridgeState, CodexTask, InboxItem } from './types.js';

const emptyState = (): BridgeState => ({ schemaVersion: 1, inbox: [], tasks: [] });

function isState(value: unknown): value is BridgeState {
  if (!value || typeof value !== 'object') return false;
  const state = value as Partial<BridgeState>;
  return state.schemaVersion === 1 && Array.isArray(state.inbox) && Array.isArray(state.tasks);
}

export class JsonStore {
  private state: BridgeState = emptyState();
  private queue: Promise<void> = Promise.resolve();

  constructor(readonly filePath: string) {}

  async load(): Promise<void> {
    await mkdir(path.dirname(this.filePath), { recursive: true });
    try {
      const raw = await readFile(this.filePath, 'utf8');
      const candidate: unknown = JSON.parse(raw);
      if (!isState(candidate)) throw new Error('Unsupported bridge state schema.');
      this.state = candidate;
    } catch (error) {
      const code = (error as NodeJS.ErrnoException).code;
      if (code === 'ENOENT') {
        this.state = emptyState();
        await this.persist();
        return;
      }
      const recoveryPath = `${this.filePath}.corrupt-${Date.now()}`;
      await rename(this.filePath, recoveryPath);
      this.state = emptyState();
      await this.persist();
    }
  }

  snapshot(): BridgeState {
    return structuredClone(this.state);
  }

  findInbox(id: string): InboxItem | undefined {
    return this.state.inbox.find((item) => item.id === id);
  }

  findTask(id: string): CodexTask | undefined {
    return this.state.tasks.find((task) => task.id === id);
  }

  async addInbox(item: InboxItem): Promise<void> {
    this.state.inbox.unshift(item);
    await this.persistQueued();
  }

  async replaceInbox(item: InboxItem): Promise<void> {
    const index = this.state.inbox.findIndex((candidate) => candidate.id === item.id);
    if (index < 0) throw new Error('Inbox item not found.');
    this.state.inbox[index] = item;
    await this.persistQueued();
  }

  async addTask(task: CodexTask): Promise<void> {
    this.state.tasks.unshift(task);
    await this.persistQueued();
  }

  async replaceTask(task: CodexTask): Promise<void> {
    const index = this.state.tasks.findIndex((candidate) => candidate.id === task.id);
    if (index < 0) throw new Error('Task not found.');
    this.state.tasks[index] = task;
    await this.persistQueued();
  }

  private async persistQueued(): Promise<void> {
    this.queue = this.queue.then(() => this.persist());
    await this.queue;
  }

  private async persist(): Promise<void> {
    const tempPath = `${this.filePath}.tmp-${process.pid}-${Date.now()}`;
    await writeFile(tempPath, `${JSON.stringify(this.state, null, 2)}\n`, 'utf8');
    try {
      await rename(tempPath, this.filePath);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'EEXIST' &&
          (error as NodeJS.ErrnoException).code !== 'EPERM') throw error;
      await copyFile(tempPath, this.filePath);
      await unlink(tempPath);
    }
  }
}
