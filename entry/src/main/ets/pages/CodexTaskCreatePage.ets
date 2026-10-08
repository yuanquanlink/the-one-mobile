import { AppServiceContainer } from '../services/AppServiceContainer';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct CodexTaskCreatePage {
  pathStack: NavPathStack = new NavPathStack();
  onDataChanged: () => void = (): void => {};

  @State private title: string = '';
  @State private description: string = '';
  @State private saving: boolean = false;

  private async save(): Promise<void> {
    if (this.title.trim().length === 0 || this.saving) {
      return;
    }
    this.saving = true;
    try {
      await AppServiceContainer.get().taskService.create(this.title, this.description);
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: 'Codex 任务已创建' });
      this.pathStack.pop();
    } catch (error) {
      console.error(`Task creation failed: ${error}`);
      this.getUIContext().getPromptAction().showToast({ message: '创建失败，请稍后重试' });
    } finally {
      this.saving = false;
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 22 }) {
          Column({ space: 10 }) {
            Text('任务标题')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            TextInput({ placeholder: '例如：整理本周 AI 学习笔记', text: this.title })
              .height(54)
              .fontSize(16)
              .fontColor(AppColors.TEXT)
              .placeholderColor(AppColors.TEXT_MUTED)
              .padding({ left: 16, right: 16 })
              .backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: AppColors.BORDER })
              .borderRadius(16)
              .onChange((value: string): void => {
                this.title = value;
              })
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('任务说明')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            TextArea({ placeholder: '写清目标、输入材料和期望输出…', text: this.description })
              .height(240)
              .fontSize(16)
              .fontColor(AppColors.TEXT)
              .placeholderColor(AppColors.TEXT_MUTED)
              .padding(16)
              .backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: AppColors.BORDER })
              .borderRadius(18)
              .onChange((value: string): void => {
                this.description = value;
              })
          }
          .width('100%')

          Row({ space: 10 }) {
            Circle({ width: 7, height: 7 }).fill(AppColors.WARNING)
            Text('任务会先进入本地 pending 队列，未来由 Bridge 发送到电脑。')
              .layoutWeight(1)
              .fontSize(12)
              .fontColor(AppColors.TEXT_MUTED)
              .lineHeight(18)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#231F19')
          .borderRadius(14)

          Button(this.saving ? '创建中…' : '创建任务')
            .width('100%')
            .height(52)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.BACKGROUND)
            .backgroundColor(this.title.trim().length > 0 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
            .borderRadius(26)
            .enabled(this.title.trim().length > 0 && !this.saving)
            .onClick((): void => {
              this.save();
            })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 20, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('创建 Codex 任务')
    .backgroundColor(AppColors.BACKGROUND)
  }
}

