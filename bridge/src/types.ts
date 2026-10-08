export const PROTOCOL_VERSION = '1.0.0';

export type InboxType = 'note' | 'idea' | 'material' | 'task';
export type InboxStatus = 'pending' | 'archived';
export type TaskStatus = 'pending' | 'sent' | 'done' | 'failed';
export type SyncStatus = 'local' | 'pending' | 'synced' | 'failed';

export interface InboxItem {
  id: string;
  content: string;
  createdAt: string;
  updatedAt: string;
  type: InboxType;
  status: InboxStatus;
  tags: string[];
  syncStatus: SyncStatus;
}

export interface CodexTask {
  id: string;
  title: string;
  description: string;
  createdAt: string;
  updatedAt: string;
  status: TaskStatus;
  syncStatus: SyncStatus;
  result?: string;
}

export interface BridgeState {
  schemaVersion: 1;
  inbox: InboxItem[];
  tasks: CodexTask[];
}

export interface SearchHit {
  path: string;
  title: string;
  excerpt: string;
}

export interface KnowledgeSearchResult {
  capability: 'bridge_local_index';
  obsidianConnected: false;
  query: string;
  hits: SearchHit[];
}
