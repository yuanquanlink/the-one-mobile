import { BrainSearchRequest, BrainSearchResult, BridgeResult, BridgeSearchHit,
  BridgeSearchResponse, InboxSyncPayload, TaskSyncPayload } from '../model/BridgeModels';
import { InboxItem } from '../model/InboxItem';
import { CodexTask } from '../model/CodexTask';
import { BridgeSettings } from '../model/BridgeSettings';
import { SettingsRepository } from '../repository/SettingsRepository';
import { http } from '@kit.NetworkKit';

export interface BridgeClient {
  healthCheck(): Promise<BridgeResult>;
  sendInboxItem(item: InboxItem): Promise<BridgeResult>;
  sendTask(task: CodexTask): Promise<BridgeResult>;
  getTaskStatus(taskId: string): Promise<BridgeResult>;
  searchBrain(query: string): Promise<Array<BrainSearchResult>>;
}

export class DisabledBridgeClient implements BridgeClient {
  async healthCheck(): Promise<BridgeResult> {
    return new BridgeResult(false, 'Bridge 尚未配置');
  }
  async sendInboxItem(item: InboxItem): Promise<BridgeResult> {
    return new BridgeResult(false, `Bridge 尚未配置，记录 ${item.id} 仅保存在本机`);
  }

  async sendTask(task: CodexTask): Promise<BridgeResult> {
    return new BridgeResult(false, `Bridge 尚未配置，任务 ${task.id} 仅保存在本机`);
  }

  async getTaskStatus(taskId: string): Promise<BridgeResult> {
    return new BridgeResult(false, `Bridge 尚未配置，无法查询 ${taskId}`);
  }

  async searchBrain(query: string): Promise<Array<BrainSearchResult>> {
    console.info(`Bridge search deferred for query: ${query}`);
    return [];
  }
}

export class HttpBridgeClient implements BridgeClient {
  private settingsRepository: SettingsRepository;

  constructor(settingsRepository: SettingsRepository) {
    this.settingsRepository = settingsRepository;
  }

  private async request(path: string, method: http.RequestMethod,
    body: string = ''): Promise<BridgeResult> {
    const settings: BridgeSettings = await this.settingsRepository.getBridgeSettings();
    if (!settings.isConfigured()) return new BridgeResult(false, 'Bridge 尚未配置');
    const request: http.HttpRequest = http.createHttp();
    const headers: Record<string, string> = settings.token.length > 0 ? {
      'content-type': 'application/json',
      'x-the-one-token': settings.token
    } : { 'content-type': 'application/json' };
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: headers,
        connectTimeout: 5000,
        readTimeout: 5000
      };
      if (body.length > 0) options.extraData = body;
      const response: http.HttpResponse = await request.request(`${settings.baseUrl()}${path}`, options);
      const responseCode: number = response.responseCode;
      const responseData: string = typeof response.result === 'string' ?
        response.result : JSON.stringify(response.result);
      return new BridgeResult(responseCode >= 200 && responseCode < 300,
        responseCode >= 200 && responseCode < 300 ? 'Bridge 请求成功' : `Bridge 返回 ${responseCode}`,
        responseCode, responseData);
    } catch (error) {
      console.error(`Bridge request failed: ${error}`);
      return new BridgeResult(false, 'Bridge 离线或请求超时');
    } finally {
      request.destroy();
    }
  }

  async healthCheck(): Promise<BridgeResult> {
    return await this.request('/health', http.RequestMethod.GET);
  }

  async sendInboxItem(item: InboxItem): Promise<BridgeResult> {
    const payload: InboxSyncPayload = new InboxSyncPayload(item.id, item.content, item.type, item.tags);
    return await this.request('/api/inbox', http.RequestMethod.POST, JSON.stringify(payload));
  }

  async sendTask(task: CodexTask): Promise<BridgeResult> {
    const payload: TaskSyncPayload = new TaskSyncPayload(task.id, task.title,
      task.description, task.status);
    return await this.request('/api/tasks', http.RequestMethod.POST, JSON.stringify(payload));
  }

  async getTaskStatus(taskId: string): Promise<BridgeResult> {
    return await this.request(`/api/tasks/${encodeURIComponent(taskId)}`, http.RequestMethod.GET);
  }

  async searchBrain(query: string): Promise<Array<BrainSearchResult>> {
    const payload: BrainSearchRequest = new BrainSearchRequest(query);
    const result: BridgeResult = await this.request('/api/search', http.RequestMethod.POST,
      JSON.stringify(payload));
    if (!result.success) {
      console.info('Bridge brain search unavailable');
      return [];
    }
    try {
      const response: BridgeSearchResponse = JSON.parse(result.data) as BridgeSearchResponse;
      const mapped: Array<BrainSearchResult> = [];
      for (let index: number = 0; index < response.hits.length; index += 1) {
        const hit: BridgeSearchHit = response.hits[index];
        mapped.push(new BrainSearchResult(hit.path, hit.title, hit.excerpt));
      }
      return mapped;
    } catch (error) {
      console.error(`Bridge search response could not be parsed: ${error}`);
      return [];
    }
  }
}
