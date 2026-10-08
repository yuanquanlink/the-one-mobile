import { InboxType } from '../model/InboxItem';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { inboxTypeLabel } from '../utils/DisplayText';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct CapturePage {
  pathStack: NavPathStack = new NavPathStack();
  onDataChanged: () => void = (): void => {};

  @State private content: string = '';
  @State private tagsText: string = '';
  @State private selectedType: InboxType = InboxType.IDEA;
  @State private saving: boolean = false;

  private readonly types: Array<InboxType> = [
    InboxType.IDEA,
    InboxType.NOTE,
    InboxType.MATERIAL,
    InboxType.TASK
  ];

  private parseTags(): Array<string> {
    const rawTags: Array<string> = this.tagsText.replace(new RegExp('，', 'g'), ',').split(',');
    const tags: Array<string> = [];
    rawTags.forEach((value: string): void => {
      const tag: string = value.trim();
      if (tag.length > 0 && tags.indexOf(tag) < 0) {
        tags.push(tag);
      }
    });
    return tags;
  }

  private async save(): Promise<void> {
    if (this.content.trim().length === 0 || this.saving) {
      return;
    }
    this.saving = true;
    try {
      await AppServiceContainer.get().captureService.capture(this.content, this.selectedType, this.parseTags());
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: '已保存到 Inbox' });
      this.pathStack.pop();
    } catch (error) {
      console.error(`Capture failed: ${error}`);
      this.getUIContext().getPromptAction().showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.saving = false;
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 24 }) {
          Column({ space: 10 }) {
            Text('记录内容')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            TextArea({ placeholder: '输入想法、笔记、素材或待办…', text: this.content })
              .height(220)
              .fontSize(17)
              .fontColor(AppColors.TEXT)
              .placeholderColor(AppColors.TEXT_MUTED)
              .padding(16)
              .backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: AppColors.BORDER })
              .borderRadius(18)
              .onChange((value: string): void => {
                this.content = value;
              })
          }
          .width('100%')

          Column({ space: 12 }) {
            Text('类型')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.types, (type: InboxType) => {
                Button(inboxTypeLabel(type))
                  .height(38)
                  .fontSize(13)
                  .fontColor(this.selectedType === type ? AppColors.BACKGROUND : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.selectedType === type ? AppColors.PRIMARY : AppColors.SURFACE)
                  .border({ width: 1, color: this.selectedType === type ? AppColors.PRIMARY : AppColors.BORDER })
                  .borderRadius(19)
                  .margin({ right: 9, bottom: 9 })
                  .onClick((): void => {
                    this.selectedType = type;
                  })
              }, (type: InboxType): string => type)
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('标签（可选）')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
            TextInput({ placeholder: '用逗号分隔，例如：产品, 灵感', text: this.tagsText })
              .height(52)
              .fontSize(15)
              .fontColor(AppColors.TEXT)
              .placeholderColor(AppColors.TEXT_MUTED)
              .padding({ left: 16, right: 16 })
              .backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: AppColors.BORDER })
              .borderRadius(15)
              .onChange((value: string): void => {
                this.tagsText = value;
              })
          }
          .width('100%')

          Button(this.saving ? '保存中…' : '保存到 Inbox')
            .width('100%')
            .height(52)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.BACKGROUND)
            .backgroundColor(this.content.trim().length > 0 ? AppColors.PRIMARY : AppColors.TEXT_MUTED)
            .borderRadius(26)
            .enabled(this.content.trim().length > 0 && !this.saving)
            .onClick((): void => {
              this.save();
            })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 18, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('快速收集')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
