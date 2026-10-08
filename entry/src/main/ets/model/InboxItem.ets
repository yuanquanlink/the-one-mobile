export enum InboxType {
  IDEA = 'idea',
  NOTE = 'note',
  MATERIAL = 'material',
  TASK = 'task'
}

export enum InboxStatus {
  PENDING = 'pending',
  PROCESSED = 'processed'
}

export enum SyncStatus {
  LOCAL = 'local',
  PENDING = 'pending',
  SYNCED = 'synced',
  FAILED = 'failed'
}

export class InboxItem {
  id: string;
  content: string;
  createdAt: number;
  updatedAt: number;
  type: InboxType;
  status: InboxStatus;
  tags: Array<string>;
  syncStatus: SyncStatus;

  constructor(id: string, content: string, createdAt: number, type: InboxType,
    status: InboxStatus = InboxStatus.PENDING, tags: Array<string> = [],
    updatedAt: number = createdAt, syncStatus: SyncStatus = SyncStatus.LOCAL) {
    this.id = id;
    this.content = content;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.type = type;
    this.status = status;
    this.tags = tags;
    this.syncStatus = syncStatus;
  }
}
