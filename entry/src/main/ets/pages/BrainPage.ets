import { BrainSearchResult } from '../model/BridgeModels';
import { BridgeSettings } from '../model/BridgeSettings';
import { AppServiceContainer } from '../services/AppServiceContainer';
import { AppColors, AppSpacing } from '../ui/Theme';

@Component
export struct BrainPage {
  @State private query: string = '';
  @State private results: Array<BrainSearchResult> = [];
  @State private status: string = 'Bridge 本地索引 · 未连接 Obsidian';
  @State private searching: boolean = false;

  private async search(): Promise<void> {
    const normalized: string = this.query.trim();
    if (normalized.length === 0 || this.searching) return;
    const settings: BridgeSettings = await AppServiceContainer.get().settingsRepository.getBridgeSettings();
    if (!settings.isConfigured()) {
      this.results = [];
      this.status = '离线：请先在设置中配置 Bridge';
      return;
    }
    this.searching = true;
    try {
      this.results = await AppServiceContainer.get().syncService.searchBrain(normalized);
      this.status = this.results.length > 0 ? `找到 ${this.results.length} 条 Bridge 本地结果` :
        '没有结果，或 Bridge 当前不可达';
    } catch (error) {
      console.error(`Brain search failed: ${error}`);
      this.results = [];
      this.status = '搜索失败；本地数据未受影响';
    } finally {
      this.searching = false;
    }
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 7 }) {
          Text('AI BRAIN')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)
            .letterSpacing(1.4)
            .width('100%')
          Text(this.status)
            .fontSize(13)
            .fontColor(AppColors.TEXT_MUTED)
            .width('100%')
        }
        .width('100%')

        Row({ space: 10 }) {
          TextInput({ text: this.query, placeholder: '搜索 Bridge 已接收的数据' })
            .layoutWeight(1)
            .height(48)
            .fontColor(AppColors.TEXT)
            .placeholderColor(AppColors.TEXT_MUTED)
            .backgroundColor(AppColors.SURFACE)
            .border({ width: 1, color: AppColors.BORDER })
            .borderRadius(15)
            .onChange((value: string): void => { this.query = value; })
          Button(this.searching ? '搜索中' : '搜索')
            .height(48)
            .enabled(!this.searching && this.query.trim().length > 0)
            .fontColor(AppColors.BACKGROUND)
            .backgroundColor(AppColors.PRIMARY)
            .borderRadius(24)
            .onClick((): void => { this.search(); })
        }
        .width('100%')

        if (!this.searching && this.results.length === 0) {
          Column({ space: 8 }) {
            Text('没有可显示的结果')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT)
            Text('当前只检索 Bridge 本地 Inbox/Task；不会伪装成 Obsidian 搜索。')
              .fontSize(13)
              .fontColor(AppColors.TEXT_MUTED)
              .lineHeight(20)
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.results, (result: BrainSearchResult) => {
              ListItem() {
                Column({ space: 8 }) {
                  Text(result.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT)
                    .width('100%')
                  Text(result.excerpt)
                    .fontSize(13)
                    .fontColor(AppColors.TEXT_SECONDARY)
                    .lineHeight(20)
                    .maxLines(4)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text(result.id)
                    .fontSize(10)
                    .fontColor(AppColors.TEXT_MUTED)
                    .maxLines(1)
                    .width('100%')
                }
                .width('100%')
                .padding(16)
                .backgroundColor(AppColors.SURFACE)
                .border({ width: 1, color: AppColors.BORDER })
                .borderRadius(17)
              }
            }, (result: BrainSearchResult): string => result.id)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppSpacing.PAGE, right: AppSpacing.PAGE, top: 18, bottom: 24 })
    }
    .title('Brain')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
