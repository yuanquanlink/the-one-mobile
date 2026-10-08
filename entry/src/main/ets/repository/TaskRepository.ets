import { CodexTask, CodexTaskStatus, TaskSyncStatus } from '../model/CodexTask';
import { AppPreferences } from '../storage/AppPreferences';
import { StorageMigration } from '../storage/StorageMigration';

const STORAGE_KEY: string = 'codex_tasks_v1';

export class TaskRepository {
  private storage: AppPreferences;

  constructor(storage: AppPreferences) {
    this.storage = storage;
  }

  private async readAll(): Promise<Array<CodexTask>> {
    const raw: string = await this.storage.getString(STORAGE_KEY, '[]');
    try {
      const parsed: Array<CodexTask> = JSON.parse(raw) as Array<CodexTask>;
      if (!Array.isArray(parsed)) {
        throw new Error('Task storage is not an array');
      }
      return StorageMigration.tasks(parsed);
    } catch (error) {
      console.error(`Codex task data could not be parsed: ${error}`);
      await this.storage.preserveCorruptedValue(STORAGE_KEY, raw);
      return [];
    }
  }

  private async writeAll(tasks: Array<CodexTask>): Promise<void> {
    await this.storage.putString(STORAGE_KEY, JSON.stringify(tasks));
  }

  async list(): Promise<Array<CodexTask>> {
    const tasks: Array<CodexTask> = await this.readAll();
    tasks.sort((left: CodexTask, right: CodexTask): number => right.createdAt - left.createdAt);
    return tasks;
  }

  async save(task: CodexTask): Promise<void> {
    const tasks: Array<CodexTask> = await this.readAll();
    const existingIndex: number = tasks.findIndex((candidate: CodexTask): boolean => candidate.id === task.id);
    if (existingIndex >= 0) tasks[existingIndex] = task;
    else tasks.push(task);
    await this.writeAll(tasks);
  }

  async getById(id: string): Promise<CodexTask | null> {
    const tasks: Array<CodexTask> = await this.readAll();
    const task: CodexTask | undefined = tasks.find((candidate: CodexTask): boolean => candidate.id === id);
    return task === undefined ? null : task;
  }

  async search(query: string, status: CodexTaskStatus | null = null): Promise<Array<CodexTask>> {
    const normalized: string = query.trim().toLowerCase();
    const tasks: Array<CodexTask> = await this.list();
    return tasks.filter((task: CodexTask): boolean =>
      (normalized.length === 0 || task.title.toLowerCase().includes(normalized) ||
        task.description.toLowerCase().includes(normalized)) && (status === null || task.status === status));
  }

  async update(task: CodexTask): Promise<boolean> {
    const current: CodexTask | null = await this.getById(task.id);
    if (current === null) return false;
    task.updatedAt = Date.now();
    if (task.syncStatus === TaskSyncStatus.SYNCED) task.syncStatus = TaskSyncStatus.PENDING;
    await this.save(task);
    return true;
  }

  async updateStatus(id: string, status: CodexTaskStatus): Promise<boolean> {
    const tasks: Array<CodexTask> = await this.readAll();
    for (let index: number = 0; index < tasks.length; index += 1) {
      if (tasks[index].id === id) {
        tasks[index].status = status;
        tasks[index].updatedAt = Date.now();
        if (tasks[index].syncStatus === TaskSyncStatus.SYNCED) tasks[index].syncStatus = TaskSyncStatus.PENDING;
        await this.writeAll(tasks);
        return true;
      }
    }
    return false;
  }

  async countPending(): Promise<number> {
    const tasks: Array<CodexTask> = await this.readAll();
    return tasks.filter((task: CodexTask): boolean => task.status === CodexTaskStatus.PENDING).length;
  }

  async remove(id: string): Promise<boolean> {
    const tasks: Array<CodexTask> = await this.readAll();
    const remaining: Array<CodexTask> = tasks.filter((task: CodexTask): boolean => task.id !== id);
    if (remaining.length === tasks.length) return false;
    await this.writeAll(remaining);
    return true;
  }

  async updateSyncStatus(id: string, status: TaskSyncStatus): Promise<boolean> {
    const tasks: Array<CodexTask> = await this.readAll();
    const task: CodexTask | undefined = tasks.find((candidate: CodexTask): boolean => candidate.id === id);
    if (task === undefined) return false;
    task.syncStatus = status;
    await this.writeAll(tasks);
    return true;
  }

  async applyRemoteState(id: string, status: CodexTaskStatus, result: string): Promise<boolean> {
    const tasks: Array<CodexTask> = await this.readAll();
    const task: CodexTask | undefined = tasks.find((candidate: CodexTask): boolean => candidate.id === id);
    if (task === undefined) return false;
    task.status = status;
    task.result = result;
    task.updatedAt = Date.now();
    task.syncStatus = TaskSyncStatus.SYNCED;
    await this.writeAll(tasks);
    return true;
  }

  async listUnsynced(): Promise<Array<CodexTask>> {
    const tasks: Array<CodexTask> = await this.list();
    return tasks.filter((task: CodexTask): boolean => task.syncStatus !== TaskSyncStatus.SYNCED);
  }

  async removeTestData(): Promise<number> {
    const tasks: Array<CodexTask> = await this.readAll();
    const remaining: Array<CodexTask> = tasks.filter((task: CodexTask): boolean =>
      !task.title.toUpperCase().startsWith('[TEST]'));
    const removed: number = tasks.length - remaining.length;
    if (removed > 0) await this.writeAll(remaining);
    return removed;
  }
}
