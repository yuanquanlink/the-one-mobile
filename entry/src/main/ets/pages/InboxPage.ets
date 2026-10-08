import { EmptyState } from '../components/EmptyState';
import { StatusBadge } from '../components/StatusBadge';
import { TypeBadge } from '../components/TypeBadge';
import { InboxItem, InboxStatus } from '../model/InboxItem';
import { NavigationState, Routes } from '../navigation/Routes';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { formatDateTime } from '../utils/DateTime';
import { inboxStatusLabel, summarize } from '../utils/DisplayText';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct InboxPage {
  pathStack: NavPathStack = new NavPathStack();

  @State private items: Array<InboxItem> = [];
  @State private loading: boolean = true;
  @State private searchText: string = '';
  @State private filter: string = 'all';

  aboutToAppear(): void {
    this.loadItems();
  }

  private async loadItems(): Promise<void> {
    this.loading = true;
    try {
      let status: InboxStatus | null = null;
      if (this.filter === 'pending') status = InboxStatus.PENDING;
      if (this.filter === 'processed') status = InboxStatus.PROCESSED;
      this.items = await AppServiceContainer.get().inboxRepository.search(this.searchText, status);
    } catch (error) {
      console.error(`Inbox load failed: ${error}`);
      this.getUIContext().getPromptAction().showToast({ message: 'Inbox 加载失败' });
    } finally {
      this.loading = false;
    }
  }

  private openDetail(id: string): void {
    NavigationState.selectedInboxId = id;
    this.pathStack.pushPath({ name: Routes.INBOX_DETAIL });
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text(this.loading ? '读取中' : `${this.items.length} 条记录`)
            .fontSize(12)
            .fontColor(AppColors.TEXT_MUTED)
          Blank()
          Button('+ 收集')
            .height(36)
            .fontSize(13)
            .fontColor(AppColors.BACKGROUND)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(18)
            .onClick((): void => {
              this.pathStack.pushPath({ name: Routes.CAPTURE });
            })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 12, bottom: 12 })

        Column({ space: 10 }) {
          TextInput({ placeholder: '搜索内容或标签', text: this.searchText })
            .height(44)
            .fontSize(14)
            .fontColor(AppColors.TEXT)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.SURFACE)
            .border({ width: 1, color: AppColors.BORDER })
            .borderRadius(14)
            .onChange((value: string): void => {
              this.searchText = value;
              this.loadItems();
            })
          Row({ space: 8 }) {
            ForEach(['all', 'pending', 'processed'], (value: string) => {
              Button(value === 'all' ? '全部' : value === 'pending' ? '待处理' : '已处理')
                .height(34)
                .fontSize(12)
                .fontColor(this.filter === value ? AppColors.BACKGROUND : AppColors.TEXT_SECONDARY)
                .backgroundColor(this.filter === value ? AppColors.PRIMARY : AppColors.SURFACE)
                .borderRadius(17)
                .onClick((): void => {
                  this.filter = value;
                  this.loadItems();
                })
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, bottom: 14 })

        if (!this.loading && this.items.length === 0) {
          EmptyState({ title: 'Inbox 还是空的', message: '收下第一条想法，它会安全保存在这台手机上。' })
        } else {
          List({ space: 12 }) {
            ForEach(this.items, (item: InboxItem) => {
              ListItem() {
                Column({ space: 12 }) {
                  Row() {
                    TypeBadge({ type: item.type })
                    Blank()
                    StatusBadge({
                      label: inboxStatusLabel(item.status),
                      active: item.status === InboxStatus.PROCESSED
                    })
                  }
                  .width('100%')

                  Text(summarize(item.content))
                    .width('100%')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT)
                    .lineHeight(23)
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row() {
                    Text(formatDateTime(item.createdAt))
                      .fontSize(12)
                      .fontColor(AppColors.TEXT_MUTED)
                    Blank()
                    Text('查看  ›')
                      .fontSize(12)
                      .fontColor(AppColors.TEXT_SECONDARY)
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(16)
                .backgroundColor(AppColors.SURFACE)
                .border({ width: 1, color: AppColors.BORDER })
                .borderRadius(18)
                .onClick((): void => {
                  this.openDetail(item.id);
                })
              }
            }, (item: InboxItem): string => item.id)
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, bottom: 24 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('Inbox')
    .backgroundColor(AppColors.BACKGROUND)
    .onShown((): void => {
      this.loadItems();
    })
  }
}
