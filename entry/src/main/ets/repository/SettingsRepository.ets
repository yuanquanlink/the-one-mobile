import { BridgeSettings } from '../model/BridgeSettings';
import { AppPreferences } from '../storage/AppPreferences';

const ADDRESS_KEY: string = 'bridge_address';
const PORT_KEY: string = 'bridge_port';
const TOKEN_KEY: string = 'bridge_token';
const AUTO_SYNC_KEY: string = 'bridge_auto_sync';
const DEVICE_NAME_KEY: string = 'device_name';

export class SettingsRepository {
  private storage: AppPreferences;

  constructor(storage: AppPreferences) {
    this.storage = storage;
  }

  async getBridgeSettings(): Promise<BridgeSettings> {
    return new BridgeSettings(
      await this.storage.getString(ADDRESS_KEY, ''),
      await this.storage.getString(PORT_KEY, '4317'),
      await this.storage.getString(TOKEN_KEY, ''),
      await this.storage.getBoolean(AUTO_SYNC_KEY, false),
      await this.storage.getString(DEVICE_NAME_KEY, 'Mate 70 Pro')
    );
  }

  async saveBridgeSettings(settings: BridgeSettings): Promise<void> {
    const port: number = Number(settings.port);
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      throw new Error('Bridge 端口必须在 1 到 65535 之间');
    }
    await this.storage.putString(ADDRESS_KEY, settings.address.trim());
    await this.storage.putString(PORT_KEY, settings.port.trim());
    await this.storage.putString(TOKEN_KEY, settings.token.trim());
    await this.storage.putBoolean(AUTO_SYNC_KEY, settings.autoSync);
    await this.storage.putString(DEVICE_NAME_KEY, settings.deviceName.trim());
  }
}
