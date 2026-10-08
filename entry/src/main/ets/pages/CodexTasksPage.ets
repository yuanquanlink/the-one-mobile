import { EmptyState } from '../components/EmptyState';
import { StatusBadge } from '../components/StatusBadge';
import { CodexTask, CodexTaskStatus } from '../model/CodexTask';
import { NavigationState, Routes } from '../navigation/Routes';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { formatDateTime } from '../utils/DateTime';
import { summarize, taskStatusLabel } from '../utils/DisplayText';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct CodexTasksPage {
  pathStack: NavPathStack = new NavPathStack();
  onDataChanged: () => void = (): void => {};

  @State private tasks: Array<CodexTask> = [];
  @State private loading: boolean = true;
  @State private searchText: string = '';
  @State private filter: string = 'all';

  aboutToAppear(): void {
    this.loadTasks();
  }

  private async loadTasks(): Promise<void> {
    this.loading = true;
    try {
      let status: CodexTaskStatus | null = null;
      if (this.filter === 'pending') status = CodexTaskStatus.PENDING;
      if (this.filter === 'sent') status = CodexTaskStatus.SENT;
      if (this.filter === 'done') status = CodexTaskStatus.DONE;
      if (this.filter === 'failed') status = CodexTaskStatus.FAILED;
      this.tasks = await AppServiceContainer.get().taskRepository.search(this.searchText, status);
    } catch (error) {
      console.error(`Task load failed: ${error}`);
      this.getUIContext().getPromptAction().showToast({ message: '任务列表加载失败' });
    } finally {
      this.loading = false;
    }
  }

  private openDetail(id: string): void {
    NavigationState.selectedTaskId = id;
    this.pathStack.pushPath({ name: Routes.CODEX_TASK_DETAIL });
  }

  private nextStatus(current: CodexTaskStatus): CodexTaskStatus {
    if (current === CodexTaskStatus.PENDING) {
      return CodexTaskStatus.SENT;
    }
    if (current === CodexTaskStatus.SENT) {
      return CodexTaskStatus.DONE;
    }
    return CodexTaskStatus.PENDING;
  }

  private async advance(task: CodexTask): Promise<void> {
    const status: CodexTaskStatus = this.nextStatus(task.status);
    const updated: boolean = await AppServiceContainer.get().taskRepository.updateStatus(task.id, status);
    if (updated) {
      await this.loadTasks();
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: `任务状态：${taskStatusLabel(status)}` });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Column({ space: 3 }) {
            Text('准备交给电脑执行的工作')
              .fontSize(13)
              .fontColor(AppColors.TEXT_SECONDARY)
            Text('本地优先 · 可同步到 Bridge 队列')
              .fontSize(11)
              .fontColor(AppColors.TEXT_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button('+ 新任务')
            .height(36)
            .fontSize(13)
            .fontColor(AppColors.BACKGROUND)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(18)
            .onClick((): void => {
              this.pathStack.pushPath({ name: Routes.CODEX_TASK_CREATE });
            })
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 12, bottom: 14 })

        Column({ space: 10 }) {
          TextInput({ placeholder: '搜索任务', text: this.searchText })
            .height(44)
            .fontSize(14)
            .fontColor(AppColors.TEXT)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.SURFACE)
            .borderRadius(14)
            .onChange((value: string): void => {
              this.searchText = value;
              this.loadTasks();
            })
          Scroll() {
            Row({ space: 8 }) {
              ForEach(['all', 'pending', 'sent', 'done', 'failed'], (value: string) => {
                Button(value === 'all' ? '全部' : taskStatusLabel(value as CodexTaskStatus))
                  .height(32)
                  .fontSize(11)
                  .fontColor(this.filter === value ? AppColors.BACKGROUND : AppColors.TEXT_SECONDARY)
                  .backgroundColor(this.filter === value ? AppColors.PRIMARY : AppColors.SURFACE)
                  .borderRadius(16)
                  .onClick((): void => {
                    this.filter = value;
                    this.loadTasks();
                  })
              })
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, bottom: 14 })

        if (!this.loading && this.tasks.length === 0) {
          EmptyState({ title: '还没有 Codex 任务', message: '创建一个任务，为未来连接 The One Bridge 做准备。' })
        } else {
          List({ space: 12 }) {
            ForEach(this.tasks, (task: CodexTask) => {
              ListItem() {
                Column({ space: 12 }) {
                  Row() {
                    Text('CODEX')
                      .fontSize(10)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(AppColors.PRIMARY)
                      .letterSpacing(1.2)
                    Blank()
                    StatusBadge({
                      label: taskStatusLabel(task.status),
                      active: task.status === CodexTaskStatus.DONE
                    })
                  }
                  .width('100%')

                  Text(task.title)
                    .width('100%')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (task.description.length > 0) {
                    Text(summarize(task.description, 100))
                      .width('100%')
                      .fontSize(13)
                      .fontColor(AppColors.TEXT_SECONDARY)
                      .lineHeight(20)
                      .maxLines(3)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }

                  Row() {
                    Text(formatDateTime(task.createdAt))
                      .fontSize(11)
                      .fontColor(AppColors.TEXT_MUTED)
                    Blank()
                    Button(task.status === CodexTaskStatus.PENDING ? '标记已发送' :
                      task.status === CodexTaskStatus.SENT ? '标记完成' : '重新打开')
                      .height(32)
                      .fontSize(11)
                      .fontColor(AppColors.TEXT_SECONDARY)
                      .backgroundColor(AppColors.SURFACE_RAISED)
                      .borderRadius(16)
                      .onClick((): void => {
                        this.advance(task);
                      })
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(16)
                .backgroundColor(AppColors.SURFACE)
                .border({ width: 1, color: AppColors.BORDER })
                .borderRadius(18)
                .onClick((): void => {
                  this.openDetail(task.id);
                })
              }
            }, (task: CodexTask): string => task.id)
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
    .title('Codex Tasks')
    .backgroundColor(AppColors.BACKGROUND)
    .onShown((): void => {
      this.loadTasks();
    })
  }
}
