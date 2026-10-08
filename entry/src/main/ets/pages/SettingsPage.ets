import { BridgeResult } from '../model/BridgeModels';
import { BridgeSettings } from '../model/BridgeSettings';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct SettingsPage {
  @State private address: string = '';
  @State private port: string = '4317';
  @State private token: string = '';
  @State private autoSync: boolean = false;
  @State private deviceName: string = 'Mate 70 Pro';
  @State private connectionState: string = '尚未测试';
  @State private inboxCount: number = 0;
  @State private taskCount: number = 0;
  @State private busy: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const settings: BridgeSettings = await AppServiceContainer.get().settingsRepository.getBridgeSettings();
    this.address = settings.address;
    this.port = settings.port;
    this.token = settings.token;
    this.autoSync = settings.autoSync;
    this.deviceName = settings.deviceName;
    this.inboxCount = (await AppServiceContainer.get().inboxRepository.list()).length;
    this.taskCount = (await AppServiceContainer.get().taskRepository.list()).length;
  }

  private currentSettings(): BridgeSettings {
    return new BridgeSettings(this.address, this.port, this.token, this.autoSync, this.deviceName);
  }

  private async save(): Promise<void> {
    try {
      await AppServiceContainer.get().settingsRepository.saveBridgeSettings(this.currentSettings());
      this.getUIContext().getPromptAction().showToast({ message: '设置已保存' });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}` });
    }
  }

  private async testConnection(): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    await this.save();
    const result: BridgeResult = await AppServiceContainer.get().syncService.healthCheck();
    this.connectionState = result.success ? '已连接' : result.message;
    this.busy = false;
  }

  private async syncNow(): Promise<void> {
    if (this.busy) return;
    this.busy = true;
    await this.save();
    const result: BridgeResult = await AppServiceContainer.get().syncService.syncPending();
    this.getUIContext().getPromptAction().showToast({ message: result.message });
    this.busy = false;
  }

  private async clearTestData(): Promise<void> {
    const inboxRemoved: number = await AppServiceContainer.get().inboxRepository.removeTestData();
    const taskRemoved: number = await AppServiceContainer.get().taskRepository.removeTestData();
    await this.load();
    this.getUIContext().getPromptAction().showToast({
      message: `已清理 ${inboxRemoved + taskRemoved} 条明确标记的测试数据`
    });
  }

  private confirmClearTestData(): void {
    AlertDialog.show({
      title: '清理测试数据？',
      message: '仅删除标签为 test 的 Inbox 和标题以 [TEST] 开头的任务。其他数据不会受影响。',
      primaryButton: { value: '取消', action: (): void => {} },
      secondaryButton: {
        value: '确认清理',
        fontColor: AppColors.DANGER,
        action: (): void => { this.clearTestData(); }
      }
    });
  }

  @Builder
  private label(text: string) {
    Text(text)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_SECONDARY)
      .width('100%')
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 22 }) {
          Column({ space: 6 }) {
            Text('THE ONE')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .letterSpacing(2)
            Text('Mobile V1.0')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
            Text('本地优先；Bridge 不可用时，数据仍会安全留在手机。')
              .fontSize(13)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: 12 }) {
            Text(`THE ONE BRIDGE · ${this.connectionState}`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .width('100%')
            this.label('电脑地址（例如 192.168.1.8）')
            TextInput({ text: this.address, placeholder: '未配置' })
              .height(48)
              .fontColor(AppColors.TEXT)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(14)
              .onChange((value: string): void => { this.address = value; })
            this.label('端口')
            TextInput({ text: this.port, placeholder: '4317' })
              .height(48)
              .type(InputType.Number)
              .fontColor(AppColors.TEXT)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(14)
              .onChange((value: string): void => { this.port = value; })
            this.label('配对 Token（留空则只适用于电脑本机模式）')
            TextInput({ text: this.token, placeholder: '不会写入 Git' })
              .height(48)
              .type(InputType.Password)
              .fontColor(AppColors.TEXT)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(14)
              .onChange((value: string): void => { this.token = value; })
            Row() {
              Text('自动同步').fontSize(14).fontColor(AppColors.TEXT_SECONDARY)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.autoSync })
                .onChange((value: boolean): void => { this.autoSync = value; })
            }
            .width('100%')
            Row({ space: 10 }) {
              Button('保存')
                .layoutWeight(1)
                .onClick((): void => { this.save(); })
              Button(this.busy ? '测试中…' : '测试连接')
                .layoutWeight(1)
                .enabled(!this.busy)
                .fontColor(AppColors.BACKGROUND)
                .backgroundColor(AppColors.PRIMARY)
                .onClick((): void => { this.testConnection(); })
            }
            .width('100%')
            Button('立即同步待处理数据')
              .width('100%')
              .enabled(!this.busy)
              .onClick((): void => { this.syncNow(); })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.SURFACE)
          .border({ width: 1, color: AppColors.BORDER })
          .borderRadius(18)

          Column({ space: 12 }) {
            this.label('设备名称')
            TextInput({ text: this.deviceName, placeholder: 'Mate 70 Pro' })
              .height(48)
              .fontColor(AppColors.TEXT)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(14)
              .onChange((value: string): void => { this.deviceName = value; })
            Text(`本地数据：Inbox ${this.inboxCount} · Tasks ${this.taskCount}`)
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            Text('HarmonyOS 7 · API 26 · The One Mobile 1.0.0')
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
              .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(18)

          Button('清理明确标记的测试数据')
            .width('100%')
            .fontColor(AppColors.DANGER)
            .backgroundColor('#2B1C24')
            .onClick((): void => { this.confirmClearTestData(); })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 24, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('设置')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
