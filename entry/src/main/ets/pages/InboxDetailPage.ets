import { StatusBadge } from '../components/StatusBadge';
import { TypeBadge } from '../components/TypeBadge';
import { InboxItem, InboxStatus, InboxType } from '../model/InboxItem';
import { NavigationState } from '../navigation/Routes';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { formatDateTime } from '../utils/DateTime';
import { inboxStatusLabel } from '../utils/DisplayText';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct InboxDetailPage {
  pathStack: NavPathStack = new NavPathStack();
  onDataChanged: () => void = (): void => {};

  @State private found: boolean = false;
  @State private content: string = '';
  @State private createdAt: number = 0;
  @State private type: InboxType = InboxType.IDEA;
  @State private status: InboxStatus = InboxStatus.PENDING;
  @State private tags: Array<string> = [];
  @State private tagsText: string = '';
  @State private editing: boolean = false;

  aboutToAppear(): void {
    this.loadItem();
  }

  private async loadItem(): Promise<void> {
    const item: InboxItem | null = await AppServiceContainer.get().inboxRepository
      .getById(NavigationState.selectedInboxId);
    if (item === null) {
      this.found = false;
      return;
    }
    this.content = item.content;
    this.createdAt = item.createdAt;
    this.type = item.type;
    this.status = item.status;
    this.tags = item.tags;
    this.tagsText = item.tags.join(', ');
    this.found = true;
  }

  private parseTags(): Array<string> {
    const tags: Array<string> = [];
    this.tagsText.replace(new RegExp('，', 'g'), ',').split(',').forEach((raw: string): void => {
      const tag: string = raw.trim();
      if (tag.length > 0 && tags.indexOf(tag) < 0) tags.push(tag);
    });
    return tags;
  }

  private async saveEdit(): Promise<void> {
    const normalized: string = this.content.trim();
    if (normalized.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '内容不能为空' });
      return;
    }
    const existing: InboxItem | null = await AppServiceContainer.get().inboxRepository
      .getById(NavigationState.selectedInboxId);
    if (existing === null) return;
    existing.content = normalized;
    existing.tags = this.parseTags();
    const updated: boolean = await AppServiceContainer.get().inboxRepository.update(existing);
    if (updated) {
      this.tags = existing.tags;
      this.editing = false;
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: '修改已保存' });
    }
  }

  private async toggleStatus(): Promise<void> {
    const nextStatus: InboxStatus = this.status === InboxStatus.PENDING ?
      InboxStatus.PROCESSED : InboxStatus.PENDING;
    const updated: boolean = await AppServiceContainer.get().inboxRepository
      .updateStatus(NavigationState.selectedInboxId, nextStatus);
    if (updated) {
      this.status = nextStatus;
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: `已标记为${inboxStatusLabel(nextStatus)}` });
    }
  }

  private async deleteItem(): Promise<void> {
    const removed: boolean = await AppServiceContainer.get().inboxRepository.remove(NavigationState.selectedInboxId);
    if (removed) {
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: '记录已删除' });
      this.pathStack.pop();
    }
  }

  private confirmDelete(): void {
    AlertDialog.show({
      title: '删除这条记录？',
      message: '删除后无法从 App 内恢复。',
      primaryButton: {
        value: '取消',
        action: (): void => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppColors.DANGER,
        action: (): void => {
          this.deleteItem();
        }
      }
    });
  }

  build() {
    NavDestination() {
      if (!this.found) {
        Column({ space: 12 }) {
          Text('记录不存在')
            .fontSize(19)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT)
          Text('它可能已被删除。')
            .fontSize(13)
            .fontColor(AppColors.TEXT_MUTED)
        }
        .width('100%')
        .padding({ top: 72 })
      } else {
        Scroll() {
          Column({ space: 22 }) {
            Row() {
              TypeBadge({ type: this.type })
              Blank()
              StatusBadge({
                label: inboxStatusLabel(this.status),
                active: this.status === InboxStatus.PROCESSED
              })
            }
            .width('100%')

            if (this.editing) {
              TextArea({ text: this.content, placeholder: '记录内容' })
                .width('100%')
                .height(220)
                .fontSize(17)
                .fontColor(AppColors.TEXT)
                .backgroundColor(AppColors.SURFACE)
                .borderRadius(16)
                .padding(14)
                .onChange((value: string): void => {
                  this.content = value;
                })
              TextInput({ text: this.tagsText, placeholder: '标签用逗号分隔' })
                .width('100%')
                .height(48)
                .fontColor(AppColors.TEXT)
                .backgroundColor(AppColors.SURFACE)
                .borderRadius(14)
                .onChange((value: string): void => {
                  this.tagsText = value;
                })
              Row({ space: 10 }) {
                Button('取消')
                  .layoutWeight(1)
                  .onClick((): void => {
                    this.editing = false;
                    this.loadItem();
                  })
                Button('保存修改')
                  .layoutWeight(1)
                  .fontColor(AppColors.BACKGROUND)
                  .backgroundColor(AppColors.PRIMARY)
                  .onClick((): void => {
                    this.saveEdit();
                  })
              }
              .width('100%')
            } else {
              Text(this.content)
                .width('100%')
                .fontSize(18)
                .fontColor(AppColors.TEXT)
                .lineHeight(28)
                .copyOption(CopyOptions.LocalDevice)
              Button('编辑记录')
                .width('100%')
                .height(46)
                .fontSize(14)
                .fontColor(AppColors.TEXT_SECONDARY)
                .backgroundColor(AppColors.SURFACE_RAISED)
                .borderRadius(23)
                .onClick((): void => {
                  this.editing = true;
                })
            }

            Column({ space: 10 }) {
              Row() {
                Text('创建时间')
                  .fontSize(13)
                  .fontColor(AppColors.TEXT_MUTED)
                Blank()
                Text(formatDateTime(this.createdAt))
                  .fontSize(13)
                  .fontColor(AppColors.TEXT_SECONDARY)
              }
              .width('100%')

              if (this.tags.length > 0) {
                Row() {
                  Text('标签')
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_MUTED)
                  Blank()
                  Text(this.tags.join(' · '))
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .maxLines(2)
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(AppColors.SURFACE)
            .borderRadius(16)

            Button(this.status === InboxStatus.PENDING ? '标记为已处理' : '重新标记为待处理')
              .width('100%')
              .height(50)
              .fontSize(14)
              .fontColor(AppColors.BACKGROUND)
              .backgroundColor(AppColors.PRIMARY)
              .borderRadius(25)
              .onClick((): void => {
                this.toggleStatus();
              })

            Button('删除记录')
              .width('100%')
              .height(48)
              .fontSize(14)
              .fontColor(AppColors.DANGER)
              .backgroundColor('#2B1C24')
              .borderRadius(24)
              .onClick((): void => {
                this.confirmDelete();
              })
          }
          .width('100%')
          .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 22, bottom: 36 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title('记录详情')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
