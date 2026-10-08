import { CodexTask, CodexTaskStatus } from '../model/CodexTask';
import { BridgeResult } from '../model/BridgeModels';
import { NavigationState } from '../navigation/Routes';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { taskStatusLabel } from '../utils/DisplayText';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct CodexTaskDetailPage {
  pathStack: NavPathStack = new NavPathStack();
  onDataChanged: () => void = (): void => {};

  @State private found: boolean = false;
  @State private title: string = '';
  @State private description: string = '';
  @State private status: CodexTaskStatus = CodexTaskStatus.PENDING;
  @State private editing: boolean = false;

  aboutToAppear(): void {
    this.loadTask();
  }

  private async loadTask(): Promise<void> {
    const task: CodexTask | null = await AppServiceContainer.get().taskRepository
      .getById(NavigationState.selectedTaskId);
    if (task === null) {
      this.found = false;
      return;
    }
    this.title = task.title;
    this.description = task.description;
    this.status = task.status;
    this.found = true;
  }

  private async save(): Promise<void> {
    if (this.title.trim().length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '标题不能为空' });
      return;
    }
    const task: CodexTask | null = await AppServiceContainer.get().taskRepository
      .getById(NavigationState.selectedTaskId);
    if (task === null) return;
    task.title = this.title.trim();
    task.description = this.description.trim();
    if (await AppServiceContainer.get().taskRepository.update(task)) {
      this.editing = false;
      this.onDataChanged();
      this.getUIContext().getPromptAction().showToast({ message: '任务已更新' });
    }
  }

  private async setStatus(status: CodexTaskStatus): Promise<void> {
    if (await AppServiceContainer.get().taskRepository.updateStatus(NavigationState.selectedTaskId, status)) {
      this.status = status;
      this.onDataChanged();
    }
  }

  private async retrySync(): Promise<void> {
    const task: CodexTask | null = await AppServiceContainer.get().taskRepository
      .getById(NavigationState.selectedTaskId);
    if (task === null) return;
    const result: BridgeResult = await AppServiceContainer.get().syncService.uploadTask(task);
    this.getUIContext().getPromptAction().showToast({ message: result.message });
  }

  private async refreshFromBridge(): Promise<void> {
    const result: BridgeResult = await AppServiceContainer.get().syncService
      .refreshTaskStatus(NavigationState.selectedTaskId);
    if (result.success) await this.loadTask();
    this.getUIContext().getPromptAction().showToast({ message: result.message });
  }

  private async deleteTask(): Promise<void> {
    if (await AppServiceContainer.get().taskRepository.remove(NavigationState.selectedTaskId)) {
      this.onDataChanged();
      this.pathStack.pop();
    }
  }

  private confirmDelete(): void {
    AlertDialog.show({
      title: '删除这个任务？',
      message: '删除后无法从 App 内恢复。',
      primaryButton: { value: '取消', action: (): void => {} },
      secondaryButton: {
        value: '删除',
        fontColor: AppColors.DANGER,
        action: (): void => { this.deleteTask(); }
      }
    });
  }

  build() {
    NavDestination() {
      if (!this.found) {
        Text('任务不存在')
          .fontColor(AppColors.TEXT)
          .padding(32)
      } else {
        Scroll() {
          Column({ space: 18 }) {
            if (this.editing) {
              TextInput({ text: this.title, placeholder: '任务标题' })
                .height(52)
                .fontColor(AppColors.TEXT)
                .backgroundColor(AppColors.SURFACE)
                .borderRadius(15)
                .onChange((value: string): void => { this.title = value; })
              TextArea({ text: this.description, placeholder: '任务说明' })
                .height(220)
                .fontColor(AppColors.TEXT)
                .backgroundColor(AppColors.SURFACE)
                .borderRadius(16)
                .onChange((value: string): void => { this.description = value; })
              Button('保存修改')
                .width('100%')
                .fontColor(AppColors.BACKGROUND)
                .backgroundColor(AppColors.PRIMARY)
                .onClick((): void => { this.save(); })
            } else {
              Text(this.title)
                .width('100%')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)
              Text(this.description.length > 0 ? this.description : '暂无任务说明')
                .width('100%')
                .fontSize(15)
                .lineHeight(23)
                .fontColor(AppColors.TEXT_SECONDARY)
              Text(`当前状态：${taskStatusLabel(this.status)}`)
                .width('100%')
                .fontSize(13)
                .fontColor(AppColors.TEXT_MUTED)
              Button('编辑任务')
                .width('100%')
                .onClick((): void => { this.editing = true; })
            }

            Row({ space: 8 }) {
              Button('待执行').onClick((): void => { this.setStatus(CodexTaskStatus.PENDING); })
              Button('已发送').onClick((): void => { this.setStatus(CodexTaskStatus.SENT); })
              Button('已完成').onClick((): void => { this.setStatus(CodexTaskStatus.DONE); })
              Button('失败').onClick((): void => { this.setStatus(CodexTaskStatus.FAILED); })
            }
            .width('100%')

            Button('重试同步到 Bridge')
              .width('100%')
              .onClick((): void => { this.retrySync(); })

            Button('刷新 Bridge 任务状态')
              .width('100%')
              .onClick((): void => { this.refreshFromBridge(); })

            Button('删除任务')
              .width('100%')
              .fontColor(AppColors.DANGER)
              .backgroundColor('#2B1C24')
              .onClick((): void => { this.confirmDelete(); })
          }
          .width('100%')
          .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 22, bottom: 36 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .title('任务详情')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
