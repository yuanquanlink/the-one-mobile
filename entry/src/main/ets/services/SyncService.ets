import { BrainSearchResult, BridgeResult, BridgeTaskResponse } from '../model/BridgeModels';
import { BridgeSettings } from '../model/BridgeSettings';
import { InboxItem, SyncStatus } from '../model/InboxItem';
import { CodexTask, CodexTaskStatus, TaskSyncStatus } from '../model/CodexTask';
import { InboxRepository } from '../repository/InboxRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { TaskRepository } from '../repository/TaskRepository';
import { BridgeClient } from './BridgeClient';

export class SyncService {
  private bridgeClient: BridgeClient;
  private inboxRepository: InboxRepository;
  private taskRepository: TaskRepository;
  private settingsRepository: SettingsRepository;

  constructor(bridgeClient: BridgeClient, inboxRepository: InboxRepository,
    taskRepository: TaskRepository, settingsRepository: SettingsRepository) {
    this.bridgeClient = bridgeClient;
    this.inboxRepository = inboxRepository;
    this.taskRepository = taskRepository;
    this.settingsRepository = settingsRepository;
  }

  async uploadInboxItem(item: InboxItem): Promise<BridgeResult> {
    await this.inboxRepository.updateSyncStatus(item.id, SyncStatus.PENDING);
    const result: BridgeResult = await this.bridgeClient.sendInboxItem(item);
    await this.inboxRepository.updateSyncStatus(item.id, result.success ? SyncStatus.SYNCED : SyncStatus.FAILED);
    return result;
  }

  async uploadTask(task: CodexTask): Promise<BridgeResult> {
    await this.taskRepository.updateSyncStatus(task.id, TaskSyncStatus.PENDING);
    const result: BridgeResult = await this.bridgeClient.sendTask(task);
    await this.taskRepository.updateSyncStatus(task.id,
      result.success ? TaskSyncStatus.SYNCED : TaskSyncStatus.FAILED);
    return result;
  }

  async syncPending(): Promise<BridgeResult> {
    const settings: BridgeSettings = await this.settingsRepository.getBridgeSettings();
    if (!settings.isConfigured()) return new BridgeResult(false, 'Bridge 尚未配置');
    const inbox: Array<InboxItem> = await this.inboxRepository.listUnsynced();
    let failures: number = 0;
    for (let index: number = 0; index < inbox.length; index += 1) {
      const result: BridgeResult = await this.uploadInboxItem(inbox[index]);
      if (!result.success) failures += 1;
    }
    const tasks: Array<CodexTask> = await this.taskRepository.listUnsynced();
    for (let index: number = 0; index < tasks.length; index += 1) {
      const result: BridgeResult = await this.uploadTask(tasks[index]);
      if (!result.success) failures += 1;
    }
    const total: number = inbox.length + tasks.length;
    return new BridgeResult(failures === 0,
      failures === 0 ? `已同步 ${total} 条记录` : `${failures} / ${total} 条记录同步失败`);
  }

  async healthCheck(): Promise<BridgeResult> {
    return await this.bridgeClient.healthCheck();
  }

  async searchBrain(query: string): Promise<Array<BrainSearchResult>> {
    return await this.bridgeClient.searchBrain(query);
  }

  async refreshTaskStatus(taskId: string): Promise<BridgeResult> {
    const result: BridgeResult = await this.bridgeClient.getTaskStatus(taskId);
    if (!result.success) return result;
    try {
      const response: BridgeTaskResponse = JSON.parse(result.data) as BridgeTaskResponse;
      let status: CodexTaskStatus = CodexTaskStatus.PENDING;
      if (response.task.status === CodexTaskStatus.SENT) status = CodexTaskStatus.SENT;
      else if (response.task.status === CodexTaskStatus.DONE) status = CodexTaskStatus.DONE;
      else if (response.task.status === CodexTaskStatus.FAILED) status = CodexTaskStatus.FAILED;
      const remoteResult: string = typeof response.task.result === 'string' ? response.task.result : '';
      const applied: boolean = await this.taskRepository.applyRemoteState(taskId, status, remoteResult);
      return new BridgeResult(applied, applied ? '已刷新 Bridge 任务状态' : '本地任务不存在',
        result.responseCode, result.data);
    } catch (error) {
      console.error(`Bridge task response could not be parsed: ${error}`);
      return new BridgeResult(false, 'Bridge 任务响应格式无效', result.responseCode);
    }
  }
}
