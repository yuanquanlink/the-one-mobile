import { CodexTask, CodexTaskStatus, TaskSyncStatus } from '../model/CodexTask';
import { InboxItem, InboxStatus, InboxType, SyncStatus } from '../model/InboxItem';

export class StorageMigration {
  static readonly SCHEMA_VERSION: number = 2;

  static inbox(items: Array<InboxItem>): Array<InboxItem> {
    const migrated: Array<InboxItem> = [];
    items.forEach((source: InboxItem): void => {
      if (typeof source.id !== 'string' || typeof source.content !== 'string' ||
        typeof source.createdAt !== 'number') {
        return;
      }
      let type: InboxType = InboxType.NOTE;
      if (source.type === InboxType.IDEA || source.type === InboxType.NOTE ||
        source.type === InboxType.MATERIAL || source.type === InboxType.TASK) {
        type = source.type;
      }
      const status: InboxStatus = source.status === InboxStatus.PROCESSED ?
        InboxStatus.PROCESSED : InboxStatus.PENDING;
      const updatedAt: number = typeof source.updatedAt === 'number' ? source.updatedAt : source.createdAt;
      const tags: Array<string> = Array.isArray(source.tags) ? source.tags : [];
      const syncStatus: SyncStatus = source.syncStatus === SyncStatus.SYNCED ?
        SyncStatus.SYNCED : SyncStatus.LOCAL;
      migrated.push(new InboxItem(source.id, source.content, source.createdAt, type,
        status, tags, updatedAt, syncStatus));
    });
    return migrated;
  }

  static tasks(tasks: Array<CodexTask>): Array<CodexTask> {
    const migrated: Array<CodexTask> = [];
    tasks.forEach((source: CodexTask): void => {
      if (typeof source.id !== 'string' || typeof source.title !== 'string' ||
        typeof source.createdAt !== 'number') {
        return;
      }
      const description: string = typeof source.description === 'string' ? source.description : '';
      let status: CodexTaskStatus = CodexTaskStatus.PENDING;
      if (source.status === CodexTaskStatus.SENT || source.status === CodexTaskStatus.DONE ||
        source.status === CodexTaskStatus.FAILED) {
        status = source.status;
      }
      const updatedAt: number = typeof source.updatedAt === 'number' ? source.updatedAt : source.createdAt;
      const syncStatus: TaskSyncStatus = source.syncStatus === TaskSyncStatus.SYNCED ?
        TaskSyncStatus.SYNCED : TaskSyncStatus.LOCAL;
      const result: string = typeof source.result === 'string' ? source.result : '';
      migrated.push(new CodexTask(source.id, source.title, description, source.createdAt,
        status, updatedAt, syncStatus, result));
    });
    return migrated;
  }
}
