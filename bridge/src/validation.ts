import type { InboxItem, InboxStatus, InboxType, SyncStatus, TaskStatus } from './types.js';

const inboxTypes = new Set<InboxType>(['note', 'idea', 'material', 'task']);
const inboxStatuses = new Set<InboxStatus>(['pending', 'archived']);
const taskStatuses = new Set<TaskStatus>(['pending', 'sent', 'done', 'failed']);
const syncStatuses = new Set<SyncStatus>(['local', 'pending', 'synced', 'failed']);

export class ValidationError extends Error {}

export function asRecord(input: unknown): Record<string, unknown> {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new ValidationError('JSON body must be an object.');
  }
  return input as Record<string, unknown>;
}

export function requiredText(record: Record<string, unknown>, key: string, max = 10_000): string {
  const value = record[key];
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new ValidationError(`${key} must be a non-empty string.`);
  }
  const trimmed = value.trim();
  if (trimmed.length > max) throw new ValidationError(`${key} is too long.`);
  return trimmed;
}

export function optionalText(record: Record<string, unknown>, key: string, max = 10_000): string {
  const value = record[key];
  if (value === undefined || value === null) return '';
  if (typeof value !== 'string') throw new ValidationError(`${key} must be a string.`);
  if (value.length > max) throw new ValidationError(`${key} is too long.`);
  return value.trim();
}

export function optionalId(record: Record<string, unknown>): string | undefined {
  const value = record.id;
  if (value === undefined) return undefined;
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{6,100}$/u.test(value)) {
    throw new ValidationError('id has an invalid format.');
  }
  return value;
}

export function parseInboxType(value: unknown): InboxType {
  if (typeof value !== 'string' || !inboxTypes.has(value as InboxType)) {
    throw new ValidationError('type must be note, idea, material, or task.');
  }
  return value as InboxType;
}

export function parseInboxStatus(value: unknown): InboxStatus {
  if (typeof value !== 'string' || !inboxStatuses.has(value as InboxStatus)) {
    throw new ValidationError('status must be pending or archived.');
  }
  return value as InboxStatus;
}

export function parseTaskStatus(value: unknown): TaskStatus {
  if (typeof value !== 'string' || !taskStatuses.has(value as TaskStatus)) {
    throw new ValidationError('status must be pending, sent, done, or failed.');
  }
  return value as TaskStatus;
}

export function parseTags(value: unknown): string[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.some((tag) => typeof tag !== 'string')) {
    throw new ValidationError('tags must be an array of strings.');
  }
  return [...new Set(value.map((tag) => (tag as string).trim()).filter(Boolean))].slice(0, 20);
}

export function isInboxItem(value: unknown): value is InboxItem {
  if (!value || typeof value !== 'object') return false;
  const item = value as Record<string, unknown>;
  return typeof item.id === 'string' && typeof item.content === 'string' &&
    typeof item.createdAt === 'string' && typeof item.updatedAt === 'string' &&
    inboxTypes.has(item.type as InboxType) && inboxStatuses.has(item.status as InboxStatus) &&
    Array.isArray(item.tags) && syncStatuses.has(item.syncStatus as SyncStatus);
}
