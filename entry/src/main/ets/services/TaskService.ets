import { CodexTask } from '../model/CodexTask';
import { TaskRepository } from '../repository/TaskRepository';
import { IdGenerator } from '../utils/IdGenerator';
import { SettingsRepository } from '../repository/SettingsRepository';
import { SyncService } from './SyncService';
import { BridgeSettings } from '../model/BridgeSettings';

export class TaskService {
  private repository: TaskRepository;
  private syncService: SyncService | null;
  private settingsRepository: SettingsRepository | null;

  constructor(repository: TaskRepository, syncService: SyncService | null = null,
    settingsRepository: SettingsRepository | null = null) {
    this.repository = repository;
    this.syncService = syncService;
    this.settingsRepository = settingsRepository;
  }

  async create(title: string, description: string): Promise<CodexTask> {
    const normalizedTitle: string = title.trim();
    const normalizedDescription: string = description.trim();
    if (normalizedTitle.length === 0) {
      throw new Error('任务标题不能为空');
    }
    const task: CodexTask = new CodexTask(IdGenerator.next('codex'), normalizedTitle,
      normalizedDescription, Date.now());
    await this.repository.save(task);
    if (this.syncService !== null && this.settingsRepository !== null) {
      const settings: BridgeSettings = await this.settingsRepository.getBridgeSettings();
      if (settings.autoSync && settings.isConfigured()) {
        await this.syncService.uploadTask(task);
      }
    }
    return task;
  }
}
