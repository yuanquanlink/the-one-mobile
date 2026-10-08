import { common } from '@kit.AbilityKit';
import { InboxRepository } from '../repository/InboxRepository';
import { TaskRepository } from '../repository/TaskRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AppPreferences } from '../storage/AppPreferences';
import { CaptureService } from './CaptureService';
import { HttpBridgeClient } from './BridgeClient';
import { SyncService } from './SyncService';
import { TaskService } from './TaskService';

export class AppServiceContainer {
  private static instance: AppServiceContainer | null = null;

  readonly inboxRepository: InboxRepository;
  readonly taskRepository: TaskRepository;
  readonly settingsRepository: SettingsRepository;
  readonly captureService: CaptureService;
  readonly taskService: TaskService;
  readonly syncService: SyncService;

  private constructor(context: common.Context) {
    const storage: AppPreferences = new AppPreferences(context);
    this.inboxRepository = new InboxRepository(storage);
    this.taskRepository = new TaskRepository(storage);
    this.settingsRepository = new SettingsRepository(storage);
    this.syncService = new SyncService(new HttpBridgeClient(this.settingsRepository),
      this.inboxRepository, this.taskRepository, this.settingsRepository);
    this.captureService = new CaptureService(this.inboxRepository, this.syncService, this.settingsRepository);
    this.taskService = new TaskService(this.taskRepository, this.syncService, this.settingsRepository);
  }

  static initialize(context: common.Context): void {
    if (AppServiceContainer.instance === null) {
      AppServiceContainer.instance = new AppServiceContainer(context);
    }
  }

  static get(): AppServiceContainer {
    if (AppServiceContainer.instance === null) {
      throw new Error('AppServiceContainer must be initialized by EntryAbility');
    }
    return AppServiceContainer.instance;
  }
}
