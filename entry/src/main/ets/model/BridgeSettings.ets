export class BridgeSettings {
  address: string;
  port: string;
  token: string;
  autoSync: boolean;
  deviceName: string;

  constructor(address: string = '', port: string = '4317', token: string = '',
    autoSync: boolean = false, deviceName: string = 'Mate 70 Pro') {
    this.address = address;
    this.port = port;
    this.token = token;
    this.autoSync = autoSync;
    this.deviceName = deviceName;
  }

  isConfigured(): boolean {
    const normalized: string = this.address.trim();
    const numericPort: number = Number(this.port);
    return normalized.length > 0 && !new RegExp('[\\s/:?#]').test(
      normalized.replace(new RegExp('^https?://'), '')) &&
      new RegExp('^\\d{1,5}$').test(this.port) && Number.isInteger(numericPort) &&
      numericPort >= 1 && numericPort <= 65535;
  }

  baseUrl(): string {
    const value: string = this.address.trim().replace(new RegExp('/$'), '');
    const scheme: string = value.startsWith('https://') ? 'https://' : 'http://';
    const host: string = value.replace(new RegExp('^https?://'), '');
    return `${scheme}${host}:${this.port}`;
  }
}
