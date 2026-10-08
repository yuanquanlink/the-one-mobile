import { InboxStatus, InboxType } from '../model/InboxItem';
import { CodexTaskStatus } from '../model/CodexTask';

export function inboxTypeLabel(type: InboxType): string {
  switch (type) {
    case InboxType.IDEA:
      return '想法';
    case InboxType.NOTE:
      return '笔记';
    case InboxType.MATERIAL:
      return '素材';
    case InboxType.TASK:
      return '任务';
    default:
      return '记录';
  }
}

export function inboxStatusLabel(status: InboxStatus): string {
  return status === InboxStatus.PROCESSED ? '已处理' : '待处理';
}

export function taskStatusLabel(status: CodexTaskStatus): string {
  switch (status) {
    case CodexTaskStatus.SENT:
      return '已发送';
    case CodexTaskStatus.DONE:
      return '已完成';
    case CodexTaskStatus.FAILED:
      return '失败';
    default:
      return '待执行';
  }
}

export function summarize(content: string, maxLength: number = 72): string {
  const normalized: string = content.replace(new RegExp('\\s+', 'g'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return `${normalized.substring(0, maxLength)}…`;
}
