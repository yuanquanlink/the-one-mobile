export enum CodexTaskStatus {
  PENDING = 'pending',
  SENT = 'sent',
  DONE = 'done',
  FAILED = 'failed'
}

export enum TaskSyncStatus {
  LOCAL = 'local',
  PENDING = 'pending',
  SYNCED = 'synced',
  FAILED = 'failed'
}

export class CodexTask {
  id: string;
  title: string;
  description: string;
  createdAt: number;
  updatedAt: number;
  status: CodexTaskStatus;
  syncStatus: TaskSyncStatus;
  result: string;

  constructor(id: string, title: string, description: string, createdAt: number,
    status: CodexTaskStatus = CodexTaskStatus.PENDING, updatedAt: number = createdAt,
    syncStatus: TaskSyncStatus = TaskSyncStatus.LOCAL, result: string = '') {
    this.id = id;
    this.title = title;
    this.description = description;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.status = status;
    this.syncStatus = syncStatus;
    this.result = result;
  }
}
