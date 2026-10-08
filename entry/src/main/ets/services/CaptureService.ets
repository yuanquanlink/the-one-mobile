import { InboxItem, InboxType } from '../model/InboxItem';
import { InboxRepository } from '../repository/InboxRepository';
import { IdGenerator } from '../utils/IdGenerator';
import { SettingsRepository } from '../repository/SettingsRepository';
import { SyncService } from './SyncService';
import { BridgeSettings } from '../model/BridgeSettings';

export class CaptureService {
  private repository: InboxRepository;
  private syncService: SyncService | null;
  private settingsRepository: SettingsRepository | null;

  constructor(repository: InboxRepository, syncService: SyncService | null = null,
    settingsRepository: SettingsRepository | null = null) {
    this.repository = repository;
    this.syncService = syncService;
    this.settingsRepository = settingsRepository;
  }

  async capture(content: string, type: InboxType, tags: Array<string> = []): Promise<InboxItem> {
    const normalized: string = content.trim();
    if (normalized.length === 0) {
      throw new Error('内容不能为空');
    }
    const item: InboxItem = new InboxItem(IdGenerator.next('inbox'), normalized, Date.now(), type);
    item.tags = tags;
    await this.repository.save(item);
    if (this.syncService !== null && this.settingsRepository !== null) {
      const settings: BridgeSettings = await this.settingsRepository.getBridgeSettings();
      if (settings.autoSync && settings.isConfigured()) {
        await this.syncService.uploadInboxItem(item);
      }
    }
    return item;
  }
}
