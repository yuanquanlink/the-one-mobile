import { InboxItem, InboxStatus, InboxType, SyncStatus } from '../model/InboxItem';
import { AppPreferences } from '../storage/AppPreferences';
import { StorageMigration } from '../storage/StorageMigration';

const STORAGE_KEY: string = 'inbox_items_v1';

export class InboxRepository {
  private storage: AppPreferences;

  constructor(storage: AppPreferences) {
    this.storage = storage;
  }

  private async readAll(): Promise<Array<InboxItem>> {
    const raw: string = await this.storage.getString(STORAGE_KEY, '[]');
    try {
      const parsed: Array<InboxItem> = JSON.parse(raw) as Array<InboxItem>;
      if (!Array.isArray(parsed)) {
        throw new Error('Inbox storage is not an array');
      }
      return StorageMigration.inbox(parsed);
    } catch (error) {
      console.error(`Inbox data could not be parsed: ${error}`);
      await this.storage.preserveCorruptedValue(STORAGE_KEY, raw);
      return [];
    }
  }

  private async writeAll(items: Array<InboxItem>): Promise<void> {
    await this.storage.putString(STORAGE_KEY, JSON.stringify(items));
  }

  async list(): Promise<Array<InboxItem>> {
    const items: Array<InboxItem> = await this.readAll();
    items.sort((left: InboxItem, right: InboxItem): number => right.createdAt - left.createdAt);
    return items;
  }

  async getById(id: string): Promise<InboxItem | null> {
    const items: Array<InboxItem> = await this.readAll();
    for (let index: number = 0; index < items.length; index += 1) {
      if (items[index].id === id) {
        return items[index];
      }
    }
    return null;
  }

  async save(item: InboxItem): Promise<void> {
    const items: Array<InboxItem> = await this.readAll();
    const existingIndex: number = items.findIndex((candidate: InboxItem): boolean => candidate.id === item.id);
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.push(item);
    }
    await this.writeAll(items);
  }

  async search(query: string, status: InboxStatus | null = null,
    type: InboxType | null = null): Promise<Array<InboxItem>> {
    const normalized: string = query.trim().toLowerCase();
    const items: Array<InboxItem> = await this.list();
    return items.filter((item: InboxItem): boolean => {
      const matchesQuery: boolean = normalized.length === 0 || item.content.toLowerCase().includes(normalized) ||
        item.tags.some((tag: string): boolean => tag.toLowerCase().includes(normalized));
      return matchesQuery && (status === null || item.status === status) && (type === null || item.type === type);
    });
  }

  async update(item: InboxItem): Promise<boolean> {
    const current: InboxItem | null = await this.getById(item.id);
    if (current === null) return false;
    item.updatedAt = Date.now();
    if (item.syncStatus === SyncStatus.SYNCED) item.syncStatus = SyncStatus.PENDING;
    await this.save(item);
    return true;
  }

  async updateStatus(id: string, status: InboxStatus): Promise<boolean> {
    const items: Array<InboxItem> = await this.readAll();
    for (let index: number = 0; index < items.length; index += 1) {
      if (items[index].id === id) {
        items[index].status = status;
        items[index].updatedAt = Date.now();
        if (items[index].syncStatus === SyncStatus.SYNCED) items[index].syncStatus = SyncStatus.PENDING;
        await this.writeAll(items);
        return true;
      }
    }
    return false;
  }

  async remove(id: string): Promise<boolean> {
    const items: Array<InboxItem> = await this.readAll();
    const remaining: Array<InboxItem> = items.filter((item: InboxItem): boolean => item.id !== id);
    if (remaining.length === items.length) {
      return false;
    }
    await this.writeAll(remaining);
    return true;
  }

  async countPending(): Promise<number> {
    const items: Array<InboxItem> = await this.readAll();
    return items.filter((item: InboxItem): boolean => item.status === InboxStatus.PENDING).length;
  }

  async updateSyncStatus(id: string, status: SyncStatus): Promise<boolean> {
    const items: Array<InboxItem> = await this.readAll();
    const item: InboxItem | undefined = items.find((candidate: InboxItem): boolean => candidate.id === id);
    if (item === undefined) return false;
    item.syncStatus = status;
    await this.writeAll(items);
    return true;
  }

  async listUnsynced(): Promise<Array<InboxItem>> {
    const items: Array<InboxItem> = await this.list();
    return items.filter((item: InboxItem): boolean => item.syncStatus !== SyncStatus.SYNCED);
  }

  async removeTestData(): Promise<number> {
    const items: Array<InboxItem> = await this.readAll();
    const remaining: Array<InboxItem> = items.filter((item: InboxItem): boolean =>
      !item.tags.some((tag: string): boolean => tag.toLowerCase() === 'test'));
    const removed: number = items.length - remaining.length;
    if (removed > 0) await this.writeAll(remaining);
    return removed;
  }
}
