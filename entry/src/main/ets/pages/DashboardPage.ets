import { ControlCard } from '../components/ControlCard';
import { SectionHeader } from '../components/SectionHeader';
import { InboxType } from '../model/InboxItem';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { greetingForNow } from '../utils/DateTime';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct DashboardPage {
  inboxPending: number = 0;
  taskPending: number = 0;
  onOpenCapture: () => void = (): void => {};
  onOpenInbox: () => void = (): void => {};
  onOpenTasks: () => void = (): void => {};
  onOpenSettings: () => void = (): void => {};
  onOpenBrain: () => void = (): void => {};
  onDataChanged: () => void = (): void => {};

  @State private quickContent: string = '';
  @State private saving: boolean = false;

  private async saveQuickCapture(): Promise<void> {
    if (this.quickContent.trim().length === 0 || this.saving) {
      return;
    }
    this.saving = true;
    try {
      await AppServiceContainer.get().captureService.capture(this.quickContent, InboxType.IDEA);
      this.quickContent = '';
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: '已保存到 Inbox' });
    } catch (error) {
      console.error(`Quick capture failed: ${error}`);
      this.getUIContext().getPromptAction().showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.saving = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Column({ space: 5 }) {
            Text('THE ONE')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .letterSpacing(2.6)
            Text(greetingForNow())
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button() {
            Text('设置')
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .height(36)
          .padding({ left: 14, right: 14 })
          .backgroundColor(AppColors.SURFACE)
          .border({ width: 1, color: AppColors.BORDER })
          .borderRadius(18)
          .onClick(this.onOpenSettings)
        }
        .width('100%')

        Column({ space: 14 }) {
          Row() {
            Text('有什么想法？')
              .fontSize(19)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Blank()
            Text('IDEA')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .letterSpacing(1.2)
          }
          .width('100%')

          TextArea({ placeholder: '把此刻的想法留在这里…', text: this.quickContent })
            .height(112)
            .fontSize(16)
            .fontColor(AppColors.TEXT)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(Color.Transparent)
            .padding(0)
            .onChange((value: string): void => {
              this.quickContent = value;
            })

          Row() {
            Button('选择类型与标签')
              .height(42)
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
              .backgroundColor(AppColors.SURFACE_RAISED)
              .borderRadius(21)
              .onClick(this.onOpenCapture)
            Blank()
            Button(this.saving ? '保存中' : '收进 Inbox')
              .height(42)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.BACKGROUND)
              .backgroundColor(this.quickContent.trim().length > 0 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
              .borderRadius(21)
              .enabled(this.quickContent.trim().length > 0 && !this.saving)
              .onClick((): void => {
                this.saveQuickCapture();
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .margin({ top: 30 })
        .backgroundColor(AppColors.SURFACE)
        .border({ width: 1, color: AppColors.BORDER })
        .borderRadius(22)

        Column({ space: 14 }) {
          SectionHeader({ title: '控制中心', caption: '本机数据' })
          Row({ space: 12 }) {
            ControlCard({
              eyebrow: 'INBOX',
              title: '收件箱',
              value: this.inboxPending,
              onOpen: this.onOpenInbox
            })
              .layoutWeight(1)
            ControlCard({
              eyebrow: 'CODEX',
              title: '执行队列',
              value: this.taskPending,
              onOpen: this.onOpenTasks
            })
              .layoutWeight(1)
          }
          .width('100%')
          ControlCard({
            eyebrow: 'BRAIN',
            title: '本地检索',
            valueText: 'SEARCH',
            unit: 'Bridge 本地检索',
            onOpen: this.onOpenBrain
          })
          .width('100%')
        }
        .width('100%')
        .margin({ top: AppSpacing.SECTION })

        Row({ space: 8 }) {
          Circle({ width: 7, height: 7 })
            .fill(AppColors.SUCCESS)
          Text('本地优先 · Bridge 尚未连接')
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .margin({ top: 22, bottom: 24 })
      }
      .width('100%')
      .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
    .scrollBar(BarState.Off)
  }
}
