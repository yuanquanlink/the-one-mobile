import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'the_one_mobile_v1';

export class AppPreferences {
  private context: common.Context;
  private store: preferences.Preferences | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (this.store !== null) {
      return this.store;
    }
    const initializedStore: preferences.Preferences = await preferences.getPreferences(this.context, {
      name: STORE_NAME
    });
    this.store = initializedStore;
    return initializedStore;
  }

  async getString(key: string, fallback: string = ''): Promise<string> {
    const store: preferences.Preferences = await this.getStore();
    return await store.get(key, fallback) as string;
  }

  async putString(key: string, value: string): Promise<void> {
    const store: preferences.Preferences = await this.getStore();
    await store.put(key, value);
    await store.flush();
  }

  async getBoolean(key: string, fallback: boolean = false): Promise<boolean> {
    const store: preferences.Preferences = await this.getStore();
    return await store.get(key, fallback) as boolean;
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    const store: preferences.Preferences = await this.getStore();
    await store.put(key, value);
    await store.flush();
  }

  async preserveCorruptedValue(key: string, raw: string): Promise<void> {
    const backupKey: string = `${key}_corrupt_${Date.now()}`;
    await this.putString(backupKey, raw);
  }
}
